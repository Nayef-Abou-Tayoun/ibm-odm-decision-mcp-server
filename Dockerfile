# Dockerfile for IBM ODM Decision MCP Server
FROM python:3.13-slim

# Install git (required for uvx to install from git repositories)
RUN apt-get update && \
    apt-get install -y --no-install-recommends git && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Install uv package manager
RUN pip install uv
    
EXPOSE 8081

# Run the MCP server using uvx
CMD ["uvx", "--python", "3.13", "--from", "git+https://github.com/DecisionsDev/ibm-odm-decision-mcp-server.git", \
     "ibm-odm-decision-mcp-server", \
     "--url", "https://dev-ds-console.odm.robobob.ca/res", \
     "--runtime-url", "https://dev-ds-runtime.odm.robobob.ca/DecisionService", \
     "--host", "0.0.0.0", \
     "--port", "8081", \
     "--mount-path", "/", \
     "--transport", "sse", \
     "--username", "odmAdmin", \
     "--password", "odmAdmin"]
