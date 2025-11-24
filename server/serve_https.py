#!/usr/bin/env python3
import argparse
import http.server
import os
import ssl
from pathlib import Path

def main():
    ap = argparse.ArgumentParser(description="Simple HTTPS static server for SWU hosting")
    ap.add_argument("--dir", default="pkgs/out", help="Directory to serve (default: pkgs/out)")
    ap.add_argument("--port", type=int, default=4443, help="HTTPS port (default: 4443)")
    ap.add_argument("--cert", default="server/server.crt", help="TLS cert path")
    ap.add_argument("--key", default="server/server.key", help="TLS key path")
    args = ap.parse_args()

    serve_dir = Path(args.dir).resolve()
    if not serve_dir.exists():
        raise SystemExit(f"Serve dir not found: {serve_dir}")

    # ✅ resolve cert/key paths BEFORE chdir
    cert_path = Path(args.cert).resolve()
    key_path  = Path(args.key).resolve()

    if not cert_path.exists():
        raise SystemExit(f"Cert not found: {cert_path}")
    if not key_path.exists():
        raise SystemExit(f"Key not found: {key_path}")

    os.chdir(serve_dir)

    handler = http.server.SimpleHTTPRequestHandler
    httpd = http.server.ThreadingHTTPServer(("0.0.0.0", args.port), handler)

    ctx = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
    ctx.load_cert_chain(certfile=cert_path, keyfile=key_path)
    httpd.socket = ctx.wrap_socket(httpd.socket, server_side=True)

    print(f"[HTTPS] Serving {serve_dir} on https://0.0.0.0:{args.port}/")
    print("[HTTPS] Files:")
    for p in serve_dir.iterdir():
        print("  -", p.name)

    httpd.serve_forever()

if __name__ == "__main__":
    main()
