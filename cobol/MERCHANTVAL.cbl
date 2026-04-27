IDENTIFICATION DIVISION.
       PROGRAM-ID. MERCHANTVAL.

       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT MERCHANT-FILE
               ASSIGN TO "/app/data/merchants.dat"
               ORGANIZATION IS LINE SEQUENTIAL
               ACCESS MODE IS SEQUENTIAL
               FILE STATUS IS WS-FILE-STATUS.

       DATA DIVISION.
       FILE SECTION.
       FD  MERCHANT-FILE.
       01  MERCHANT-FILE-RECORD     PIC X(200).

       WORKING-STORAGE SECTION.
       01  WS-FILE-STATUS           PIC XX.
           88  FS-OK                VALUE "00".
       01  WS-INPUT-MERCHANT-ID     PIC X(20).
       01  WS-FOUND-FLAG            PIC X VALUE "N".
       01  WS-EOF-FLAG              PIC X VALUE "N".
       01  WS-JSON-OUTPUT           PIC X(1000).
       
       01  WS-M-RAW-RECORD          PIC X(200).
       01  WS-M-PARSE.
           05  WS-M-ID              PIC X(20).
           05  WS-M-NAME            PIC X(50).
           05  WS-M-STATUS          PIC X(15).

       PROCEDURE DIVISION.
       MAIN-LOGIC.
           ACCEPT WS-INPUT-MERCHANT-ID
           MOVE FUNCTION TRIM(WS-INPUT-MERCHANT-ID) TO WS-INPUT-MERCHANT-ID

           OPEN INPUT MERCHANT-FILE
           IF NOT FS-OK
               STRING "{" """status"":""error""," """code"":5001,"
               """data"":null," """message"":""Database merchants error""}" 
               DELIMITED SIZE INTO WS-JSON-OUTPUT
               DISPLAY WS-JSON-OUTPUT
               STOP RUN
           END-IF

           PERFORM UNTIL WS-FOUND-FLAG = "Y" OR WS-EOF-FLAG = "Y"
               READ MERCHANT-FILE INTO WS-M-RAW-RECORD
                   AT END MOVE "Y" TO WS-EOF-FLAG
                   NOT AT END
                       UNSTRING WS-M-RAW-RECORD DELIMITED BY "|"
                           INTO WS-M-ID WS-M-NAME WS-M-STATUS
                       END-UNSTRING
                       
                       IF FUNCTION TRIM(WS-M-ID) = FUNCTION TRIM(WS-INPUT-MERCHANT-ID)
                           MOVE "Y" TO WS-FOUND-FLAG
                       END-IF
               END-READ
           END-PERFORM

           CLOSE MERCHANT-FILE

           IF WS-FOUND-FLAG = "Y"
               STRING "{"
                   """status"":""success"","
                   """code"":0,"
                   """data"":{"
                   """merchant_id"":""" FUNCTION TRIM(WS-M-ID) ""","
                   """merchant_name"":""" FUNCTION TRIM(WS-M-NAME) ""","
                   """status"":""" FUNCTION TRIM(WS-M-STATUS) ""","
                   """source"":""legacy-cobol"""
                   "},"
                   """message"":""Merchant ditemukan"""
                   "}" DELIMITED SIZE INTO WS-JSON-OUTPUT
           ELSE
               STRING "{"
                   """status"":""error"","
                   """code"":1005,"
                   """data"":null,"
                   """message"":""Merchant tidak ditemukan"""
                   "}" DELIMITED SIZE INTO WS-JSON-OUTPUT
           END-IF

           DISPLAY WS-JSON-OUTPUT
           STOP RUN.
