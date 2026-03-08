FROM python:3.13-slim

WORKDIR /app

COPY . .

RUN pip install --upgrade pip
RUN pip install .

ENV PYTHONPATH=/app/src

# Create a patch file that fixes the None.values() bug
RUN cat > /tmp/fix_server.py << 'EOFPATCH'
import sys
import os

# Path to the DecisionServerManager.py file
manager_file = "/app/src/decision_mcp_server/DecisionServerManager.py"

print(f"Patching {manager_file}...", file=sys.stderr)

try:
    with open(manager_file, 'r') as f:
        content = f.read()
    
    # Fix 1: Make fetch_rulesets return empty dict on error instead of None
    original_fetch = '''        except requests.exceptions.RequestException as e:
            self.logger.error("An error occurred: %s", e)
        except json.JSONDecodeError:
            self.logger.error("Failed to decode JSON response.")'''
    
    fixed_fetch = '''        except requests.exceptions.RequestException as e:
            self.logger.error("An error occurred: %s", e)
            return {}  # Return empty dict instead of None
        except json.JSONDecodeError:
            self.logger.error("Failed to decode JSON response.")
            return {}  # Return empty dict instead of None'''
    
    content = content.replace(original_fetch, fixed_fetch)
    
    # Fix 2: Add defensive check in generate_tools_format
    original_generate = '''    def generate_tools_format(self, filtered_rulesets)-> list[DecisionServiceDescription]:
        """
        :no-index:
        Generates a formatted list of rulesets in the tools format from the filtered rulesets.

        Args:
            filtered_rulesets (dict): A dictionary of filtered rulesets.

        Returns:
            list: A list of formatted rulesets.
        """
        formatted_tools = []

        for ruleset in filtered_rulesets.values():'''
    
    fixed_generate = '''    def generate_tools_format(self, filtered_rulesets)-> list[DecisionServiceDescription]:
        """
        :no-index:
        Generates a formatted list of rulesets in the tools format from the filtered rulesets.

        Args:
            filtered_rulesets (dict): A dictionary of filtered rulesets.

        Returns:
            list: A list of formatted rulesets.
        """
        formatted_tools = []
        
        # Defensive check: handle None or empty rulesets
        if filtered_rulesets is None:
            self.logger.warning("filtered_rulesets is None, returning empty list")
            return formatted_tools
        
        if not isinstance(filtered_rulesets, dict):
            self.logger.error(f"filtered_rulesets is not a dict: {type(filtered_rulesets)}")
            return formatted_tools

        for ruleset in filtered_rulesets.values():'''
    
    content = content.replace(original_generate, fixed_generate)
    
    # Write the patched content back
    with open(manager_file, 'w') as f:
        f.write(content)
    
    print("✅ Successfully patched DecisionServerManager.py", file=sys.stderr)
    sys.exit(0)
    
except Exception as e:
    print(f"❌ Failed to patch: {e}", file=sys.stderr)
    sys.exit(1)
EOFPATCH

# Apply the patch
RUN python /tmp/fix_server.py

EXPOSE 8080

CMD ["decision-mcp-server", \
     "--transport", "sse", \
     "--mount-path", "/sse", \
     "--host", "0.0.0.0", \
     "--port", "8080", \
     "--url", "https://dev-ds-console.odm.robobob.ca", \
     "--runtime-url", "https://dev-ds-runtime.odm.robobob.ca/DecisionService/rest", \
     "--username", "odmAdmin", \
     "--password", "odmAdmin"]
