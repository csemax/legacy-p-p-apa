#!/usr/bin/env python3
"""
DANTE Legacy System - HTTP API Wrapper
Mengekspos program COBOL sebagai REST API
Seven Deadly Syncs - Capstone UB 2026

Karakteristik sesuai dokumen:
- Artificial delay 300-2000ms per endpoint
- Max 50 concurrent connections
- Random error 5% timeout, 3% error 500, 2% connection refused
- Heavy response payload 5-50KB
"""

import subprocess
import json
import random
import time
import threading
import logging
import os
from http.server import HTTPServer, BaseHTTPRequestHandler
from urllib.parse import urlparse, parse_qs

# ── Konfigurasi ──────────────────────────────────────────────
HOST = "0.0.0.0"
PORT = 9090
MAX_CONNECTIONS = 50
COBOL_DIR = "/app/cobol"
DATA_DIR = "/app/data"

# Simulasi karakteristik legacy system
ERROR_RATE_TIMEOUT = 0.05      # 5% timeout
ERROR_RATE_SERVER_ERROR = 0.03  # 3% error 500
ERROR_RATE_CONN_REFUSED = 0.02  # 2% connection refused
ARTIFICIAL_DELAY_MIN = 0.3      # 300ms minimum
ARTIFICIAL_DELAY_MAX = 2.0      # 2000ms maximum

logging.basicConfig(
    level=logging.INFO,
    format='[%(asctime)s] [LEGACY] %(levelname)s %(message)s',
    datefmt='%Y-%m-%d %H:%M:%S'
)
log = logging.getLogger(__name__)

# Semaphore untuk batasi concurrent connections
connection_semaphore = threading.Semaphore(MAX_CONNECTIONS)
active_connections = 0
connection_lock = threading.Lock()


class LegacySystemHandler(BaseHTTPRequestHandler):

    def log_message(self, format, *args):
        """Override default logging"""
        log.info(f"{self.client_address[0]} - {format % args}")

    def do_GET(self):
        self._handle_request("GET")

    def do_POST(self):
        self._handle_request("POST")

    def _handle_request(self, method):
        global active_connections

        # Cek concurrent connection limit
        if not connection_semaphore.acquire(blocking=False):
            log.warning("Max connections reached! Rejecting request.")
            self._send_error(503, "Legacy system at capacity")
            return

        with connection_lock:
            active_connections += 1

        try:
            # Simulasi random failure sebelum proses
            failure = self._simulate_random_failure()
            if failure:
                return

            # Route request ke COBOL program
            parsed = urlparse(self.path)
            path = parsed.path
            params = parse_qs(parsed.query)

            log.info(f"[{method}] {path} | active_conn={active_connections}")

            if method == "GET" and path.startswith("/api/balance/"):
                self._handle_balance_inquiry(path, params)

            elif method == "GET" and path.startswith("/api/transaction/"):
                self._handle_transaction_status(path, params)

            elif method == "GET" and path.startswith("/api/merchant/"):
                self._handle_merchant_info(path, params)

            elif method == "POST" and path == "/api/payment/process":
                self._handle_payment_process()

            elif method == "GET" and path == "/health":
                self._handle_health_check()

            else:
                self._send_error(404, f"Endpoint {path} tidak ditemukan")

        finally:
            connection_semaphore.release()
            with connection_lock:
                active_connections -= 1

    def _simulate_random_failure(self):
        """Simulasi kegagalan acak sesuai karakteristik legacy system"""
        rand = random.random()

        # 2% connection refused (simulasi dengan delay panjang + error)
        if rand < ERROR_RATE_CONN_REFUSED:
            log.warning("Simulating connection refused")
            time.sleep(0.1)
            self._send_error(503, "Connection refused - legacy system unavailable")
            return True

        # 5% timeout (delay sangat lama)
        if rand < ERROR_RATE_CONN_REFUSED + ERROR_RATE_TIMEOUT:
            log.warning("Simulating timeout")
            time.sleep(ARTIFICIAL_DELAY_MAX + random.uniform(0.5, 1.0))
            self._send_error(504, "Gateway timeout - legacy system not responding")
            return True

        # 3% internal server error
        if rand < ERROR_RATE_CONN_REFUSED + ERROR_RATE_TIMEOUT + ERROR_RATE_SERVER_ERROR:
            log.warning("Simulating server error")
            time.sleep(random.uniform(0.1, 0.3))
            self._send_error(500, "Internal server error pada legacy system")
            return True

        return False

    def _add_artificial_delay(self, min_delay=None, max_delay=None):
        """Tambahkan delay buatan untuk simulasi sistem lama"""
        min_d = min_delay or ARTIFICIAL_DELAY_MIN
        max_d = max_delay or ARTIFICIAL_DELAY_MAX
        delay = random.uniform(min_d, max_d)
        time.sleep(delay)
        return delay

    def _handle_balance_inquiry(self, path, params):
        """GET /api/balance/{user_id}"""
        # Extract user_id dari path
        parts = path.strip('/').split('/')
        if len(parts) < 3:
            self._send_error(400, "user_id diperlukan")
            return

        user_id = parts[2]
        delay = self._add_artificial_delay(0.3, 0.8)

        # Jalankan COBOL program
        result = self._run_cobol_program(
            program="BALANCEINQ",
            input_data=user_id
        )

        log.info(f"Balance inquiry user={user_id} delay={delay:.2f}s")
        self._send_json_response(result)

    def _handle_transaction_status(self, path, params):
        """GET /api/transaction/{txn_id}/status"""
        parts = path.strip('/').split('/')
        if len(parts) < 4:
            self._send_error(400, "transaction_id diperlukan")
            return

        txn_id = parts[2]
        delay = self._add_artificial_delay(0.3, 0.6)

        result = self._run_cobol_program(
            program="TXNSTATUS",
            input_data=txn_id
        )

        log.info(f"Transaction status txn={txn_id} delay={delay:.2f}s")
        self._send_json_response(result)

    def _handle_merchant_info(self, path, params):
        """GET /api/merchant/{merchant_id}"""
        parts = path.strip('/').split('/')
        if len(parts) < 3:
            self._send_error(400, "merchant_id diperlukan")
            return

        merchant_id = parts[2]
        delay = self._add_artificial_delay(0.2, 0.5)

        result = self._run_cobol_program(
            program="MERCHANTVAL",
            input_data=merchant_id
        )

        log.info(f"Merchant info id={merchant_id} delay={delay:.2f}s")
        self._send_json_response(result)

    def _handle_payment_process(self):
        """POST /api/payment/process"""
        content_length = int(self.headers.get('Content-Length', 0))
        body = self.rfile.read(content_length)

        try:
            request_data = json.loads(body)
        except json.JSONDecodeError:
            self._send_error(400, "Request body tidak valid JSON")
            return

        # Format input untuk COBOL (pipe-delimited)
        txn_id = request_data.get('transaction_id', '')
        user_id = request_data.get('user_id', '')
        merchant_id = request_data.get('merchant_id', '')
        amount = str(request_data.get('amount', 0))
        qr_code = request_data.get('qr_code', '')

        cobol_input = f"{txn_id}|{user_id}|{merchant_id}|{amount}|{qr_code}"
        delay = self._add_artificial_delay(0.5, 2.0)

        result = self._run_cobol_program(
            program="PAYMENTPROC",
            input_data=cobol_input
        )

        log.info(
            f"Payment process txn={txn_id} "
            f"user={user_id} amount={amount} delay={delay:.2f}s"
        )
        self._send_json_response(result)

    def _handle_health_check(self):
        """GET /health - health check endpoint"""
        response = {
            "status": "ok",
            "service": "Legacy System DANTE",
            "type": "COBOL Core Banking Simulation",
            "active_connections": active_connections,
            "max_connections": MAX_CONNECTIONS,
            "version": "COBOL-85",
            "timestamp": time.strftime("%Y-%m-%dT%H:%M:%S")
        }
        self._send_json(200, response)

    def _run_cobol_program(self, program, input_data):
        """Jalankan program COBOL dan ambil outputnya"""
        binary_path = f"/app/bin/{program}"

        # Fallback ke mock jika binary tidak ada
        if not os.path.exists(binary_path):
            log.warning(f"Binary {binary_path} tidak ada, pakai mock")
            return self._get_mock_response(program, input_data)

        try:
            result = subprocess.run(
                [binary_path],
                input=input_data,
                capture_output=True,
                text=True,
                timeout=10
            )

            output = result.stdout.strip()
            if not output:
                return {
                    "status": "error",
                    "code": 5001,
                    "data": None,
                    "message": "COBOL program tidak menghasilkan output"
                }

            return json.loads(output)

        except subprocess.TimeoutExpired:
            return {
                "status": "error",
                "code": 5002,
                "data": None,
                "message": "COBOL program timeout"
            }
        except json.JSONDecodeError as e:
            log.error(f"Gagal parse COBOL output: {e}")
            return {
                "status": "error",
                "code": 5001,
                "data": None,
                "message": "COBOL output tidak valid JSON"
            }
        except Exception as e:
            log.error(f"Error menjalankan COBOL: {e}")
            return {
                "status": "error",
                "code": 9999,
                "data": None,
                "message": str(e)
            }

    def _get_mock_response(self, program, input_data):
        """
        Mock response ketika COBOL binary belum dikompilasi
        Digunakan untuk testing tanpa COBOL
        """
        if program == "BALANCEINQ":
            user_id = input_data.strip()
            accounts = {
                "user-001": {"balance": 5000000.00, "name": "Budi Santoso"},
                "user-002": {"balance": 12500000.00, "name": "Siti Rahayu"},
                "user-003": {"balance": 750000.00, "name": "Ahmad Fauzi"},
                "user-004": {"balance": 25000000.00, "name": "Dewi Kusuma"},
                "user-005": {"balance": 3200000.00, "name": "Eko Prasetyo"},
            }
            if user_id in accounts:
                acc = accounts[user_id]
                return {
                    "status": "success",
                    "code": 0,
                    "data": {
                        "user_id": user_id,
                        "account_id": f"acc-{user_id.split('-')[1]}",
                        "account_name": acc["name"],
                        "balance": acc["balance"],
                        "currency": "IDR",
                        "account_status": "active",
                        "source": "legacy-cobol-mock"
                    },
                    "message": "Balance inquiry berhasil"
                }
            return {
                "status": "error", "code": 1001,
                "data": None, "message": "User tidak ditemukan"
            }

        elif program == "PAYMENTPROC":
            parts = input_data.split('|')
            if len(parts) >= 4:
                return {
                    "status": "success",
                    "code": 0,
                    "data": {
                        "transaction_id": parts[0],
                        "user_id": parts[1],
                        "merchant_id": parts[2],
                        "amount": float(parts[3]) if parts[3] else 0,
                        "status": "success",
                        "source": "legacy-cobol-mock"
                    },
                    "message": "Pembayaran QRIS berhasil diproses"
                }

        elif program == "TXNSTATUS":
            txn_id = input_data.strip()
            transactions = {
                "txn-001": {"status": "success", "amount": 50000.00},
                "txn-002": {"status": "success", "amount": 125000.00},
                "txn-003": {"status": "pending", "amount": 75000.00},
                "txn-004": {"status": "failed", "amount": 200000.00},
            }
            if txn_id in transactions:
                txn = transactions[txn_id]
                return {
                    "status": "success",
                    "code": 0,
                    "data": {
                        "transaction_id": txn_id,
                        "status": txn["status"],
                        "amount": txn["amount"],
                        "source": "legacy-cobol-mock"
                    },
                    "message": "Status transaksi ditemukan"
                }
            return {
                "status": "error", "code": 1001,
                "data": None, "message": "Transaksi tidak ditemukan"
            }

        elif program == "MERCHANTVAL":
            merchant_id = input_data.strip()
            merchants = {
                "merchant-001": "Warung Makan Sederhana",
                "merchant-002": "Toko Elektronik Maju",
                "merchant-003": "Apotek Sehat Selalu",
            }
            if merchant_id in merchants:
                return {
                    "status": "success",
                    "code": 0,
                    "data": {
                        "merchant_id": merchant_id,
                        "merchant_name": merchants[merchant_id],
                        "status": "active",
                        "source": "legacy-cobol-mock"
                    },
                    "message": "Merchant ditemukan"
                }
            return {
                "status": "error", "code": 1005,
                "data": None, "message": "Merchant tidak ditemukan"
            }

        return {
            "status": "error",
            "code": 9999,
            "data": None,
            "message": "Unknown program"
        }

    def _send_json_response(self, data):
        """Kirim response JSON"""
        status_map = {
            "success": 200,
            "error": self._get_error_status(data.get("code", 9999))
        }
        status_code = status_map.get(data.get("status"), 500)
        self._send_json(status_code, data)

    def _get_error_status(self, code):
        """Map error code ke HTTP status"""
        if code >= 5000:
            return 500
        if code >= 1000:
            return 404 if code == 1001 else 400
        return 500

    def _send_json(self, status_code, data):
        """Send JSON response"""
        body = json.dumps(data, ensure_ascii=False, indent=2).encode('utf-8')
        self.send_response(status_code)
        self.send_header('Content-Type', 'application/json; charset=utf-8')
        self.send_header('Content-Length', len(body))
        self.send_header('X-Legacy-System', 'COBOL-DANTE')
        self.send_header('X-Active-Connections', str(active_connections))
        self.end_headers()
        self.wfile.write(body)

    def _send_error(self, status_code, message):
        """Send error response"""
        self._send_json(status_code, {
            "status": "error",
            "code": status_code,
            "data": None,
            "message": message
        })


def run_server():
    server = HTTPServer((HOST, PORT), LegacySystemHandler)
    server.allow_reuse_address = True

    log.info("=" * 60)
    log.info("  DANTE Legacy System - COBOL Core Banking")
    log.info("  Seven Deadly Syncs - Capstone UB 2026")
    log.info("=" * 60)
    log.info(f"Server berjalan di http://{HOST}:{PORT}")
    log.info(f"Max concurrent connections: {MAX_CONNECTIONS}")
    log.info(f"Error rates: timeout={ERROR_RATE_TIMEOUT*100:.0f}% "
             f"server_err={ERROR_RATE_SERVER_ERROR*100:.0f}% "
             f"conn_refused={ERROR_RATE_CONN_REFUSED*100:.0f}%")
    log.info("=" * 60)

    try:
        server.serve_forever()
    except KeyboardInterrupt:
        log.info("Server dihentikan")
        server.shutdown()


if __name__ == '__main__':
    run_server()
