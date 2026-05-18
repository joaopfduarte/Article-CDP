---
name: article-conventional-commits
description: >-
  Applies Conventional Commits to this article repository, grouping changes by
  logical concern (manuscript, slides, bibliography, assets, tooling) and writing
  concise commit messages in British English.
disable-model-invocation: true
---

# Conventional commits for Article-CDP

## Format

- Subject: `type(scope)!: description` (imperative mood, no trailing full stop).
- Optional body: what changed and why.
- Optional footer: `BREAKING CHANGE:`, `Refs:`, and related metadata.

## Language

- Use standard Conventional Commit keywords in English (`feat`, `fix`, `docs`, and so on).
- Write descriptions in British English.

## Suggested scopes

`content`, `slides`, `bib`, `assets`, `structure`, `build`, `agents`.

## Safeguards

1. Keep one logical concern per commit where possible.
2. Do not commit ignored artefacts or secrets.
3. If bibliography and manuscript claims are both touched, ensure they remain consistent before committing.

## Agent execution flow

1. Inspect `git status`, unstaged diff, and staged diff.
2. Group changes into one or more atomic commits.
3. Stage by group and commit with Conventional Commit subjects.
4. Do not push unless explicitly requested by the user.

## Reference

Examples and anti-patterns: [reference.md](reference.md).
