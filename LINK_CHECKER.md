# Link Checker

Elixir-based link verification system for the Masters of Elixir project.

## 🚀 How to Use

### Locally

```bash
# Run the script
elixir check_links.exs

# Or specify a different file
elixir check_links.exs CONTRIBUTING.md
```

## 📋 Features

- ✅ **Automatically extracts links** from README.md
- ✅ **Checks HTTP status** of each link
- ✅ **Handles redirects** automatically
- ✅ **Ignores problematic links** (localhost, anchors, etc.)
- ✅ **Categorizes results**:
  - OK (200-399)
  - Warning (403, 429 - rate limit)
  - Error (400+, timeouts, DNS failures)
- ✅ **Detailed report** saved to `link-checker-report.txt`

## 🔧 CI Configuration

GitHub Actions is configured to:

1. **Run on**:
   - Push to main/master
   - Pull requests
   - Every Monday at 9 AM UTC (scheduled)
   - Manually (workflow_dispatch)

2. **Timeout**: 15 minutes

3. **Artifacts**: Report saved for 30 days

## 📊 Error Handling

| Status | Meaning |
|--------|---------|
| 200-299 | ✅ Valid link |
| 300-399 | ✅ Redirect OK |
| 403 | ⚠️ Forbidden (accepted) |
| 429 | ⚠️ Rate limited (accepted) |
| 400+ | ❌ Error |
| timeout | ❌ Timeout |
| DNS error | ❌ Domain not found |

## 📝 Notes

- Links to Amazon and other anti-bot protected sites may return 403/405
- Rate limiting (429) is acceptable as it indicates the server exists
- Links with anchors (#) are checked without the anchor
- Relative links (e.g., `images/masters.jpg`) are flagged as errors but are OK for local files

## 📁 Project Structure

```
masters-of-elixir/
├── .github/
│   └── workflows/
│       └── check-links.yml    # CI workflow
├── check_links.exs            # Link verification script
├── LINK_CHECKER.md            # This documentation
└── README.md                  # Main content
```

## 🛠️ Technologies

- **Elixir** ~> 1.15
- **:inets** - Erlang/OTP HTTP client (built-in)
- **:ssl** - SSL support (built-in)
- No external dependencies!
