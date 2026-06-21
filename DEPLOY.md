# go-music-api 云端部署指南

把 go-music-api 部署到 [Fly.io](https://fly.io) 公开后端，给 Pikachu Music 客户端（iOS / Android / 桌面 Web）调用。

## 为什么需要云端

go-music-api 是 Go 写的 HTTP server，监听 `:8080`。本地桌面版（Tauri）可以 spawn sidecar 进程，但移动 App（Android / iOS）没法 spawn 本地子进程，必须有公网可达的后端 URL。

## 准备清单

| 项 | 说明 |
|---|------|
| Fly.io 账号 | https://fly.io 注册（免费，无需绑卡） |
| Fly API token | https://fly.io/user/personal_access_tokens 创建（read + write 权限） |
| flyctl CLI | `curl -L https://fly.io/install.sh \| sh` 安装 |

## 一键部署

```bash
cd /home/shijingtian/workspace/projects/go-music-api
export FLY_TOKEN=your_personal_access_token_here
./deploy-fly.sh
```

脚本会：
1. `fly auth token` 登录
2. 创建 `pikachu-music-api` app（如果不存在）
3. 创建 1GB volume 用于持久化 `cookies.json`（用户登录态）
4. `fly deploy --remote-only`（在 Fly 远端构建 Docker 镜像 + 部署）
5. 健康检查 `https://pikachu-music-api.fly.dev/api/v1/music/search?q=test&type=song&n=1`

部署完成后 URL：`https://pikachu-music-api.fly.dev`

## RN 客户端配置

打开 Pikachu Music APK → 设置面板 → 填入：

```
后端地址: https://pikachu-music-api.fly.dev/api/v1
```

保存后即可启用 13 个平台聚合（咪咕 / 网易云 / QQ / 酷我 / B站 / 千千 / 汽水 / 5sing / Jamendo / JOOX 等）。

## 验证

```bash
# 健康检查
curl https://pikachu-music-api.fly.dev/api/v1/music/search?q=周杰伦&type=song&n=5

# 应该返回 JSON
{
  "code": 200,
  "data": {
    "songs": [ { "id": "xxx", "name": "七里香", "artist": "周杰伦", ... } ]
  }
}
```

## 限制

- **免费档会 sleep**：连续 5 分钟无请求 Fly 会停掉实例，下次访问需 10-30 秒冷启动。RN 客户端 `waitForApi()` 15s 轮询会自动唤醒
- **cookies.json 在 volume 上**：实例重启后登录态仍保留；但如果 Fly 账户过期或 volume 误删需要重新扫码登录
- **中国访问**：默认 region `sin`（新加坡）CDN 还行；如果需要更快可在 `fly.toml` 改 `primary_region = "hkg"`（香港）

## 维护命令

```bash
# 看日志
fly logs -a pikachu-music-api

# 重新部署
cd /home/shijingtian/workspace/projects/go-music-api
fly deploy

# 改 region
fly regions set hkg -a pikachu-music-api

# 删除部署
fly apps destroy pikachu-music-api
```
