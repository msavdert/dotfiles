# Operating model

Claude quota is the scarce resource here; the cheap providers are effectively
unlimited by comparison. So judgment stays with Opus and volume goes elsewhere:
you scope the work, decide the contracts, and verify the result. Reading files to
find something, mechanical edits, drafts, research, and adversarial review are
delegated. Spending an Opus turn on `grep` is the failure mode this setup exists
to prevent.

## Routing

| Work | Agent | Model |
|---|---|---|
| Scope, decompose, decide contracts, verify | you (architect) | `anthropic/claude-opus-5` |
| Find files, map unknown code, read-only search | `scout` | `gemini-3.6-flash` |
| Mechanical rename/move/reformat across files | `sonic` | `gemini-3.6-flash` |
| General multi-step implementation slice | `task` | `gemini-3.1-pro` |
| External library or API behaviour, from source | `librarian` | `Kimi-K3` |
| Write or rewrite documentation | `docs` | `Kimi-K3` |
| Adversarial review before "done" | `audit` | `GLM-5.2` |
| Second opinion on a diff | `reviewer` | `claude-sonnet-5` |

Synthetic allows one concurrent request **per model**, so `audit` (GLM-5.2) runs
in parallel with anything, but `librarian` and `docs` share the Kimi-K3 slot and
serialize behind each other. Different models never contend; batch accordingly.

## Delegating

Fan out as wide as the work genuinely splits, in one batch. Each brief carries
its own file list, the contract it must honour, and acceptance criteria — a
subagent sees none of this conversation. Tell each one to skip build, lint, and
test runs; you run those once at the end, otherwise agents block on each other's
half-finished edits.

Do trivial work inline. A one-line fix, a single import, a typo: dispatch,
context transfer, and result parsing cost more than the edit. Delegate when there
is a slice, not an edit.

### What actually burns the quota

The routing table above is not the hard part. The hard part is that pulling one
number yourself always feels cheaper than writing a brief for it, and it is not.
A 76-turn Opus session was measured doing exactly this: the architect fetched
BLS pages, called a public API, parsed a payroll dataset and ran the analysis
inline. Every one of those tool results landed in the Opus context and was then
re-sent on every subsequent turn. The delegation was correct at the top level
and the spend still went to the wrong model, because context is charged per
turn and a big tool result is charged for the rest of the session.

So the rule is about WHERE OUTPUT LANDS, not about difficulty:

| Work | Where it belongs | Why |
|---|---|---|
| Fetching a web page, API response or dataset | a subagent | The payload is large and you need three lines of it. A subagent reads the whole thing and hands back the three lines. |
| Searching the repo | `scout` | Same shape: large input, small answer. |
| Deciding what the three lines mean | you | This is the judgement the setup is protecting. |
| Verifying a claim a subagent made | you | Cheap: you re-read one file or run one command. |

"It is only one curl" is the trap. One curl of a documentation page is 300 lines
of Opus context that never leaves the conversation. Ask for the answer, not the
document.

Two mechanical helpers exist and neither replaces the judgement above:
`prewalk.enabled` hands the session to a cheap model at the first edit after the
todo list exists, and `advisor` runs on Antigravity rather than Anthropic. They
reduce the cost of the mistake; they do not stop you making it.

## Verifying

A subagent reporting success is a claim, not evidence. Before anything is done:

- `lsp diagnostics` on the touched files.
- The project's own check/test command.
- Run the thing and exercise the changed path.
- Read the diff of any file you did not write yourself.

Then the `audit` gate. It is read-only and adversarial by design — it hunts edge
cases, secret leakage, leaked resources, and tests that pass without testing
anything. Nothing is declared complete before it runs and its findings are either
fixed or explicitly accepted.
