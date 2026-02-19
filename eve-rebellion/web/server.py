#!/usr/bin/env python3
"""Simple HTTP server with proper MIME types for WASM."""

import http.server
import socketserver

PORT = 8080

class WASMHandler(http.server.SimpleHTTPRequestHandler):
    extensions_map = {
        '.html': 'text/html',
        '.js': 'application/javascript',
        '.wasm': 'application/wasm',
        '.css': 'text/css',
        '.json': 'application/json',
        '.png': 'image/png',
        '.jpg': 'image/jpeg',
        '.svg': 'image/svg+xml',
        '.ico': 'image/x-icon',
        '': 'application/octet-stream',
    }

    def end_headers(self):
        # Enable CORS and cross-origin isolation for SharedArrayBuffer
        self.send_header('Cross-Origin-Opener-Policy', 'same-origin')
        self.send_header('Cross-Origin-Embedder-Policy', 'require-corp')
        super().end_headers()

if __name__ == '__main__':
    with socketserver.TCPServer(("", PORT), WASMHandler) as httpd:
        print(f"Serving at http://localhost:{PORT}")
        httpd.serve_forever()
