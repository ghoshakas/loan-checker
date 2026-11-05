# Backend: FastAPI + Uvicorn. Build context is ./backend (the submodule).
FROM python:3.13-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

WORKDIR /app

COPY requirements.txt .
RUN pip install -r requirements.txt

COPY . .

# Run as an unprivileged user; uploaded documents live in a volume at /data/uploads.
RUN useradd --create-home --uid 10001 app \
 && mkdir -p /data/uploads \
 && chown -R app:app /data /app
USER app

ENV UPLOAD_DIR=/data/uploads
EXPOSE 8000

HEALTHCHECK --interval=10s --timeout=5s --start-period=20s --retries=5 \
  CMD python -c "import urllib.request,sys; sys.exit(0 if urllib.request.urlopen('http://127.0.0.1:%s/health' % __import__('os').environ.get('PORT','8000')).status == 200 else 1)"

# Migrations run on startup (AUTO_MIGRATE=true); the admin account is seeded if missing.
# Bind to $PORT (Railway/Render inject it); fall back to 8000 locally.
CMD ["sh", "-c", "exec uvicorn app.main:app --host 0.0.0.0 --port ${PORT:-8000} --proxy-headers --forwarded-allow-ips=*"]
