# Scribe Transcribe

微信视频号下载工具。Python CLI 实现，轻量简洁。支持 Windows / macOS / Linux。

基于 [autogame-17/scribe-studio](https://github.com/autogame-17/scribe-studio) 的视频号下载核心，用 Python 重新封装。

## 功能

- **视频号下载** — MITM 代理拦截，自动注入下载按钮到微信视频号页面

## 架构

```
wx-dl.exe (Go, MITM代理+API服务)
    ↕ HTTP API (localhost:2022)
main.py (Python CLI, 总控)
    ├── 启动/管理代理服务
    └── 查看下载任务
```

## 前置条件

| 依赖 | 版本要求 | 用途 | 安装方式 |
|------|---------|------|---------|
| **Go** | 1.21+ | 编译视频号下载器 | `winget install GoLang.Go` 或 `brew install go` |
| **Python** | 3.10+ | 运行主程序 | [python.org](https://python.org) |
| **Git** | 任意版本 | 克隆上游下载器源码 | `winget install Git.Git` 或 `brew install git` |

## 安装

### 1. 克隆本项目

```bash
git clone https://github.com/<your-username>/scribe-transcribe.git
cd scribe-transcribe
```

### 2. 编译 Go 下载器

需要先克隆上游的 scribe-studio（本项目已包含其 `backend/core` 作为参考）：

```bash
cd scribe-studio/backend/core

# 设置国内代理加速（国内用户推荐）
go env -w GOPROXY=https://goproxy.cn,direct

# Windows
go build -o ../../../scribe-transcribe/bin/wx-dl.exe .

# macOS / Linux
go build -o ../../../scribe-transcribe/bin/wx-dl .
```

编译完成后二进制文件约 36MB。

### 3. 安装 Python 依赖

```bash
pip install -r requirements.txt -i https://pypi.tuna.tsinghua.edu.cn/simple
```

只需 `requests` 一个包，非常轻量。

## 使用

### 快速开始：下载视频号

```bash
# Windows
start.bat

# macOS / Linux
chmod +x start.sh
./start.sh
```

启动后，在电脑浏览器打开微信视频号网页（`channels.weixin.qq.com`），页面会自动注入下载按钮，点击即可下载。

> **不需要手机配置代理**。代理服务运行在本地（`127.0.0.1:2023`），电脑端直接访问视频号网页即可。

### 命令行模式

```bash
# 启动视频号代理服务
python main.py serve --download-dir ./downloads

# 查看已下载的任务
python main.py tasks
```

### 手机端下载（可选）

如果想在手机微信 App 里直接看到下载按钮，需要配置手机代理：

1. 手机和电脑连同一个 WiFi
2. 手机 WiFi 设置 → HTTP 代理 → 手动
3. 服务器填电脑 IP（启动脚本会显示）
4. 端口填 `2023`
5. 打开微信视频号，页面会自动注入下载按钮

> 这是**可选方案**，只在需要在手机端操作时才需要配置。

## 项目结构

```
scribe-transcribe/
├── main.py              # CLI 入口（serve / tasks）
├── downloader.py        # Go 代理服务管理
├── config.py            # 配置管理
├── start.bat            # Windows 一键启动脚本
├── start.sh             # macOS / Linux 一键启动脚本
├── requirements.txt     # Python 依赖（仅 requests）
└── bin/                 # 编译产物（gitignore）
    └── wx-dl(.exe)
```

## 常见问题

**Q: 启动后在电脑浏览器打开视频号，没有看到下载按钮？**
A: 请按以下步骤排查：
1. 确认代理服务已启动成功（看到 `API 地址 http://127.0.0.1:2022` 的提示）
2. **macOS 用户**：确认 `start.sh` 已设置系统代理（会提示输入管理员密码）。如果跳过了这一步，手动设置：系统设置 → 网络 → Wi-Fi → 详细信息 → 代理 → 开启「网页代理(HTTP)」和「安全网页代理(HTTPS)」→ 服务器 `127.0.0.1`，端口 `2023`
3. 清除浏览器缓存后刷新页面
4. **首次使用**：代理会生成 HTTPS 证书，浏览器可能弹出安全警告，点击「高级」→「继续访问」即可。如果想在手机端使用，需要在手机上安装并信任 CA 证书

**Q: macOS 上提示「找不到下载器」？**
A: macOS 需要手动编译 Go 下载器。Apple Silicon (M1/M2/M3/M4) 编译为 `wx-dl-arm64`，Intel Mac 编译为 `wx-dl`：
```bash
cd scribe-studio/backend/core
# Apple Silicon
go build -o ../../../scribe-transcribe/bin/wx-dl-arm64 .
# Intel Mac
go build -o ../../../scribe-transcribe/bin/wx-dl .
```

**Q: macOS 提示「无法打开 wx-dl，因为无法验证开发者」？**
A: 这是 macOS 的安全限制（Gatekeeper），执行以下命令解除：
```bash
xattr -cr bin/wx-dl-arm64  # 或 bin/wx-dl
```

**Q: 手机配置代理后无法上网？**
A: 检查手机代理配置的 IP 和端口是否正确，确保手机和电脑在同一局域网。

**Q: 权限不够无法启动代理？**
A: Windows 右键 `start.bat` → 以管理员身份运行；macOS 使用 `sudo ./start.sh`（设置系统代理需要管理员权限）。

## 致谢

- [autogame-17/scribe-studio](https://github.com/autogame-17/scribe-studio) — 视频号下载核心和整体架构
- [ltaoo/wx_channels_download](https://github.com/ltaoo/wx_channels_download) — 视频号 MITM 拦截实现

## License

GPL-3.0-or-later（与上游 scribe-studio 保持一致）
