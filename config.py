import os
import sys
import platform

# 项目根目录
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
BIN_DIR = os.path.join(BASE_DIR, "bin")
DOWNLOAD_DIR = os.path.join(BASE_DIR, "downloads")


def _get_dl_binary_name():
    """根据平台和架构确定 Go 下载器二进制名"""
    if sys.platform == "win32":
        return "wx-dl.exe"
    # macOS Apple Silicon 优先使用 arm64 版本
    if sys.platform == "darwin" and platform.machine() == "arm64":
        arm64_path = os.path.join(BIN_DIR, "wx-dl-arm64")
        if os.path.exists(arm64_path):
            return "wx-dl-arm64"
    return "wx-dl"


# Go 下载器
_DL_BIN = _get_dl_binary_name()
WX_DL_EXE = os.path.join(BIN_DIR, _DL_BIN)
WX_DL_API = "http://127.0.0.1:2022"


def ensure_dirs():
    os.makedirs(DOWNLOAD_DIR, exist_ok=True)
    os.makedirs(BIN_DIR, exist_ok=True)
