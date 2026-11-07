#!/usr/bin/env node
// Minimal task cards: create | list | start <id> | done <id>. No dependencies.
import fs from 'node:fs'
import path from 'node:path'

const root = path.resolve('docs/tasks')
const open = path.join(root, 'open')
const done = path.join(root, 'done')
const [cmd, ...rest] = process.argv.slice(2)
const arg = n => { const i = rest.indexOf(`--${n}`); return i >= 0 ? rest[i + 1] : undefined }
fs.mkdirSync(open, { recursive: true }); fs.mkdirSync(done, { recursive: true })
const cards = d => fs.readdirSync(d).filter(f => f.endsWith('.md'))
const find = id => cards(open).find(f => f.startsWith(`${id}-`) || f === `${id}.md`)
const setStatus = (file, status) => {
  const p = path.join(open, file)
  fs.writeFileSync(p, fs.readFileSync(p, 'utf8').replace(/^status:.*$/m, `status: ${status}`))
}

if (cmd === 'create') {
  const title = arg('title'); if (!title) { console.error('--title required'); process.exit(1) }
  const id = String(cards(open).length + cards(done).length + 1).padStart(3, '0')
  const slug = title.toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, '').slice(0, 40)
  const tpl = fs.readFileSync(path.join(root, 'TEMPLATE.md'), 'utf8')
  const body = tpl.replace('{{id}}', id).replace('{{title}}', title).replace('{{date}}', new Date().toISOString().slice(0, 10))
  const file = `${id}-${slug}.md`
  fs.writeFileSync(path.join(open, file), body); console.log(path.join('docs/tasks/open', file))
} else if (cmd === 'list') {
  for (const f of cards(open)) console.log(f.replace('.md', ''), '|', (fs.readFileSync(path.join(open, f), 'utf8').match(/^status:\s*(.*)$/m) || [])[1])
} else if (cmd === 'start' || cmd === 'done') {
  const f = rest[0] && find(rest[0]); if (!f) { console.error('card not found'); process.exit(1) }
  if (cmd === 'start') { setStatus(f, 'IN PROGRESS'); console.log('started', f) }
  else { setStatus(f, 'DONE'); fs.renameSync(path.join(open, f), path.join(done, f)); console.log('done', f) }
} else {
  console.error('usage: task.mjs create --title "..." | list | start <id> | done <id>'); process.exit(1)
}
