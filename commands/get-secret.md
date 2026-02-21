# Get Secret

Fetch a credential from Bitwarden vault by name.

## Usage

```
/get-secret <search-term>
```

## Protocol

1. Use the `bitwarden` MCP tools to search for the vault item matching `$ARGUMENTS`
2. Return ONLY the requested field (password, username, URI, notes, or TOTP)
3. Do NOT echo the full vault item unless explicitly asked
4. If multiple matches exist, list them by name and ask which one to use

## Rules

- NEVER write secrets to files
- NEVER include secrets in commit messages
- NEVER log secrets to console output
- If BW_SESSION is expired, instruct user to run: `eval "$(bw-session)"`
