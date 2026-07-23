# Bookshelf Backend

楽天ブックスAPI (`BooksTotal/Search`) を叩くための薄いプロキシAPI。Hono + TypeScript で実装し、Fly.io にデプロイする。

このリポジトリは public なので、`applicationId` / `affiliateId` をアプリや Git 管理下のコードに一切含めない。これらはこのバックエンドのプロセス環境変数としてのみ保持し、クライアント (iOS アプリ) は自身の API キーのみを保持する。

## エンドポイント

すべて `/v1/*` 配下は `X-API-Key` ヘッダーが必須(`API_KEY` 環境変数と一致しない場合は 401)。IPごとに 1分あたり30リクエストのレート制限あり(429)。

> **注意**: レート制限はプロセス内メモリで実装しているため、Fly マシンが複数台稼働する構成にスケールすると台数分だけ上限が緩くなる(グローバルに共有されない)。現状は単一マシン構成(`fly scale count 1`)を前提としており、複数台へスケールする場合は Redis 等を使った共有ストアへの置き換えが必要。

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
cp .env.example .env   # RAKUTEN_APPLICATION_ID / API_KEY 等を設定
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
  RAKUTEN_AFFILIATE_ID=xxxx \
  API_KEY=$(openssl rand -hex 32) \
  --app bookshelf-quiet-glade-4873
```

CI (`.github/workflows/fly-deploy.yml`) は `FLY_API_TOKEN` を GitHub Actions の Secrets からのみ読み込み、デプロイ時にリポジトリ内の秘匿値は使用しない。

## iOS アプリ側の対応(未実施・別タスク)

現状 iOS アプリは `Infrastructure/Sources/{SearchClientLive,BookClientLive}/Generated/Secret.generated.swift` に楽天の `applicationId`/`affiliateId` を Sourcery で平文埋め込みしている。このバックエンドへの移行を行う場合は、上記2箇所の実装をこのAPIへのHTTPリクエストに置き換え、iOSアプリ側にはこのバックエンドの `API_KEY` のみを保持させる必要がある(それでもバイナリ解析で抽出されうる値である点は変わらないが、少なくとも楽天の本番クレデンシャルはリポジトリからもアプリバイナリからも排除できる)。
