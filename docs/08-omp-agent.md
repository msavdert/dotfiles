# 08 — OMP coding agent

## The idea in one paragraph

The scarce resource is not compute, it is **Claude quota**. So Opus is spent
only on judgement: it scopes the work, designs it, and decides whether the
result is acceptable. Everything in between — grepping the repo, drafting
mechanical edits, writing reference tables, researching a library — is handed to
models that are fast and effectively free at this volume. Nothing that comes
back is believed on sight: a change is only done once an **adversarial audit**
pass has tried to break it and a **real verification gate** (the command, the
build, the test that actually covers the change) has agreed. The whole
configuration in `configs/omp/` exists to make that routing automatic, so the
cheap path is the default path and the expensive model is never spent on typing.

## Providers and models

Three providers are authenticated. Two are OAuth (no key on disk that we
manage), one is an API key.

| Provider | Auth | Notable models | What it is for |
|---|---|---|---|
| `anthropic` | OAuth | `claude-opus-5`, `claude-sonnet-5` (1M context, 128K output, thinking `low`…`max`), `claude-opus-4-6`, `claude-sonnet-4-6`, `claude-haiku-4-5` | Architecture, planning, review, the final QA gate. The only tier trusted to decide something is finished. |
| `google-antigravity` | OAuth | `gemini-3.1-pro`, `gemini-3.6-flash`, `gemini-3.5-flash`, `gemini-3.1-flash-lite`, `gemini-2.5-pro` (1M context, 66K output) | Bulk work: search, mechanical edits, session titles, general delegated tasks. Fast and high-throughput. |
| `synthetic` | API key (`SYNTHETIC_API_KEY`) | `hf:zai-org/GLM-5.2` (524K), `hf:moonshotai/Kimi-K3` (524K), `hf:zai-org/GLM-4.7-Flash` (197K), `hf:Qwen/Qwen3.6-27B`, `hf:openai/gpt-oss-120b`, `hf:nvidia/NVIDIA-Nemotron-3-Super-120B-A12B-NVFP4` | Long-context specialists: adversarial review and documentation. Subscription-priced, so the constraint is concurrency, not cost per token. |

Synthetic also exposes capability aliases — `syn:large:text` (GLM-5.2),
`syn:small:text` (GLM-4.7-Flash), `syn:large:vision` (Kimi-K3),
`syn:small:vision` (Qwen3.6-27B). **`configs/omp/config.yml` uses the concrete
ids, not the aliases**, because an alias can be re-pointed upstream and the
concurrency argument below depends on knowing exactly which model a role hits.

## Role routing

| Work type | Agent / role | Model | Why |
|---|---|---|---|
| Architecture, planning, final acceptance | `default`, `slow`, `plan` | `anthropic/claude-opus-5` | The only judgement call that cannot be delegated. 1M context means the whole repo plus a plan fits without compaction. |
| Session titles, classification, cheap background turns | `smol` | `google-antigravity/gemini-3.6-flash` | High volume, zero judgement. Spending Opus here is pure waste. |
| Read-only repo search | `scout` | `google-antigravity/gemini-3.6-flash` | Reads a lot, decides nothing. Bundled agent, re-pointed by model override only — see [O4](#o4--bundled-agents-are-re-pointed-by-model-override-not-replaced). |
| Mechanical edits | `sonic` | `google-antigravity/gemini-3.6-flash` | Rename, move, apply-the-same-change-in-twelve-files. Speed matters, taste does not. |
| General delegated work | `task` | `google-antigravity/gemini-3.1-pro` | The default worker gets the stronger Gemini: it has to investigate *and* edit in one pass. |
| Library and API research | `librarian` | `synthetic/hf:moonshotai/Kimi-K3` | 524K context swallows a whole vendored dependency; benchmarked as the best writer of the three Synthetic models. |
| Repository documentation | `docs` | `synthetic/hf:moonshotai/Kimi-K3` | Same model, different prompt — a custom agent that knows this repo's doc conventions. |
| Adversarial review gate | `audit` | `synthetic/hf:zai-org/GLM-5.2` | A reasoning model, read-only, told to assume the change is broken. Deliberately a *different* model from the one that wrote the code. |
| Code review | `reviewer` | `anthropic/claude-sonnet-5` | Review needs judgement but not Opus; Sonnet is the cheapest model still trusted to say "no". |
| Passive per-turn review (advisor) | `advisor` | `anthropic/claude-sonnet-5` | Runs on every turn, so it must be fast; injects concerns and blockers rather than editing. |

Roles live under `modelRoles` in `configs/omp/config.yml`; subagents are
re-pointed under `task.agentModelOverrides`, which takes precedence over an
agent file's own `model:` frontmatter.

## Synthetic rate limits, and why roles use different models

Synthetic's subscription packs limit **one concurrent request per model**, not
per account. A second request to the same model does not fail — it *queues*
behind the first, which in an agent harness looks like a subagent that has hung.
Requests to **different** models run fully in parallel.

That single fact drives the role assignment. The audit gate (`audit`, GLM-5.2)
and the writing roles (`librarian` and `docs`, Kimi-K3) sit on **different**
models, so the most common parallel pairing — implement something, then audit it
while the docs are drafted — never contends with itself.

`librarian` and `docs` deliberately share Kimi-K3, which means two of them in the
same batch serialise. That is accepted: they are research and writing roles that
are rarely spawned together, and the alternative is a worse writer on one of
them. The rule to remember when adding a Synthetic role is that **a new role
needs a new model**, or it will queue behind an existing one and look hung.

The quota itself:

| Budget | Limit | Regeneration |
|---|---|---|
| Requests | 500 per rolling 5 hours | 5% every 15 minutes |
| Credits | $24 per week | 2% every 202 minutes |

Cheaper models consume fractional request units, so the 500 is a soft ceiling in
practice. `omp usage` prints the current standing for every authenticated
account.

One trap specific to GLM-5.2: it is a **reasoning** model, and its internal
thinking is billed against the *same* `max_tokens` budget as the visible answer.
A budget sized for the answer alone gets consumed entirely by reasoning and the
call returns empty content — no error, just nothing. Budget generously for that
role.

## File map

Everything tracked in `configs/omp/` lands flat in `~/.omp/agent/`.

| Tracked file | Lands at | Controls |
|---|---|---|
| `config.yml` | `~/.omp/agent/config.yml` | Global settings: `modelRoles`, `task.agentModelOverrides`, tool approval policy, memory backend, compaction, theme. |
| `models.yml` | `~/.omp/agent/models.yml` | Custom model and provider definitions, including the Synthetic model ids and their context/output limits. |
| `keybindings.yml` | `~/.omp/agent/keybindings.yml` | TUI key bindings. |
| `lsp.json` | `~/.omp/agent/lsp.json` | Language-server configuration for the `lsp` tool. |
| `AGENTS.md` | `~/.omp/agent/AGENTS.md` | **Opening context, loaded once.** Injected into the session's `<context>` block at start-up. This is where the bulk of the guidance belongs: it costs context budget exactly once. |
| `RULES.md` | `~/.omp/agent/RULES.md` | **Always-apply sticky rule.** Not a context file — it is loaded as a rule and *re-attached near the current turn*, so it survives a long conversation pushing the opening context out of sight. It is always sticky; frontmatter cannot make it optional. **Keep it short**, because it is paid for on every turn. |
| `WATCHDOG.md` | `~/.omp/agent/WATCHDOG.md` | **Advisor-only.** Appended to the *advisor's* system prompt and never injected into the primary agent's context. Use it for review priorities that would be noise for the executor: dangerous APIs, architectural boundaries, traps specific to this repo. |
| `APPEND_SYSTEM.md` | `~/.omp/agent/APPEND_SYSTEM.md` | **Appended after the default system prompt blocks.** Adds a block; it does not replace one — see [O3](#o3--append_systemmd-not-systemmd). |
| `agents/audit.md` | `~/.omp/agent/agents/audit.md` | The adversarial reviewer: read-only tools, GLM-5.2, high thinking. |
| `agents/docs.md` | `~/.omp/agent/agents/docs.md` | The documentation writer: Kimi-K3, knows this repo's doc conventions. |
| `skills/add-secret/SKILL.md` | `~/.omp/agent/skills/add-secret/SKILL.md` | The `configs/op-env` + 1Password procedure from [05-secrets.md](05-secrets.md). |
| `skills/devbox-image/SKILL.md` | `~/.omp/agent/skills/devbox-image/SKILL.md` | The add-a-tool / rebuild / test loop from [06-maintenance.md](06-maintenance.md). |
| `skills/vps-deploy/SKILL.md` | `~/.omp/agent/skills/vps-deploy/SKILL.md` | The compose pull/up, volume and rollback procedure from [03-vps-deployment.md](03-vps-deployment.md). |
| `skills/omp-tuning/SKILL.md` | `~/.omp/agent/skills/omp-tuning/SKILL.md` | This document's procedures, as a skill: changing the OMP setup itself and verifying the change landed. |

The four Markdown files at the top are easy to confuse and behave completely
differently. The short version: `AGENTS.md` is *background* (once, at the top),
`RULES.md` is *law* (every turn, near the bottom), `WATCHDOG.md` is *for the
reviewer only*, and `APPEND_SYSTEM.md` is *an extra system-prompt block*.

Skills must sit exactly one level under `skills/`
(`skills/<name>/SKILL.md`). A grouping directory in between is not discovered.

## How the config reaches the agent

**Container.** One line in the `Dockerfile`, at build time:

```dockerfile
COPY --chown=$UID:$GID configs/omp/ .omp/agent/
```

The image ships the config; the container never clones this repo and never
fetches anything at start-up (invariant 1).

**Laptop.** `link_configs()` in `macos/setup.sh` creates **per-file** symlinks
into `~/.omp/agent/` — one entry per tracked file, plus the `agents/` and
`skills/` directories. The agent directory itself is never symlinked; see
[O1](#o1--the-agent-directory-is-not-symlinked-as-a-whole).

**`PI_CODING_AGENT_DIR` is not used anywhere, deliberately.** It relocates the
entire agent base — `config.yml`, the `agent.db` auth store, `sessions/`, all of
it. An earlier pass set it to `$HOME/dotfiles/configs/omp`. That path **does not
exist inside the container**, because the image never clones the repo, so the
agent silently fell back to creating a fresh directory with no config in it. The
default `~/.omp/agent` is already exactly where the `COPY` and the symlinks put
the files, so the variable buys nothing and costs a whole class of
environment-dependent failure. Print the directory actually in use with
`omp config path`.

## State and credentials

OMP writes its runtime state into the *same* directory as the config:

| Path | What it is |
|---|---|
| `agent.db` (+ `-wal`, `-shm`) | Auth store: OAuth sessions and API keys. |
| `history.db`, `models.db` | Prompt history and the model catalogue cache. |
| `sessions/`, `terminal-sessions/` | Session transcripts (JSONL) and subagent artifacts. |
| `last-changelog-version` | "Have I shown you the changelog" marker. |
| `.env` | Written by `mise run omp:auth`; see below. |

None of it is tracked — `.gitignore` excludes all of it. Only `sessions/` is
persisted across container recreation, by a named volume in `compose.yaml`:

```yaml
    volumes:
      - ompsessions:/home/dev/.omp/agent/sessions
```

The mount is on the **`sessions` subdirectory**, not on `~/.omp` or
`~/.omp/agent`, and that is the whole point — see
[O2](#o2--the-volume-mounts-sessions-not-the-agent-directory).

**Credentials are not baked into the image and are not in the repo.** They are
treated as disposable, exactly like `gh` auth: losing them costs a minute, not a
rebuild.

```bash
mise run omp:auth        # Synthetic API key: op read -> ~/.omp/agent/.env (chmod 600)
omp                      # then, inside the TUI:
/login anthropic         # interactive OAuth
/login google-antigravity
```

`omp:auth` reads `op://dotfiles/Synthetic/credential` and writes
`SYNTHETIC_API_KEY=…` into `~/.omp/agent/.env`, which is one of OMP's own `.env`
discovery locations. **Nothing is exported into the shell** (invariant 2) — the
value lives in a 0600 file that only OMP reads, in a directory that is already
gitignored. This is the same materialise-on-demand pattern as
`mise run kube:homelab`.

The two OAuth providers cannot be scripted; `/login` opens a browser flow and
stores the session in `agent.db`. After `docker compose down -v`, expect to run
`mise run omp:auth` and two `/login` calls. That is the accepted cost of not
having credentials in an image.

## Daily usage

### Magic keywords

Three standalone lowercase words in a prompt attach a hidden instruction to that
turn. They are cheap to type and expensive to run, so they are worth
understanding rather than sprinkling.

| Keyword | What it does | When it earns its cost |
|---|---|---|
| `ultrathink` | Selects the highest reasoning effort the current model supports for that turn. | A design decision with real consequences, a bug whose cause is not obvious, anything where being wrong is expensive. Not for "rename this variable". |
| `orchestrate` | Switches to the multi-agent contract: scope the whole task, delegate independent slices in parallel, verify each phase, continue until complete. | Work that genuinely decomposes into slices that can run at once. On a linear task it adds handoff latency and nothing else. |
| `workflowz` | Builds and runs a deterministic multi-subagent workflow with the `task` tool. | Broad coverage jobs: a repo-wide review, a migration, research across many sources. Requires the `task` tool to be available. |

Matching is deliberate: exact lowercase, standalone word. `Ultrathink`,
`orchestrated` and `orchestrate.ts` do not trigger, and code blocks are ignored,
so writing *about* the keywords in a prompt is safe.

### Slash commands

| Command | Effect |
|---|---|
| `/agents` | Agent Control Center: which agents were discovered, from where, and which model each resolves to. First stop when an agent misbehaves. |
| `/models` (alias of `/model`) | Switch the model for this session. |
| `/settings` | The settings panel. Writes land in the **global** `config.yml` — which on this setup is a symlink into the repo on macOS, so a change here is a repo change. |
| `/memory` | Inspect and run memory maintenance. |
| `/advisor` | Toggle the second reviewing model for this session. `/advisor status` shows its model, context and cost; `/advisor dump` copies its transcript. |
| `/compact` | Compact the context manually, rather than waiting for the automatic threshold. |
| `/fresh` | Resets the **provider-side** stream state and leaves the local transcript alone. The repair for a session that has started erroring mid-stream. |
| `/new` (alias `/clear`) | Starts a new session. The old one stays on disk. |
| `/drop` | Deletes the current session and starts a new one. Destructive — the transcript is gone. |
| `/fork` | Branches a new session from an earlier message, copying the artifact directory. Use it to try a second approach without losing the first. |
| `/resume` | Switch to a different existing session. From the shell: `omp -c` continues the last one, `omp -r` opens the picker. |
| `/collab` | Shares the live session over a relay; guests join with `omp join <token>` or in a browser and can prompt and interrupt. The host machine runs every tool. |
| `/share` | Publishes an end-to-end encrypted snapshot and prints a viewer link. |
| `/export [path]` | Writes the session to a self-contained HTML file, subagent transcripts included. |
| `/dump` | Copies the whole transcript — system prompt, tool definitions, thinking blocks — to the clipboard. The right tool for reporting a bad turn. |

### Keybindings

From `configs/omp/keybindings.yml`:

| Key | Action |
|---|---|
| `Alt+Shift+P` | Toggle plan mode |
| `Alt+P` | Pick a model for the next message only |
| `Ctrl+G` | Open the message in `$EDITOR` |
| `Ctrl+O` | Expand the last tool call |
| `Ctrl+T` | Cycle the thinking level |
| `Ctrl+Q` | Queue a follow-up message |
| `Alt+R` | Retry the last turn |

---

# Decision records

Same format as [00-architecture.md](00-architecture.md#decision-records): what
was decided, why, what was rejected.

## O1 — The agent directory is not symlinked as a whole

**Decision.** `macos/setup.sh` links each tracked file individually into
`~/.omp/agent/`. It never links `~/.omp/agent` -> `configs/omp`.

**Why.** OMP treats that directory as its working directory as well as its
config directory. It writes `agent.db`, `history.db` and `models.db` (SQLite,
each with `-wal` and `-shm` companions), a `sessions/` tree of JSONL
transcripts, and a `.env` holding a live API key. Linking the directory would
drop every one of those into this repo's working tree, where they would show up
as untracked churn in `git status` on every session and — for `.env` — sit one
careless `git add -A` away from a committed secret.

**Rejected: link the directory and gitignore the state.** It works right up
until OMP adds a new state file, which then appears untracked. An allowlist of
symlinks fails safe; a denylist of ignores fails open.

**Cost we accept:** adding a file to `configs/omp/` also means adding a line to
`link_configs()`. The loop warns and skips on a missing source, so a forgotten
entry is visible on the next `./macos/setup.sh --links-only` rather than silent.

## O2 — The volume mounts `sessions`, not the agent directory

**Decision.** `compose.yaml` mounts `ompsessions:/home/dev/.omp/agent/sessions`.

**Why.** This is [D6](00-architecture.md#d6--the-home-directory-is-not-one-big-volume)
applied one directory deeper. A volume on `~/.omp` or `~/.omp/agent` would
shadow everything the `COPY` put there: pull an image with an updated
`config.yml`, new agent definitions or a new skill, and you would still be
running last month's config, because the volume wins. The failure is silent —
nothing errors, the config just stops changing.

Session transcripts are the only thing in that directory that cannot be
rebuilt from the repo or recovered with a login, so they get the volume and
nothing else does.

**Rejected: persisting `agent.db` too, to survive re-auth.** It would save two
`/login` calls per rebuild, at the price of putting a credential store in a
Docker volume and re-introducing the shadowing risk on any future file that
lands beside it. Auth is disposable by design.

## O3 — `APPEND_SYSTEM.md`, not `SYSTEM.md`

**Decision.** Repo-specific system-prompt guidance goes in
`configs/omp/APPEND_SYSTEM.md`. There is no `SYSTEM.md`.

**Why.** They are not two flavours of the same thing. `SYSTEM.md` **replaces
prompt block 0** — the stable default instructions. Block 0 is also where OMP
injects the auto-generated material: the discovered skills list, the rulebook
summary, always-apply rules, and the tool inventory that tells the model which
tools exist and when to prefer each one. Replacing it would silently discard all
of that, and the skills in `configs/omp/skills/` would stop being offered at
all. `APPEND_SYSTEM.md` adds a block after the defaults and keeps everything.

**Rejected: `SYSTEM.md` with the generated sections copied in by hand.** They
would then be a frozen snapshot — a new skill would not appear until someone
remembered to paste it in. Automatic discovery is the feature.

**Note:** contents are inserted verbatim. Handlebars-looking syntax such as
`{{cwd}}` is *not* substituted; it reaches the model as literal text.

## O4 — Bundled agents are re-pointed by model override, not replaced

**Decision.** To change which model a bundled agent (`scout`, `sonic`, `task`,
`librarian`, `reviewer`, `designer`) runs on, add an entry to
`task.agentModelOverrides` in `config.yml`. Never create
`configs/omp/agents/<bundled-name>.md`.

**Why.** Agent discovery dedups by name, first-wins, with user and project files
ahead of bundled definitions. A file named `scout.md` does not *adjust* the
bundled `scout` — it **replaces the whole definition**, including its tuned
system prompt and its flags. `scout` ships with `blocking: true` and
`read-summarize: false`; a hand-written replacement that omits them changes the
agent's scheduling and its read behaviour, and nothing reports that anything was
lost. `task.agentModelOverrides` is resolved at spawn time and takes precedence
over frontmatter, so it changes the model and only the model.

A file in `configs/omp/agents/` is the right answer only for an agent that does
not exist upstream — `audit` and `docs` here.

**Rejected: `omp agents unpack` and editing the exported copies.** It produces
exactly the replacement files described above, and freezes them at today's
version: an upstream prompt improvement would never reach us.

## O5 — No `omp()` wrapper around `op run`

**Decision.** `omp` is invoked directly. Unlike `claude` and `kilocode`, it gets
no `opwith` wrapper in `.zshrc`.

**Why.** `configs/op-env/ai.env` sets `ANTHROPIC_BASE_URL=https://openrouter.ai/api`
and an `ANTHROPIC_AUTH_TOKEN`, which is correct for the tools that env file
exists for. Injected into OMP, it would **reroute the `anthropic` provider
through OpenRouter**, discarding the Anthropic OAuth session in `agent.db` — so
the architect role would silently start billing a different account through a
different endpoint with a different model list. The one credential OMP does need
from 1Password is delivered out of band by `mise run omp:auth`, which touches
nothing else.

**Rejected: a dedicated `configs/op-env/omp.env` with only `SYNTHETIC_API_KEY`.**
It would work, and it keeps the pattern uniform. It also means every `omp`
invocation pays a 1Password round-trip before the TUI appears, on a command
that is started dozens of times a day and is expected to be instant. Writing the
key once to a 0600 file that OMP reads natively costs one `mise` task and no
start-up latency. Revisit if OMP ever needs a second key.

---

## Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| Config changes have no effect | `omp` was started from a directory containing its own `.omp/config.yml`; project settings sit above global ones. | `cd` elsewhere, or reconcile the project file. `omp config get <key>` from that directory shows the effective value; `omp config path` shows the active agent directory. |
| One array setting "lost" its global values in a project | Arrays are **replaced** wholesale by the higher layer, never appended. Affects `disabledProviders`, `enabledModels`, `cycleOrder`, `extensions`, and every other array key. | List the complete desired set in the project file. |
| A model is not selectable although it is authenticated | `disabledProviders` is evaluated **before** credentials — a disabled id drops the provider regardless of any stored key, OAuth session or `.env` entry. | Remove the id from the effective `disabledProviders` (check the project layer too). If the list is clean, the provider is simply not authenticated: `mise run omp:auth` for Synthetic, `/login <provider>` for the OAuth ones. Restart the session if the model list was already built. |
| A Synthetic reasoning model returns empty content, no error | GLM-5.2 bills internal thinking against the same `max_tokens` budget as the answer. Thinking consumed all of it and nothing was left to emit. | Raise the output budget for that role, or lower its thinking level. A silent empty response is the signature. |
| A second Synthetic subagent appears to hang | One concurrent request per model per pack; the second call to the *same* model queues behind the first. | Put the two roles on different Synthetic models. Different models run fully in parallel. |
| Sessions vanished after an image upgrade | Only `ompsessions:/home/dev/.omp/agent/sessions` is persisted. Anything written elsewhere under `~/.omp` belongs to the image and is replaced on pull. | Nothing to recover. `/export` or `/share` anything worth keeping; treat `~/work` as the only durable location, per [D6](00-architecture.md#d6--the-home-directory-is-not-one-big-volume). |
| A custom agent does not appear in `/agents` | Its frontmatter is missing `name` or `description` — both are required, and the file is skipped with a warning rather than failing the session. | Add both fields. One bad file does not stop the others loading, which is why the omission is easy to miss. |
| A skill is never offered | The file is one level too deep. Discovery is non-recursive: `skills/<name>/SKILL.md` is found, `skills/<group>/<name>/SKILL.md` is not. Native discovery also *requires* `description`. | Flatten the directory and give the frontmatter a `description` that says when to use the skill. |
| A bundled agent lost `blocking: true` or its prompt | A file in `configs/omp/agents/` shares its name and replaced the definition wholesale. | Delete the file and set the model in `task.agentModelOverrides` instead — [O4](#o4--bundled-agents-are-re-pointed-by-model-override-not-replaced). |
| Auth is gone after `docker compose down -v` | `agent.db` is not persisted, on purpose. | `mise run omp:auth`, then `/login anthropic` and `/login google-antigravity`. About a minute. |
