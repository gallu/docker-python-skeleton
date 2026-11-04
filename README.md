# Docker Python Skeleton

Python の Web アプリケーションをローカルで開発するための Docker Compose 環境です。ブラウザから nginx、Gunicorn、WSGI アプリの順に HTTP リクエストを処理します。初期サンプルは Python 標準ライブラリだけで実装しています。Flask、Django、ASGI / FastAPI は含みません。

## 採用バージョンと必要なソフトウェア

| ソフトウェア | 指定タグ・バージョン |
|---|---|
| Python 公式イメージ | `python:3.14-bookworm` |
| Gunicorn | `26.2.0` |
| nginx | `1.31` |
| MySQL | `9.7` |
| PostgreSQL | `18` |
| Redis | `7` |

ホスト側に Docker Engine、Docker Compose v2.20 以降相当（`depends_on.required` 対応）、Make、POSIX シェルが必要です。ホストへの Python インストールは不要です。Linux / WSL では Linux 側のファイルシステムで作業してください。

## ディレクトリ構成

```text
.
├── .env.sample
├── .gitignore
├── Makefile
├── docker-compose.yml
├── docker/
│   ├── python/Dockerfile
│   ├── nginx/Dockerfile
│   ├── nginx/default.conf
│   ├── mysql/init/init.sql
│   └── postgres/init/init.sql
├── examples/plain-wsgi/app.py
├── scripts/setup.sh
└── src/                 # setup で作成。別リポジトリとして管理するアプリ本体
```

`src/` と `.env` はこのリポジトリの Git 管理対象外です。`src/` を独立した Git リポジトリにできます。サンプルの原本は `examples/plain-wsgi/app.py` にあり、セットアップ時に `src/` が空の場合だけ `src/app.py` にコピーします。既存のアプリファイルや権限は変更しません。

## 初期セットアップ

以下はリポジトリのルートで、ホスト側のシェルから実行します。

```bash
sh scripts/setup.sh
cp .env.sample .env
make up
```

既に `.env` がある場合は `cp` で上書きしないでください。`.env` の `WEB_PORT` はホストの公開ポートで、既定は `8081` です。`COMPOSE_PROJECT_NAME` を指定すると Compose のコンテナ・ネットワーク・volume 名の接頭辞を変更できます。サービスには固定の `container_name` を付けていません。

`make up` は nginx、Python、Redis、MySQL、PostgreSQL を起動します。DB を片方だけ使う場合は以下のいずれかを実行します。

```bash
make up-mysql
make up-pg
```

`up-mysql` と `up-pg` は、使わない方の DB コンテナを停止します。Redis はどの起動方法でも立ち上がります。DB は Compose profiles で選択するため、`docker compose up` だけでは起動しません。Python コンテナは有効な DB が healthy になるまで待ちます。

## ブラウザ・curl での動作確認

`.env.sample` のままなら `http://localhost:8081/` をブラウザで開きます。`WEB_PORT` を変えた場合は、そのポートに読み替えてください。

```bash
curl -i http://localhost:8081/
curl -i http://localhost:8081/json
curl -i http://localhost:8081/missing
```

`/` はテキストと HTTP 200、`/json` は JSON と HTTP 200、存在しないパスは HTTP 404 を返します。

## Python ソースの変更

ホスト側で `src/app.py` を編集します。例えば `vi src/app.py` を使います。`src/` は Python コンテナの `/app` へ bind mount され、開発用 Gunicorn は `--reload` を有効にしているため、保存後にワーカープロセスが再起動します。変更後に上記の `curl` で応答を確認してください。起動対象は `.env` の `WSGI_APP` で変更できます。既定値は `app:application` です。対象モジュールは `src/` 内に置き、`module:callable` の形式で指定します。

この Compose 構成はローカル開発用です。本番で Gunicorn を起動する場合は `--reload` を使わず、ワーカー数、権限、公開範囲などを環境に合わせて設計してください。

## DB と Redis

| サービス | アプリからの接続先 | 開発用ユーザー / パスワード | データ |
|---|---|---|---|
| MySQL | `mysql:3306` | `app` / `app` | `app`, `app_testing` |
| PostgreSQL | `postgres:5432` | `app` / `app` | `app`, `app_testing` |
| Redis | `redis:6379` | 認証なし | 既定 DB 0 |

管理者は MySQL が `root` / `root`、PostgreSQL が `postgres` / `root` です。これらはローカル開発専用です。DB の初期化 SQL は named volume が空の初回起動時に実行されます。MySQL と PostgreSQL のデータは `mysql_data` と `postgres_data` に保存され、`make down` では消えません。Redis は AOF を無効化しており、永続化しません。DB と Redis のポートはホストへ公開していません。Python サンプルに DB ドライバーや接続コードは含みません。

```bash
make exec-mysql
make exec-pg
docker compose exec redis redis-cli ping
```

## 操作コマンド

| コマンド | 内容 |
|---|---|
| `make up` | 全サービスをビルド・起動 |
| `make up-mysql` | MySQL 側のみを起動し PostgreSQL を停止 |
| `make up-pg` | PostgreSQL 側のみを起動し MySQL を停止 |
| `make ps` | コンテナの状態を表示 |
| `make logs` | 全サービスのログを追跡 |
| `make exec-python` | Python コンテナで bash を起動 |
| `make exec-mysql` / `make exec-pg` | DB コンテナで bash を起動 |
| `make down` | コンテナとネットワークを停止・削除。DB volume は保持 |
| `make clean` | この Compose プロジェクトのイメージと DB volume も削除 |

`make clean` は DB データを削除します。既存2リポジトリと同じく、`make all-clean` と `make disintegrate` も定義していますが、Docker 全体の未使用リソースを削除し他プロジェクトにも影響します。

## 将来のアプリへの差し替え

Flask や Django を使う場合は `src/` のアプリ、アプリ側の依存関係、必要な Dockerfile を用意し、`WSGI_APP` をその WSGI 呼び出し対象へ変更します。ASGI / FastAPI は WSGI と実行方式が異なるため、起動コマンドとサーバ構成の変更が必要です。今回の構成には含めていません。
