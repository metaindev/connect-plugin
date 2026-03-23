![Metain](https://metain.dev/og-image.png)

# Metain Connect

The official Roblox Studio plugin for [Metain](https://metain.dev) which builds Roblox games with AI, powered by [Claude](https://anthropic.com).

> [!IMPORTANT]
> Only install this plugin from the [official Creator Store page](https://create.roblox.com/store/asset/77655523450717) or from this repository. Verify the asset ID matches `77655523450717`. Unofficial or copycat plugins could access your Studio session or inject malicious scripts into your game.

## Quick Setup

1. Download [Roblox Studio](https://www.roblox.com/create) if you don't have it
2. Get the plugin either from the [Creator Store](https://create.roblox.com/store/asset/77655523450717) or clone this repo and save it as a [local plugin](https://create.roblox.com/docs/studio/plugins#saving-a-local-plugin) in Studio
3. Open Studio, click **Metain Connect** in the Plugins tab
4. Go to [metain.dev/chat](https://metain.dev/chat), click **Get Connection Code** and enter it in the plugin
5. Start typing what you want to build

For a detailed walkthrough, visit the [Setup Guide](https://metain.dev/setup).

## How It Works

The plugin connects Roblox Studio to Metain's AI through a WebSocket connection. When you send a prompt on [metain.dev/chat](https://metain.dev/chat), the AI generates Luau code and sends commands directly to the plugin, which executes them in your Studio session in real-time.

All changes are recorded in Studio's undo history. You can revert any AI action without affecting your manual work.

## Plugin Capabilities

| Category | Commands |
|----------|----------|
| **Scripts** | Read, create, update and edit Luau scripts |
| **Instances** | Create, rename, move, delete and clone instances |
| **UI** | Create full UI hierarchies from specs |
| **Properties** | Set properties, tags and attributes on any instance |
| **Exploration** | Run Luau code to explore game hierarchy, properties and any service |
| **Undo** | Revert Metain actions without affecting manual changes |

## Security

The plugin only connects when you provide a connection code and can only modify things inside your Studio session. The connection is authenticated and uses a reconnect token for stability.

## Links

- [Website](https://metain.dev)
- [Setup Guide](https://metain.dev/setup)
- [Get Plugin](https://create.roblox.com/store/asset/77655523450717)
- [Discord](https://discord.gg/npVzt2ZZ6S) - join us to shape the future of Metain
- [X (Twitter)](https://x.com/metaindev)