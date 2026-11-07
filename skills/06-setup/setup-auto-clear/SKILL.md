---
name: setup-auto-clear
description: Set up and explain automatic handoff + /clear for Claude Code so long chats reset before context bloats or the prompt cache expires. Use when the user asks about auto clear, auto handoff, context getting too big, or configuring /clear behavior.
---

# Setup Auto-Clear

Goal: when a chat is large, write a short handoff, run `/clear`, and carry the handoff into the fresh chat, without the user doing it by hand.

## What can and cannot do this

- A normal settings.json **hook cannot run `/clear`** (hooks run commands; they cannot issue slash commands). Do not promise that.
- A Claude Code **mod** (function-hook plugin) can: it can fork the model for a handoff, store it, and run `/clear` through its command API.
- Built-in `autoCompact` in `~/.claude/settings.json` compacts a full context but keeps the same chat; it is a fallback, not a clear.

## Step 1: Check what is already installed

1. Read `~/.claude/settings.json`: is `CLAUDE_CODE_PLUGIN_DIRS` set under `env`, and does it point to a mod folder?
2. In that folder look for `hooks/register.tsx` and search it for `command.run` with `command: 'clear'`.
3. If found, the user already has auto-clear. Go to "Usage" and "Tuning"; change nothing else.

## Step 2: If no mod exists

Offer two options and let the user pick:

- **Light:** set `"autoCompact": true` in `~/.claude/settings.json` and write a handoff by hand before `/clear`.
- **Full:** build a small mod. Load the plugin-authoring skill first for the API, and follow the claude-mod-workflow skill for where mods live and how they load. The mod needs: a `handoff` command handler, a model fork that writes the handoff, a store entry per folder, a timer that fires after a finished step when context passes a threshold, and a `command.run` call with `clear`. Always give the user a few seconds and a way to cancel (typing anything cancels).

## Usage (reference implementation: a mod named `hq-scope`)

| Action | How |
|---|---|
| Manual handoff + clear now | `/handoff` |
| Save handoff, keep chat | `/handoff save` |
| Browse cleared chats | `/chats` |
| Auto at step end | After a step finishes and context passes the lower limit, a toast says "handoff + clear in 5s"; type anything to keep the chat |
| Auto when idle | If nothing is typed until just before the prompt cache expires, it hands off and clears |
| After clear | The next message gets the saved handoff as starting context |

## Tuning (constants at the top of the mod's `hooks/register.tsx`)

| Constant | Default | Meaning |
|---|---|---|
| `MIN_K` | 80 | Context (thousand tokens) above which a finished step may trigger handoff + clear |
| `MAX_K` | 160 | Above this, a turn end always triggers it |
| `AUTO_CLEAR_DELAY_MS` | 5000 | Time the user has to cancel |
| `CACHE_TTL_MIN` / `CACHE_MARGIN_MIN` | 60 / 5 | Idle clear fires at TTL minus margin; set TTL to 5 if the short cache is in use |
| `IDLE_MIN_K` | 50 | Minimum context for the idle clear |
| `HANDOFF_COOLDOWN_MS` | 10 min | No second handoff right after one |

After editing, start a new session; mods load at startup.

## Verify

Ask the user to run `/handoff save` in a test chat and confirm the toast "handoff saved". Then `/handoff` and confirm the chat clears and the next message sees the handoff. Report anything not confirmed.

## Disable

Remove the mod path from `CLAUDE_CODE_PLUGIN_DIRS` (or delete the `clear` command call), then restart.
