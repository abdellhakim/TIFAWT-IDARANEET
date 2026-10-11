FROM python:3.11-slim

WORKDIR /srv/backend
COPY backend/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt gunicorn

COPY backend/ .
# The catalog JSON is shared with the mobile app.
COPY assets/data /srv/assets/data
ENV TIFAWT_DATA_DIR=/srv/assets/data

EXPOSE 5000
CMD ["gunicorn", "--bind", "0.0.0.0:5000", "--workers", "2", "run:app"]
