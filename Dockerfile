FROM python:3.13-slim

WORKDIR /app

RUN pip install uv

RUN uvx --from git+https://github.com/DecisionsDev/ibm-odm-decision-mcp-server.git --help

EXPOSE 8080

CMD ["uvx",
 "--from","git+https://github.com/DecisionsDev/ibm-odm-decision-mcp-server.git",
 "ibm-odm-decision-mcp-server",
 "--url","https://dev-ds-console.odm.robobob.ca/res",
 "--runtime-url","https://dev-ds-runtime.odm.robobob.ca/DecisionService",
 "--host","0.0.0.0",
 "--port","8080",
 "--transport","sse",
 "--username","odmAdmin",
 "--password","odmAdmin"]
