# Docker Compose 部署指南

这份配置用于把项目直接部署到自己的服务器上。镜像使用 Next.js standalone 产物运行，不依赖 Vercel 或 Cloudflare。

原作者项目：https://github.com/YYsuni/2025-blog-public

## 服务器要求

- Docker 24+
- Docker Compose v2+
- 建议内存 1GB 以上

## 1. 直接部署

在服务器上新建目录：

```bash
mkdir -p 2025-blog
cd 2025-blog
```

下载一个 Compose 文件：

```bash
curl -fsSL -o docker-compose.yml https://raw.githubusercontent.com/oldwangnewbe/2025-blog-public/main/docker-compose.remote.yml
```

编辑 `docker-compose.yml` 顶部的 `x-blog-config`：

```yaml
x-blog-config: &blog-config
  NEXT_PUBLIC_SITE_URL: "https://你的域名"
  SITE_URL: "https://你的域名"
  NEXT_PUBLIC_GITHUB_OWNER: "你的 GitHub 用户名或组织名"
  NEXT_PUBLIC_GITHUB_REPO: "你的博客仓库名"
  NEXT_PUBLIC_GITHUB_BRANCH: "main"
  NEXT_PUBLIC_GITHUB_APP_ID: "你的 GitHub App ID"
  NEXT_PUBLIC_GITHUB_ENCRYPT_KEY: "换成你自己的随机字符串"
  BLOG_SLUG_KEY: ""
```

如果你的服务器访问 npm 官方源更快，可以把 `x-build-config` 里的 `NPM_REGISTRY` 改成 `https://registry.npmjs.org`：

```yaml
x-build-config: &build-config
  NPM_REGISTRY: "https://registry.npmmirror.com"
  PNPM_VERSION: "10.24.0"
```

如果要换端口，把 `ports` 里的 `"3000:3000"` 改成 `"8080:3000"` 这种格式即可。

注意：`NEXT_PUBLIC_*` 会在构建时写入前端资源。修改这些变量后，需要重新构建镜像。

启动：

```bash
docker compose up -d --build
```

查看日志：

```bash
docker compose logs -f blog
```

默认访问：

```text
http://服务器IP:3000
```

## 2. 本地源码部署

如果你已经把仓库克隆到服务器，也可以在仓库目录里直接运行：

```bash
docker compose up -d --build
```

## 3. 更新

直接部署模式更新：

```bash
docker compose up -d --build
```

源码部署模式更新：

```bash
git pull
docker compose up -d --build
```

只重启服务：

```bash
docker compose restart blog
```

停止服务：

```bash
docker compose down
```

## 4. 反向代理示例

如果服务器上有 Nginx，可以把域名代理到容器端口：

```nginx
server {
    listen 80;
    server_name blog.example.com;

    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

生产环境建议再配 HTTPS，例如使用 Certbot 或服务器面板自带的证书功能。

## 5. 常见问题

### 修改环境变量不生效

如果改的是 `NEXT_PUBLIC_*`，需要重新构建：

```bash
docker compose up -d --build
```

### 卡在 pnpm install 或下载依赖失败

默认已经使用 `https://registry.npmmirror.com`。如果你的服务器在海外，可以改成：

```yaml
x-build-config: &build-config
  NPM_REGISTRY: "https://registry.npmjs.org"
  PNPM_VERSION: "10.24.0"
```

然后重新构建：

```bash
docker compose up -d --build
```

### 报 `ERR_PNPM_IGNORED_BUILDS`

项目已经在 `pnpm-workspace.yaml` 里允许 `esbuild`、`sharp`、`workerd` 运行安装脚本。更新到最新的 `docker-compose.yml` 后重新构建：

```bash
docker compose build --no-cache
docker compose up -d
```

### GitHub App 已配置但页面仍然写入失败

确认 GitHub App 安装到了目标仓库，并且仓库权限包含 Contents Read and write。还要确认 `docker-compose.yml` 顶部的 `NEXT_PUBLIC_GITHUB_OWNER`、`NEXT_PUBLIC_GITHUB_REPO`、`NEXT_PUBLIC_GITHUB_BRANCH` 和 `NEXT_PUBLIC_GITHUB_APP_ID` 都是你的值。

### 想换端口

修改 `docker-compose.yml`：

```yaml
ports:
  - "8080:3000"
```

然后重启：

```bash
docker compose up -d
```
