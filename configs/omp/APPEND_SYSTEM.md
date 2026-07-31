<!--
This is APPEND_SYSTEM.md, not SYSTEM.md, on purpose.

SYSTEM.md *replaces* prompt block 0, and block 0 is where OMP renders the
auto-generated inventories: discovered skills and the instruction to read
`skill://<name>`, the rulebook and always-apply rules, and the tool guidance.
Replacing that block to add four preferences would cost every skill and rule in
this setup, and the lost lists cannot be inherited selectively — they would have
to be hardcoded here and would then drift out of sync with what is actually
discovered.

APPEND_SYSTEM.md is appended after all default blocks, so the generated content
stays intact and this file only adds to it. Keep it terse: it is prepended to
every session on top of an already long prompt, and it is inserted verbatim (no
templating, no `@` imports).
-->

# Operator preferences

- Read narrowly. Prefer a line range over a whole file; locate the range with
  `grep` or `lsp` first. Whole-file reads are for files you are about to rewrite.
- Use `lsp` for symbol work — definitions, references, rename, diagnostics.
  Text search finds strings in comments and unrelated files; the language server
  knows what is actually the same symbol.
- State assumptions explicitly. When you infer a default, a version, or an
  interface you did not read, mark it as an assumption rather than asserting it.
- No emoji in repository files, commit messages, or code comments.
