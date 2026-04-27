       IDENTIFICATION DIVISION.
       PROGRAM-ID. PAYMENTPROC.
       AUTHOR. SEVEN-DEADLY-SYNCS.

       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT ACCOUNT-FILE
               ASSIGN TO "/app/data/accounts.dat"
               ORGANIZATION IS LINE SEQUENTIAL
               ACCESS MODE IS SEQUENTIAL
               FILE STATUS IS WS-ACC-STATUS.

           SELECT MERCHANT-FILE
               ASSIGN TO "/app/data/merchants.dat"
               ORGANIZATION IS LINE SEQUENTIAL
               ACCESS MODE IS SEQUENTIAL
               FILE STATUS IS WS-MER-STATUS.

           SELECT TRANSACTION-FILE
               ASSIGN TO "/app/data/transactions.dat"
               ORGANIZATION IS LINE SEQUENTIAL
               ACCESS MODE IS EXTEND
               FILE STATUS IS WS-TXN-STATUS.

       DATA DIVISION.
       FILE SECTION.

       FD  ACCOUNT-FILE.
       01  ACCOUNT-RECORD          PIC X(200).

       FD  MERCHANT-FILE.
       01  MERCHANT-RECORD         PIC X(300).

       FD  TRANSACTION-FILE.
       01  TRANSACTION-RECORD      PIC X(300).

       WORKING-STORAGE SECTION.

       01  WS-ACC-STATUS           PIC XX.
           88  ACC-OK              VALUE "00".
           88  ACC-EOF             VALUE "10".

       01  WS-MER-STATUS           PIC XX.
           88  MER-OK              VALUE "00".
           88  MER-EOF             VALUE "10".

       01  WS-TXN-STATUS           PIC XX.
           88  TXN-OK              VALUE "00".

       01  WS-INPUT-LINE           PIC X(300).

       01  WS-IN-TXN-ID            PIC X(36).
       01  WS-IN-USER-ID           PIC X(20).
       01  WS-IN-MERCHANT-ID       PIC X(20).
       01  WS-IN-AMOUNT-STR        PIC X(20).
       01  WS-IN-AMOUNT            PIC 9(13)V99.
       01  WS-IN-QR-CODE           PIC X(100).

       01  WS-ACC-FOUND            PIC X VALUE "N".
       01  WS-MER-FOUND            PIC X VALUE "N".
       01  WS-ACC-EOF              PIC X VALUE "N".
       01  WS-MER-EOF              PIC X VALUE "N".

       01  WS-ACC-PARSE.
           05  WS-AP-USER-ID       PIC X(20).
           05  FILLER              PIC X(1).
           05  WS-AP-ACC-ID        PIC X(20).
           05  FILLER              PIC X(1).
           05  WS-AP-NAME          PIC X(50).
           05  FILLER              PIC X(1).
           05  WS-AP-BALANCE-STR   PIC X(20).
           05  FILLER              PIC X(1).
           05  WS-AP-CURRENCY      PIC X(3).
           05  FILLER              PIC X(1).
           05  WS-AP-STATUS        PIC X(10).

       01  WS-MER-PARSE.
           05  WS-MP-MER-ID        PIC X(20).
           05  FILLER              PIC X(1).
           05  WS-MP-NAME          PIC X(100).
           05  FILLER              PIC X(1).
           05  WS-MP-CATEGORY      PIC X(50).
           05  FILLER              PIC X(1).
           05  WS-MP-STATUS        PIC X(10).
           05  FILLER              PIC X(1).
           05  WS-MP-BANK-CODE     PIC X(10).
           05  FILLER              PIC X(1).
           05  WS-MP-ACCOUNT       PIC X(20).

       01  WS-AP-BALANCE           PIC 9(13)V99.
       01  WS-TXN-WRITE            PIC X(300).
       01  WS-JSON-OUTPUT          PIC X(1000).
       01  WS-DATETIME             PIC X(20).

       PROCEDURE DIVISION.

       MAIN-LOGIC.
           ACCEPT WS-INPUT-LINE

           UNSTRING WS-INPUT-LINE
               DELIMITED BY "|"
               INTO WS-IN-TXN-ID
                    WS-IN-USER-ID
                    WS-IN-MERCHANT-ID
                    WS-IN-AMOUNT-STR
                    WS-IN-QR-CODE
           END-UNSTRING

           IF FUNCTION TRIM(WS-IN-AMOUNT-STR) = SPACES
               STRING
                   "{"
                   """status"":""error"","
                   """code"":1002,"
                   """data"":null,"
                   """message"":""Jumlah tidak valid"""
                   "}"
                   DELIMITED SIZE INTO WS-JSON-OUTPUT
               END-STRING
               DISPLAY WS-JSON-OUTPUT
               STOP RUN
           END-IF

           MOVE FUNCTION NUMVAL(WS-IN-AMOUNT-STR)
               TO WS-IN-AMOUNT

           IF WS-IN-AMOUNT <= 0
               STRING
                   "{"
                   """status"":""error"","
                   """code"":1002,"
                   """data"":null,"
                   """message"":""Jumlah transaksi tidak valid"""
                   "}"
                   DELIMITED SIZE INTO WS-JSON-OUTPUT
               END-STRING
               DISPLAY WS-JSON-OUTPUT
               STOP RUN
           END-IF

           PERFORM VALIDATE-ACCOUNT
           IF WS-ACC-FOUND = "N"
               STRING
                   "{"
                   """status"":""error"","
                   """code"":1004,"
                   """data"":null,"
                   """message"":""User tidak ditemukan"""
                   "}"
                   DELIMITED SIZE INTO WS-JSON-OUTPUT
               END-STRING
               DISPLAY WS-JSON-OUTPUT
               STOP RUN
           END-IF

           MOVE FUNCTION NUMVAL(WS-AP-BALANCE-STR)
               TO WS-AP-BALANCE

           IF WS-AP-BALANCE < WS-IN-AMOUNT
               STRING
                   "{"
                   """status"":""error"","
                   """code"":1003,"
                   """data"":null,"
                   """message"":""Saldo tidak mencukupi"""
                   "}"
                   DELIMITED SIZE INTO WS-JSON-OUTPUT
               END-STRING
               DISPLAY WS-JSON-OUTPUT
               STOP RUN
           END-IF

           PERFORM VALIDATE-MERCHANT
           IF WS-MER-FOUND = "N"
               STRING
                   "{"
                   """status"":""error"","
                   """code"":1005,"
                   """data"":null,"
                   """message"":""Merchant tidak ditemukan"""
                   "}"
                   DELIMITED SIZE INTO WS-JSON-OUTPUT
               END-STRING
               DISPLAY WS-JSON-OUTPUT
               STOP RUN
           END-IF

           PERFORM WRITE-TRANSACTION

           STRING
               "{"
               """status"":""success"","
               """code"":0,"
               """data"":{"
               """transaction_id"":"""
                   FUNCTION TRIM(WS-IN-TXN-ID) ""","
               """user_id"":"""
                   FUNCTION TRIM(WS-IN-USER-ID) ""","
               """merchant_id"":"""
                   FUNCTION TRIM(WS-IN-MERCHANT-ID) ""","
               """merchant_name"":"""
                   FUNCTION TRIM(WS-MP-NAME) ""","
               """amount"":"
                   FUNCTION TRIM(WS-IN-AMOUNT-STR) ","
               """status"":""success"","
               """source"":""legacy-cobol"""
               "},"
               """message"":""Pembayaran QRIS berhasil"""
               "}"
               DELIMITED SIZE INTO WS-JSON-OUTPUT
           END-STRING
           DISPLAY WS-JSON-OUTPUT
           STOP RUN.

       VALIDATE-ACCOUNT.
           OPEN INPUT ACCOUNT-FILE
           IF NOT ACC-OK
               MOVE "N" TO WS-ACC-FOUND
               EXIT PARAGRAPH
           END-IF

           MOVE "N" TO WS-ACC-FOUND
           MOVE "N" TO WS-ACC-EOF

           PERFORM UNTIL WS-ACC-FOUND = "Y" OR WS-ACC-EOF = "Y"
               READ ACCOUNT-FILE INTO WS-ACC-PARSE
               AT END
                   MOVE "Y" TO WS-ACC-EOF
               NOT AT END
                   IF FUNCTION TRIM(WS-AP-USER-ID) =
                      FUNCTION TRIM(WS-IN-USER-ID)
                       MOVE "Y" TO WS-ACC-FOUND
                   END-IF
               END-READ
           END-PERFORM

           CLOSE ACCOUNT-FILE.

       VALIDATE-MERCHANT.
           OPEN INPUT MERCHANT-FILE
           IF NOT MER-OK
               MOVE "N" TO WS-MER-FOUND
               EXIT PARAGRAPH
           END-IF

           MOVE "N" TO WS-MER-FOUND
           MOVE "N" TO WS-MER-EOF

           PERFORM UNTIL WS-MER-FOUND = "Y" OR WS-MER-EOF = "Y"
               READ MERCHANT-FILE INTO WS-MER-PARSE
               AT END
                   MOVE "Y" TO WS-MER-EOF
               NOT AT END
                   IF FUNCTION TRIM(WS-MP-MER-ID) =
                      FUNCTION TRIM(WS-IN-MERCHANT-ID)
                       MOVE "Y" TO WS-MER-FOUND
                   END-IF
               END-READ
           END-PERFORM

           CLOSE MERCHANT-FILE.

       WRITE-TRANSACTION.
           MOVE FUNCTION CURRENT-DATE TO WS-DATETIME

           STRING
               FUNCTION TRIM(WS-IN-TXN-ID) "|"
               FUNCTION TRIM(WS-IN-USER-ID) "|"
               FUNCTION TRIM(WS-IN-MERCHANT-ID) "|"
               FUNCTION TRIM(WS-IN-AMOUNT-STR) "|"
               "success|QRIS|"
               FUNCTION TRIM(WS-IN-QR-CODE) "|"
               FUNCTION TRIM(WS-DATETIME)
               DELIMITED SIZE
               INTO WS-TXN-WRITE
           END-STRING

           OPEN EXTEND TRANSACTION-FILE
           IF TXN-OK
               WRITE TRANSACTION-RECORD FROM WS-TXN-WRITE
               CLOSE TRANSACTION-FILE
           END-IF.
