FROM python:3.13-slim

WORKDIR /app

COPY . .

RUN pip install --upgrade pip
RUN pip install .

ENV PYTHONPATH=/app/src

# Create a comprehensive patch that fixes both XML/JSON and response format issues
RUN cat > /tmp/fix_odm_json.py << 'EOFPATCH'
import sys
import os

# Path to the DecisionServerManager.py file
manager_file = "/app/src/decision_mcp_server/DecisionServerManager.py"

print(f"Patching {manager_file} for JSON support...", file=sys.stderr)

try:
    with open(manager_file, 'r') as f:
        content = f.read()
    
    # Fix 1: Add Accept header to get JSON instead of XML
    # Find the requests.get call in fetch_rulesets
    original_request = '''        response = requests.get(url, auth=HTTPBasicAuth(self.username, self.password), timeout=10)'''
    
    fixed_request = '''        response = requests.get(
            url, 
            auth=HTTPBasicAuth(self.username, self.password), 
            headers={"Accept": "application/json"},
            timeout=10
        )'''
    
    if original_request in content:
        content = content.replace(original_request, fixed_request)
        print("✅ Added Accept: application/json header", file=sys.stderr)
    else:
        print("⚠️  Could not find request line to patch", file=sys.stderr)
    
    # Fix 2: Handle JSON response as list instead of dict with 'elements'
    # The ODM API returns a list directly, not {"elements": [...]}
    original_parse = '''            rulesets = response.json()
            return rulesets'''
    
    fixed_parse = '''            rulesets_data = response.json()
            # ODM API returns a list directly, not a dict with 'elements'
            if isinstance(rulesets_data, list):
                # Convert list to dict format expected by the rest of the code
                rulesets = {}
                for ruleset in rulesets_data:
                    ruleset_id = ruleset.get('id', '')
                    if ruleset_id:
                        rulesets[ruleset_id] = ruleset
                return rulesets
            elif isinstance(rulesets_data, dict):
                # If it's already a dict, return as-is
                return rulesets_data
            else:
                self.logger.error(f"Unexpected response type: {type(rulesets_data)}")
                return {}'''
    
    if original_parse in content:
        content = content.replace(original_parse, fixed_parse)
        print("✅ Fixed JSON response parsing", file=sys.stderr)
    else:
        print("⚠️  Could not find parse section to patch", file=sys.stderr)
    
    # Fix 3: Make fetch_rulesets return empty dict on error instead of None
    original_fetch = '''        except requests.exceptions.RequestException as e:
            self.logger.error("An error occurred: %s", e)
        except json.JSONDecodeError:
            self.logger.error("Failed to decode JSON response.")'''
    
    fixed_fetch = '''        except requests.exceptions.RequestException as e:
            self.logger.error("An error occurred: %s", e)
            return {}  # Return empty dict instead of None
        except json.JSONDecodeError as e:
            self.logger.error("Failed to decode JSON response: %s", e)
            return {}  # Return empty dict instead of None'''
    
    if original_fetch in content:
        content = content.replace(original_fetch, fixed_fetch)
        print("✅ Added error handling for None returns", file=sys.stderr)
    else:
        print("⚠️  Could not find error handling to patch", file=sys.stderr)
    
    # Fix 4: Add defensive check in generate_tools_format
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
    
    if original_generate in content:
        content = content.replace(original_generate, fixed_generate)
        print("✅ Added defensive checks in generate_tools_format", file=sys.stderr)
    else:
        print("⚠️  Could not find generate_tools_format to patch", file=sys.stderr)
    
    # Write the patched content back
    with open(manager_file, 'w') as f:
        f.write(content)
    
    print("✅ Successfully patched DecisionServerManager.py for JSON support", file=sys.stderr)
    sys.exit(0)
    
except Exception as e:
    print(f"❌ Failed to patch: {e}", file=sys.stderr)
    import traceback
    traceback.print_exc(file=sys.stderr)
    sys.exit(1)
EOFPATCH

# Apply the patch
RUN python /tmp/fix_odm_json.py

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
