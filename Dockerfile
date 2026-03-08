FROM python:3.13-slim

WORKDIR /app

COPY . .

RUN pip install --upgrade pip
RUN pip install .

ENV PYTHONPATH=/app/src

EXPOSE 8000

CMD ["decision-mcp-server", "--transport", "sse", "--host", "0.0.0.0", "--port", "8000"]
