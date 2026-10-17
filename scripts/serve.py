#!/usr/bin/env python3
"""Serves the browser player (web/) on this computer and opens it.

    scripts/serve.py [port] [--no-open]     # default http://localhost:8080

Only reachable from this computer (it listens on 127.0.0.1). Ctrl+C stops it.
"""
import functools
import http.server
import os
import sys
import webbrowser

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', 'web'))


class Handler(http.server.SimpleHTTPRequestHandler):
    extensions_map = {
        **http.server.SimpleHTTPRequestHandler.extensions_map,
        '.js': 'text/javascript',
        '.wasm': 'application/wasm',
        '.gz': 'application/octet-stream',
        '.txt': 'text/plain; charset=utf-8',
    }

    def end_headers(self):
        # Always check for a newer copy, so a rebuilt game shows up on reload.
        self.send_header('Cache-Control', 'no-cache')
        super().end_headers()

    def log_message(self, *args):
        pass


def main():
    args = [a for a in sys.argv[1:] if not a.startswith('--')]
    port = int(args[0]) if args else int(os.environ.get('PORT', 8080))
    missing = [f for f in ('game/halloflegends.gba.gz', 'vendor/nostalgist.js', 'vendor/mgba_libretro.wasm')
               if not os.path.exists(os.path.join(ROOT, f))]
    if missing:
        print('Missing ' + ', '.join('web/' + f for f in missing) + '.')
        print('Run scripts/play.sh (or scripts/build.sh and scripts/fetch-vendor.sh) first.')
        sys.exit(1)
    try:
        server = http.server.ThreadingHTTPServer(('127.0.0.1', port), functools.partial(Handler, directory=ROOT))
    except OSError:
        print(f'Port {port} is in use. Try another one: scripts/serve.py {port + 1}')
        sys.exit(1)
    url = f'http://localhost:{port}/'
    print(f'Hall of Legends is running at {url}  (Ctrl+C to stop)', flush=True)
    if '--no-open' not in sys.argv:
        webbrowser.open(url)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print()


if __name__ == '__main__':
    main()
