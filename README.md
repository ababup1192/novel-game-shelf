# ノベルゲームシェルフ（試作）

スマホの縦の画面で遊ぶノベルゲームを、表紙の棚に並べて無料で配信するサイトの試作。
elm-pages で全頁を静的に書き出す。ゲームそのものは各作品の GitHub Pages で開く。

- 公開: https://ababup1192.github.io/novel-game-shelf/
- 構成と今後の計画（nextcms・Cloudflare・作者画面・費用）: [docs/architecture.md](docs/architecture.md)

## 動かす

```bash
devbox run -- npm install
devbox run -- npx elm-pages dev        # http://localhost:1234
devbox run -- bash scripts/build-pages.sh   # GitHub Pages 向けの書き出し → dist-pages/
```

## 直す所

| 直したい物 | 書く所 |
|---|---|
| 作品（題名・あらすじ・注意の札・遊ぶ URL・表紙） | `content/works.json` |
| 作者 | `content/authors.json` |
| 表紙の絵 | `public/covers/` |
| ロゴ | `public/brand/`（元の絵は `brand/`。Codex の画像生成で作った） |
| 頁 | `app/Route/`（ホーム・作品・遊ぶ前のシート・作者・ガイドライン） |
| 見た目 | `style.css` |

注意の札は `blood` `loud` `flash` `blade` `jumpscare` のどれか（それ以外はビルドが止まる）。
`mock: true` の作品は「モック」の札が付き、遊ぶボタンが「準備中」になる。
