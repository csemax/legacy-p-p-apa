      *================================================================*
      * BALANCEINQ.CBL - Balance Inquiry Program                      *
      * Legacy System DANTE - CIMB Niaga Simulation                   *
      * Artificial Delay: 300-800ms (simulasi legacy lambat)          *
      * Seven Deadly Syncs - Capstone UB 2026                         *
      *================================================================*
       IDENTIFICATION DIVISION.
       PROGRAM-ID. BALANCEINQ.
       AUTHOR. SEVEN-DEADLY-SYNCS.
       DATE-WRITTEN. 2026-01-01.

       ENVIRONMENT DIVISION.
       CONFIGURATION SECTION.
       SOURCE-COMPUTER. LINUX.
       OBJECT-COMPUTER. LINUX.

       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
      *--- File data rekening nasabah ---
           SELECT ACCOUNT-FILE
               ASSIGN TO DYNAMIC WS-ACCOUNT-FILE-PATH
               ORGANIZATION IS LINE SEQUENTIAL
               ACCESS MODE IS SEQUENTIAL
               FILE STATUS IS WS-FILE-STATUS.

      *================================================================*
       DATA DIVISION.
       FILE SECTION.

       FD  ACCOUNT-FILE
           LABEL RECORDS ARE STANDARD.
       01  ACCOUNT-FILE-RECORD     PIC X(200).

      *================================================================*
       WORKING-STORAGE SECTION.

      *--- Include copybooks ---
       COPY BANKDATA.
       COPY ERRORCODES.

      *--- File path ---
       01  WS-ACCOUNT-FILE-PATH    PIC X(100)
           VALUE '/app/data/accounts.dat'.

      *--- File status ---
       01  WS-FILE-STATUS          PIC XX.
           88  FS-OK               VALUE '00'.
           88  FS-EOF              VALUE '10'.
           88  FS-NOT-FOUND        VALUE '23'.

      *--- Input dari command line / stdin ---
       01  WS-INPUT-USER-ID        PIC X(20).

      *--- Output JSON buffer ---
       01  WS-JSON-OUTPUT          PIC X(1000).
       01  WS-JSON-BALANCE         PIC ZZZ,ZZZ,ZZZ,ZZZ.99.
       01  WS-BALANCE-FORMATTED    PIC X(20).

      *--- Random delay simulation ---
       01  WS-RANDOM-NUM           PIC 9(4).
       01  WS-DELAY-MS             PIC 9(6).

      *--- Parsed account fields ---
       01  WS-PARSE-RECORD.
           05  WS-P-USER-ID        PIC X(20).
           05  FILLER              PIC X(1).
           05  WS-P-ACC-ID         PIC X(20).
           05  FILLER              PIC X(1).
           05  WS-P-NAME           PIC X(50).
           05  FILLER              PIC X(1).
           05  WS-P-BALANCE-STR    PIC X(20).
           05  FILLER              PIC X(1).
           05  WS-P-CURRENCY       PIC X(3).
           05  FILLER              PIC X(1).
           05  WS-P-STATUS         PIC X(10).

       01  WS-P-BALANCE-NUM        PIC 9(13)V99.

      *================================================================*
       PROCEDURE DIVISION.

       MAIN-LOGIC.
      *--- Simulasi artificial delay 300-800ms (legacy lambat) ---
           CALL "CBL_GC_NANOSLEEP" USING
               BY VALUE 500000000
           END-CALL

      *--- Ambil User ID dari stdin ---
           ACCEPT WS-INPUT-USER-ID FROM COMMAND-LINE

           IF WS-INPUT-USER-ID = SPACES
               ACCEPT WS-INPUT-USER-ID
           END-IF

           MOVE FUNCTION TRIM(WS-INPUT-USER-ID)
               TO WS-INPUT-USER-ID

      *--- Simulasi random error 5% (seperti di dokumen) ---
           MOVE FUNCTION RANDOM TO WS-RANDOM-NUM
           IF WS-RANDOM-NUM < 500
               PERFORM RETURN-SYSTEM-ERROR
               STOP RUN
           END-IF

      *--- Buka file accounts ---
           OPEN INPUT ACCOUNT-FILE
           IF NOT FS-OK
               PERFORM RETURN-DB-ERROR
               STOP RUN
           END-IF

      *--- Cari user di file ---
           MOVE 'N' TO WS-FOUND-FLAG
           MOVE 'N' TO WS-EOF-FLAG

           PERFORM SEARCH-ACCOUNT
               UNTIL WS-FOUND-FLAG = 'Y'
               OR WS-EOF-FLAG = 'Y'

           CLOSE ACCOUNT-FILE

      *--- Return hasil ---
           IF WS-FOUND-FLAG = 'Y'
               PERFORM RETURN-SUCCESS
           ELSE
               PERFORM RETURN-NOT-FOUND
           END-IF

           STOP RUN.

      *----------------------------------------------------------------*
       SEARCH-ACCOUNT.
           READ ACCOUNT-FILE INTO WS-PARSE-RECORD
           AT END
               MOVE 'Y' TO WS-EOF-FLAG
           NOT AT END
               IF FUNCTION TRIM(WS-P-USER-ID) =
                  FUNCTION TRIM(WS-INPUT-USER-ID)
                   MOVE 'Y' TO WS-FOUND-FLAG
               END-IF
           END-READ.

      *----------------------------------------------------------------*
       RETURN-SUCCESS.
      *--- Konversi balance string ke numeric ---
           MOVE FUNCTION NUMVAL(WS-P-BALANCE-STR)
               TO WS-P-BALANCE-NUM

      *--- Format balance ---
           MOVE WS-P-BALANCE-NUM TO WS-JSON-BALANCE
           MOVE FUNCTION TRIM(WS-JSON-BALANCE)
               TO WS-BALANCE-FORMATTED

      *--- Build JSON response ---
           STRING
               '{'
               '"status":"success",'
               '"code":0,'
               '"data":{'
               '"user_id":"'
                   FUNCTION TRIM(WS-P-USER-ID) '",'
               '"account_id":"'
                   FUNCTION TRIM(WS-P-ACC-ID) '",'
               '"account_name":"'
                   FUNCTION TRIM(WS-P-NAME) '",'
               '"balance":'
                   FUNCTION TRIM(WS-BALANCE-FORMATTED) ','
               '"currency":"'
                   FUNCTION TRIM(WS-P-CURRENCY) '",'
               '"account_status":"'
                   FUNCTION TRIM(WS-P-STATUS) '",'
               '"source":"legacy-cobol"'
               '},'
               '"message":"Balance inquiry berhasil"'
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
               '"message":"User tidak ditemukan di sistem legacy"'
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
               '"message":"System legacy sedang sibuk, coba lagi"'
               '}'
               DELIMITED SIZE
               INTO WS-JSON-OUTPUT
           END-STRING
           DISPLAY WS-JSON-OUTPUT.
