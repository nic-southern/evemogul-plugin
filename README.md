# EVE Mogul for Cursor and Grok

Connect Cursor or Grok to your EVE Mogul account. After you allow access, the
assistant can check market prices, industry jobs, wallets, and shopping lists.

## Install

1. Install **EVE Mogul** from the Cursor Marketplace (same listing is used in Grok).
2. When asked, sign in to EVE Mogul and choose **Allow access**.
3. Confirm the connection appears under Installed.

## Test locally in Cursor

Grok Bot only installs from the Cursor Marketplace. Cursor Desktop can load this
folder before you publish:

```bash
mkdir -p ~/.cursor/plugins/local
ln -s /absolute/path/to/this-folder ~/.cursor/plugins/local/eve-mogul
```

Then run **Developer: Reload Window**, open **Customize**, and confirm the
**EVE Mogul** skills plus the `evemogul` server. Sign in when Cursor asks you
to allow access.

On Teams or Enterprise, an admin must enable **Allow Local Plugin Imports**.
A marketplace install with the same `name` wins over this local copy.

This `mcp.json` points at production (`https://www.evemogul.com/api/mcp`).
Authorize only works after that server has the OAuth routes live. To try against
a local app instead, temporarily set the URL to `http://127.0.0.1:3000/api/mcp`.

## What you can ask

- Jita or hub prices for an item
- Whether it is cheaper to manufacture
- Open market orders and industry jobs
- Wallet and net asset value
- Shopping list contents

## Privacy

Access is limited to the EVE Mogul account you sign in with. You can disconnect
the app from your EVE Mogul user settings at any time.

This repository only describes how to connect. Your market and character data
stay on EVE Mogul.
