# CLAUDE.md

This file provides guidance to AI assistants (Claude and others) working in this repository.

## Repository Overview

**Repository:** Alusien/Alusien
**Remote:** `http://local_proxy@127.0.0.1:34573/git/Alusien/Alusien`
**Status:** Early-stage / greenfield project

This repository is at the beginning of its lifecycle. As code, configuration, and documentation are added, this file should be updated to reflect the actual structure and conventions.

## Git Workflow

### Branch Naming

- Feature branches for AI-assisted work follow the pattern: `claude/<description>-<session-id>`
  - Example: `claude/add-claude-documentation-WuNx3`
- Human-authored feature branches should follow a similar descriptive pattern.

### Commit Messages

Write clear, imperative commit messages:
- Good: `Add user authentication module`
- Good: `Fix null pointer in payment processor`
- Avoid: `changes`, `fix stuff`, `wip`

### Pushing

Always push with upstream tracking:
```bash
git push -u origin <branch-name>
```

If a push fails due to a network error, retry up to 4 times with exponential backoff (2s, 4s, 8s, 16s).

### Pull Requests

- Open PRs against the default branch (main/master).
- Provide a clear summary of what changed and why.
- Reference any related issues in the PR description.

## Development Setup

> This section should be updated once a language/framework is chosen and dependencies are introduced.

Typical first steps when contributing:

1. Clone the repository.
2. Install dependencies (add the command here once a package manager is chosen).
3. Run tests to verify the environment (add the command here).
4. Make changes on a feature branch.
5. Push and open a pull request.

## Project Structure

> This section should be updated as the codebase grows.

```
/
└── CLAUDE.md       # This file — AI assistant guidance
```

## Code Style and Conventions

> Fill in language/framework-specific conventions as they are established. Common things to document here include:
> - Formatter and linter configuration (e.g., Prettier, ESLint, Black, rustfmt)
> - Naming conventions (files, classes, functions, variables)
> - Where to place new source files
> - How to add tests

## Testing

> Document test commands and testing philosophy here once a test framework is chosen.
>
> Example for a Node.js project:
> ```bash
> npm test          # run all tests
> npm run test:watch  # watch mode
> ```

## Environment Variables

> List required environment variables and where to find their values.
>
> Example:
> ```
> DATABASE_URL=...    # connection string for the database
> SECRET_KEY=...      # application secret
> ```

## AI Assistant Instructions

- **Always read the relevant source files before suggesting or making changes.**
- **Prefer editing existing files over creating new ones** unless a new file is clearly warranted.
- **Keep changes minimal and focused** — only modify what is directly needed.
- **Do not add comments, docstrings, or type annotations** to code you did not change.
- **Do not over-engineer**: avoid premature abstractions, unused helpers, or features not requested.
- **Update this CLAUDE.md** whenever you add, remove, or significantly change project structure, tooling, or conventions.
- **Commit and push** completed work to the designated feature branch.
- **Never push to main/master** without explicit user approval.

## Keeping CLAUDE.md Current

This file should evolve with the project. Update it when:
- A language or framework is chosen
- Dependencies or a package manager are added
- Build, test, or lint commands are established
- Directory structure changes significantly
- New conventions or standards are adopted
