      *================================================================*
      * TXNSTATUS.CBL - Transaction Status Inquiry                    *
      * Legacy System DANTE - CIMB Niaga Simulation                   *
      * Seven Deadly Syncs - Capstone UB 2026                         *
      *================================================================*
       IDENTIFICATION DIVISION.
       PROGRAM-ID. TXNSTATUS.
       AUTHOR. SEVEN-DEADLY-SYNCS.

       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT TRANSACTION-FILE
               ASSIGN TO '/app/data/transactions.dat'
               ORGANIZATION IS LINE SEQUENTIAL
               ACCESS MODE IS SEQUENTIAL
               FILE STATUS IS WS-FILE-STATUS.

       DATA DIVISION.
       FILE SECTION.
       FD  TRANSACTION-FILE.
       01  TXN-FILE-RECORD         PIC X(300).

       WORKING-STORAGE SECTION.

       COPY BANKDATA.
       COPY ERRORCODES.

       01  WS-FILE-STATUS          PIC XX.
           88  FS-OK               VALUE '00'.
           88  FS-EOF              VALUE '10'.

       01  WS-INPUT-TXN-ID         PIC X(36).

       01  WS-TXN-PARSE.
           05  WS-TP-TXN-ID        PIC X(36).
           05  FILLER              PIC X(1).
           05  WS-TP-USER-ID       PIC X(20).
           05  FILLER              PIC X(1).
           05  WS-TP-MERCHANT-ID   PIC X(20).
           05  FILLER              PIC X(1).
           05  WS-TP-AMOUNT        PIC X(20).
           05  FILLER              PIC X(1).
           05  WS-TP-STATUS        PIC X(10).
           05  FILLER              PIC X(1).
           05  WS-TP-TYPE          PIC X(10).
           05  FILLER              PIC X(1).
           05  WS-TP-QR-CODE       PIC X(100).
           05  FILLER              PIC X(1).
           05  WS-TP-CREATED-AT    PIC X(20).

       01  WS-FOUND-FLAG           PIC X VALUE 'N'.
       01  WS-JSON-OUTPUT          PIC X(1000).
       01  WS-RANDOM-NUM           PIC 9(4).

       PROCEDURE DIVISION.

       MAIN-LOGIC.
      *--- Delay 300-600ms ---
           CALL "CBL_GC_NANOSLEEP" USING
               BY VALUE 400000000
           END-CALL

           ACCEPT WS-INPUT-TXN-ID

      *--- Simulasi random error 5% ---
           MOVE FUNCTION RANDOM TO WS-RANDOM-NUM
           IF WS-RANDOM-NUM < 500
               PERFORM RETURN-SYSTEM-ERROR
               STOP RUN
           END-IF

           OPEN INPUT TRANSACTION-FILE
           IF NOT FS-OK
               PERFORM RETURN-DB-ERROR
               STOP RUN
           END-IF

           MOVE 'N' TO WS-FOUND-FLAG

           PERFORM SEARCH-TRANSACTION
               UNTIL WS-FOUND-FLAG = 'Y' OR FS-EOF

           CLOSE TRANSACTION-FILE

           IF WS-FOUND-FLAG = 'Y'
               PERFORM RETURN-SUCCESS
           ELSE
               PERFORM RETURN-NOT-FOUND
           END-IF

           STOP RUN.

      *----------------------------------------------------------------*
       SEARCH-TRANSACTION.
           READ TRANSACTION-FILE INTO WS-TXN-PARSE
           AT END
               MOVE 'Y' TO WS-EOF-FLAG
           NOT AT END
               IF FUNCTION TRIM(WS-TP-TXN-ID) =
                  FUNCTION TRIM(WS-INPUT-TXN-ID)
                   MOVE 'Y' TO WS-FOUND-FLAG
               END-IF
           END-READ.

      *----------------------------------------------------------------*
       RETURN-SUCCESS.
           STRING
               '{'
               '"status":"success",'
               '"code":0,'
               '"data":{'
               '"transaction_id":"'
                   FUNCTION TRIM(WS-TP-TXN-ID) '",'
               '"user_id":"'
                   FUNCTION TRIM(WS-TP-USER-ID) '",'
               '"merchant_id":"'
                   FUNCTION TRIM(WS-TP-MERCHANT-ID) '",'
               '"amount":'
                   FUNCTION TRIM(WS-TP-AMOUNT) ','
               '"status":"'
                   FUNCTION TRIM(WS-TP-STATUS) '",'
               '"type":"'
                   FUNCTION TRIM(WS-TP-TYPE) '",'
               '"created_at":"'
                   FUNCTION TRIM(WS-TP-CREATED-AT) '",'
               '"source":"legacy-cobol"'
               '},'
               '"message":"Status transaksi ditemukan"'
               '}'
               DELIMITED SIZE
               INTO WS-JSON-OUTPUT
           END-STRING
           DISPLAY WS-JSON-OUTPUT.

      *----------------------------------------------------------------*
       RETURN-NOT-FOUND.
           STRING
               '{'
               '"status":"error",'
               '"code":1001,'
               '"data":null,'
               '"message":"Transaksi tidak ditemukan di sistem legacy"'
               '}'
               DELIMITED SIZE
               INTO WS-JSON-OUTPUT
           END-STRING
           DISPLAY WS-JSON-OUTPUT.

      *----------------------------------------------------------------*
       RETURN-DB-ERROR.
           STRING
               '{'
               '"status":"error",'
               '"code":5001,'
               '"data":null,'
               '"message":"Database legacy error"'
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
               '"message":"Sistem legacy error"'
               '}'
               DELIMITED SIZE
               INTO WS-JSON-OUTPUT
           END-STRING
           DISPLAY WS-JSON-OUTPUT.
