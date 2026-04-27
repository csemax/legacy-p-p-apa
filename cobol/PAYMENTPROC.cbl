IDENTIFICATION DIVISION.
       PROGRAM-ID. PAYMENTPROC.

       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT TXN-FILE
               ASSIGN TO "/app/data/transactions.dat"
               ORGANIZATION IS LINE SEQUENTIAL
               *> PENTING: ACCESS MODE IS SEQUENTIAL, bukan EXTEND.
               ACCESS MODE IS SEQUENTIAL 
               FILE STATUS IS WS-FILE-STATUS.

       DATA DIVISION.
       FILE SECTION.
       FD  TXN-FILE.
       01  TXN-FILE-RECORD          PIC X(200).

       WORKING-STORAGE SECTION.
       01  WS-FILE-STATUS           PIC XX.
           88  FS-OK                VALUE "00".
       
       01  WS-INPUT-PAYLOAD         PIC X(200).
       01  WS-NEW-RECORD            PIC X(200).
       01  WS-JSON-OUTPUT           PIC X(1000).
       
       01  WS-P-PARSE.
           05  WS-P-TXN-ID          PIC X(30).
           05  WS-P-USER-ID         PIC X(20).
           05  WS-P-MERCH-ID        PIC X(20).
           05  WS-P-AMOUNT          PIC X(20).
           05  WS-P-QR              PIC X(50).

       PROCEDURE DIVISION.
       MAIN-LOGIC.
           *> Terima payload utuh dari Python
           ACCEPT WS-INPUT-PAYLOAD

           *> Pecah payload
           UNSTRING WS-INPUT-PAYLOAD DELIMITED BY "|"
               INTO WS-P-TXN-ID 
                    WS-P-USER-ID 
                    WS-P-MERCH-ID 
                    WS-P-AMOUNT 
                    WS-P-QR
           END-UNSTRING

           *> Buka file dalam mode EXTEND untuk MENAMBAH data di baris paling bawah
           OPEN EXTEND TXN-FILE
           IF NOT FS-OK
               STRING "{" """status"":""error""," """code"":5001,"
               """data"":null," """message"":""Gagal buka file transaksi""}" 
               DELIMITED SIZE INTO WS-JSON-OUTPUT
               DISPLAY WS-JSON-OUTPUT
               STOP RUN
           END-IF

           *> Rangkai record baru (TxnID|Status|Amount) lalu tulis ke file
           STRING FUNCTION TRIM(WS-P-TXN-ID) "|"
                  "success|"
                  FUNCTION TRIM(WS-P-AMOUNT)
               DELIMITED BY SIZE INTO WS-NEW-RECORD
           
           WRITE TXN-FILE-RECORD FROM WS-NEW-RECORD
           CLOSE TXN-FILE

           *> Kembalikan response berhasil ke Python
           STRING "{"
               """status"":""success"","
               """code"":0,"
               """data"":{"
               """transaction_id"":""" FUNCTION TRIM(WS-P-TXN-ID) ""","
               """user_id"":""" FUNCTION TRIM(WS-P-USER-ID) ""","
               """merchant_id"":""" FUNCTION TRIM(WS-P-MERCH-ID) ""","
               """amount"":" FUNCTION TRIM(WS-P-AMOUNT) ","
               """status"":""success"","
               """source"":""legacy-cobol"""
               "},"
               """message"":""Pembayaran QRIS berhasil diproses"""
               "}" DELIMITED SIZE INTO WS-JSON-OUTPUT

           DISPLAY WS-JSON-OUTPUT
           STOP RUN.
