FROM python:3.9-slim

WORKDIR /app
COPY requirements.txt .
RUN pip install -r requirements.txt

COPY . .

# This is important for Azure
EXPOSE 8000

# Use gunicorn for production deployment
RUN pip install gunicorn
CMD ["gunicorn", "--bind", "0.0.0.0:8000", "app:app"]
