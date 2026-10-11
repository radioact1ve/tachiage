# AGENTS.md

## Skills

Skills live in `~/.agents/skills/`. Each one is a directory with a `SKILL.md`
whose frontmatter gives its `name` and a `description` of when to use it.

- If you are Claude Code, ignore `~/.agents/skills/` and use only the skills
  in `~/.claude/skills/`, which your harness already loads. The rest of this
  list does not apply to you.
- If your harness does not load that directory on its own, read the
  frontmatter of each `~/.agents/skills/*/SKILL.md` at the start of a session
  to learn which skills exist.
- Before starting a task, check whether a skill's description matches it. If
  one does, read that `SKILL.md` in full and follow it.
- A skill may refer to other files in its directory. Read them when the skill
  tells you to.
