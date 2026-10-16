# AGENTS.md

## General Behaviors

When I ask questions, make sure you understand and confirm with me before 
you go and make changes. Always propose a plan and ask for confirmation before 
modifying any files or running code-changing tools.

## Programming and Coding

When writing new code, plan to write at least unit tests as well. Ask to 
confirm. Also ask about integration tests.

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

## Git

Do all changes to a git repository in a worktree, never in the main checkout.
This is my standing preference: do not ask for consent first.

- Before the first edit in a repository, check whether you are already in a
  linked worktree. If you are, work there.
- If you are not, create one. Use your harness's own worktree tool if it has
  one. Otherwise run `git worktree add .worktrees/<branch> -b <branch>` from
  the project root, after making sure `.worktrees/` is gitignored.
- Name the branch after the change, in short lowercase words with hyphens.
- When the work is done, stop and ask me how to finish: merge into the
  default branch, open a pull request, or keep the branch. Do not merge, push
  or delete the worktree on your own.
- Reading, searching and answering questions do not need a worktree.
- Exception: in tachiage (`~/code/tachiage`, GitHub `radioact1ve/tachiage`),
  work in the main checkout and commit to `main`. Files under its `home/` are
  live through symlinks, so a change made in a worktree would not take effect.
- If a project's own instructions say how commits or branches work there,
  those instructions win over this section.
