---
name: setup-project
description: Set up a project for agent work - install chosen skills from the skill library into the project and scaffold a simple task-card workflow. Use when starting a new project, onboarding a repo to Claude Code or Codex, or when the user asks to set up skills or tasks for a project.
---

# Setup Project

Install the right skills into a project and give it a lightweight task workflow. The skill library lives outside any scanned skills folder, so nothing loads until a project opts in.

## 1. Locate the library and the project

- Library: the folder containing `install.sh` and `skills/` (a clone of this repo). If you cannot find it, ask the user for its path.
- Project: the current working directory unless the user names another. Confirm the path before writing.

## 2. Choose skills

List categories with `bash <library>/install.sh --list`. Ask the user which categories or skill names the project needs. Do not install everything: every installed skill adds its description to context in every session. Prefer a few categories.

## 3. Install

```bash
bash <library>/install.sh <names-or-categories...> --project <dir> [--prefix unity-] [--agents claude,codex] [--link]
```

- Default targets: `<project>/.claude/skills/` and `<project>/.agents/skills/` (Claude Code and Codex).
- `--prefix` renames installed skills (rewrites `name:`), useful to keep domain skills grouped. Not allowed together with `--link`.
- `--link` uses symlinks (junctions on Windows) so edits in the library show up in the project.
- Windows without Git Bash: use `install.ps1` with the same options.

## 4. Scaffold tasks (skip if the project already has a task system)

Copy these from this skill's `assets/` into the project:

| From | To |
|---|---|
| `assets/WORKFLOW.md` | `docs/tasks/WORKFLOW.md` |
| `assets/TASK-TEMPLATE.md` | `docs/tasks/TEMPLATE.md` |
| `assets/task.mjs` | `scripts/task.mjs` |

Then add this pointer to the project's `AGENTS.md` (create it if missing; if `CLAUDE.md` exists and `AGENTS.md` does not, put it in `CLAUDE.md`):

```markdown
## Tasks
Work is tracked as cards in `docs/tasks/`. Read `docs/tasks/WORKFLOW.md` once.
Create: `node scripts/task.mjs create --title "..." `; list: `node scripts/task.mjs list`.
```

## 5. Report how to use it

Tell the user, briefly: which skills were installed and where; that they appear after a new session starts; how to create, start and finish a task; and how to remove a skill (delete its folder).

## Rules

- Never overwrite an existing skill folder or task file without asking.
- Do not run the installer against a directory the user did not name.
- Needs `node` for `task.mjs`; if missing, say so and leave the cards as plain markdown.
