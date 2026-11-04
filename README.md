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

### ZIP で取得する場合

GitHub に新規リポジトリを作らず、手元に開発環境を用意する方法です。以下は Linux / WSL のホスト側シェルで実行し、`curl` と `unzip` が必要です。`my-python-app` は任意のプロジェクト名に変更できます。ZIP ファイルや展開先、変更後のディレクトリが既にある場合は、別名または別の作業ディレクトリを使用してください。

```bash
# ZIP をダウンロードして展開
curl -fL -o docker-python-skeleton.zip \
  https://github.com/gallu/docker-python-skeleton/archive/refs/heads/main.zip
unzip docker-python-skeleton.zip

# 作業するディレクトリへ移動
mv docker-python-skeleton-main my-python-app
cd my-python-app
```

取得後は下記の「取得後の初期化とアプリ配置」に進みます。不要になった ZIP は `../docker-python-skeleton.zip` です。非公開リポジトリの ZIP は匿名では取得できません。ZIP には Git 履歴が含まれないため、Git で管理する場合は必要に応じて `git init` してください。`src/` と `.env` は既定で Git 管理対象外です。

### GitHub Template から作成する場合

GitHub 上でこのリポジトリに「Use this template」が表示される場合は、そこから新しいリポジトリを作成し、ホスト側へ clone してください。表示されない場合は ZIP で取得するか、通常の clone を使用してください。clone 後は新しいリポジトリのルートへ移動します。

### 取得後の初期化とアプリ配置

以下はリポジトリのルートで、ホスト側のシェルから実行します。

```bash
sh scripts/setup.sh
cp .env.sample .env
```

`.env` の作成は省略できます。既に `.env` がある場合は `cp` で上書きせず、内容を確認してください。`setup.sh` は空の `src/` にサンプルの `src/app.py` を配置します。独自のアプリを使う場合は、セットアップ前に `src/` へ置くとサンプルのコピーを省略できます。セットアップ済みの場合は、`src/app.py` を編集するか、アプリを配置して `WSGI_APP` を起動対象に合わせてください。

起動するには、ホスト側で次を実行します。

```bash
make up
```

`make up` は nginx、Python、Redis、MySQL、PostgreSQL を起動します。DB を片方だけ使う場合は以下のいずれかを実行します。

```bash
make up-mysql
make up-pg
```

`up-mysql` と `up-pg` は、使わない方の DB コンテナを停止します。Redis はどの起動方法でも立ち上がります。DB は Compose profiles で選択するため、`docker compose up` だけでは起動しません。Python コンテナは有効な DB が healthy になるまで待ちます。

## 設定

`.env` は省略できます。Compose は未設定または空文字の変数に下表の既定値を適用します。ホスト側の環境変数を設定した場合は `.env` より優先されます。

| 変数 | 既定値 | 役割 |
|---|---|---|
| `WEB_PORT` | `8081` | ホスト側の nginx 公開ポート |
| `WSGI_APP` | `app:application` | Gunicorn が読み込む `module:callable` 形式の WSGI アプリ |
| `COMPOSE_PROJECT_NAME` | Compose が決定 | コンテナ・ネットワーク・volume 名に使うプロジェクト名 |

例えば `vi .env` で `WEB_PORT=9081` に変更すると、ブラウザからの接続先は `http://localhost:9081/` になります。`WSGI_APP` のモジュールは `src/` 内に置いてください。`COMPOSE_PROJECT_NAME` を指定する場合は、他の Compose プロジェクトと重複しない名前にしてください。サービスに固定の `container_name` は設定していません。

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
