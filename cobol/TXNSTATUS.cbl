IDENTIFICATION DIVISION.
       PROGRAM-ID. TXNSTATUS.

       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT TXN-FILE
               ASSIGN TO "/app/data/transactions.dat"
               ORGANIZATION IS LINE SEQUENTIAL
               ACCESS MODE IS SEQUENTIAL
               FILE STATUS IS WS-FILE-STATUS.

       DATA DIVISION.
       FILE SECTION.
       FD  TXN-FILE.
       01  TXN-FILE-RECORD          PIC X(200).

       WORKING-STORAGE SECTION.
       01  WS-FILE-STATUS           PIC XX.
           88  FS-OK                VALUE "00".
       01  WS-INPUT-TXN-ID          PIC X(30).
       01  WS-FOUND-FLAG            PIC X VALUE "N".
       01  WS-EOF-FLAG              PIC X VALUE "N".
       01  WS-JSON-OUTPUT           PIC X(1000).
       
       01  WS-T-RAW-RECORD          PIC X(200).
       01  WS-T-PARSE.
           05  WS-T-ID              PIC X(30).
           05  WS-T-STATUS          PIC X(15).
           05  WS-T-AMOUNT          PIC X(20).

       PROCEDURE DIVISION.
       MAIN-LOGIC.
           ACCEPT WS-INPUT-TXN-ID
           MOVE FUNCTION TRIM(WS-INPUT-TXN-ID) TO WS-INPUT-TXN-ID

           OPEN INPUT TXN-FILE
           IF NOT FS-OK
               STRING "{" """status"":""error""," """code"":5001,"
               """data"":null," """message"":""Database transactions error""}" 
               DELIMITED SIZE INTO WS-JSON-OUTPUT
               DISPLAY WS-JSON-OUTPUT
               STOP RUN
           END-IF

           PERFORM UNTIL WS-FOUND-FLAG = "Y" OR WS-EOF-FLAG = "Y"
               READ TXN-FILE INTO WS-T-RAW-RECORD
                   AT END MOVE "Y" TO WS-EOF-FLAG
                   NOT AT END
                       UNSTRING WS-T-RAW-RECORD DELIMITED BY "|"
                           INTO WS-T-ID WS-T-STATUS WS-T-AMOUNT
                       END-UNSTRING
                       
                       IF FUNCTION TRIM(WS-T-ID) = FUNCTION TRIM(WS-INPUT-TXN-ID)
                           MOVE "Y" TO WS-FOUND-FLAG
                       END-IF
               END-READ
           END-PERFORM

           CLOSE TXN-FILE

           IF WS-FOUND-FLAG = "Y"
               STRING "{"
                   """status"":""success"","
                   """code"":0,"
                   """data"":{"
                   """transaction_id"":""" FUNCTION TRIM(WS-T-ID) ""","
                   """status"":""" FUNCTION TRIM(WS-T-STATUS) ""","
                   """amount"":" FUNCTION TRIM(WS-T-AMOUNT) ","
                   """source"":""legacy-cobol"""
                   "},"
                   """message"":""Status transaksi ditemukan"""
                   "}" DELIMITED SIZE INTO WS-JSON-OUTPUT
           ELSE
               STRING "{"
                   """status"":""error"","
                   """code"":1001,"
                   """data"":null,"
                   """message"":""Transaksi tidak ditemukan"""
                   "}" DELIMITED SIZE INTO WS-JSON-OUTPUT
           END-IF

           DISPLAY WS-JSON-OUTPUT
           STOP RUN.
