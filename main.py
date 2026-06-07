#!/usr/bin/env python3
"""视频号下载工具 — MITM 代理自动下载

用法:
  python main.py serve                         启动代理服务，自动下载视频
  python main.py serve --download-dir ./out    指定下载目录
  python main.py tasks                         查看已下载任务
"""

import argparse
import os
import sys
import time

from config import DOWNLOAD_DIR, ensure_dirs
from downloader import Downloader


def cmd_serve(args):
    """启动代理服务，自动监控下载"""
    download_dir = args.download_dir or DOWNLOAD_DIR
    ensure_dirs()

    # 启动前清理上次中断残留的 .temp 文件
    _clean_temp_files(download_dir)

    dl = Downloader(download_dir=download_dir)

    if not dl.start():
        sys.exit(1)

    print(f"\n[INFO] 下载目录: {download_dir}")
    print("[INFO] 请在手机微信中打开视频号，代理会自动拦截下载")
    print("[INFO] 按 Ctrl+C 退出\n")

    poll_interval = args.poll_interval or 5

    try:
        while True:
            new_tasks = dl.poll_new_downloads()
            for task in new_tasks:
                title = task.get("title") or task.get("filename", "未知")
                size_mb = task.get("size", 0) / 1024 / 1024
                print(f"[OK] 新下载完成: {title} ({size_mb:.1f}MB)")
            time.sleep(poll_interval)
    except KeyboardInterrupt:
        print("\n[INFO] 收到退出信号")
    finally:
        dl.stop()


def cmd_tasks(args):
    """列出已下载的任务"""
    dl = Downloader()

    # 尝试连接已运行的服务
    if not dl.wait_ready(timeout=2):
        print("[WARN] 代理服务未运行，无法获取任务列表")
        print("[INFO] 请先启动代理服务: python main.py serve")
        return

    tasks = dl.list_tasks(status="done")
    if not tasks:
        print("[INFO] 暂无已完成的下载任务")
        return

    print(f"\n已完成的下载任务 ({len(tasks)} 条):\n")
    for t in tasks:
        title = t.get("title") or t.get("filename", "未知")
        size_mb = t.get("size", 0) / 1024 / 1024
        print(f"  - {title} ({size_mb:.1f}MB)")
        print(f"    路径: {t.get('path', '')}")
        print()


def _clean_temp_files(download_dir):
    """清理下载目录中残留的 .temp 文件（下载中断产生的半成品）"""
    if not os.path.exists(download_dir):
        return
    cleaned = 0
    for root, _, files in os.walk(download_dir):
        for f in files:
            if f.endswith(".temp"):
                temp_path = os.path.join(root, f)
                try:
                    size_mb = os.path.getsize(temp_path) / 1024 / 1024
                    os.remove(temp_path)
                    cleaned += 1
                    print(f"[INFO] 清理残留临时文件: {f} ({size_mb:.1f}MB)")
                except OSError as e:
                    print(f"[WARN] 无法删除 {f}: {e}")
    if cleaned:
        print(f"[OK] 共清理 {cleaned} 个残留临时文件\n")


def main():
    parser = argparse.ArgumentParser(
        description="视频号下载工具",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
示例:
  python main.py serve                         启动代理服务，自动下载
  python main.py serve --download-dir ./out    指定下载目录
  python main.py tasks                         查看已下载任务
        """,
    )
    sub = parser.add_subparsers(dest="command")

    # serve
    p_serve = sub.add_parser("serve", help="启动代理服务，自动下载视频")
    p_serve.add_argument("--download-dir", help="下载目录")
    p_serve.add_argument("--poll-interval", type=int, default=5, help="轮询间隔秒数 (默认: 5)")

    # tasks
    sub.add_parser("tasks", help="列出已下载的任务")

    args = parser.parse_args()

    if args.command == "serve":
        cmd_serve(args)
    elif args.command == "tasks":
        cmd_tasks(args)
    else:
        parser.print_help()


if __name__ == "__main__":
    main()
