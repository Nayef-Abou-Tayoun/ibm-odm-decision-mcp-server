# Copyright contributors to the IBM ODM MCP Server project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

"""Configuration settings for the ODM Decision MCP Server.

This module contains configuration settings for the ODM Decision MCP Server.
"""

import os
from pathlib import Path

# Transport protocol
TRANSPORT = os.environ.get("DECISION_MCP_TRANSPORT", "stdio")


# Security settings
SECURITY_MODE = os.environ.get("DECISION_MCP_SECURITY_MODE", "strict")
SECURITY_CONFIG_PATH = os.environ.get("DECISION_ODM_MCP_SECURITY_CONFIG", "")

# Instructions displayed to client during initialization
INSTRUCTIONS = """
Welcome to the ODM Decision MCP Server!
This server provides access to decision services for operational decision management.
You can invoke decision services using the provided tools.
For more information, please refer to the documentation.
"""

# Application paths
BASE_DIR = Path(__file__).parent.parent.parent