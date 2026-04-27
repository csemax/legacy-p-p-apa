      *================================================================*
      * PAYMENTPROC.CBL - Payment Processing Program                  *
      * Legacy System DANTE - CIMB Niaga Simulation                   *
      * Artificial Delay: 500-2000ms (transaksi lebih berat)          *
      * Seven Deadly Syncs - Capstone UB 2026                         *
      *================================================================*
       IDENTIFICATION DIVISION.
       PROGRAM-ID. PAYMENTPROC.
       AUTHOR. SEVEN-DEADLY-SYNCS.
       DATE-WRITTEN. 2026-01-01.

       ENVIRONMENT DIVISION.
       CONFIGURATION SECTION.
       SOURCE-COMPUTER. LINUX.
       OBJECT-COMPUTER. LINUX.

       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT ACCOUNT-FILE
               ASSIGN TO '/app/data/accounts.dat'
               ORGANIZATION IS LINE SEQUENTIAL
               ACCESS MODE IS SEQUENTIAL
               FILE STATUS IS WS-ACC-FILE-STATUS.

           SELECT MERCHANT-FILE
               ASSIGN TO '/app/data/merchants.dat'
               ORGANIZATION IS LINE SEQUENTIAL
               ACCESS MODE IS SEQUENTIAL
               FILE STATUS IS WS-MER-FILE-STATUS.

           SELECT TRANSACTION-FILE
               ASSIGN TO '/app/data/transactions.dat'
               ORGANIZATION IS LINE SEQUENTIAL
               ACCESS MODE IS EXTEND
               FILE STATUS IS WS-TXN-FILE-STATUS.

      *================================================================*
       DATA DIVISION.
       FILE SECTION.

       FD  ACCOUNT-FILE
           LABEL RECORDS ARE STANDARD.
       01  ACCOUNT-FILE-RECORD     PIC X(200).

       FD  MERCHANT-FILE
           LABEL RECORDS ARE STANDARD.
       01  MERCHANT-FILE-RECORD    PIC X(300).

       FD  TRANSACTION-FILE
           LABEL RECORDS ARE STANDARD.
       01  TRANSACTION-FILE-RECORD PIC X(300).

      *================================================================*
       WORKING-STORAGE SECTION.

       COPY BANKDATA.
       COPY ERRORCODES.

      *--- File Status ---
       01  WS-ACC-FILE-STATUS      PIC XX.
           88  ACC-FS-OK           VALUE '00'.
           88  ACC-FS-EOF          VALUE '10'.

       01  WS-MER-FILE-STATUS      PIC XX.
           88  MER-FS-OK           VALUE '00'.
           88  MER-FS-EOF          VALUE '10'.

       01  WS-TXN-FILE-STATUS      PIC XX.
           88  TXN-FS-OK           VALUE '00'.

      *--- Input dari stdin (format: TXN_ID|USER_ID|MERCHANT_ID|AMOUNT|QR) ---
       01  WS-INPUT-LINE           PIC X(300).

      *--- Parsed input fields ---
       01  WS-IN-TXN-ID            PIC X(36).
       01  WS-IN-USER-ID           PIC X(20).
       01  WS-IN-MERCHANT-ID       PIC X(20).
       01  WS-IN-AMOUNT-STR        PIC X(20).
       01  WS-IN-AMOUNT            PIC 9(13)V99.
       01  WS-IN-QR-CODE           PIC X(100).

      *--- Account data found ---
       01  WS-ACC-FOUND            PIC X(1) VALUE 'N'.
       01  WS-MER-FOUND            PIC X(1) VALUE 'N'.

      *--- Account record fields ---
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

       01  WS-AP-BALANCE           PIC 9(13)V99.
       01  WS-NEW-BALANCE          PIC 9(13)V99.

      *--- Merchant record fields ---
       01  WS-MER-PARSE.
           05  WS-MP-MER-ID        PIC X(20).
           05  FILLER              PIC X(1).
           05  WS-MP-NAME          PIC X(100).
           05  FILLER              PIC X(1).
           05  WS-MP-STATUS        PIC X(10).
           05  FILLER              PIC X(1).
           05  WS-MP-BANK-CODE     PIC X(10).

      *--- Transaction record to write ---
       01  WS-TXN-WRITE-RECORD     PIC X(300).

      *--- Output JSON ---
       01  WS-JSON-OUTPUT          PIC X(1000).

      *--- Date/time ---
       01  WS-DATETIME             PIC X(20).
       01  WS-DATE-PART            PIC X(8).
       01  WS-TIME-PART            PIC X(6).

      *--- Random untuk simulasi error ---
       01  WS-RANDOM-NUM           PIC 9(5).

      *================================================================*
       PROCEDURE DIVISION.

       MAIN-LOGIC.
      *--- Simulasi delay berat 500-1500ms untuk payment ---
           CALL "CBL_GC_NANOSLEEP" USING
               BY VALUE 1000000000
           END-CALL

      *--- Ambil input dari stdin ---
           ACCEPT WS-INPUT-LINE

      *--- Parse input (format pipe-delimited) ---
           UNSTRING WS-INPUT-LINE
               DELIMITED BY '|'
               INTO WS-IN-TXN-ID
                    WS-IN-USER-ID
                    WS-IN-MERCHANT-ID
                    WS-IN-AMOUNT-STR
                    WS-IN-QR-CODE
           END-UNSTRING

           MOVE FUNCTION NUMVAL(WS-IN-AMOUNT-STR)
               TO WS-IN-AMOUNT

      *--- Simulasi random error 8% (timeout 5% + error 3%) ---
           MOVE FUNCTION RANDOM TO WS-RANDOM-NUM
           IF WS-RANDOM-NUM < 800
               IF WS-RANDOM-NUM < 500
                   PERFORM RETURN-TIMEOUT
               ELSE
                   PERFORM RETURN-SYSTEM-ERROR
               END-IF
               STOP RUN
           END-IF

      *--- Validasi amount ---
           IF WS-IN-AMOUNT <= 0
               PERFORM RETURN-INVALID-AMOUNT
               STOP RUN
           END-IF

      *--- Validasi QR Code ---
           IF FUNCTION TRIM(WS-IN-QR-CODE) = SPACES
               PERFORM RETURN-INVALID-QR
               STOP RUN
           END-IF

      *--- Step 1: Cari dan validasi account user ---
           PERFORM VALIDATE-USER-ACCOUNT

           IF WS-ACC-FOUND = 'N'
               PERFORM RETURN-INVALID-USER
               STOP RUN
           END-IF

           IF FUNCTION TRIM(WS-AP-STATUS) NOT = 'active'
               PERFORM RETURN-ACCOUNT-INACTIVE
               STOP RUN
           END-IF

      *--- Step 2: Cek saldo mencukupi ---
           MOVE FUNCTION NUMVAL(WS-AP-BALANCE-STR)
               TO WS-AP-BALANCE

           IF WS-AP-BALANCE < WS-IN-AMOUNT
               PERFORM RETURN-INSUFFICIENT-FUNDS
               STOP RUN
           END-IF

      *--- Step 3: Validasi merchant ---
           PERFORM VALIDATE-MERCHANT

           IF WS-MER-FOUND = 'N'
               PERFORM RETURN-INVALID-MERCHANT
               STOP RUN
           END-IF

           IF FUNCTION TRIM(WS-MP-STATUS) NOT = 'active'
               PERFORM RETURN-MERCHANT-INACTIVE
               STOP RUN
           END-IF

      *--- Step 4: Proses debit saldo ---
           COMPUTE WS-NEW-BALANCE =
               WS-AP-BALANCE - WS-IN-AMOUNT

      *--- Step 5: Catat transaksi ke file ---
           PERFORM WRITE-TRANSACTION

      *--- Step 6: Return sukses ---
           PERFORM RETURN-SUCCESS

           STOP RUN.

      *----------------------------------------------------------------*
       VALIDATE-USER-ACCOUNT.
           OPEN INPUT ACCOUNT-FILE
           IF NOT ACC-FS-OK
               MOVE 'N' TO WS-ACC-FOUND
               STOP RUN
           END-IF

           MOVE 'N' TO WS-ACC-FOUND

           PERFORM UNTIL ACC-FS-EOF OR WS-ACC-FOUND = 'Y'
               READ ACCOUNT-FILE INTO WS-ACC-PARSE
               AT END
                   CONTINUE
               NOT AT END
                   IF FUNCTION TRIM(WS-AP-USER-ID) =
                      FUNCTION TRIM(WS-IN-USER-ID)
                       MOVE 'Y' TO WS-ACC-FOUND
                   END-IF
               END-READ
           END-PERFORM

           CLOSE ACCOUNT-FILE.

      *----------------------------------------------------------------*
       VALIDATE-MERCHANT.
           OPEN INPUT MERCHANT-FILE
           IF NOT MER-FS-OK
               MOVE 'N' TO WS-MER-FOUND
               STOP RUN
           END-IF

           MOVE 'N' TO WS-MER-FOUND

           PERFORM UNTIL MER-FS-EOF OR WS-MER-FOUND = 'Y'
               READ MERCHANT-FILE INTO WS-MER-PARSE
               AT END
                   CONTINUE
               NOT AT END
                   IF FUNCTION TRIM(WS-MP-MER-ID) =
                      FUNCTION TRIM(WS-IN-MERCHANT-ID)
                       MOVE 'Y' TO WS-MER-FOUND
                   END-IF
               END-READ
           END-PERFORM

           CLOSE MERCHANT-FILE.

      *----------------------------------------------------------------*
       WRITE-TRANSACTION.
           MOVE FUNCTION CURRENT-DATE TO WS-DATETIME

           OPEN EXTEND TRANSACTION-FILE
           IF TXN-FS-OK
               STRING
                   FUNCTION TRIM(WS-IN-TXN-ID) '|'
                   FUNCTION TRIM(WS-IN-USER-ID) '|'
                   FUNCTION TRIM(WS-IN-MERCHANT-ID) '|'
                   FUNCTION TRIM(WS-IN-AMOUNT-STR) '|'
                   'success|'
                   'QRIS|'
                   FUNCTION TRIM(WS-IN-QR-CODE) '|'
                   FUNCTION TRIM(WS-DATETIME)
                   DELIMITED SIZE
                   INTO WS-TXN-WRITE-RECORD
               END-STRING

               WRITE TRANSACTION-FILE-RECORD
                   FROM WS-TXN-WRITE-RECORD
               CLOSE TRANSACTION-FILE
           END-IF.

      *----------------------------------------------------------------*
       RETURN-SUCCESS.
           STRING
               '{'
               '"status":"success",'
               '"code":0,'
               '"data":{'
               '"transaction_id":"'
                   FUNCTION TRIM(WS-IN-TXN-ID) '",'
               '"user_id":"'
                   FUNCTION TRIM(WS-IN-USER-ID) '",'
               '"merchant_id":"'
                   FUNCTION TRIM(WS-IN-MERCHANT-ID) '",'
               '"merchant_name":"'
                   FUNCTION TRIM(WS-MP-NAME) '",'
               '"amount":'
                   FUNCTION TRIM(WS-IN-AMOUNT-STR) ','
               '"status":"success",'
               '"source":"legacy-cobol"'
               '},'
               '"message":"Pembayaran QRIS berhasil diproses"'
               '}'
               DELIMITED SIZE
               INTO WS-JSON-OUTPUT
           END-STRING
           DISPLAY WS-JSON-OUTPUT.

      *----------------------------------------------------------------*
       RETURN-INSUFFICIENT-FUNDS.
           STRING
               '{'
               '"status":"error",'
               '"code":1003,'
               '"data":null,'
               '"message":"Saldo tidak mencukupi untuk transaksi ini"'
               '}'
               DELIMITED SIZE
               INTO WS-JSON-OUTPUT
           END-STRING
           DISPLAY WS-JSON-OUTPUT.

      *----------------------------------------------------------------*
       RETURN-INVALID-USER.
           STRING
               '{'
               '"status":"error",'
               '"code":1004,'
               '"data":null,'
               '"message":"User tidak ditemukan di sistem legacy"'
               '}'
               DELIMITED SIZE
               INTO WS-JSON-OUTPUT
           END-STRING
           DISPLAY WS-JSON-OUTPUT.

      *----------------------------------------------------------------*
       RETURN-INVALID-MERCHANT.
           STRING
               '{'
               '"status":"error",'
               '"code":1005,'
               '"data":null,'
               '"message":"Merchant tidak ditemukan atau tidak aktif"'
               '}'
               DELIMITED SIZE
               INTO WS-JSON-OUTPUT
           END-STRING
           DISPLAY WS-JSON-OUTPUT.

      *----------------------------------------------------------------*
       RETURN-ACCOUNT-INACTIVE.
           STRING
               '{'
               '"status":"error",'
               '"code":1007,'
               '"data":null,'
               '"message":"Rekening tidak aktif"'
               '}'
               DELIMITED SIZE
               INTO WS-JSON-OUTPUT
           END-STRING
           DISPLAY WS-JSON-OUTPUT.

      *----------------------------------------------------------------*
       RETURN-MERCHANT-INACTIVE.
           STRING
               '{'
               '"status":"error",'
               '"code":1008,'
               '"data":null,'
               '"message":"Merchant sedang tidak aktif"'
               '}'
               DELIMITED SIZE
               INTO WS-JSON-OUTPUT
           END-STRING
           DISPLAY WS-JSON-OUTPUT.

      *----------------------------------------------------------------*
       RETURN-INVALID-AMOUNT.
           STRING
               '{'
               '"status":"error",'
               '"code":1002,'
               '"data":null,'
               '"message":"Jumlah transaksi tidak valid"'
               '}'
               DELIMITED SIZE
               INTO WS-JSON-OUTPUT
           END-STRING
           DISPLAY WS-JSON-OUTPUT.

      *----------------------------------------------------------------*
       RETURN-INVALID-QR.
           STRING
               '{'
               '"status":"error",'
               '"code":1006,'
               '"data":null,'
               '"message":"QR Code tidak valid"'
               '}'
               DELIMITED SIZE
               INTO WS-JSON-OUTPUT
           END-STRING
           DISPLAY WS-JSON-OUTPUT.

      *----------------------------------------------------------------*
       RETURN-TIMEOUT.
           CALL "CBL_GC_NANOSLEEP" USING
               BY VALUE 2000000000
           END-CALL
           STRING
               '{'
               '"status":"error",'
               '"code":5002,'
               '"data":null,'
               '"message":"Request timeout - sistem legacy sibuk"'
               '}'
               DELIMITED SIZE
               INTO WS-JSON-OUTPUT
           END-STRING
           DISPLAY WS-JSON-OUTPUT.

      *----------------------------------------------------------------*
       RETURN-SYSTEM-ERROR.
           STRING
               '{'
               '"status":"error",'
               '"code":5003,'
               '"data":null,'
               '"message":"Internal error pada sistem legacy"'
               '}'
               DELIMITED SIZE
               INTO WS-JSON-OUTPUT
           END-STRING
           DISPLAY WS-JSON-OUTPUT.
