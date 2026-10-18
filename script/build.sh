#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
if [ "$#" = 0 ]; then
  exec bash "$SCRIPT_DIR/build_and_run.sh" --build-only
fi
if [ "${1:-}" != --release ] || [ "$#" -gt 2 ]; then
  echo "Usage: bash script/build.sh [--release [patch|minor|major]]" >&2
  exit 2
fi
BUMP="${2:-patch}"
case "$BUMP" in patch|minor|major) ;; *) echo "版本递增方式只能是 patch、minor 或 major。" >&2; exit 2 ;; esac
PACKAGE="$ROOT_DIR/gpt-niang-usage/package.json"
PLUGIN="$ROOT_DIR/gpt-niang-usage/.codex-plugin/plugin.json"
BUILD_WORK="$(mktemp -d "${TMPDIR:-/tmp}/gpt-niang-release.XXXXXX")"
cp "$PACKAGE" "$BUILD_WORK/package.json"
cp "$PLUGIN" "$BUILD_WORK/plugin.json"
BUILD_DONE=0
cleanup() {
  if [ "$BUILD_DONE" != 1 ]; then
    cp "$BUILD_WORK/package.json" "$PACKAGE"
    cp "$BUILD_WORK/plugin.json" "$PLUGIN"
    echo "构建失败，版本号已恢复。" >&2
  fi
  rm -rf "$BUILD_WORK"
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

node --input-type=module - "$PACKAGE" "$PLUGIN" "$BUMP" > "$BUILD_WORK/version" <<'JS'
import fs from 'node:fs';
const files = process.argv.slice(2, 4);
const bump = process.argv[4];
const texts = files.map(file => fs.readFileSync(file, 'utf8'));
const versions = texts.map(text => JSON.parse(text).version);
if (!/^\d+\.\d+\.\d+$/.test(versions[0]) || versions[0] !== versions[1]) {
  throw new Error('两个配置文件的版本号必须一致，且为 x.y.z 格式');
}
const parts = versions[0].split('.').map(Number);
const index = {major: 0, minor: 1, patch: 2}[bump];
parts[index] += 1;
for (let i = index + 1; i < parts.length; i++) parts[i] = 0;
const version = parts.join('.');
files.forEach((file, index) => fs.writeFileSync(file,
  texts[index].replace(/("version"\s*:\s*")[^"]+("\s*[,}])/, (_, prefix, suffix) => prefix + version + suffix)));
console.log(version);
JS
VERSION="$(cat "$BUILD_WORK/version")"

echo "正在构建 v${VERSION}…"
GPT_NIANG_BUILD_UNIVERSAL=1 bash "$SCRIPT_DIR/build_and_run.sh" --build-only
ARCHIVE_NAME="gpt-niang-usage-widget-v${VERSION}-macos-universal.zip"
/usr/bin/ditto -c -k --norsrc --keepParent "$ROOT_DIR/dist/GPTNiangMac.app" "$BUILD_WORK/$ARCHIVE_NAME"
(cd "$BUILD_WORK" && /usr/bin/shasum -a 256 "$ARCHIVE_NAME" > SHA256SUMS.txt)
mv "$BUILD_WORK/$ARCHIVE_NAME" "$ROOT_DIR/dist/$ARCHIVE_NAME"
mv "$BUILD_WORK/SHA256SUMS.txt" "$ROOT_DIR/dist/SHA256SUMS.txt"
BUILD_DONE=1
echo "已生成 v${VERSION}："
echo "  $ROOT_DIR/dist/$ARCHIVE_NAME"
echo "  $ROOT_DIR/dist/SHA256SUMS.txt"
