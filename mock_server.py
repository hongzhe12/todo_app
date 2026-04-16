from http.server import BaseHTTPRequestHandler, HTTPServer
import json

HOST = "127.0.0.1"
PORT = 8000

MOCK_TODOS = [
    {"id": 1, "title": "学习 Flutter123", "completed": False},
    {"id": 2, "title": "哈哈", "completed": False},
    {"id": 3, "title": "写单元测试", "completed": True},
]


class MockHandler(BaseHTTPRequestHandler):
    def _send_json(self, data, status=200):
        body = json.dumps(data, ensure_ascii=False).encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "Content-Type, Authorization")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def do_OPTIONS(self):
        self.send_response(204)
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "Content-Type, Authorization")
        self.end_headers()

    def do_GET(self):
        if self.path == "/health":
            return self._send_json({"ok": True})

        if self.path == "/api/todos":
            return self._send_json({"code": 0, "message": "success", "data": MOCK_TODOS})

        return self._send_json({"code": 404, "message": "not found"}, status=404)

    def log_message(self, format, *args):
        return


if __name__ == "__main__":
    server = HTTPServer((HOST, PORT), MockHandler)
    print(f"Mock server running at http://{HOST}:{PORT}")
    server.serve_forever()
