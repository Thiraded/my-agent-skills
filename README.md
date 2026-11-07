# my-agent-skills

A storage library of agent skills (`SKILL.md`) for Claude Code and Codex. Nothing here loads on its own: skills are installed into a project only when you ask, so they cost no context anywhere else.

ไลบรารีเก็บ skill สำหรับ Claude Code และ Codex ไม่โหลดอัตโนมัติ ต้องติดตั้งเข้าโปรเจกต์ที่ต้องการเท่านั้น

## Quick start

```bash
git clone https://github.com/Thiraded/my-agent-skills.git
cd my-agent-skills
bash install.sh --list                                  # see categories and skills
bash install.sh --pick --project /path/to/proj          # numbered menu (type numbers like: 1 3 7-9)
bash install.sh 06-setup --scaffold --project /path/to/proj   # skills + task workflow in one go
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
| `--pick` (`-Pick`) | numbered menu; type numbers separated by spaces (ranges ok), several lines allowed, empty line to finish |
| `--scaffold` (`-Scaffold`) | also create `docs/tasks/`, `scripts/task.mjs` and the `AGENTS.md` pointer (no agent needed) |
| `--link` (`-Link`) | symlink / junction instead of copy (cannot combine with prefix) |

Without any argument the installer prints examples and installs nothing. By default skills are installed twice (Claude and Codex folders); use `--agents claude` if you only use Claude. Existing folders are never overwritten. To remove a skill, delete its folder. Start a new session after installing; skills are discovered at startup.

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

Fastest: `bash install.sh 06-setup --scaffold --project DIR` installs the skill and creates the task files directly.
Or install it into a project, then in a new session ask: "set up this project" (or `/setup-project`).
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

## External skills (not hosted here)

These belong to their original authors. This repo only stores the link; the installer downloads them straight from GitHub into your project.

```bash
./install.sh --pick                    # numbered menu, choose what to install
./install.sh tdd grill-me --project D:/MyGame
```

| Skill | Source |
|---|---|
| `ask-matt` | [mattpocock/skills](https://github.com/mattpocock/skills/tree/HEAD/skills/engineering/ask-matt) |
| `code-review` | [mattpocock/skills](https://github.com/mattpocock/skills/tree/HEAD/skills/engineering/code-review) |
| `codebase-design` | [mattpocock/skills](https://github.com/mattpocock/skills/tree/HEAD/skills/engineering/codebase-design) |
| `diagnosing-bugs` | [mattpocock/skills](https://github.com/mattpocock/skills/tree/HEAD/skills/engineering/diagnosing-bugs) |
| `domain-modeling` | [mattpocock/skills](https://github.com/mattpocock/skills/tree/HEAD/skills/engineering/domain-modeling) |
| `find-skills` | [vercel-labs/skills](https://github.com/vercel-labs/skills/tree/HEAD/skills/find-skills) |
| `grill-me` | [mattpocock/skills](https://github.com/mattpocock/skills/tree/HEAD/skills/productivity/grill-me) |
| `grill-with-docs` | [mattpocock/skills](https://github.com/mattpocock/skills/tree/HEAD/skills/engineering/grill-with-docs) |
| `grilling` | [mattpocock/skills](https://github.com/mattpocock/skills/tree/HEAD/skills/productivity/grilling) |
| `implement` | [mattpocock/skills](https://github.com/mattpocock/skills/tree/HEAD/skills/engineering/implement) |
| `improve-codebase-architecture` | [mattpocock/skills](https://github.com/mattpocock/skills/tree/HEAD/skills/engineering/improve-codebase-architecture) |
| `loop-me` | [mattpocock/skills](https://github.com/mattpocock/skills/tree/HEAD/skills/in-progress/loop-me) |
| `prototype` | [mattpocock/skills](https://github.com/mattpocock/skills/tree/HEAD/skills/engineering/prototype) |
| `research` | [mattpocock/skills](https://github.com/mattpocock/skills/tree/HEAD/skills/engineering/research) |
| `resolving-merge-conflicts` | [mattpocock/skills](https://github.com/mattpocock/skills/tree/HEAD/skills/engineering/resolving-merge-conflicts) |
| `skill-creator` | [anthropics/skills](https://github.com/anthropics/skills/tree/HEAD/skills/skill-creator) |
| `tdd` | [mattpocock/skills](https://github.com/mattpocock/skills/tree/HEAD/skills/engineering/tdd) |
| `teach` | [mattpocock/skills](https://github.com/mattpocock/skills/tree/HEAD/skills/productivity/teach) |
| `to-questionnaire` | [mattpocock/skills](https://github.com/mattpocock/skills/tree/HEAD/skills/productivity/to-questionnaire) |
| `to-spec` | [mattpocock/skills](https://github.com/mattpocock/skills/tree/HEAD/skills/engineering/to-spec) |
| `to-tickets` | [mattpocock/skills](https://github.com/mattpocock/skills/tree/HEAD/skills/engineering/to-tickets) |
| `ui-ux-reviewer` | [arjenschwarz/agentic-coding](https://github.com/arjenschwarz/agentic-coding/tree/HEAD/claude/skills/ui-ux-reviewer) |
| `using-superpowers` | [obra/superpowers](https://github.com/obra/superpowers/tree/HEAD/skills/using-superpowers) |
| `wait-what` | [mattpocock/skills](https://github.com/mattpocock/skills/tree/HEAD/skills/productivity/wait-what) |
| `wayfinder` | [mattpocock/skills](https://github.com/mattpocock/skills/tree/HEAD/skills/engineering/wayfinder) |
| `writing-for-agents` | [mattpocock/skills](https://github.com/mattpocock/skills/tree/HEAD/skills/productivity/writing-for-agents) |
