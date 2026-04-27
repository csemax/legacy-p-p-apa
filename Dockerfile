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
RUN mkdir -p /app/cobol/COPYBOOKS \
             /app/data \
             /app/bin \
             /app/api-wrapper

WORKDIR /app

# Salin copybooks
COPY cobol/COPYBOOKS/ /app/cobol/COPYBOOKS/

# Salin dan kompilasi program COBOL
COPY cobol/BALANCEINQ.cbl  /app/cobol/
COPY cobol/PAYMENTPROC.cbl /app/cobol/
COPY cobol/TXNSTATUS.cbl   /app/cobol/
COPY cobol/MERCHANTVAL.cbl /app/cobol/

# Kompilasi semua COBOL program
RUN cd /app/cobol && \
    cobc -x -o /app/bin/BALANCEINQ BALANCEINQ.cbl && \
    cobc -x -o /app/bin/PAYMENTPROC PAYMENTPROC.cbl && \
    cobc -x -o /app/bin/TXNSTATUS TXNSTATUS.cbl && \
    cobc -x -o /app/bin/MERCHANTVAL MERCHANTVAL.cbl && \
    echo "Semua COBOL program berhasil dikompilasi"

# Salin data files
COPY data/ /app/data/

# Salin API wrapper
COPY api-wrapper/server.py /app/api-wrapper/

EXPOSE 9090

CMD ["python3", "/app/api-wrapper/server.py"]
