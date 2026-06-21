# Pikachu Music API — Render.com 部署指南

把 go-music-api 部署到 [Render.com](https://render.com) 的免费 Web Service，给 Pikachu Music 移动 App 调用。

## 为什么选 Render

- ✅ **真正免费**：每月 750 instance hours（够一个服务 24/7 跑）
- ✅ **零信用卡**：用 GitHub 账号登录即可
- ✅ **Docker 原生支持**：复用现有 Dockerfile
- ⚠️ **15 分钟无请求 → 实例 sleep**，下次访问冷启动 ~30 秒
- ⚠️ **无持久化磁盘**：cookies.json 每次重启丢，需要重新扫码登录（仅影响登录态）

## 准备清单

| 项 | 说明 |
|---|------|
| GitHub 账号 | 用于注册 Render + 托管代码 |
| go-music-api 仓库 | 推到 GitHub（公开或私有都行） |

## 步骤 1：把代码推到 GitHub

当前代码在 `/home/shijingtian/workspace/projects/go-music-api/`，还没推 GitHub。

```bash
cd /home/shijingtian/workspace/projects/go-music-api

# 1. 初始化 git（如果还没）
git init
git add -A
git commit -m "init: go-music-api with Dockerfile"

# 2. 在 GitHub 上新建一个空仓库，例如：
#    https://github.com/你的用户名/pikachu-music-api
#    (不要勾 Add README / .gitignore / license)

# 3. 关联 + 推送
git remote add origin https://github.com/你的用户名/pikachu-music-api.git
git branch -M main
git push -u origin main
```

> 提示：`cookies.json` 已经在 `.gitignore` 吗？检查一下，没有的话加一行 `cookies.json`，避免把本地 cookie 推到公网。

## 步骤 2：注册 Render + 部署

1. 打开 https://render.com/register ，点 **Sign in with GitHub**
2. 授权 Render 访问你的 GitHub 仓库
3. 进入 https://dashboard.render.com/ ，点 **New +** → **Web Service**
4. 在 "Connect a repository" 列表里找到 `pikachu-music-api`，点 **Connect**
   - 如果列表里没有，点右边的 **Configure account** 授权访问
5. 填写配置：

   | 字段 | 值 |
   |---|---|
   | **Name** | `pikachu-music-api` （这会成为子域名） |
   | **Region** | `Singapore` 或 `Oregon` （Singapore 国内访问稍快） |
   | **Branch** | `main` |
   | **Runtime** | `Docker` |
   | **Dockerfile Path** | `./Dockerfile` （默认） |
   | **Docker Command** | 留空 （Dockerfile 里已有 CMD） |
   | **Instance Type** | `Free` ⚠️ **必须是 Free**（$7/月那个 Starter 会扣信用卡） |
   | **Health Check Path** | `/api/v1/music/search?q=test&type=song&n=1` |

6. 点 **Create Web Service**
7. 等 3-5 分钟构建（Go 1.25 镜像下载 + 编译）
8. 构建成功后页面顶部会显示你的 URL：

   ```
   https://pikachu-music-api.onrender.com
   ```

## 步骤 3：验证

在浏览器或终端访问：

```
curl "https://pikachu-music-api.onrender.com/api/v1/music/search?q=周杰伦&type=song&n=3"
```

期望响应：

```json
{
  "code": 200,
  "data": {
    "songs": [
      { "id": "...", "name": "...", "artist": "...", ... }
    ]
  }
}
```

如果返回 `404` 或 `Application failed`，回 Render 控制台看 **Logs** 标签页。

## 步骤 4：RN 客户端配置

打开 Pikachu Music APK → 右上角 ⚙ 设置 → **gomusic 后端** 字段填入：

```
https://pikachu-music-api.onrender.com/api/v1
```

保存后所有"聚合(go-music-api)"搜索/播放都走这个后端。

## 已知限制 & 应对

### 1. 冷启动 30 秒
免费档 15 分钟无请求后实例 sleep。下次第一次访问需要等 ~30 秒唤醒。

RN 客户端已内置 `waitForApi()` 轮询机制（`src/api/gomusic.ts`），会自动等待。但用户首次打开 App 搜索会感觉"卡一下"。

### 2. cookies 登录态丢
免费档没有持久磁盘，实例重启/重部署时 `cookies.json` 丢失。

**应对方案**：暂时不依赖登录态也能听绝大多数免费歌曲（搜索 + 播放）。如果某首歌要求登录：
- 短期：在 App 里加 "重新扫码登录" 按钮（未来工作）
- 当前：先用其他 8 个无需登录的源

### 3. 每月 750 小时限制
一个 Free 实例 24/7 跑 = 720 小时/月，刚好不超。如果加自动部署/多副本会超，超了实例会停到下月。

**应对**：保持单实例，不要勾 "Auto Deploy from GitHub"（每次 push 都重启会耗额外分钟数）。可以在 Settings → Auto-Deploy 里关掉，手动部署。

## 维护

| 操作 | 在 Render 控制台哪里 |
|---|---|
| 看实时日志 | 选服务 → **Logs** 标签 |
| 手动重启 | 选服务 → 右上角 **Manual Deploy** → **Deploy latest commit** |
| 看环境变量 | 选服务 → **Environment** 标签 |
| 删服务 | 选服务 → **Settings** → **Delete Web Service** |

## 升级路径

如果以后流量大 / 需要持久 cookies：

| 平台 | 永久免费额度 | 信用卡 | 备注 |
|---|---|---|---|
| Render Starter | 无（$7/月） | ✅ | 最简单 |
| 阿里云函数计算 FC | 100 万次/月 | ❌ | 国内最快，需要改造入口监听 9000 端口 |
| Oracle Cloud Always Free | 4 核 24GB ARM VPS | ✅ | 永久，但要卡 |

短期 Render 就够用了。

## 故障排查

| 现象 | 原因 | 修复 |
|---|---|---|
| 构建失败 `go.mod not found` | 仓库没推全 | `git push --all` 确认 go.mod/go.sum 在 |
| 启动后立刻 `connection refused` | Dockerfile CMD 端口错 | 确认 `EXPOSE 8080` 和 `--port 8080` 一致 |
| 502 Bad Gateway | 实例 sleep 中 | 等待 30 秒冷启动，或 curl 重试 |
| 搜索返回空数组 | 平台 API 限流 | 切其他源，等几分钟 |