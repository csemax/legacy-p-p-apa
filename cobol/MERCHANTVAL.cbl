      *================================================================*
      * MERCHANTVAL.CBL - Merchant Validation & Info                  *
      * Legacy System DANTE - CIMB Niaga Simulation                   *
      * Seven Deadly Syncs - Capstone UB 2026                         *
      *================================================================*
       IDENTIFICATION DIVISION.
       PROGRAM-ID. MERCHANTVAL.

       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT MERCHANT-FILE
               ASSIGN TO '/app/data/merchants.dat'
               ORGANIZATION IS LINE SEQUENTIAL
               ACCESS MODE IS SEQUENTIAL
               FILE STATUS IS WS-FILE-STATUS.

       DATA DIVISION.
       FILE SECTION.
       FD  MERCHANT-FILE.
       01  MERCHANT-FILE-RECORD    PIC X(300).

       WORKING-STORAGE SECTION.

       COPY BANKDATA.
       COPY ERRORCODES.

       01  WS-FILE-STATUS          PIC XX.
           88  FS-OK               VALUE '00'.
           88  FS-EOF              VALUE '10'.

       01  WS-INPUT-MERCHANT-ID    PIC X(20).

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

       01  WS-FOUND-FLAG           PIC X VALUE 'N'.
       01  WS-JSON-OUTPUT          PIC X(1000).

       PROCEDURE DIVISION.

       MAIN-LOGIC.
      *--- Delay 200-500ms ---
           CALL "CBL_GC_NANOSLEEP" USING
               BY VALUE 300000000
           END-CALL

           ACCEPT WS-INPUT-MERCHANT-ID

           OPEN INPUT MERCHANT-FILE
           IF NOT FS-OK
               PERFORM RETURN-DB-ERROR
               STOP RUN
           END-IF

           MOVE 'N' TO WS-FOUND-FLAG

           PERFORM SEARCH-MERCHANT
               UNTIL WS-FOUND-FLAG = 'Y' OR FS-EOF

           CLOSE MERCHANT-FILE

           IF WS-FOUND-FLAG = 'Y'
               PERFORM RETURN-SUCCESS
           ELSE
               PERFORM RETURN-NOT-FOUND
           END-IF

           STOP RUN.

      *----------------------------------------------------------------*
       SEARCH-MERCHANT.
           READ MERCHANT-FILE INTO WS-MER-PARSE
           AT END
               MOVE 'Y' TO WS-EOF-FLAG
           NOT AT END
               IF FUNCTION TRIM(WS-MP-MER-ID) =
                  FUNCTION TRIM(WS-INPUT-MERCHANT-ID)
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
               '"merchant_id":"'
                   FUNCTION TRIM(WS-MP-MER-ID) '",'
               '"merchant_name":"'
                   FUNCTION TRIM(WS-MP-NAME) '",'
               '"category":"'
                   FUNCTION TRIM(WS-MP-CATEGORY) '",'
               '"status":"'
                   FUNCTION TRIM(WS-MP-STATUS) '",'
               '"bank_code":"'
                   FUNCTION TRIM(WS-MP-BANK-CODE) '",'
               '"source":"legacy-cobol"'
               '},'
               '"message":"Merchant ditemukan"'
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
               '"code":1005,'
               '"data":null,'
               '"message":"Merchant tidak ditemukan"'
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
               '"message":"Database error"'
               '}'
               DELIMITED SIZE
               INTO WS-JSON-OUTPUT
           END-STRING
           DISPLAY WS-JSON-OUTPUT.
