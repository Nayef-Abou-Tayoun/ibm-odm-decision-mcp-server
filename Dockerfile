FROM python:3.13-slim

WORKDIR /app

COPY . .

RUN pip install --upgrade pip
RUN pip install .

ENV PYTHONPATH=/app/src

# Create a Python wrapper that catches and handles the error
RUN cat > /app/safe_server.py << 'EOF'
#!/usr/bin/env python3
"""
Wrapper for decision-mcp-server that adds error handling for the list_tools bug.
This intercepts MCP requests and adds defensive null checks.
"""
import sys
import json
import asyncio
from typing import Any, Dict
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Import the original server module
try:
    from decision_mcp_server import server
    from mcp.server import Server
    from mcp.types import Tool
except ImportError as e:
    logger.error(f"Failed to import decision_mcp_server: {e}")
    sys.exit(1)

# Wrap the original list_tools handler
original_handlers = {}

def wrap_list_tools_handler(original_server: Server):
    """Wrap the list_tools handler with error handling."""
    
    # Store original handler
    if hasattr(original_server, '_request_handlers'):
        handlers = original_server._request_handlers
        if 'tools/list' in handlers:
            original_handlers['tools/list'] = handlers['tools/list']
            
            async def safe_list_tools(*args, **kwargs):
                """Safe wrapper for list_tools that handles None values."""
                try:
                    result = await original_handlers['tools/list'](*args, **kwargs)
                    
                    # Handle None result
                    if result is None:
                        logger.warning("list_tools returned None, returning empty list")
                        return {"tools": []}
                    
                    # Handle dict with .values()
                    if isinstance(result, dict):
                        if 'tools' not in result:
                            tools = list(result.values()) if result else []
                            return {"tools": tools}
                    
                    return result
                    
                except AttributeError as e:
                    logger.error(f"AttributeError in list_tools (likely None.values()): {e}")
                    return {"tools": []}
                except Exception as e:
                    logger.error(f"Error in list_tools: {e}", exc_info=True)
                    return {"tools": []}
            
            # Replace handler
            handlers['tools/list'] = safe_list_tools
            logger.info("Successfully wrapped list_tools handler")

# Apply wrapper
if server:
    wrap_list_tools_handler(server)

# Run the server
if __name__ == "__main__":
    import sys
    from decision_mcp_server.__main__ import main
    sys.exit(main())
EOF

RUN chmod +x /app/safe_server.py

EXPOSE 8080

# Use the wrapper instead of calling decision-mcp-server directly
CMD ["python", "/app/safe_server.py", \
     "--transport", "sse", \
     "--mount-path", "/sse", \
     "--host", "0.0.0.0", \
     "--port", "8080", \
     "--url", "https://dev-ds-console.odm.robobob.ca", \
     "--runtime-url", "https://dev-ds-runtime.odm.robobob.ca/DecisionService/rest", \
     "--username", "odmAdmin", \
     "--password", "odmAdmin"]
