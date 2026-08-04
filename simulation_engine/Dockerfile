# ==============================================================================
# Multi-stage Dockerfile for VirtuaNetLab Python Simulation Engine
# ==============================================================================

# --- Stage 1: Build Dependencies ---
FROM python:3.11-slim AS builder

WORKDIR /app

ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=1

RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    tcpdump \
    libpcap-dev \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --prefix=/install -r requirements.txt


# --- Stage 2: Final Production Image ---
FROM python:3.11-slim AS final

WORKDIR /app

ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PATH="/install/bin:${PATH}" \
    PYTHONPATH="/install/lib/python3.11/site-packages:${PYTHONPATH}:/app"

RUN apt-get update && apt-get install -y --no-install-recommends \
    tcpdump \
    libpcap-dev \
    && rm -rf /var/lib/apt/lists/*

# Copy installed python dependencies from builder
COPY --from=builder /install /install

# Copy application source
COPY . /app/

# Cloud Run injects the port to listen on as $PORT and is free to change it, so
# the app must not hard-code 8080. 8080 stays as the default for plain
# `docker run` and for local use.
ENV PORT=8080
EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
  CMD python -c "import os,urllib.request; urllib.request.urlopen('http://localhost:'+os.environ.get('PORT','8080')+'/health')" || exit 1

# Shell form (not exec form) so that $PORT is expanded at container start.
# The exec-form equivalent would pass the literal string "$PORT" to uvicorn,
# which fails to parse as an integer and the container never becomes ready —
# Cloud Run then reports the unhelpful "container failed to start and listen
# on the port defined by the PORT environment variable".
CMD exec uvicorn main:app --host 0.0.0.0 --port ${PORT}

