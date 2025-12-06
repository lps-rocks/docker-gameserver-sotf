#!/usr/bin/env python3
import a2s
import os

ADDRESS = ("127.0.0.1", os.getenv("QUERY_PORT", 27016))  # Update port if needed

try:
    info = a2s.info(ADDRESS, timeout=3)
    print("Server OK:", info.server_name)
    exit(0)
except Exception as e:
    print("Server unhealthy:", e)
    exit(1)
