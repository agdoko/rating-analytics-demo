# Security Policy

This policy is enforced both by CLAUDE.md conventions (read by Claude during generation) and by the `scripts/security_check.sh` PostToolUse hook (automated enforcement on every file write).

---

## Credential Management

- **No hardcoded credentials, API keys, or connection strings** in source code
- Use environment variables or secret management services (e.g., AWS Secrets Manager, GCP Secret Manager, HashiCorp Vault)
- All secrets must be loaded via `os.environ` or a config provider — never string literals

## SQL Injection Prevention

- **Always use parameterized queries** — never interpolate user input into SQL strings
- Use SQLAlchemy ORM or parameterized `execute()` calls
- f-strings containing SQL keywords (`SELECT`, `INSERT`, `UPDATE`, `DELETE`) will be flagged by the security hook

## Authentication & Authorization

- All new API endpoints must include authentication middleware
- No unauthenticated endpoints in production — exceptions require explicit security review
- Use dependency injection for auth (e.g., FastAPI `Depends()` with auth provider)

## Dependency Security

- Dependencies must be checked against known vulnerability databases before merging
- Pin dependency versions in `requirements.txt` — no open-ended ranges
- Review transitive dependencies for known CVEs

## Secrets in Version Control

- All generated code must be scanned for secrets before commit
- `.env` files must be in `.gitignore`
- Pre-commit hooks should include secret detection (e.g., `detect-secrets`, `trufflehog`)
