# my-agent-skills

A storage library of agent skills (`SKILL.md`) for Claude Code and Codex. Nothing here loads on its own: skills are installed into a project only when you ask, so they cost no context anywhere else.

ไลบรารีเก็บ skill สำหรับ Claude Code และ Codex ไม่โหลดอัตโนมัติ ต้องติดตั้งเข้าโปรเจกต์ที่ต้องการเท่านั้น

## Quick start

```bash
git clone https://github.com/Thiraded/my-agent-skills.git
cd my-agent-skills
bash install.sh --list                                  # see categories and skills
bash install.sh 04-media-audio --project /path/to/proj  # install a whole category
bash install.sh ref-board music --project /path/to/proj --prefix media-
```

Windows PowerShell:

```powershell
.\install.ps1 -List
.\install.ps1 04-media-audio -Project D:\my\project
.\install.ps1 ref-board music -Project D:\my\project -Prefix media-
```

| Option | Meaning |
|---|---|
| `<name or category>` | one or more skill names, or a category folder name |
| `--project DIR` (`-Project`) | target project, default current directory |
| `--agents claude,codex` (`-Agents`) | targets `.claude/skills` and/or `.agents/skills` (default both) |
| `--prefix P` (`-Prefix`) | rename installed skills (`name:` is rewritten) |
| `--link` (`-Link`) | symlink / junction instead of copy (cannot combine with prefix) |

Existing folders are never overwritten. Start a new session after installing; skills are discovered at startup.

## What is inside

| Category | Skill | What it does |
|---|---|---|
| `00-meta-workflow` | `claude-mod-workflow` | How Claude Code mods (function-hook plugins) are built, loaded and fixed |
| `03-research-refs` | `gemini-research` | Gather references and docs through Gemini in the browser |
| `03-research-refs` | `ref-board` | Hunt visual references (Pinterest, YouTube) and lay them out as a categorized board |
| `04-media-audio` | `music` | Generate music with the ElevenLabs Music API |
| `04-media-audio` | `sound-effects` | Generate sound effects with ElevenLabs |
| `04-media-audio` | `voice-isolator` | Remove background noise and isolate speech with ElevenLabs |
| `05-tools-platform` | `microsoft-foundry` | Deploy, evaluate and manage Foundry agents with azd |
| `06-setup` | `setup-project` | Install chosen skills into a project and scaffold a small task-card workflow |
| `06-setup` | `setup-auto-clear` | Explain and set up automatic handoff + `/clear` for Claude Code |

## Setup skills: how to use

### setup-project

Install it into a project, then in a new session ask: "set up this project" (or `/setup-project`).
The agent asks which categories you need, runs the installer, copies the task scaffold
(`docs/tasks/WORKFLOW.md`, `docs/tasks/TEMPLATE.md`, `scripts/task.mjs`) and adds a pointer to `AGENTS.md`.

Task cards (needs Node):

```bash
node scripts/task.mjs create --title "Add login"   # new card in docs/tasks/open/
node scripts/task.mjs list
node scripts/task.mjs start 001
node scripts/task.mjs done 001                      # moves card to docs/tasks/done/
```

### setup-auto-clear

Ask: "set up auto clear". The agent checks whether you already have a mod that can run `/clear`
(a normal hook cannot), explains `/handoff`, `/handoff save`, `/chats`, and the thresholds you can tune,
and offers a lighter option (`autoCompact`) if you do not want to build a mod.
This repo does not ship the author's private mod; the skill documents the mechanism and tuning.

## Add a skill

1. Create `skills/<category>/<name>/SKILL.md` with `name:` equal to the folder name and a short `description:`.
2. Keep descriptions short: every installed skill's description is loaded into every session.
3. For manual-only skills add `disable-model-invocation: true` to the frontmatter.

## Licenses

- Own skills (`claude-mod-workflow`, `gemini-research`, `ref-board`, `setup-project`, `setup-auto-clear`, installers): MIT, see `LICENSE`.
- `music`, `sound-effects`, `voice-isolator`, `microsoft-foundry`: their frontmatter declares `license: MIT`; they keep their original text and authorship.
- Other skills the author uses locally (Unity, Matt Pocock-style engineering skills, research helpers and others) are **not** included because their license could not be verified. Get them from their original sources.
