      *================================================================*
      * BANKDATA.CPY - DANTE Legacy System                             *
      * Copybook: Struktur data utama perbankan CIMB Niaga             *
      * Seven Deadly Syncs - Capstone UB 2026                         *
      *================================================================*

      *----------------------------------------------------------------*
      * ACCOUNT RECORD - Data Rekening Nasabah                        *
      *----------------------------------------------------------------*
       01  WS-ACCOUNT-RECORD.
           05  WS-ACC-ID           PIC X(20).
           05  WS-ACC-USER-ID      PIC X(20).
           05  WS-ACC-NAME         PIC X(50).
           05  WS-ACC-BALANCE      PIC 9(13)V99.
           05  WS-ACC-CURRENCY     PIC X(3).
           05  WS-ACC-STATUS       PIC X(10).
           05  WS-ACC-CREATED-AT   PIC X(20).

      *----------------------------------------------------------------*
      * MERCHANT RECORD - Data Merchant                               *
      *----------------------------------------------------------------*
       01  WS-MERCHANT-RECORD.
           05  WS-MER-ID           PIC X(20).
           05  WS-MER-NAME         PIC X(100).
           05  WS-MER-CATEGORY     PIC X(50).
           05  WS-MER-STATUS       PIC X(10).
           05  WS-MER-BANK-CODE    PIC X(10).
           05  WS-MER-ACCOUNT      PIC X(20).

      *----------------------------------------------------------------*
      * TRANSACTION RECORD - Data Transaksi                           *
      *----------------------------------------------------------------*
       01  WS-TRANSACTION-RECORD.
           05  WS-TXN-ID           PIC X(36).
           05  WS-TXN-USER-ID      PIC X(20).
           05  WS-TXN-MERCHANT-ID  PIC X(20).
           05  WS-TXN-AMOUNT       PIC 9(13)V99.
           05  WS-TXN-STATUS       PIC X(10).
           05  WS-TXN-TYPE         PIC X(10).
           05  WS-TXN-QR-CODE      PIC X(100).
           05  WS-TXN-CREATED-AT   PIC X(20).
           05  WS-TXN-UPDATED-AT   PIC X(20).

      *----------------------------------------------------------------*
      * REQUEST RECORD - Input dari API                               *
      *----------------------------------------------------------------*
       01  WS-API-REQUEST.
           05  WS-REQ-TYPE         PIC X(20).
           05  WS-REQ-USER-ID      PIC X(20).
           05  WS-REQ-MERCHANT-ID  PIC X(20).
           05  WS-REQ-TXN-ID       PIC X(36).
           05  WS-REQ-AMOUNT       PIC 9(13)V99.
           05  WS-REQ-QR-CODE      PIC X(100).

      *----------------------------------------------------------------*
      * RESPONSE RECORD - Output ke API                               *
      *----------------------------------------------------------------*
       01  WS-API-RESPONSE.
           05  WS-RESP-STATUS      PIC X(10).
           05  WS-RESP-CODE        PIC 9(4).
           05  WS-RESP-MESSAGE     PIC X(200).
           05  WS-RESP-DATA        PIC X(500).

      *----------------------------------------------------------------*
      * WORKING STORAGE UMUM                                          *
      *----------------------------------------------------------------*
       01  WS-COMMON.
           05  WS-RETURN-CODE      PIC 9(4)    VALUE 0.
           05  WS-ERROR-FLAG       PIC X(1)    VALUE 'N'.
           05  WS-EOF-FLAG         PIC X(1)    VALUE 'N'.
           05  WS-FOUND-FLAG       PIC X(1)    VALUE 'N'.
           05  WS-COUNTER          PIC 9(6)    VALUE 0.
           05  WS-TEMP-AMOUNT      PIC 9(13)V99 VALUE 0.
           05  WS-CURRENT-DATE     PIC X(20).
           05  WS-DELAY-SECS       PIC 9(4)    VALUE 0.
