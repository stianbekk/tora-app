# Setting up Slack for Tora

Tora watches Slack messages by registering as a Slack App with the Events API. During development, you'll use ngrok to tunnel webhooks from Slack into the local relay running on port `9377`.

## 1. Install ngrok

```bash
brew install ngrok
ngrok config add-authtoken <YOUR_NGROK_TOKEN>
```

## 2. Start the local relay

Launch Tora. The relay binds to `127.0.0.1:9377` automatically. Verify it's running:

```bash
curl http://127.0.0.1:9377/health
# {"status":"ok","service":"tora-relay"}
```

## 3. Tunnel the relay

```bash
ngrok http 9377
```

Copy the HTTPS URL (e.g. `https://abc123.ngrok.io`). You'll point Slack at this.

## 4. Create a Slack App

1. Visit https://api.slack.com/apps and click **Create New App** → **From scratch**.
2. Name it (e.g. "Tora") and pick your workspace.
3. Under **OAuth & Permissions**, add the following bot scopes:
   - `channels:history`
   - `groups:history`
   - `im:history`
   - `users:read`
4. Click **Install to Workspace** and copy the **Bot User OAuth Token** (starts with `xoxb-…`).

## 5. Configure Event Subscriptions

1. In the Slack app dashboard, go to **Event Subscriptions** → **Enable Events**.
2. Set the **Request URL** to `https://abc123.ngrok.io/slack/events` (your ngrok URL).
3. Slack will send a one-time `url_verification` challenge — Tora's relay handles it automatically and you should see "Verified" in the Slack UI.
4. Under **Subscribe to bot events**, add:
   - `message.channels`
   - `message.groups`
   - `message.im`
5. Save changes.

## 6. Paste the bot token into Tora

1. Open Tora → click the menu bar icon → ⚙️ → **Sources**.
2. Paste the `xoxb-…` token into the **Slack bot token** field and click **Save**.
3. Tora stores it in macOS Keychain.

## 7. Test

In any channel Tora is invited to, send a message like:
> "Can you send me the updated pricing doc by Thursday?"

Within ~30 seconds (the batch interval), a suggestion should appear in the popover with `Accept` / `Dismiss` actions.

## Troubleshooting

- **No events arriving:** check `ngrok http 9377` is still running; check Slack app **Event Subscriptions** → **Recent Deliveries** for delivery failures.
- **`401 invalid_auth`:** the bot token is wrong or revoked — paste a fresh one in Settings.
- **No suggestions extracted:** check **Settings → AI Extraction** has an OpenAI key. Tora falls back silently if the key is missing.
- **Channel/user IDs in suggestions instead of names:** the `users:read` scope is missing or the bot isn't in the channel; reinstall the app.

## Production deployment

For a stable Tora install (no laptop sleep), proxy webhooks through a small relay:

- A Cloudflare Worker or VPS that accepts Slack webhooks and forwards them to your Mac via a persistent WebSocket / SSE connection.
- The Tora relay accepts the same payload format on `/slack/events`, so the proxy just needs to retransmit verbatim.

This is post-MVP. For now ngrok is fine.
