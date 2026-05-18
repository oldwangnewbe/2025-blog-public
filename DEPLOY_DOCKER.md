# Docker 部署指南

这份配置用于把项目部署到自己的服务器上。镜像使用 Next.js standalone 产物运行，不依赖 Vercel 或 Cloudflare。

## 服务器要求

- Docker 24+
- Docker Compose v2+
- 建议内存 1GB 以上

## 1. 准备环境变量

复制模板：

```bash
cp .env.example .env
```

至少建议修改：

```dotenv
APP_PORT=3000
NEXT_PUBLIC_SITE_URL=https://你的域名
SITE_URL=https://你的域名
NEXT_PUBLIC_GITHUB_OWNER=你的 GitHub 用户名或组织名
NEXT_PUBLIC_GITHUB_REPO=你的博客仓库名
NEXT_PUBLIC_GITHUB_BRANCH=main
NEXT_PUBLIC_GITHUB_APP_ID=你的 GitHub App ID
NEXT_PUBLIC_GITHUB_ENCRYPT_KEY=换成你自己的随机字符串
```

注意：`NEXT_PUBLIC_*` 会在构建时写入前端资源。修改这些变量后，需要重新构建镜像。

## 2. 构建并启动

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

如果你修改了 `APP_PORT`，访问端口也要跟着变化。

## 3. 更新部署

拉取新代码后重新构建：

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

### GitHub App 已配置但页面仍然写入失败

确认 GitHub App 安装到了目标仓库，并且仓库权限包含 Contents Read and write。还要确认 `.env` 中的 `NEXT_PUBLIC_GITHUB_OWNER`、`NEXT_PUBLIC_GITHUB_REPO`、`NEXT_PUBLIC_GITHUB_BRANCH` 和 `NEXT_PUBLIC_GITHUB_APP_ID` 都是你的值。

### 想换端口

修改 `.env`：

```dotenv
APP_PORT=8080
```

然后重启：

```bash
docker compose up -d
```
