FROM python:3.13-slim

WORKDIR /app

COPY . .

RUN pip install --upgrade pip
RUN pip install .

ENV PYTHONPATH=/app/src

CMD ["python", "-m", "decision_mcp_server"]
