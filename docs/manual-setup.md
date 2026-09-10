# Manual setup, updates, and removal

Use this route when your company distributes software centrally or you prefer to review each change. These instructions describe the intended setup; the initial integration is awaiting pilot validation.

## Install the executable

Use Microsoft tgrep **1.0.5** for the initial pilot. Obtain the Windows archive for your operating system from the [official release](https://github.com/microsoft/tgrep/releases/tag/v1.0.5), or use your company's approved copy of that same version.

| Windows architecture | Archive | SHA-256 |
| --- | --- | --- |
| x64 | `tgrep-v1.0.5-x86_64-pc-windows-msvc.zip` | `5b6ba08ffddb5bc1b436c5c83b4f0c9e66c70a006b3853ed57daf51e7a75986c` |
| ARM64 | `tgrep-v1.0.5-aarch64-pc-windows-msvc.zip` | `f49b68f97810530688a8fe71282dfc384ed4ff99ffe7a8a769e43e68a7c633fe` |

The digests come from the official GitHub release metadata. Check a downloaded archive with `Get-FileHash -Algorithm SHA256 -LiteralPath '<downloaded-archive>'` before extracting it. Replace angle-bracket placeholders with your actual paths.

Extract `tgrep.exe` to a stable directory and add that directory to your **user PATH**, or have IT provide it on PATH. The supplied installer uses `%LOCALAPPDATA%\Programs\copilot-tgrep\1.0.5`. Restart Visual Studio after changing PATH. If an existing installation is managed by IT, keep that arrangement and copy only the skill and instruction below.

## Install the skill and default instruction

1. Create `%USERPROFILE%\.copilot\skills\tgrep-search\`.
2. Copy [SKILL.md](../.github/skills/tgrep-search/SKILL.md) into that folder, keeping the exact uppercase filename `SKILL.md`.
3. Copy [THIRD_PARTY_NOTICES.md](../THIRD_PARTY_NOTICES.md) into the same folder.
4. Back up `%USERPROFILE%\copilot-instructions.md` if it exists. Add the full contents of [copilot-tgrep.md](../instructions/copilot-tgrep.md), including its start/end markers. Create the file if absent. If the marked section already exists, replace that section instead of adding a duplicate. Keep everything outside it unchanged.
5. In Visual Studio 2026 18.5+, enable custom instructions and use Copilot's **Agent** mode with the terminal tool available.

The skill is then available for all projects opened by that Windows user. Copying only `AGENTS.md` from the Microsoft repository is not this setup. A `SKILL.md` in an arbitrary download folder is not a global installation either.

### A repository-scoped alternative

For teams that want configuration to travel with each source repository, copy the skill and its notice to `<repository>\.github\skills\tgrep-search\`. Merge the default instruction into that repository's `.github\copilot-instructions.md`, changing the final fallback path to `.github/skills/tgrep-search/SKILL.md`.

Commit those files through the team's usual process. Do not add them to a `.csproj` or `.sln` just for discovery. Executable installation remains a per-machine/user prerequisite. Choose either this route or a personal skill installation for the same workflow to avoid conflicting duplicate versions.

## Update

Get a reviewed revision of this repository. Compare the default instruction and skill changes, then rerun setup or replace the same files manually. The current installer pins tgrep 1.0.5; pulling the repository does not authorize or trigger an arbitrary latest-version update. Maintainers change that pin only after the validation plan has been completed for a candidate release.

The setup script preserves unrelated instruction content and records previous files and the original user PATH in the backup directory it prints. Retain that location until the pilot succeeds. Review project instructions for conflicting search preferences rather than deleting them.

## Remove or roll back

1. Close Visual Studio before changing the setup. If a tgrep server was started for a pilot, identify the process and its repository before stopping it. Do not stop all tgrep processes indiscriminately; a server can be shared by multiple clients.
2. Remove only the section between `<!-- copilot-tgrep-search:start -->` and `<!-- copilot-tgrep-search:end -->` from the personal instruction file. Preserve unrelated content and any edits made since installation.
3. Remove the installed `tgrep-search` skill and notice if you no longer need them, or restore their preceding copies from the printed backup directory. Do not delete unrelated files in a shared skills directory.
4. Remove this setup's executable directory from user PATH if it is no longer used. Remove the executable only when no other workflow depends on it. Existing tgrep installations are separate.
5. To undo an installation, consult its recovery manifest and file backups. Restore the recorded PATH wholesale only if no unrelated PATH changes have occurred since; otherwise remove just this setup's entry.
6. Restart Visual Studio. Index folders belong to their source repositories and are not deleted by removing the skill.

## Troubleshooting

| Symptom | Check |
| --- | --- |
| Skill is not activated | Use Agent mode and Visual Studio 18.5+. Check its name/path and duplicate installations. Explicitly request `tgrep-search` and inspect the chat activation. |
| Default preference is missing | Check custom instructions are enabled and that the marked section exists in the intended user or repository instruction file. |
| `tgrep` is not found | Restart Visual Studio and check PATH inside its terminal. An already-running IDE retains its earlier environment. |
| Search repeatedly reports no index | Keep the positional root at the indexed repository root; narrow with globs. A nested search directory does not discover the parent index. |
| Search misses a recent change | Check saved editor contents, initial indexing, exclusions, and the skill's direct-scan rules. `Indexing: complete` alone does not establish freshness. |
| Setup is blocked by script/network policy | Use IT distribution or manual file placement. Do not weaken policy to complete setup. |

See [Microsoft's skill documentation](https://learn.microsoft.com/en-us/visualstudio/ide/copilot-agent-skills?view=visualstudio) and [custom-instruction documentation](https://learn.microsoft.com/en-us/visualstudio/ide/copilot-chat-context?view=visualstudio) for the supported discovery mechanisms.
