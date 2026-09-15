#!/bin/zsh
# 打包 Flicker.dmg
# 用法: ./scripts/build_dmg.sh
# 产物: dist/Flicker-<version>.dmg
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PROJECT="$PROJECT_DIR/Flicker.xcodeproj"
SCHEME="Flicker"
CONFIG="Release"
BUILD_DIR="$PROJECT_DIR/build"
APP_PATH="$BUILD_DIR/Flicker.app"
echo "==> Universal Release 构建（arm64 + x86_64）"
# 手动清理 build 目录（xcodebuild clean 无法删除自定义 CONFIGURATION_BUILD_DIR）
rm -rf "$BUILD_DIR"
xcodebuild -project "$PROJECT" -scheme "$SCHEME" -configuration "$CONFIG" \
  -derivedDataPath "$BUILD_DIR/DerivedData" \
  -destination "generic/platform=macOS" \
  ARCHS="arm64 x86_64" ONLY_ACTIVE_ARCH=NO \
  CONFIGURATION_BUILD_DIR="$BUILD_DIR" build

if [[ ! -d "$APP_PATH" ]]; then
  echo "构建产物未找到: $APP_PATH" >&2
  exit 1
fi

# 主应用和扩展都必须包含两种架构，才允许生成安装包。
for EXECUTABLE in \
  "$APP_PATH/Contents/MacOS/Flicker" \
  "$APP_PATH/Contents/PlugIns/FlickerExtension.appex/Contents/MacOS/FlickerExtension"; do
  if [[ ! -f "$EXECUTABLE" ]]; then
    echo "构建产物缺失: $EXECUTABLE" >&2
    exit 1
  fi
  if ! xcrun lipo "$EXECUTABLE" -verify_arch arm64 x86_64; then
    echo "构建产物不是通用版本: $EXECUTABLE" >&2
    exit 1
  fi
  echo "==> 架构验证通过: $(xcrun lipo -archs "$EXECUTABLE")"
done

# 从构建产物中提取版本号
APP_VERSION=$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" "$APP_PATH/Contents/Info.plist")
echo "==> 应用版本: $APP_VERSION"

DMG_NAME="Flicker-${APP_VERSION}.dmg"
DMG_PATH="$PROJECT_DIR/dist/$DMG_NAME"

echo "==> 准备 DMG 暂存目录"
STAGING="$BUILD_DIR/dmg-staging"
rm -rf "$STAGING"
mkdir -p "$STAGING"
cp -R "$APP_PATH" "$STAGING/"
ln -s /Applications "$STAGING/Applications"

echo "==> 生成 DMG"
mkdir -p "$(dirname "$DMG_PATH")"
rm -f "$DMG_PATH"
hdiutil create -volname "Flicker" -srcfolder "$STAGING" \
  -fs "HFS+" -format "UDZO" -imagekey "zlib-level=9" "$DMG_PATH"

echo "==> 完成: $DMG_PATH"
rm -rf "$STAGING"
