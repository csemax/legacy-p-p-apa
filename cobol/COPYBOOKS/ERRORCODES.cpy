      *================================================================*
      * ERRORCODES.CPY - Kode Error Legacy System DANTE               *
      *================================================================*

       01  WS-ERROR-CODES.
      *--- Success Codes ---
           05  EC-SUCCESS              PIC 9(4) VALUE 0000.
           05  EC-FOUND                PIC 9(4) VALUE 0001.

      *--- Client Error Codes ---
           05  EC-NOT-FOUND            PIC 9(4) VALUE 1001.
           05  EC-INVALID-AMOUNT       PIC 9(4) VALUE 1002.
           05  EC-INSUFFICIENT-FUNDS   PIC 9(4) VALUE 1003.
           05  EC-INVALID-USER         PIC 9(4) VALUE 1004.
           05  EC-INVALID-MERCHANT     PIC 9(4) VALUE 1005.
           05  EC-INVALID-QR           PIC 9(4) VALUE 1006.
           05  EC-ACCOUNT-INACTIVE     PIC 9(4) VALUE 1007.
           05  EC-MERCHANT-INACTIVE    PIC 9(4) VALUE 1008.
           05  EC-DUPLICATE-TXN        PIC 9(4) VALUE 1009.

      *--- Server Error Codes (simulasi legacy failure) ---
           05  EC-DB-ERROR             PIC 9(4) VALUE 5001.
           05  EC-TIMEOUT              PIC 9(4) VALUE 5002.
           05  EC-SYSTEM-BUSY          PIC 9(4) VALUE 5003.
           05  EC-LOCK-ERROR           PIC 9(4) VALUE 5004.
           05  EC-UNKNOWN-ERROR        PIC 9(4) VALUE 9999.

      *--- Error Messages ---
       01  WS-ERROR-MESSAGES.
           05  EM-SUCCESS          PIC X(50)
               VALUE 'Transaksi berhasil diproses'.
           05  EM-NOT-FOUND        PIC X(50)
               VALUE 'Data tidak ditemukan'.
           05  EM-INSUFF-FUNDS     PIC X(50)
               VALUE 'Saldo tidak mencukupi'.
           05  EM-INVALID-USER     PIC X(50)
               VALUE 'User tidak valid atau tidak aktif'.
           05  EM-INVALID-MERCHANT PIC X(50)
               VALUE 'Merchant tidak valid atau tidak aktif'.
           05  EM-SYSTEM-ERROR     PIC X(50)
               VALUE 'System error, coba beberapa saat lagi'.
           05  EM-TIMEOUT          PIC X(50)
               VALUE 'Request timeout, sistem sedang sibuk'.
