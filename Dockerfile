# syntax=docker/dockerfile:1

FROM node:22-alpine AS base

ARG NPM_REGISTRY=https://registry.npmmirror.com
ARG PNPM_VERSION=10.24.0

ENV PNPM_HOME="/pnpm"
ENV PATH="$PNPM_HOME:$PATH"
ENV NEXT_TELEMETRY_DISABLED=1
ENV NPM_CONFIG_REGISTRY=$NPM_REGISTRY

WORKDIR /app

RUN npm install -g pnpm@${PNPM_VERSION} --registry=${NPM_REGISTRY} \
	&& pnpm config set registry ${NPM_REGISTRY} \
	&& pnpm config set store-dir /pnpm/store

FROM base AS deps

COPY package.json pnpm-lock.yaml pnpm-workspace.yaml .npmrc ./
RUN --mount=type=cache,id=pnpm-store,target=/pnpm/store pnpm install --frozen-lockfile

FROM base AS builder

ARG NEXT_PUBLIC_GITHUB_OWNER=yysuni
ARG NEXT_PUBLIC_GITHUB_REPO=2025-blog-public
ARG NEXT_PUBLIC_GITHUB_BRANCH=main
ARG NEXT_PUBLIC_GITHUB_APP_ID=-
ARG NEXT_PUBLIC_GITHUB_ENCRYPT_KEY=wudishiduomejimo
ARG NEXT_PUBLIC_SITE_URL=http://localhost:3000
ARG SITE_URL=http://localhost:3000
ARG BLOG_SLUG_KEY=

ENV NEXT_STANDALONE=true
ENV NEXT_PUBLIC_GITHUB_OWNER=$NEXT_PUBLIC_GITHUB_OWNER
ENV NEXT_PUBLIC_GITHUB_REPO=$NEXT_PUBLIC_GITHUB_REPO
ENV NEXT_PUBLIC_GITHUB_BRANCH=$NEXT_PUBLIC_GITHUB_BRANCH
ENV NEXT_PUBLIC_GITHUB_APP_ID=$NEXT_PUBLIC_GITHUB_APP_ID
ENV NEXT_PUBLIC_GITHUB_ENCRYPT_KEY=$NEXT_PUBLIC_GITHUB_ENCRYPT_KEY
ENV NEXT_PUBLIC_SITE_URL=$NEXT_PUBLIC_SITE_URL
ENV SITE_URL=$SITE_URL
ENV BLOG_SLUG_KEY=$BLOG_SLUG_KEY

COPY --from=deps /app/node_modules ./node_modules
COPY . .

RUN pnpm build

FROM node:22-alpine AS runner

WORKDIR /app

ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1
ENV HOSTNAME=0.0.0.0
ENV PORT=3000

RUN addgroup --system --gid 1001 nodejs \
	&& adduser --system --uid 1001 nextjs

COPY --from=builder /app/public ./public
COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /app/.next/static ./.next/static

USER nextjs

EXPOSE 3000

CMD ["node", "server.js"]
