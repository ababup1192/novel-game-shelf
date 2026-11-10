# アーキテクチャ

ノベルゲームシェルフの今の形と、作品データを nextcms で管理して作者が自分の作品を直せるようにする目標の形。
図と費用の表は [architecture.html](architecture.html)（同じ内容を 1 枚の頁にした物）。

## 決めたこと

| 何を | どうするか | なぜ |
|---|---|---|
| 公開サイト | elm-pages で全頁を静的に書き出し、Cloudflare の Workers 静的アセットで配る | 配信は回数無制限で無料。サーバが落ちても読める |
| ゲーム本体 | flix_game_engine の export-web の書き出しを R2 の `play/<slug>/<版>/` に置く | 1 本 100 前後のファイル・20 MB 前後。CMS の asset（1 ファイル前提）には合わない |
| 作品・作者のデータ | 既存の nextcms（`cms.ababup.dev`）に別プロジェクト `novel-game-shelf` として置く | 箱もドメインも増えない。公開・非公開がそのまま使える |
| 公開・非公開 | nextcms の公開（publish）と取り下げ（unpublish） | 作者は下書きまで、公開は管理者、という審査の形が役割（WRITER / EDITOR）で最初から作れる |
| 作者の編集 | シェルフ側の作者画面 → Worker API（BFF）→ nextcms の管理 API | 作者を nextcms に直接入れると、WRITER は他の作者の作品も直せてしまう |
| いいね・感想 | Worker API → D1 | 匿名で頻繁に書かれる物は CMS に入れない |
| サイトへの反映 | nextcms の Webhook（`entry.published` など）→ GitHub Actions → elm-pages build → `cf` で配り直す | elm-pages はビルドの時にコンテンツ API を読むだけ |

## 構成

```
読者（ブラウザ / Capacitor アプリ）
  ├─ 頁 ──────────────> Cloudflare 静的アセット（elm-pages の全頁・作者画面）
  ├─ はじめる ─────────> R2  play/<slug>/<版>/（ゲームの書き出し）
  └─ いいね・感想 ─────> Worker API /api/likes・/api/comments ──> D1

ゲーム作者
  └─ ログイン ─> Cloudflare Access（メールのワンタイム）
                 └─> Worker API /api/author（BFF）
                       ├─ ゲームの zip ──> R2 に置く
                       └─ 下書きを書く ──> nextcms 管理 API（WRITE キー・WRITER 役割）
                                          ※ 作者の作品か・直してよいフィールドかを BFF が確かめる

管理者
  └─ nextcms の管理画面 ─> 公開・非公開

nextcms ── Webhook（公開したら）──> GitHub Actions
GitHub Actions ── コンテンツ API で読む ──> nextcms
GitHub Actions ── cf deploy ──> Cloudflare 静的アセット
```

### nextcms の置き場（既存の本番）

記録は nextcms の `deploy/RUNBOOK.md`。

- さくらの VPS 4 GB・Ubuntu 24.04。docker compose で cms / postgres / backup / caddy
- 入口は Cloudflare の Proxied な A レコード → Caddy（Cloudflare の IP の外は切る）
- asset は R2（`nextcms-assets`）、バックアップも R2。本人確認は Clerk
- シェルフのプロジェクトは `cms.ababup.dev/p/novel-game-shelf/graphql`（コンテンツ API）と `/p/novel-game-shelf/admin/graphql`（管理 API）

## nextcms の型（案）

`works`（COLLECTION）

| apiId | 種類 | 中身 |
|---|---|---|
| `title` | TEXT（必須） | 題名 |
| `slug` | SLUG（`title` から・一意） | URL の `/works/<slug>/` |
| `author` | REFERENCE → `authors`（必須） | 作者 |
| `genres` | SELECT（many） | ホラー・怪談・ダーク童話・青春… |
| `synopsis` | TEXT_AREA | あらすじ |
| `authorNote` | TEXT_AREA | 作者からのひとこと（遊ぶ前のシートに出す） |
| `minutes` / `endings` | NUMBER | プレイ時間（分）・結末の数 |
| `age` | SELECT | 全年齢 / 12+ / 15+（18+ は配信しない） |
| `warnings` | SELECT（many） | `blood` `loud` `flash` `blade` `jumpscare`（今の `Catalog.Warning` と同じ一覧） |
| `cover` / `hero` | ASSET | 3:4 の表紙・16:9 前後のピックアップの絵（文字の無い物） |
| `playUrl` / `buildVersion` | TEXT | R2 に置いたゲームの URL と版。BFF が書く |
| `tags` | SELECT（many） | `pick` `popular` `new` `short`（並べ方の手がかり） |

`authors`（COLLECTION）: `name`・`slug`・`bio`・`avatar`（ASSET）・`links`・`ownerId`（作者のログインと結び付ける ID。BFF がここを見て「本人か」を決める）。

今の `content/works.json` と `content/authors.json` は、この型へそのまま移せる形にしてある。

## 作者の権限

nextcms の役割はプロジェクト単位（VIEWER / WRITER / EDITOR / OWNER）で、行ごとの権限はまだ無い（nextcms のロードマップ #22b に未着手で載っている）。

1. **最初: BFF で確かめる**（nextcms は変えない）
   - Worker が WRITE 範囲・WRITER 役割の API キーを 1 本だけ持つ（公開はできない）
   - 作者のログイン（Access の本人のメール）→ `authors.ownerId` → その作者の `works` だけを読む・直す
   - 直してよいフィールドを BFF で絞る（`tags` や `slug` は作者に触らせない）
   - 鍵が漏れると全作品の下書きを直せる。公開はできないので、読者に出る前に管理者が止められる
2. **作者が増える前: nextcms に #22b を足す**
   - 作者ごとの鍵に「`author` = 自分」の条件が付き、サーバ側で守られる
   - 作者画面は自分の鍵で管理 API を叩くだけになり、BFF の確かめは要らなくなる
   - BFF が使う管理 API の範囲を最初から小さく保っておけば、画面側はほとんど変わらない

## 費用（月額の上乗せ）

| 項目 | 費用 | 無料で収まる目安 |
|---|---|---|
| Workers 静的アセット | 0 円 | 回数無制限。1 版 20,000 ファイル・1 ファイル 25 MiB まで |
| Worker API | 0 円 | 1 日 10 万回まで（超えたら月 5 ドル） |
| D1 | 0 円 | 読み 1 日 500 万行・書き 1 日 10 万行・5 GB |
| R2 | 0 円 | 10 GB まで（ゲーム 1 本 20 MB なら約 500 本）。転送量は無料 |
| Access・Turnstile・WAF | 0 円 | Access は 50 人まで |
| GitHub Actions | 0 円 | 公開リポジトリ |
| VPS（nextcms） | 0 円 | 既存のさくらの VPS 4 GB に同居 |
| ドメイン | 0 円 | 既存の `ababup.dev` のサブドメイン |

後で要る物: Apple Developer Program 年 約 1.3 万円（iOS のアプリ）、Google Play 25 ドル（1 回）、
Workers の有料プラン 月 5 ドル（Worker API が 1 日 10 万回を超えた時）、VPS 8 GB（JVM 2 つの切り替えが 4 GB に収まらなくなった時）。

## 段階

| 段 | やること | 状態 |
|---|---|---|
| P0 | 画面イメージのモック | 済 |
| P1 | elm-pages で頁を組み、JSON の作品で GitHub Pages に公開。ゲームは各作品の GitHub Pages へ飛ばす | 済（https://ababup1192.github.io/novel-game-shelf/） |
| P2 | Cloudflare へ移す（静的アセット・R2 にゲーム・`cf` で配る・`_headers` のキャッシュ） | |
| P3 | nextcms に `novel-game-shelf` プロジェクトと型を作り、elm-pages がコンテンツ API を読む。Webhook → Actions で配り直す | |
| P4 | 作者画面と BFF（Access・下書きの編集・ゲームの zip を R2 へ） | |
| P5 | いいね・感想（Worker・D1・Turnstile） | |
| P6 | nextcms の #22b（作者ごとの権限）へ移す | |
| P7 | Capacitor 版（ゲームを同梱・最低 OS は WasmGC の動く iOS 18.2 / Android WebView 119） | |

## 気を付けること

- ゲームの `bundle.json` の `id` は作品ごとに別にする。同じドメインに置くと、`id` が同じ作品どうしで localStorage のセーブが混ざる（今の血鱗は `"game"`）
- elm-pages の `build --base` はこの版では全頁が Page not found になる。下の階層に置く時は `scripts/build-pages.sh` の書き換えで対処している（Cloudflare へ移って根に置けば要らない）
- 感想をアプリの中で他の人に見せると、App Store の決まりで通報・ブロック・不適切な言葉の除外が要る。最初は作者だけが読む形にする
