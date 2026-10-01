# AGENTS.md — house conventions for the local-dev agent

<!--
  Boilerplate. Fill in the TODO/<...> placeholders with your real conventions.
  Referenced from local-dev-agent.draft.yaml via `instructions: AGENTS.md`.
  Keep it tight — every line here is spent on a token-scarce local model, so
  prefer concrete rules over prose. This is where a 27B local model gains the
  most: explicit house rules compensate for knowledge a frontier model would
  carry implicitly.
-->

## Golden rules
- Make the smallest change that solves the task. Do not refactor unrelated code.
- After editing, run the matching validator (below) and fix errors before
  showing a diff. Never present code you have not validated.
- Show `git diff` for only the files you touched. Do not paste whole files.
- Ask before destructive git/gh actions (force push, closing issues, merge).

## Python
- Formatter + linter: **ruff** (`ruff format` then `ruff check --fix`). No black/flake8/isort.
- Target version: Python <TODO e.g. 3.12>. Type hints on public functions.
- Dependency/tooling via **uv** (`uv add`, `uv run`), not pip/poetry.
- Validator (run before diff): `ruff format . && ruff check .`

## Terraform
- Run `terraform fmt` on every changed file; 2-space indent.
- Module/resource naming follows the project naming cascade (see the vault
  "Naming Cascade" standard): <TODO one-line summary of the pattern>.
- Provider versions are pinned; do not bump them as a side effect.
- State backend: <TODO backend + where state lives>. Never touch state manually.
- Validator (run before diff): `terraform fmt -check && terraform validate`

## Databricks (Asset Bundles)
- These repos are **Databricks Asset Bundles** (YAML + Python), NOT classic
  Terraform. Config lives in `databricks.yml` / `resources/*.yml`; 2-space YAML.
- Use the **databricks CLI** with OAuth profiles (`auth_type = databricks-cli`).
  NEVER use or suggest personal access tokens (PATs).
- Workspace profiles: <TODO list the profile names you use>.
- Validator (run before diff): `databricks bundle validate`
- Do NOT run `databricks bundle deploy` without explicit user approval.

## GitHub (issues & PRs)
- Use the `gh` CLI. Issue titles: imperative, <=70 chars. Bodies: context,
  acceptance criteria, and any source URL the request came from.
- PR descriptions: summary of changes, what was tested (name the validator run),
  and anything intentionally left out. Link the issue it closes.
- Branch naming: <TODO e.g. feat/<short-desc>, fix/<short-desc>>.
- Never push to main/master or merge a PR without explicit approval.
