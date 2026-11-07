# Task workflow

One card = one scoped piece of work, a markdown file in `docs/tasks/open/`.

States (in the `status:` line): `READY` -> `IN PROGRESS` -> `REVIEW` -> `DONE`.

1. Create: `node scripts/task.mjs create --title "Short title"`. Fill goal, files/areas, out of scope, acceptance.
2. Start: `node scripts/task.mjs start <id>`. Only one agent owns a card; do not touch files outside its listed areas.
3. Finish: run the validation written on the card, then `node scripts/task.mjs done <id>`. The card moves to `docs/tasks/done/`.
4. Planning a card does not authorize implementing it.
