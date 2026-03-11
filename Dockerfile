FROM python:3.13-slim

WORKDIR /app

# install uv
RUN pip install uv

# install the ODM MCP server
RUN uv pip install --system git+https://github.com/DecisionsDev/ibm-odm-decision-mcp-server.git

EXPOSE 8080

CMD ["ibm-odm-decision-mcp-server","--url","https://dev-ds-console.odm.robobob.ca/res","--runtime-url","https://dev-ds-runtime.odm.robobob.ca/DecisionService","--host","0.0.0.0","--port","8080","--transport","sse","--username","odmAdmin","--password","odmAdmin"]
