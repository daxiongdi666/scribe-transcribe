#!/usr/bin/env bash
# 视频号下载器 - 一键启动 (macOS / Linux)
#
# macOS: 自动设置系统 HTTP 代理，退出时自动恢复。
# Linux: 需要手动配置浏览器代理为 127.0.0.1:2023。

set -e

cd "$(dirname "$0")"

# ── 确定二进制文件名 ──
BIN_NAME="wx-dl"
if [ "$(uname -s)" = "Darwin" ] && [ "$(uname -m)" = "arm64" ]; then
    # Apple Silicon: 优先用 arm64 版本，不存在则回退通用版
    if [ -f "bin/wx-dl-arm64" ]; then
        BIN_NAME="wx-dl-arm64"
    fi
fi

if [ ! -f "bin/$BIN_NAME" ]; then
    echo "[ERROR] 找不到 bin/$BIN_NAME"
    echo "请先编译:"
    echo "  cd scribe-studio/backend/core"
    if [ "$(uname -m)" = "arm64" ]; then
        echo "  go build -o ../../../scribe-transcribe/bin/wx-dl-arm64 ."
    else
        echo "  go build -o ../../../scribe-transcribe/bin/wx-dl ."
    fi
    exit 1
fi

# macOS 权限检查：解除 Gatekeeper 限制
if [ "$(uname -s)" = "Darwin" ]; then
    if ! xattr "bin/$BIN_NAME" 2>/dev/null | grep -q "com.apple.quarantine"; then
        : # 没有 quarantine 标记，正常
    else
        echo "[WARN] 检测到 macOS 安全限制 (Gatekeeper)，正在解除..."
        xattr -cr "bin/$BIN_NAME"
        echo "[OK] 已解除 Gatekeeper 限制"
    fi
fi

# ── 配置 ──
PROXY_PORT=2023
API_PORT=2022
IS_MACOS=false
NETWORK_SERVICE=""

# ── macOS: 设置系统 HTTP 代理 ──
setup_proxy_macos() {
    if [ "$(uname -s)" != "Darwin" ]; then
        return
    fi

    IS_MACOS=true

    # 获取当前优先级最高的活跃网络服务
    NETWORK_SERVICE=$(networksetup -listnetworkserviceorder 2>/dev/null \
        | awk '/\(1\)/{getline; print $1; exit}')

    # 回退方案: 尝试 Wi-Fi / Ethernet
    if [ -z "$NETWORK_SERVICE" ]; then
        if networksetup -getinfo "Wi-Fi" &>/dev/null; then
            NETWORK_SERVICE="Wi-Fi"
        elif networksetup -getinfo "Ethernet" &>/dev/null; then
            NETWORK_SERVICE="Ethernet"
        fi
    fi

    if [ -z "$NETWORK_SERVICE" ]; then
        echo "[WARN] 无法自动检测网络服务，请手动配置浏览器代理:"
        echo "  代理地址: 127.0.0.1:$PROXY_PORT"
        return
    fi

    echo "[INFO] 检测到网络服务: $NETWORK_SERVICE"
    echo "[INFO] 设置系统 HTTP/HTTPS 代理 -> 127.0.0.1:$PROXY_PORT ..."
    echo "       (需要管理员权限，请输入密码)"

    if ! sudo networksetup -setwebproxy "$NETWORK_SERVICE" 127.0.0.1 $PROXY_PORT; then
        echo "[WARN] 设置 HTTP 代理失败，请手动配置浏览器代理: 127.0.0.1:$PROXY_PORT"
        return
    fi
    sudo networksetup -setsecurewebproxy "$NETWORK_SERVICE" 127.0.0.1 $PROXY_PORT
    sudo networksetup -setwebproxystate "$NETWORK_SERVICE" on
    sudo networksetup -setsecurewebproxystate "$NETWORK_SERVICE" on

    echo "[OK] 系统代理已设置"
}

# ── macOS: 恢复系统代理设置 ──
restore_proxy_macos() {
    if [ "$IS_MACOS" = false ] || [ -z "$NETWORK_SERVICE" ]; then
        return
    fi

    echo ""
    echo "[INFO] 恢复系统代理设置..."
    # 用 -n (non-interactive) 避免 sudo 密码过期时卡住
    if sudo -n networksetup -setwebproxystate "$NETWORK_SERVICE" off 2>/dev/null && \
       sudo -n networksetup -setsecurewebproxystate "$NETWORK_SERVICE" off 2>/dev/null; then
        echo "[OK] 系统代理已关闭"
    else
        echo "[WARN] 无法自动恢复代理（sudo 密码已过期），请手动关闭:"
        echo "  sudo networksetup -setwebproxystate \"$NETWORK_SERVICE\" off"
        echo "  sudo networksetup -setsecurewebproxystate \"$NETWORK_SERVICE\" off"
    fi
}

# ── 退出时清理（临时关闭 set -e 避免 cleanup 中途失败） ──
cleanup() {
    set +e
    restore_proxy_macos
    echo "[INFO] 已退出"
}
trap cleanup EXIT HUP INT QUIT TERM

# ── 启动 ──
echo "========================================"
echo "  视频号下载器 - 一键启动"
echo "========================================"
echo ""

# 设置系统代理（macOS）
setup_proxy_macos

echo ""
echo "[INFO] 启动视频号代理服务..."
echo "[INFO] API 地址:  http://127.0.0.1:$API_PORT"
echo "[INFO] 代理端口:  $PROXY_PORT"
echo ""

if [ "$IS_MACOS" = true ]; then
    echo "系统代理已自动配置，直接在浏览器中打开:"
    echo "  https://channels.weixin.qq.com"
    echo "页面会自动出现下载按钮。"
else
    echo "请在浏览器中配置 HTTP/HTTPS 代理:"
    echo "  服务器: 127.0.0.1"
    echo "  端口:   $PROXY_PORT"
    echo ""
    echo "然后打开 https://channels.weixin.qq.com"
fi

echo ""
echo "按 Ctrl+C 退出（会自动恢复代理设置）"
echo ""

# 启动 Go 代理服务
# --hostname 0.0.0.0: 监听所有接口，方便手机/局域网设备通过代理下载
# 如果只需电脑端使用，改为 127.0.0.1
"./bin/$BIN_NAME" --hostname 0.0.0.0 --port $PROXY_PORT &
DL_PID=$!

# 等待子进程退出
wait $DL_PID 2>/dev/null
EXIT_CODE=$?

if [ $EXIT_CODE -ne 0 ]; then
    echo ""
    echo "[ERROR] 下载器异常退出 (退出码: $EXIT_CODE)"
    echo "[INFO] 常见原因:"
    echo "  - 端口 $PROXY_PORT 已被占用"
    if [ "$(uname -s)" = "Darwin" ]; then
        echo "  - macOS 安全拦截，尝试: chmod +x bin/$BIN_NAME && xattr -cr bin/$BIN_NAME"
    fi
    echo "  - 权限不足，尝试: chmod +x bin/$BIN_NAME"
fi
