# Security Policy

This skill is designed for infrastructure operations. Treat every issue, pull request, and example as potentially sensitive.

## Please Do Not Publish

- Passwords, API keys, private keys, session cookies, or OAuth secrets.
- Full `.env` files or credential-bearing compose files.
- Private hostnames, private customer names, internal issue URLs, or personal data.
- Complete public IP maps unless the environment is intentionally public.

## Reporting Security Issues

Open a GitHub security advisory or contact the repository maintainer privately if this repository exposes a secret, unsafe command, or dangerous operating pattern.

## Safe Example Style

Use placeholders such as:

```text
<lxc-id>
<service-name>
<internal-hostname>
<redacted-secret>
<operator>
```

