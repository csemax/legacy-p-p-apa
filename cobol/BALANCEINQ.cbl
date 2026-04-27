IDENTIFICATION DIVISION.
       PROGRAM-ID. BALANCEINQ.
       AUTHOR. SEVEN-DEADLY-SYNCS.

       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT ACCOUNT-FILE
               ASSIGN TO "/app/data/accounts.dat"
               ORGANIZATION IS LINE SEQUENTIAL
               ACCESS MODE IS SEQUENTIAL
               FILE STATUS IS WS-FILE-STATUS.

       DATA DIVISION.
       FILE SECTION.
       FD  ACCOUNT-FILE.
       01  ACCOUNT-FILE-RECORD      PIC X(200).

       WORKING-STORAGE SECTION.
       01  WS-FILE-STATUS           PIC XX.
           88  FS-OK                VALUE "00".
           88  FS-EOF               VALUE "10".

       01  WS-INPUT-USER-ID         PIC X(20).
       01  WS-FOUND-FLAG            PIC X VALUE "N".
       01  WS-EOF-FLAG              PIC X VALUE "N".
       01  WS-JSON-OUTPUT           PIC X(1000).
       
       01  WS-ACC-RAW-RECORD        PIC X(200).
       01  WS-ACC-PARSE.
           05  WS-AP-USER-ID        PIC X(20).
           05  WS-AP-ACC-ID         PIC X(20).
           05  WS-AP-NAME           PIC X(50).
           05  WS-AP-BALANCE-STR    PIC X(20).
           05  WS-AP-CURRENCY       PIC X(3).
           05  WS-AP-STATUS         PIC X(10).
           05  WS-AP-DATE           PIC X(10).

       PROCEDURE DIVISION.
       MAIN-LOGIC.
           *> Terima input dari Python (stdin)
           ACCEPT WS-INPUT-USER-ID
           MOVE FUNCTION TRIM(WS-INPUT-USER-ID) TO WS-INPUT-USER-ID

           OPEN INPUT ACCOUNT-FILE
           IF NOT FS-OK
               STRING "{"
                   """status"":""error"","
                   """code"":5001,"
                   """data"":null,"
                   """message"":""Database accounts error"""
                   "}" DELIMITED SIZE INTO WS-JSON-OUTPUT
               DISPLAY WS-JSON-OUTPUT
               STOP RUN
           END-IF

           PERFORM UNTIL WS-FOUND-FLAG = "Y" OR WS-EOF-FLAG = "Y"
               READ ACCOUNT-FILE INTO WS-ACC-RAW-RECORD
                   AT END MOVE "Y" TO WS-EOF-FLAG
                   NOT AT END
                       UNSTRING WS-ACC-RAW-RECORD DELIMITED BY "|"
                           INTO WS-AP-USER-ID
                                WS-AP-ACC-ID
                                WS-AP-NAME
                                WS-AP-BALANCE-STR
                                WS-AP-CURRENCY
                                WS-AP-STATUS
                                WS-AP-DATE
                       END-UNSTRING
                       
                       IF FUNCTION TRIM(WS-AP-USER-ID) = FUNCTION TRIM(WS-INPUT-USER-ID)
                           MOVE "Y" TO WS-FOUND-FLAG
                       END-IF
               END-READ
           END-PERFORM

           CLOSE ACCOUNT-FILE

           IF WS-FOUND-FLAG = "Y"
               STRING "{"
                   """status"":""success"","
                   """code"":0,"
                   """data"":{"
                   """user_id"":""" FUNCTION TRIM(WS-AP-USER-ID) ""","
                   """account_id"":""" FUNCTION TRIM(WS-AP-ACC-ID) ""","
                   """account_name"":""" FUNCTION TRIM(WS-AP-NAME) ""","
                   """balance"":" FUNCTION TRIM(WS-AP-BALANCE-STR) ","
                   """currency"":""" FUNCTION TRIM(WS-AP-CURRENCY) ""","
                   """account_status"":""" FUNCTION TRIM(WS-AP-STATUS) ""","
                   """source"":""legacy-cobol"""
                   "},"
                   """message"":""Balance inquiry berhasil"""
                   "}" DELIMITED SIZE INTO WS-JSON-OUTPUT
           ELSE
               STRING "{"
                   """status"":""error"","
                   """code"":1001,"
                   """data"":null,"
                   """message"":""User tidak ditemukan"""
                   "}" DELIMITED SIZE INTO WS-JSON-OUTPUT
           END-IF

           DISPLAY WS-JSON-OUTPUT
           STOP RUN.
