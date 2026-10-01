# AGENTS.md — house conventions for the local-dev agent

## Golden rules
- Make the smallest change that solves the task. Do not refactor unrelated code.
- After editing, run the matching validator (below) and fix errors before
  showing a diff. Never present code you have not validated.
- Show `git diff` for only the files you touched. Do not paste whole files.
- Ask before destructive git/gh actions (force push, closing issues, merge).

## Python
- Formatter + linter: **ruff** (`ruff format` then `ruff check --fix`). No black/flake8/isort.
- Target version: Python 3.12. Type hints on public functions.
- Dependency/tooling via **uv** (`uv add`, `uv run`), not pip/poetry.
- Validator (run before diff): `ruff format . && ruff check .`

## Terraform
- Run `terraform fmt` on every changed file; 2-space indent.
- Provider versions are pinned; do not bump them as a side effect.
- Never touch state manually.
- Validator (run before diff): `terraform fmt -check && terraform validate`

## Databricks (Asset Bundles)
- These repos are **Databricks Asset Bundles** (YAML + Python), NOT classic
  Terraform. Config lives in `databricks.yml` / `resources/*.yml`; 2-space YAML.
- Use the **databricks CLI** with OAuth profiles (`auth_type = databricks-cli`).
  NEVER use or suggest personal access tokens (PATs).
- Validator (run before diff): `databricks bundle validate`
- Do NOT run `databricks bundle deploy` without explicit user approval.

## GitHub (issues & PRs)
- Use the `gh` CLI. Issue titles: imperative, <=70 chars. Bodies: context,
  acceptance criteria, and any source URL the request came from.
- PR descriptions: summary of changes, what was tested (name the validator run),
  and anything intentionally left out. Link the issue it closes.

## Documentation lookup (fetch before guessing)
When unsure about an API, argument, resource, or schema, use the `fetch` tool
(via the `reader` sub-agent) to read the OFFICIAL docs BEFORE writing code —
do not guess from memory. Prefer these canonical sources, and MATCH the version
pinned in the repo (provider/library versions), not the latest:
- Terraform:   registry.terraform.io/providers/<provider>  (pinned version)
- Databricks:  docs.databricks.com + the in-repo bundle JSON schema
- Python libs: the library's official docs or its PyPI project page
Distill to the specific argument/signature/field you need — never paste whole
pages. A local model's memory may be stale; the official doc at the pinned
version is the source of truth.
