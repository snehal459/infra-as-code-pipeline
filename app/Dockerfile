FROM python:3.9-slim

WORKDIR /app

COPY . .

RUN pip install flask

ENV FLASK_HOST=0.0.0.0

CMD ["python", "app.py"]