#!/usr/bin/env bash
# dist-pages を gh-pages ブランチへ丸ごと置き換えて push する（履歴は残さない）。
set -euo pipefail
cd "$(dirname "$0")/.."
REMOTE="$(git remote get-url origin)"
bash scripts/build-pages.sh
cd dist-pages
rm -rf .git
git init -q -b gh-pages
git add -A
git commit -q -m "GitHub Pages 向けの書き出し"
git push -q -f "$REMOTE" gh-pages
echo "push 済み: gh-pages"
