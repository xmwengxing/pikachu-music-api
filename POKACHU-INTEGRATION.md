# 与 pikachu-music 的对接说明

本目录的 `go-music-api` 已部署并接入到同级的 `pikachu-music/` 前端项目。

## 当前部署

- **容器**：`go-music-api`（基于官方镜像 `guohuiyuan/go-music-api:latest`）
- **端口**：`8080`（容器内 `8080` 映射到宿主机 `8080`）
- **Cookie**：`./cookies.json` 挂载到容器 `/home/appuser/cookies.json`（当前为空）

## 容器管理

```bash
# 启动（已在运行）
docker run -d --name go-music-api -p 8080:8080 \
  -v "$(pwd)/cookies.json:/home/appuser/cookies.json" \
  -e TZ=Asia/Shanghai guohuiyuan/go-music-api:latest

# 查看日志
docker logs -f go-music-api

# 重启
docker restart go-music-api

# 停止
docker stop go-music-api

# 删除并重建
docker rm -f go-music-api && docker run -d --name go-music-api -p 8080:8080 \
  -v "$(pwd)/cookies.json:/home/appuser/cookies.json" \
  -e TZ=Asia/Shanghai guohuiyuan/go-music-api:latest
```

## 冒烟测试

```bash
# 健康：搜索
curl -s "http://localhost:8080/api/v1/music/search?q=周杰伦&type=song" | head -c 200

# 取音频直链
curl -s "http://localhost:8080/api/v1/music/url?id=5257138&source=netease"

# 取歌词
curl -s "http://localhost:8080/api/v1/music/lyric?id=5257138&source=netease"
```

## 接口文档

浏览器打开 `http://localhost:8080/swagger/index.html` 查看完整 Swagger 文档。

## 前端对接关键点

- 前端在 `../pikachu-music/index.html` 顶部常量：
  ```js
  const GOMUSIC_BASE = 'http://localhost:8080/api/v1';
  ```
- 前端新增了 5 号源「聚合（go-music-api）」，默认开启
- 前端调用 3 个核心接口：
  - `GET /api/v1/music/search?q=&type=song&n=` → 搜索
  - `GET /api/v1/music/url?id=&source=` → 取音频直链
  - `GET /api/v1/music/lyric?id=&source=` → 取 LRC 歌词
- CORS 已内置 `*` 全允许（参见 `router/router.go` 第 17-28 行），无需额外配置

## 已知边界

- **部分平台需登录**：QQ 部分付费曲、网易云 VIP 曲目、汽水音乐全部曲目，需在 `cookies.json` 中配置对应平台 Cookie
- **首次请求慢**：后端启动后第一次请求需要约 1-3 秒初始化
- **B 站音频可能失败**：B 站音频分块存储，需特殊处理；详见 `/api/v1/music/stream` 接口