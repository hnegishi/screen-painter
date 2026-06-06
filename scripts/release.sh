#!/usr/bin/env bash
#
# ScreenPainter リリースビルドスクリプト
#
#   配布用の ScreenPainter.app をビルドし、.zip に固めて SHA256 を算出します。
#   署名なし(アドホック署名のみ)の構成です。
#
# 使い方:
#   scripts/release.sh                # ビルド + zip + SHA256 を表示
#   scripts/release.sh 1.1            # バージョンを明示してビルド
#   scripts/release.sh --release      # 上記に加えて gh で GitHub Release を作成
#   scripts/release.sh 1.1 --release  # 両方
#
set -euo pipefail

# --- リポジトリのルートへ移動 ---------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_ROOT"

PROJECT="ScreenPainter.xcodeproj"
SCHEME="ScreenPainter"
APP_NAME="ScreenPainter.app"
BUILD_DIR="$REPO_ROOT/build/release"
DIST_DIR="$REPO_ROOT/dist"

# --- 引数のパース ----------------------------------------------------------
VERSION=""
DO_RELEASE=0
for arg in "$@"; do
  case "$arg" in
    --release|-r) DO_RELEASE=1 ;;
    -*) echo "不明なオプション: $arg" >&2; exit 1 ;;
    *)  VERSION="$arg" ;;
  esac
done

# --- フル Xcode が選択されているか確認 ------------------------------------
DEVDIR="$(xcode-select -p 2>/dev/null || true)"
if [[ "$DEVDIR" != *"Xcode.app"* ]]; then
  cat >&2 <<EOF
エラー: このビルドにはフルの Xcode が必要です(現在は Command Line Tools)。

  現在の developer directory: ${DEVDIR:-(未設定)}

Xcode を選択してから再実行してください:
  sudo xcode-select -s /Applications/Xcode.app/Contents/Developer

Xcode 未インストールの場合は App Store からインストールしてください。
EOF
  exit 1
fi

# --- バージョン決定(未指定なら project の MARKETING_VERSION) --------------
if [[ -z "$VERSION" ]]; then
  VERSION="$(grep -m1 'MARKETING_VERSION' "$PROJECT/project.pbxproj" \
    | sed -E 's/.*= ([^;]+);/\1/' | tr -d ' ')"
fi
if [[ -z "$VERSION" ]]; then
  echo "エラー: バージョンを特定できませんでした。引数で指定してください: scripts/release.sh 1.0" >&2
  exit 1
fi

ZIP_NAME="ScreenPainter-${VERSION}.zip"
ZIP_PATH="$DIST_DIR/$ZIP_NAME"
TAG="v${VERSION}"

echo "==> ScreenPainter ${VERSION} をビルドします"

# --- クリーンビルド --------------------------------------------------------
rm -rf "$BUILD_DIR"
xcodebuild \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -configuration Release \
  -derivedDataPath "$BUILD_DIR" \
  -destination 'generic/platform=macOS' \
  ARCHS="x86_64 arm64" \
  ONLY_ACTIVE_ARCH=NO \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGN_IDENTITY="" \
  clean build

APP_PATH="$BUILD_DIR/Build/Products/Release/$APP_NAME"
if [[ ! -d "$APP_PATH" ]]; then
  echo "エラー: ビルド成果物が見つかりません: $APP_PATH" >&2
  exit 1
fi

# --- アドホック署名(unsigned よりは Gatekeeper 系の不具合が起きにくい) ----
echo "==> アドホック署名を付与します"
codesign --force --sign - --timestamp=none "$APP_PATH"

# --- .zip 化(ditto で macOS のメタデータを保持) --------------------------
echo "==> $ZIP_NAME を作成します"
mkdir -p "$DIST_DIR"
rm -f "$ZIP_PATH"
/usr/bin/ditto -c -k --sequesterRsrc --keepParent "$APP_PATH" "$ZIP_PATH"

# --- SHA256 算出 -----------------------------------------------------------
SHA256="$(shasum -a 256 "$ZIP_PATH" | awk '{print $1}')"

# --- リポジトリ owner/name を git remote から取得 -------------------------
REMOTE_URL="$(git remote get-url origin 2>/dev/null || echo '')"
REPO_SLUG="$(echo "$REMOTE_URL" | sed -E 's#(git@github.com:|https://github.com/)##; s#\.git$##')"
REPO_SLUG="${REPO_SLUG:-hnegishi/screen-painter}"
ASSET_URL="https://github.com/${REPO_SLUG}/releases/download/${TAG}/${ZIP_NAME}"

echo ""
echo "============================================================"
echo " ビルド完了"
echo "   zip   : $ZIP_PATH"
echo "   version: $VERSION   (tag: $TAG)"
echo "   sha256: $SHA256"
echo "============================================================"
echo ""
echo "Cask 用の値(Casks/screen-painter.rb を更新してください):"
echo "   version \"$VERSION\""
echo "   sha256 \"$SHA256\""
echo ""

# --- GitHub Release 作成(--release 指定時) --------------------------------
if [[ "$DO_RELEASE" -eq 1 ]]; then
  if ! command -v gh >/dev/null 2>&1; then
    echo "エラー: gh (GitHub CLI) が見つかりません。'brew install gh' でインストールしてください。" >&2
    exit 1
  fi
  echo "==> GitHub Release $TAG を作成し、$ZIP_NAME をアップロードします"
  if ! git rev-parse "$TAG" >/dev/null 2>&1; then
    git tag "$TAG"
    git push origin "$TAG"
  fi
  gh release create "$TAG" "$ZIP_PATH" \
    --title "ScreenPainter $VERSION" \
    --notes "ScreenPainter $VERSION" \
    --repo "$REPO_SLUG" || \
  gh release upload "$TAG" "$ZIP_PATH" --clobber --repo "$REPO_SLUG"
  echo ""
  echo "リリースURL: https://github.com/${REPO_SLUG}/releases/tag/${TAG}"
  echo "アセットURL: $ASSET_URL"
else
  echo "次の手順:"
  echo "  1) git でバージョンタグを作成: git tag $TAG && git push origin $TAG"
  echo "  2) GitHub Release を作成し $ZIP_NAME を添付"
  echo "     (または scripts/release.sh $VERSION --release で自動化)"
  echo "  3) tap リポジトリの Casks/screen-painter.rb の version と sha256 を更新"
fi
