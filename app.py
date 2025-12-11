#!/usr/bin/env python3
"""
Simple example web application for the GitHub Deployment POC
This could be deployed using the deployment scripts
"""

import sys
from datetime import datetime


def main():
    version = "1.0.0"
    timestamp = datetime.now().isoformat()

    print(f"GitHub Deployment POC Application v{version}")
    print(f"Started at: {timestamp}")
    print("Ready to serve requests!")

    return 0


if __name__ == "__main__":
    sys.exit(main())
