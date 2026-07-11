# Secrets & Local Setup

Namida Sync requires certain secrets (API keys, client secrets) for Google Drive and Firebase integration.

## Setting Up Secrets

1. **Copy the Example File:**
   - Copy `lib/utils/credentials.dart.example` to `lib/utils/credentials.dart`.
   - Or, if using environment variables, copy `.env.example` to `.env`.
2. **Fill in Your Credentials:**
   - Add your Google API keys, client secrets, and any other required values.
3. **Never Commit Secrets:**
   - `.gitignore` is set up to ignore these files. Double-check before committing.

## What to Never Commit
- `.env`, `.env.*`, `*.keystore`, `*.jks`, `*.p8`, `*.p12`, `*.pem`, `*.crt`, `*.cer`, `*.der`, `*.key`, `serviceAccountKey.json`, `*.secret.json`, `*.private.json`, `*.credentials.json`, and any file containing secrets.

## References
- See [CONTRIBUTING.md](../CONTRIBUTING.md) for more info.