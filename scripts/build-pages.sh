#!/usr/bin/env bash
# GitHub Pages（https://<user>.github.io/<repo>/）向けに書き出す。
# WhyNot: elm-pages build --base は、この版では全頁が「Page not found」になるので使わない。
#         普通に書き出してから、HTML の中の道に頭を付ける。
# WhyNot: JS（elm-pages の画面切り替え）は外す。残すと content.dat を頭なしの道で取りに行って失敗する。
#         全頁がビルド時に書き出した静的な HTML なので、JS が無くても同じ見た目で動く。
set -euo pipefail
BASE="${1:-/novel-game-shelf}"
cd "$(dirname "$0")/.."
rm -rf dist
BASE_PATH="$BASE" npx elm-pages build
OUT=dist-pages
rm -rf "$OUT"
mkdir -p "$OUT"
cp -R dist/assets dist/brand dist/covers dist/favicon.png "$OUT"/
cd dist
find . -name index.html -not -path './elm-stuff/*' | while read -r f; do
  mkdir -p "../$OUT/$(dirname "$f")"
  perl -0pe '
    s{<script\b[^>]*>.*?</script>}{}gs;
    s{<link rel="(?:modulepreload|preload)"[^>]*>}{}g;
    s{(href|src)="/(?!/|'"${BASE#/}"'/)}{$1="'"$BASE"'/}g;
  ' "$f" > "../$OUT/$f"
done
touch "../$OUT/.nojekyll"
echo "書き出し: $OUT（$BASE の下に置く）"
