# syntax=docker/dockerfile:1
# https://docs.docker.com/engine/reference/builder/

ARG NODE_VERSION=20.10.0

# ベースイメージを指定
FROM node:${NODE_VERSION}-alpine as base

# デフォルトでプロダクション用のNode環境を使用
# ENV NODE_ENV production

# 実行時の作業ディレクトリを指定
WORKDIR /usr/src/app

# 3000ポートを公開する
EXPOSE 3000

# Dockerのキャッシュ機能を利用するため、依存関係のダウンロードを別のステップとして実行する
# 次回以降のビルドを高速化するために、/root/.npmにキャッシュマウントを利用する
# package.jsonとpackage-lock.jsonをこのレイヤーにコピーする必要がないようにバインドマウントを利用する
# RUN --mount=type=bind,source=package.json,target=package.json \
#     --mount=type=bind,source=package-lock.json,target=package-lock.json \
#     --mount=type=cache,target=/root/.npm \
#     npm ci --omit=dev

# 非rootユーザーとしてアプリケーションを実行する
# USER node

# 残りのソースファイルをイメージにコピーする
# COPY . .

# 3000ポートを公開する
# EXPOSE 3000

# アプリケーションの実行
# CMD node src/index.js

# 開発環境用のイメージ
FROM base as dev
RUN --mount=type=bind,source=package.json,target=package.json \
    --mount=type=bind,source=package-lock.json,target=package-lock.json \
    --mount=type=cache,target=/root/.npm \
    npm ci --include=dev
USER node
COPY . .
CMD npm run dev


# 本番環境用のイメージ
FROM base as prod
RUN --mount=type=bind,source=package.json,target=package.json \
    --mount=type=bind,source=package-lock.json,target=package-lock.json \
    --mount=type=cache,target=/root/.npm \
    npm ci --omit=dev
USER node
COPY . .
CMD node src/index.js


# テスト環境用のイメージ
FROM base as test
ENV NODE_ENV test
RUN --mount=type=bind,source=package.json,target=package.json \
    --mount=type=bind,source=package-lock.json,target=package-lock.json \
    --mount=type=cache,target=/root/.npm \
    npm ci --include=dev
USER node
COPY . .
RUN npm run test