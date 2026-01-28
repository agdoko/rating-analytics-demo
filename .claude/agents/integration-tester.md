---
name: integration-tester
description: Generate integration tests for FastAPI endpoints. Use for testing HTTP request/response flows.
tools: Read, Glob, Grep, Write, Bash
model: sonnet
---

Generate FastAPI integration tests using httpx AsyncClient:
1. Read the FastAPI app and endpoint definitions
2. Create test_api.py in rating_service/tests/
3. Test success cases with valid payloads
4. Test validation errors (missing fields, invalid types, out-of-range)
5. Test error responses and edge cases
6. Test bulk endpoints including partial failures
