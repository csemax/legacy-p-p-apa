FROM ubuntu:22.04

LABEL maintainer="Seven Deadly Syncs"
LABEL description="DANTE Legacy System - COBOL Core Banking"

ENV DEBIAN_FRONTEND=noninteractive

# Install GnuCOBOL dan Python
RUN apt-get update && apt-get install -y \
    gnucobol \
    python3 \
    python3-pip \
    && rm -rf /var/lib/apt/lists/*

# Buat direktori
RUN mkdir -p /app/cobol \
             /app/data \
             /app/bin \
             /app/api-wrapper

WORKDIR /app

# Salin data files
COPY data/ /app/data/

# Salin COBOL programs
COPY cobol/BALANCEINQ.cbl  /app/cobol/
COPY cobol/PAYMENTPROC.cbl /app/cobol/
COPY cobol/TXNSTATUS.cbl   /app/cobol/
COPY cobol/MERCHANTVAL.cbl /app/cobol/

# Kompilasi semua COBOL program
# Tidak perlu copybook karena sudah di-embed langsung
RUN cobc -x -free -o /app/bin/BALANCEINQ /app/cobol/BALANCEINQ.cbl && \
    cobc -x -free -o /app/bin/PAYMENTPROC /app/cobol/PAYMENTPROC.cbl && \
    cobc -x -free -o /app/bin/TXNSTATUS /app/cobol/TXNSTATUS.cbl && \
    cobc -x -free -o /app/bin/MERCHANTVAL /app/cobol/MERCHANTVAL.cbl && \
    echo "Semua COBOL program berhasil dikompilasi"

# Salin API wrapper
COPY api-wrapper/server.py /app/api-wrapper/

EXPOSE 9090

CMD ["python3", "/app/api-wrapper/server.py"]
