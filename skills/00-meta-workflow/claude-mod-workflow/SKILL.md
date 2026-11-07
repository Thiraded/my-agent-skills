---
name: claude-mod-workflow
description: How this machine builds, loads and fixes Claude Code mods (function-hook plugins with ui.render bands/panes), e.g. hq-scope. Use when creating, editing or debugging a mod, when a mod does not show in the desktop app, or when two mods' bars overlap. Load the built-in plugin-authoring skill too for the API.
---

# Claude mod workflow (this machine)

The built-in `plugin-authoring` skill owns the API and types. This skill holds what was learned the hard way here.

## Where mods live and how they load

- Kept mods: `~/.claude/mods/<mod>/` (`.claude-plugin/plugin.json`, `hooks/hooks.json`, `hooks/register.tsx`, `types/index.d.ts`, `tests/`).
- The desktop app loads mods from `env.CLAUDE_CODE_PLUGIN_DIRS` in `~/.claude/settings.json`, paths joined with `;`. Add the mod folder there. A marketplace install (`claude plugin install`) did NOT show in the desktop app; don't use it for personal mods.
- The env is read when the app starts: after editing the list, quit Claude fully and reopen. Edits to a listed mod's files reload in new sessions without that.
- Active mod today: `hq-scope` (one bar above the prompt + `/hq` Deck + `/handoff` + read guard). `prompt-band` and `effortless` were retired into it; don't re-enable them, or bars stack again.

## One bar rule

- Only one mod should own the `AbovePrompt` band. Put new bar items into hq-scope instead of a new mod.
- A `ui.render` hook that returns its own tree without `next(e)` hides every band beneath it. If two bands must coexist, call `const below = await next(e)` and return `<Box flexDirection="column">{mine}{below}</Box>`.

## Code pitfalls seen here

- Never name a variable `h`: JSX compiles to `h(...)`, and a local `h` breaks every element ("h is not a function").
- Functions that take `$` must be top-level `function` declarations (not consts inside `register`), or `claude plugin validate` refuses the module.
- Gating hooks (`prompt.submit`, `tool.call`) get `.catch(($, e, next) => next(e))` so a bug never blocks the user.
- Timer work: wrap in `settle(job)` (`job.catch(() => undefined)`).
- Writing TS through a shell heredoc turns `'\n'`/`'\t'` into real newlines/tabs; write with the Edit/Write tools or use regex `/\r?\n/`, `/\t/`.
- State a drawing reads goes in `$.state` atoms declared in `types/index.d.ts`; a changed shape needs a new `shape` tag.

## Check before saying done

1. `claude plugin validate <mod>`: must end with Validation passed.
2. Type-check with `tsc` using the tsconfig from the types header (keep it outside the mod folder, e.g. `/tmp/hqtsc`).
3. `claude plugin test <mod>`: tests mock what sits beneath the plugin. Give `ui.render` a bottom (`on('ui.render', ($, e) => { const { Box } = $.ui.resolve(e); return <Box /> })`), plus `clock.now/every/after`, `session.usage`, `store.get/set`, `process.run` as the mod uses them.
4. Say plainly that the real app was not checked until the user confirms after a restart.
