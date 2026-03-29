# cc-review

Automated review loop between Claude Code and Codex CLI.

Claude Code generates plans or code, Codex reviews them, feedback flows back to Claude Code automatically, and the cycle repeats until Codex approves.

## How it works

```
┌─────────────┐     plan/code      ┌─────────────┐
│ Claude Code  │ ─────────────────→ │   Codex     │
│  (generate)  │                    │  (review)   │
│              │ ←───────────────── │             │
│  (revise)    │     feedback       │             │
└─────────────┘                    └─────────────┘
       ↑                                  │
       └──── loop until APPROVED ─────────┘
```

Each round:
1. Claude Code produces output (plan or code) via `claude -p`
2. Codex reviews it via `codex exec` against quality criteria
3. If Codex says APPROVED, the loop ends
4. Otherwise, feedback goes back to Claude Code for revision (using `--resume` to preserve context)
5. Repeat until approved or max rounds reached

## Prerequisites

```bash
npm install -g @anthropic-ai/claude-code   # Claude Code CLI
npm install -g @openai/codex               # Codex CLI
brew install jq                            # JSON processor
```

## Install

```bash
git clone https://github.com/anthropics/multi-agent-loop.git
cd multi-agent-loop

# Option A: install to /usr/local/bin
./install.sh

# Option B: install to custom path
./install.sh ~/bin

# Option C: run directly
chmod +x cc-review.sh
./cc-review.sh --help
```

## Usage

```bash
# Generate and review a development plan
cc-review plan "Build a REST API for user management with JWT auth"

# Generate and review code
cc-review code "Implement a rate limiter middleware for Express"

# Review an existing plan file
cc-review plan --file docs/plan.md

# Review an existing code file with specific instructions
cc-review code --file src/auth.ts "Refactor to use passport.js"

# More review rounds with verbose output
cc-review plan --max-rounds 10 --verbose "Design a real-time notification system"
```

## Configuration

Configure via CLI flags or environment variables:

| Flag | Environment Variable | Default | Description |
|---|---|---|---|
| `--max-rounds` | `CC_REVIEW_MAX_ROUNDS` | 5 | Maximum review cycles |
| `--claude-model` | `CC_REVIEW_CLAUDE_MODEL` | *(default)* | Claude model override |
| `--codex-model` | `CC_REVIEW_CODEX_MODEL` | o3 | Codex model for reviews |
| `--output-dir` | `CC_REVIEW_OUTPUT_DIR` | .cc-review | Session output directory |
| `--timeout` | `CC_REVIEW_TIMEOUT` | 300 | Timeout per CLI call (seconds) |
| `--verbose` | `CC_REVIEW_VERBOSE` | false | Show debug output |

You can also copy the config template to your home directory:

```bash
cp .cc-review.conf.example ~/.cc-review.conf
```

## Output

Each session creates a timestamped directory under `.cc-review/`:

```
.cc-review/
  20260329_143022_12345/
    round_1_claude.md           # Initial generation
    round_2_codex_review.md     # First review
    round_2_claude_revised.md   # First revision
    round_3_codex_review.md     # Second review
    final.md                    # Final version
    status.txt                  # APPROVED or MAX_ROUNDS_REACHED
```

## Tips

- **Plan reviews**: give detailed requirements so Claude Code produces a thorough plan and Codex has enough context to evaluate it.
- **Code reviews**: use `--file` to point at a specific file for focused review.
- **Strictness**: edit the review prompts in `cc-review.sh` to tune Codex's review criteria. Make them stricter (`"only approve if there are zero issues"`) or more lenient (`"approve if the approach is fundamentally sound"`).
- **Cost control**: use `CC_REVIEW_CODEX_MODEL=gpt-4.1-mini` or `CC_REVIEW_MAX_ROUNDS=3` to reduce API costs during experimentation.

## License

MIT
