#!/usr/bin/env python3
"""Build a locally signed Universal Flicker bundle using Apple's Command Line Tools.
No Xcode, preview macro plugin or asset compiler is required. Source files and the
installed toolchain are never modified; temporary compiler inputs live outside iCloud.
"""
import json
from pathlib import Path
import plistlib
import shutil
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parent.parent


def run(*args):
    print('+ ' + ' '.join(map(str, args)), flush=True)
    subprocess.run(list(map(str, args)), check=True)


def capture(*args):
    return subprocess.check_output(list(map(str, args)), text=True).strip()


def main():
    project = json.loads(capture('plutil', '-convert', 'json', '-o', '-', ROOT / 'Flicker.xcodeproj/project.pbxproj'))['objects']
    settings = project['A50202']['buildSettings']
    version = settings['MARKETING_VERSION']
    build = settings['CURRENT_PROJECT_VERSION']
    deployment = project['A50102']['buildSettings']['MACOSX_DEPLOYMENT_TARGET']
    sdk = capture('xcrun', '--sdk', 'macosx', '--show-sdk-path')
    swift = Path(capture('xcrun', '--find', 'swiftc'))
    output = ROOT / 'dist' / f'Flicker-{version}-CLT'
    output.mkdir(parents=True, exist_ok=True)

    with tempfile.TemporaryDirectory(prefix='flicker-clt-') as directory:
        work = Path(directory)
        (work / 'sources').mkdir()
        sources = {}
        for path in sorted((ROOT / 'Flicker').glob('**/*.swift')) + sorted((ROOT / 'FlickerExtension').glob('*.swift')):
            text = path.read_text()
            # All existing previews are at the end of their source files. Do not
            # silently omit runtime code if this project convention changes.
            if '\n#Preview {' in text:
                body, preview = text.split('\n#Preview {', 1)
                if not preview.rstrip().endswith('}'):
                    raise RuntimeError(f'Unexpected preview layout: {path}')
                text = body + '\n#if FLICKER_XCODE_PREVIEWS\n#Preview {' + preview + '\n#endif\n'
            dest = work / 'sources' / path.name
            dest.write_text(text)
            sources[path.name] = dest

        flags = ['-swift-version', '6', '-parse-as-library', '-O', '-sdk', sdk]
        # Some CLT installations contain two identical module declarations.
        # Hide only that duplicate through a compiler-local virtual filesystem.
        include = swift.parent.parent / 'include/swift'
        maps = [include / 'module.modulemap', include / 'bridging.modulemap']
        if all(p.exists() and 'module SwiftBridging' in p.read_text() for p in maps):
            empty = work / 'empty.modulemap'
            empty.write_text('')
            overlay = work / 'overlay.json'
            overlay.write_text(json.dumps({'version': 0, 'roots': [{'type': 'file', 'name': str(maps[0]), 'external-contents': str(empty)}]}))
            flags += ['-vfsoverlay', str(overlay), '-Xcc', '-ivfsoverlay', '-Xcc', str(overlay)]

        app = work / 'Flicker.app'
        extension = app / 'Contents/PlugIns/FlickerExtension.appex'
        for bundle in (app, extension):
            (bundle / 'Contents/MacOS').mkdir(parents=True)
            (bundle / 'Contents/Resources').mkdir()

        def info(template, bundle, name, identifier):
            replacements = {'DEVELOPMENT_LANGUAGE': 'en', 'EXECUTABLE_NAME': name,
                            'PRODUCT_BUNDLE_IDENTIFIER': identifier, 'PRODUCT_NAME': name,
                            'PRODUCT_MODULE_NAME': name, 'MARKETING_VERSION': version,
                            'CURRENT_PROJECT_VERSION': build, 'MACOSX_DEPLOYMENT_TARGET': deployment}
            text = template.read_text()
            for key, value in replacements.items():
                text = text.replace('$(' + key + ')', str(value))
            if '$(' in text:
                raise RuntimeError('Unresolved Info.plist build variable')
            data = plistlib.loads(text.encode())
            if name == 'Flicker':
                data.pop('CFBundleIconName', None)  # No compiled asset catalog.
                data['LSApplicationCategoryType'] = 'public.app-category.utilities'
            else:
                # FinderSync is exported with an explicit Objective-C name.
                data['NSExtension']['NSExtensionPrincipalClass'] = 'FinderSync'
            (bundle / 'Contents/Info.plist').write_bytes(plistlib.dumps(data))
            (bundle / 'Contents/PkgInfo').write_bytes((data['CFBundlePackageType'] + '????').encode())

        info(ROOT / 'Flicker/Resources/Info.plist', app, 'Flicker', settings['PRODUCT_BUNDLE_IDENTIFIER'])
        info(ROOT / 'FlickerExtension/Info.plist', extension, 'FlickerExtension', project['A50302']['buildSettings']['PRODUCT_BUNDLE_IDENTIFIER'])
        shutil.copy2(ROOT / 'Flicker/Resources/AppIcon.icns', app / 'Contents/Resources/AppIcon.icns')
        for path in (ROOT / 'Flicker/Resources/Assets.xcassets/MenuBarIcon.imageset').glob('*.png'):
            shutil.copy2(path, app / 'Contents/Resources' / path.name)

        # Read actual target source membership from the Xcode project.
        def target_sources(phase):
            result = []
            for build_id in project[phase]['files']:
                ref = project[project[build_id]['fileRef']]['path']
                result.append(sources[Path(ref).name])
            return result

        for arch in ('arm64', 'x86_64'):
            print(f'Building {arch}', flush=True)
            run(swift, *flags, '-target', f'{arch}-apple-macos{deployment}', '-module-name', 'Flicker',
                *target_sources('A41001'), '-o', work / f'Flicker-{arch}')
            run(swift, *flags, '-target', f'{arch}-apple-macos{deployment}', '-module-name', 'FlickerExtension',
                '-application-extension', *target_sources('A41004'), '-Xlinker', '-e', '-Xlinker', '_NSExtensionMain',
                '-o', work / f'FlickerExtension-{arch}')
        for name, bundle in [('Flicker', app), ('FlickerExtension', extension)]:
            executable = bundle / 'Contents/MacOS' / name
            run('xcrun', 'lipo', '-create', work / f'{name}-arm64', work / f'{name}-x86_64', '-output', executable)
            run('xcrun', 'lipo', executable, '-verify_arch', 'arm64', 'x86_64')

        entitlements = plistlib.loads((ROOT / 'FlickerExtension/FlickerExtension.entitlements').read_bytes())
        # The original exception contains the upstream author's username.
        entitlements['com.apple.security.temporary-exception.files.absolute-path.read-only'] = [
            str(Path.home() / 'Library/Application Support/Flicker') + '/']
        entitlements_file = work / 'extension.entitlements'
        entitlements_file.write_bytes(plistlib.dumps(entitlements))
        run('codesign', '--force', '--sign', '-', '--options', 'runtime', '--entitlements', entitlements_file, extension)
        run('codesign', '--force', '--sign', '-', '--options', 'runtime', '--entitlements', ROOT / 'Flicker/Resources/Flicker.entitlements', app)
        run('codesign', '--verify', '--deep', '--strict', '--verbose=2', app)
        # Versioned output is dedicated to this script; leave installed apps alone.
        destination = output / 'Flicker.app'
        if destination.exists():
            shutil.rmtree(destination)
        # Archive the verified temporary bundle before copying into iCloud:
        # Finder/iCloud may attach FinderInfo to .app directories, which fails
        # strict code-signature validation even though binary contents are intact.
        archive = output / f'Flicker-{version}-Universal.zip'
        run('ditto', '-c', '-k', '--sequesterRsrc', '--keepParent', app, archive)
        shutil.copytree(app, destination, symlinks=True, copy_function=shutil.copyfile)
        verification = work / 'archive-check'
        run('ditto', '-x', '-k', archive, verification)
        run('codesign', '--verify', '--deep', '--strict', '--verbose=2', verification / 'Flicker.app')
        print(f'Built: {destination}\nArchive: {archive}', flush=True)


if __name__ == '__main__':
    main()
