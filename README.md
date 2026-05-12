# sysadmin-repo-setup

A [Claude Code skill](https://agentskills.io) for scaffolding git-backed
sysadmin documentation repositories.

## What it does

Do you forget everything about a working system, only to realize you have a ton
of leg-work to do to remember how it all works when it's time for maintenance
or upgrades?  Document it and keep it in revision control!

When invoked, this skill guides Claude through creating a well-structured
documentation repo for a machine -- the kind that serves as both human
reference and Claude session context. The resulting repo documents hardware,
OS, storage, and services, and includes a `CLAUDE.md` that drives automatic
maintenance behavior in future sessions (reading the todo list at session
start, keeping docs in sync after system changes).

## Workflow

1. **Explore first** -- run provided commands to gather hardware, OS, storage,
   service, and network info from the live system
2. **Prompt the user** -- ask for things the system can't tell you (role,
   upgrade history, gotchas, credentials location)
3. **Scaffold and populate** -- create the standard file set with section-level
   guidance for each file

## Standard file set

```
CLAUDE.md      hardware.md    os.md
storage.md     services.md    todo.md
```

Plus judgment-call files for significant subsystems (`network.md`,
`configs.md`, `backups.md`, etc.).

## Platform coverage

- Any Linux (general exploration commands)
- Debian / Ubuntu (apt sources, package history)
- Windows and macOS (stubs -- contributions welcome)

## Installation

Clone directly into your Claude Code skills directory:

```bash
git clone https://github.com/joeyparrish/sysadmin-repo-setup \
  ~/.claude/skills/sysadmin-repo-setup
```

Updates are then just `git pull` inside that directory.

## Usage

In Claude Code, ask to create a new sysadmin documentation repo and the skill
will be invoked automatically. Or trigger it explicitly:

> "Use the sysadmin-repo-setup skill to document this machine."
