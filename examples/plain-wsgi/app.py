"""Minimal WSGI application for local development."""

import json


def application(environ, start_response):
    path = environ.get("PATH_INFO", "")

    if path == "/":
        status = "200 OK"
        content_type = "text/plain; charset=utf-8"
        body = b"Hello, Python!\n"
    elif path == "/json":
        status = "200 OK"
        content_type = "application/json; charset=utf-8"
        body = json.dumps({"message": "Hello, Python!"}).encode("utf-8")
    else:
        status = "404 Not Found"
        content_type = "text/plain; charset=utf-8"
        body = b"Not Found\n"

    start_response(status, [("Content-Type", content_type), ("Content-Length", str(len(body)))])
    return [body]
