# Generate Password

Generate a secure password via Bitwarden.

## Usage

```
/gen-password [options]
```

## Protocol

1. Use the `bitwarden` MCP `generate` tool to create a secure password
2. Default: 32 characters, uppercase, lowercase, numbers, special characters
3. If `$ARGUMENTS` is provided, parse for options (length, character types)
4. Output the generated password

## Rules

- NEVER write generated passwords to files unless saving to Bitwarden vault
- If BW_SESSION is expired, instruct user to run: `eval "$(bw-session)"`
