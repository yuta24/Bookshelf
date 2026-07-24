# Bookshelf Backend

楽天ブックスAPI (`BooksTotal/Search`) を叩くための薄いプロキシAPI。Hono + TypeScript で実装し、Fly.io にデプロイする。

このリポジトリは public なので、`applicationId` / `accessKey` / `affiliateId` をアプリや Git 管理下のコードに一切含めない。これらはこのバックエンドのプロセス環境変数としてのみ保持し、クライアント (iOS アプリ) は自身の API キーのみを保持する。

## 楽天API 2026年仕様変更への対応

楽天ウェブサービスは2026年に認証まわりを含む破壊的な仕様変更を行った(移行期間 2026-02-10 〜 2026-05-13、旧仕様は完全廃止済み)。このリポジトリは新仕様に追従済みだが、**デプロイ先の楽天アプリ登録とネットワーク設定は各自の対応が必要**:

1. **アプリの再登録**: 旧来の19桁数字の `applicationId` は無効になっている。[Rakuten Developers](https://webservice.rakuten.co.jp/) でアプリを新規登録し直し、UUID形式の `applicationId` と `pk_` から始まる `accessKey` をペアで取得する。
2. **IPアドレス許可リストへの登録**: 登録済みIP以外からのアクセスは403になる。Fly.io の [app-scoped static egress IP](https://fly.io/docs/networking/egress-ips/) を割り当てて固定IPにしてから、そのIPを楽天アプリ管理画面の Allow IP address に登録する。
   ```bash
   fly ips allocate-egress --app bookshelf-quiet-glade-4873 -r nrt
   ```
   反映まで数分かかる場合がある。
3. 上記で取得した `applicationId` / `accessKey` を後述の `fly secrets set` で設定する。

## エンドポイント

すべて `/v1/*` 配下は `X-API-Key` ヘッダーが必須(`API_KEY` 環境変数と一致しない場合は 401)。IPごとに 1分あたり30リクエストのレート制限あり(429)。

> **注意**: レート制限はプロセス内メモリで実装しているため、Fly マシンが複数台稼働する構成にスケールすると台数分だけ上限が緩くなる(グローバルに共有されない)。現状は単一マシン構成(`fly scale count 1`)を前提としており、複数台へスケールする場合は Redis 等を使った共有ストアへの置き換えが必要。
>
> Fly は機械が0台の状態から `fly deploy` するとデフォルトで冗長化のため2台作成する。CI (`fly-deploy.yml`) は `--ha=false` を付けてこれを防いでいるが、手動で `fly deploy` する場合も同様に `--ha=false` を付けること(付け忘れて2台になった場合は `fly scale count 1 --app bookshelf-quiet-glade-4873` で戻せる)。

| Method | Path | 用途 | クエリパラメータ |
| --- | --- | --- | --- |
| GET | `/health` | ヘルスチェック(認証不要) | - |
| GET | `/v1/books/search` | タイトル/ISBN検索 | `keyword` か `isbn` のいずれか必須 |
| GET | `/v1/books` | ジャンル別新着・売れ筋一覧 | `genreId` (省略時 `001`), `sort` (`-releaseDate` か `sales`、省略時 `-releaseDate`) |

レスポンス: `{ "items": [{ title, author, price, affiliateUrl, imageUrl, isbn, publisher, caption, salesDate }] }`

## ローカル開発

```bash
cd Backend
npm install
cp .env.example .env   # RAKUTEN_APPLICATION_ID / RAKUTEN_ACCESS_KEY / API_KEY 等を設定
npm run dev
```

```bash
curl "http://localhost:8080/v1/books/search?keyword=dune" -H "X-API-Key: $API_KEY"
```

## テスト / 型チェック

```bash
npm test
npm run typecheck
```

## Secrets の設定 (Fly.io)

`.env` や `fly.toml` に秘匿値を書かないこと。デプロイ先には `fly secrets set` で注入する。

```bash
fly secrets set \
  RAKUTEN_APPLICATION_ID=xxxx \
  RAKUTEN_ACCESS_KEY=pk_xxxx \
  RAKUTEN_AFFILIATE_ID=xxxx \
  API_KEY=$(openssl rand -hex 32) \
  --app bookshelf-quiet-glade-4873
```

CI (`.github/workflows/fly-deploy.yml`) は `FLY_API_TOKEN` を GitHub Actions の Secrets からのみ読み込み、デプロイ時にリポジトリ内の秘匿値は使用しない。

## iOS アプリ側の対応(未実施・別タスク)

現状 iOS アプリは `Infrastructure/Sources/{SearchClientLive,BookClientLive}/Generated/Secret.generated.swift` に楽天の `applicationId`/`affiliateId` を Sourcery で平文埋め込みしている。このバックエンドへの移行を行う場合は、上記2箇所の実装をこのAPIへのHTTPリクエストに置き換え、iOSアプリ側にはこのバックエンドの `API_KEY` のみを保持させる必要がある(それでもバイナリ解析で抽出されうる値である点は変わらないが、少なくとも楽天の本番クレデンシャルはリポジトリからもアプリバイナリからも排除できる)。
