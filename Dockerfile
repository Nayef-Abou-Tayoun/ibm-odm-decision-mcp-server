FROM python:3.11-slim

WORKDIR /app

COPY . .

RUN pip install --upgrade pip
RUN pip install .

CMD ["python", "-m", "decision_mcp_server"]
