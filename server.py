#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
RightPick 職場遊樂場 — 極簡本機靜態伺服器
只需要 Python 3，唔需要安裝任何套件。
用法：  python server.py [port]
"""
import http.server
import os
import socketserver
import sys

PORT = int(sys.argv[1]) if len(sys.argv) > 1 else 8080
ROOT = os.path.dirname(os.path.abspath(__file__))
os.chdir(ROOT)


class Handler(http.server.SimpleHTTPRequestHandler):
    # 重要：.wasm / .task / .js 要正確 MIME，否則 MediaPipe 載入唔到
    extensions_map = dict(http.server.SimpleHTTPRequestHandler.extensions_map)
    extensions_map.update({
        '.html': 'text/html; charset=utf-8',
        '.js':   'text/javascript; charset=utf-8',
        '.mjs':  'text/javascript; charset=utf-8',
        '.css':  'text/css; charset=utf-8',
        '.json': 'application/json; charset=utf-8',
        '.wasm': 'application/wasm',
        '.task': 'application/octet-stream',
        '.svg':  'image/svg+xml',
        '.png':  'image/png',
        '.woff2': 'font/woff2',
    })

    def end_headers(self):
        self.send_header('Cache-Control', 'no-store')
        self.send_header('Access-Control-Allow-Origin', '*')
        super().end_headers()

    def log_message(self, fmt, *args):
        pass


class Server(socketserver.ThreadingTCPServer):
    allow_reuse_address = True
    daemon_threads = True


if __name__ == '__main__':
    try:
        with Server(('127.0.0.1', PORT), Handler) as httpd:
            print('RightPick Arcade -> http://localhost:%d/' % PORT, flush=True)
            httpd.serve_forever()
    except OSError as e:
        print('Port %d 用唔到：%s' % (PORT, e), flush=True)
        sys.exit(1)
