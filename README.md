# gjc-acct

[English](README.md) | [한국어](README.ko.md)

A small launcher for selecting named subscription accounts in
**[Gajae-Code](https://github.com/Yeachan-Heo/gajae-code) (`gjc`)**.

It does not perform login itself. It connects login slots created by the sibling account
launchers to isolated gjc stores.

| Source | Slot manager | Slot root | Input read by gjc | gjc provider |
| --- | --- | --- | --- | --- |
| `claude` | [`claude-acct`](https://github.com/yazzang-homelab/claude-acct) | `~/.claude-accounts/<slot>` | `CLAUDE_CONFIG_DIR` | `anthropic` |
| `codex` | [`codex-acct`](https://github.com/yazzang-homelab/codex-acct) | `~/.codex-accounts/<slot>` | `CODEX_HOME` | `openai-codex` |

An account may bind multiple sources. Additional source types can be registered through
`GJC_ACCT_EXTRA_SOURCES`.

> **Unofficial third-party tool.** Not affiliated with, sponsored by, or endorsed by the
> Gajae-Code project or its author, [@Yeachan-Heo](https://github.com/Yeachan-Heo). Report
> launcher problems here, not to the Gajae-Code issue tracker.

```bash
gjc-acct sources                            # show source types and detected slots
gjc-acct bind work claude=team-a codex=2    # bind Claude and Codex slots to one account
gjc-acct work                               # launch gjc as "work"
gjc-acct                                    # launch the default account or show a picker
```

---

## Design principle: do not modify gjc

This launcher is intentionally thin because Gajae-Code already exposes almost everything it
needs through supported interfaces:

- **`GJC_CODING_AGENT_DIR`** selects the complete agent store, which is sufficient for
  per-account isolation.
- **`CLAUDE_CONFIG_DIR`, `CODEX_HOME`, and `gjc setup credentials`** provide the official
  import path for both Claude Code and Codex credentials. The importer also warns that OAuth
  refresh-token rotation may log the source CLI out.
- **Managed session scope** validates ownership, `0700` mode, ACLs, and no-follow traversal,
  and rejects symlink/junction session roots.
- **`--session-dir`** remains a documented operator-selected storage and lookup override,
  allowing an explicit shared-session mode without weakening gjc's managed default.

This repository does not patch or monkey-patch gjc. One temporary internal dependency remains
and is documented below as this project's technical debt.

---

## Intended use

This tool is for **one person switching between accounts they are authorized to use** on one
machine.

- Each slot authenticates with its own subscription.
- Only credentials from bound sources are isolated in the account store.
- Unbound providers, such as a corporate Copilot credential, are inherited from the base
  store.
- Configuration, skills, and commands are shared from the base store; only account identity
  is isolated.

It is not for pooling or rotating accounts to circumvent usage limits, or for sharing one
subscription between people. Limits remain attached to each seat and new usage is charged to
the account selected for that store.

---

## How isolation works

Each account receives its own gjc store at
`~/.gjc-accounts/<name>/agent`, selected through `GJC_CODING_AGENT_DIR`.

- `agent.db`, which contains credentials, is account-specific.
- `config.yml`, `models.yml`, `mcp.json`, `skills`, `commands`, and other non-credential
  configuration are symlinked from the base `~/.gjc/agent` store.
- Login slots remain the source of truth. All bound sources are imported in one official gjc
  command:

  ```bash
  GJC_CODING_AGENT_DIR=<account-store> \
  CLAUDE_CONFIG_DIR=<claude-slot> CODEX_HOME=<codex-slot> \
    gjc setup credentials --yes
  ```

Unbound source variables point to empty directories during import so unrelated credentials
cannot leak into an account store. Imports rerun only when a slot credential marker changes
size or modification time.

> **Relationship with `codex-acct`.** The public `codex-acct` manages only `CODEX_HOME`
> slots. It does not extract OAuth tokens or modify gjc's `.env` or `models.yml`. `gjc-acct`
> is the integration path that imports those slots into per-account `agent.db` stores.

### Binding accounts to slots

A slot whose name matches the account is bound automatically (`lee` → `claude=lee`). Use an
explicit binding when names differ or an account needs more than one source:

```bash
gjc-acct bind work claude=team-a codex=2   # saved to ~/.gjc-accounts/work/sources
gjc-acct unbind work codex
gjc-acct list
```

> **Refresh-token rotation.** When Claude Code or Codex CLI and gjc use the same slot, one
> application's refresh may invalidate the other's token. Log in again within that slot when
> this occurs.

### Temporary internal dependency

The official importer inserts credentials only when absent, so replacing a credential first
requires removing its existing row. The corresponding official command,
`gjc auth-broker logout <provider>`, exists in Gajae-Code 0.12.12 but is not registered by
`packages/coding-agent/src/cli.ts`; its argv is passed to chat instead. This is tracked in
[Yeachan-Heo/gajae-code#3975](https://github.com/Yeachan-Heo/gajae-code/issues/3975).

Until upstream registers the command, `gjc-acct` probes it once, caches the unavailable state,
and falls back to deleting only the matching provider row. This is the project's sole direct
dependency on gjc's internal database schema. The official path automatically takes priority
once it becomes available.

### Shared sessions via `--session-dir`

Account stores cannot share a symlinked `sessions` directory because gjc's managed session
scope correctly rejects reparse points. Instead, session-opening launches may receive an
explicit `--session-dir <shared-path>` override.

- Default shared root: `<base>/sessions`, configurable with `GJC_ACCT_SESSIONS_ROOT`.
- Sessions are separated by current working directory and shared between named accounts in
  the same directory.
- Management subcommands and invocations already containing `--session-dir` or `--no-session`
  are left unchanged.
- On Windows Git Bash, paths passed to `gjc.exe` are converted with `cygpath -m`.

> **Known limitation with gjc 0.12+.** Named accounts share sessions with one another, but
> not with a plain `gjc` invocation. Plain gjc uses a managed `sessions/v2-<digest>` directory,
> while this launcher uses its explicit path. Explicit session paths also sit outside managed
> scope's ACL and no-follow validation. Set `GJC_ACCT_NO_SESSION_SHARE=1` to retain gjc's
> managed per-account session scope instead.

---

## Install

> Requires `gjc` on `PATH` ([Gajae-Code installation](https://github.com/Yeachan-Heo/gajae-code):
> `bun install -g gajae-code`). Create login slots with `claude-acct` and/or `codex-acct`.

### Clone and install

```bash
git clone https://github.com/yazzang-homelab/gjc-acct.git
cd gjc-acct
./install.sh
```

### One-line installer

```bash
curl -fsSL https://raw.githubusercontent.com/yazzang-homelab/gjc-acct/main/install.sh \
  | GJC_ACCT_RAW_BASE=https://raw.githubusercontent.com/yazzang-homelab/gjc-acct/main bash
```

- Linux/macOS: installs `/usr/local/bin/gjc-acct` and the `gca` alias.
- Windows Git Bash: installs `~/.local/libexec/gjc-acct` and a `gjc-acct.cmd` wrapper.

---

## Usage

```text
gjc-acct                      launch the default account or show a picker
gjc-acct <name> [args…]       launch gjc with a named account
gjc-acct list|ls              list source bindings and isolated-store status
gjc-acct status               show source, slot, subscription, and limit-tier metadata
gjc-acct sources              list source types and detected slots
gjc-acct bind <name> <src>=<slot> [...]   bind slots manually
gjc-acct unbind <name> <src>  remove a binding
gjc-acct sync <name>          import slot credentials without launching gjc
gjc-acct reseed <name>        rebuild an account store from the base
gjc-acct default [name]       get or set the default account
gjc-acct dir <name>           print the account-store path
gjc-acct completion bash|zsh  print shell completion
```

### Environment variables

| Variable | Default | Purpose |
| --- | --- | --- |
| `GJC_ACCOUNTS_DIR` | `~/.gjc-accounts` | Root of isolated account stores |
| `GJC_BASE_AGENT_DIR` | `~/.gjc/agent` | Shared base agent store |
| `CLAUDE_ACCOUNTS_DIR` | `~/.claude-accounts` | `claude-acct` slot root |
| `CODEX_ACCOUNTS_DIR` | `~/.codex-accounts` | `codex-acct` slot root |
| `GJC_ACCT_EXTRA_SOURCES` | unset | Extra `key|root|env|marker|provider|tool` definitions, separated by `;` |
| `GJC_ACCT_SESSIONS_ROOT` | `<base>/sessions` | Shared session root |
| `GJC_ACCT_BIN` | `gjc` | gjc executable |
| `GJC_ACCT_NO_SESSION_SHARE` | unset | Set to `1` to keep gjc's managed per-account session scope |

---

## License and attribution

MIT — see [`LICENSE`](LICENSE). Upstream attribution and the distinction between public and
internal interfaces are documented in [`NOTICE.md`](NOTICE.md).
