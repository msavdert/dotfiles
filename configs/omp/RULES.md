<!--
Deliberately short. This file is re-attached to the context on every single turn,
so every line is paid for repeatedly and a long list trains the model to skim it.
Hard, non-negotiable requirements only. Background, rationale, and routing live in
AGENTS.md, which is loaded once per session.
-->

- Never commit or push unless explicitly asked. Staging and committing are the
  operator's call, not a step in finishing a task.
- Never commit a red tree. Type check and tests pass first, or the commit waits.
- Never hardcode a secret, token, key, or password. This machine resolves
  credentials from 1Password `op://` references injected per command; a literal
  value in a tracked file is a leak.
- Never edit generated or lockfile artifacts by hand. Change the source and
  regenerate.
- State uncertainty. If an API, flag, or field is not confirmed in the source or
  docs you read, say so instead of inventing plausible behaviour.
