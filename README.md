# ms-xoauth2

A python-based tool for retrieving Microsoft OAuth2 access tokens.

## Overview

This tool implements various OAuth2 authentication flows for Microsoft
365 / Exchange Online, obtaining and caching access tokens and
returning the access token to stdout.  It was originally based on
[sasl-xoauth2-tool](https://github.com/tarickb/sasl-xoauth2), with
modifications for it to work in a background context more seamlessly.

It was written specifically to be used with
[msmtp](https://marlam.de/msmtp/) (SMTP), but should be usable in
other contexts as well (IMAP, POP, etc.)

Inspired by
[sasl-xoauth2-tool](https://github.com/tarickb/sasl-xoauth2), but with
the additional goal of being run in the background (i.e. by msmtp).

## Requirements

- Python 3.x
- `requests`
- `requests-oauthlib`
- `appdirs`
- `pywebview` (optional, for embedded browser method)
- `zenity` or `gxmessage` (optional, for GUI dialogs for the "device" and "manual" methods)

Install Python dependencies:

```bash
pip install requests requests-oauthlib appdirs pywebview
```

## Configuration

Create a config file at `~/.config/ms-xoauth2/config`:

```ini
[default]
account: myaccount

[myaccount]
tenant: your-tenant-id
client_id: your-client-id
# comma-separated list of scopes, e.g. SMTP.Send, IMAP.AccessAsUser.All, POP.AccessAsUser.All
scope: SMTP.Send
```

## Usage

```bash
# Get an access token (uses embedded browser by default)
./ms-xoauth2

# Specify authentication method
./ms-xoauth2 --method embedded
./ms-xoauth2 --method localhost
./ms-xoauth2 --method device
./ms-xoauth2 --method manual

# Use a specific account from config
./ms-xoauth2 --account work

# Use a custom config file
./ms-xoauth2 --config /path/to/config
```

The tool outputs the access token to stdout, suitable for piping to
other commands.

For use with msmtp, specify the path to the script (along with any
command line arguments) as the argument(s) to the `passwordeval`
config variable:

```
passwordeval /path/to/ms-xoauth2
```

## Authentication Methods

### `embedded` (default)

Opens an embedded browser window within the application using
pywebview. The browser monitors URL changes and automatically captures
the authorization code when Microsoft redirects after successful
authentication.

**Advantages:**
- No app registration changes required (uses existing nativeclient redirect URI)
- Seamless user experience
- Remembers login credentials between sessions (cookies stored in `~/.cache/ms-xoauth2/webview`)

**Requirements:**
- `pywebview` package
- On Linux: WebKitGTK (`python3-gi`, `gir1.2-webkit2-4.0`)

### `localhost`

Starts a local HTTP server on a dynamically-assigned free port, opens
the system browser to the authorization URL, and waits for Microsoft
to redirect back to localhost with the authorization code.

**Advantages:**
- Uses system browser (full compatibility, existing sessions)
- Automatic code capture

**Requirements:**
- The redirect URI `http://localhost:<port>/` must be registered in the Azure app registration

### `device`

Uses the OAuth2 device code flow. Displays a code and opens a browser
to `microsoft.com/devicelogin` where the user enters the code to
authenticate.

**Advantages:**
- Works on headless systems or when browser integration is difficult
- No redirect URI required

**Requirements:**
- "Allow public client flows" must be enabled in the Azure app registration

### `manual`

Opens the system browser to the authorization URL and displays a
dialog prompting the user to copy and paste the redirect URL from the
browser's address bar after authentication.

**Advantages:**
- Works without any app registration changes
- Fallback when other methods aren't available

**Disadvantages:**
- Requires manual URL copying
- Microsoft may show a warning page on the nativeclient redirect, and
  not provide much time to grap the redirect URL.

## Token Caching

Tokens are cached in `~/.cache/ms-xoauth2/tokens/<account>.json`. The
tool automatically:

1. Returns a cached token if still valid
2. Refreshes an expired token using the refresh token
3. Initiates a new authentication flow if refresh fails

## Azure App Registration

To use this tool, you need an Azure app registration with:

- **Redirect URIs** (depending on method):
  - `https://login.microsoftonline.com/common/oauth2/nativeclient` (embedded, manual)
  - `http://localhost:<port>/` (localhost - can use any port)
- **API Permissions**:
  - `https://outlook.office.com/SMTP.Send` (for SMTP)
  - `https://outlook.office.com/IMAP.AccessAsUser.All` (for IMAP)
  - `https://outlook.office.com/POP.AccessAsUser.All` (for POP)
- **Allow public client flows**: Yes (required for device code flow)

## Environment Variables

- `LOG_LEVEL`: Set logging verbosity (DEBUG, INFO, WARNING, ERROR)

## License

GPLv3 or later
