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
1. Claude Code produces output (plan or code)
2. Codex reviews it via `codex exec` against quality criteria
3. If Codex says APPROVED, the loop ends
4. Otherwise, feedback goes back to Claude Code for revision
5. Repeat until approved or max rounds reached

## Prerequisites

```bash
npm install -g @anthropic-ai/claude-code   # Claude Code CLI
npm install -g @openai/codex               # Codex CLI
brew install jq                            # JSON processor (for standalone mode)
```

## Two ways to use

### Option 1: Slash command inside Claude Code (recommended)

Use `/codex-review` directly within a Claude Code session. No extra install needed — just copy the command file:

```bash
# Install the slash command (one-time setup)
cp .claude/commands/codex-review.md ~/.claude/commands/

# Or clone and copy
git clone https://github.com/haohappy/multi-agent-loop.git
cp multi-agent-loop/.claude/commands/codex-review.md ~/.claude/commands/
```

Then inside any Claude Code session:

```
# Generate from prompt, then review loop
> /codex-review plan Design a REST API for user management with JWT auth
> /codex-review code Implement a rate limiter middleware for Express

# Review an existing file
> /codex-review plan --file docs/plan.md
> /codex-review code --file src/auth.ts

# Review an existing file with additional instructions
> /codex-review plan --file docs/plan.md Add error handling details
> /codex-review code --file src/auth.ts Refactor to use middleware pattern

# Review what you just wrote in this conversation (no args)
> /codex-review plan
> /codex-review code
```

This is the most convenient way — Claude Code drives the loop directly, calling Codex for review, reading feedback, and revising in-session. No separate process needed.

### Option 2: Standalone shell command

Run from any terminal as an independent process:

```bash
# Install
git clone https://github.com/haohappy/multi-agent-loop.git
cd multi-agent-loop
./install.sh            # installs to /usr/local/bin
# or: ./install.sh ~/bin

# Usage
cc-review plan "Build a REST API for user management with JWT auth"
cc-review code "Implement a rate limiter middleware for Express"
cc-review plan --file docs/plan.md
cc-review code --file src/auth.ts "Refactor to use passport.js"
cc-review plan --max-rounds 10 --verbose "Design a real-time notification system"
```

## Default models

- **Claude Code**: Claude Opus 4.6 (used for plan/code generation and revision)
- **Codex**: GPT-5.4 (used for review)

## Configuration

Configure via CLI flags or environment variables:

| Flag | Environment Variable | Default | Description |
|---|---|---|---|
| `--max-rounds` | `CC_REVIEW_MAX_ROUNDS` | *(unlimited)* | Maximum review cycles (0 = no limit) |
| `--claude-model` | `CC_REVIEW_CLAUDE_MODEL` | Claude Opus 4.6 | Claude model for generation |
| `--codex-model` | `CC_REVIEW_CODEX_MODEL` | GPT-5.4 | Codex model for reviews |
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

---

# cc-review（中文）

Claude Code 与 Codex CLI 之间的自动化 review 循环。

Claude Code 生成计划或代码，Codex 自动审查，反馈回传给 Claude Code 进行修改，循环往复直到 Codex 批准通过。

## 工作原理

```
┌─────────────┐    计划/代码       ┌─────────────┐
│ Claude Code  │ ─────────────────→ │   Codex     │
│  （生成）     │                    │  （审查）    │
│              │ ←───────────────── │             │
│  （修改）     │      反馈          │             │
└─────────────┘                    └─────────────┘
       ↑                                  │
       └──── 循环直到 APPROVED ───────────┘
```

每一轮：
1. Claude Code 生成输出（计划或代码）
2. Codex 通过 `codex exec` 按质量标准审查
3. 如果 Codex 输出 APPROVED，循环结束
4. 否则，反馈回传给 Claude Code 进行修改
5. 重复直到通过或达到最大轮数

## 前置要求

```bash
npm install -g @anthropic-ai/claude-code   # Claude Code CLI
npm install -g @openai/codex               # Codex CLI
brew install jq                            # JSON 处理器（独立模式需要）
```

## 两种使用方式

### 方式一：在 Claude Code 内使用斜杠命令（推荐）

在任何 Claude Code 会话中直接使用 `/codex-review`，只需复制命令文件即可：

```bash
# 安装斜杠命令（一次性设置）
cp .claude/commands/codex-review.md ~/.claude/commands/

# 或者克隆后复制
git clone https://github.com/haohappy/multi-agent-loop.git
cp multi-agent-loop/.claude/commands/codex-review.md ~/.claude/commands/
```

然后在 Claude Code 会话中：

```
# 从 prompt 生成，然后进入 review 循环
> /codex-review plan Design a REST API for user management with JWT auth
> /codex-review code Implement a rate limiter middleware for Express

# 审查已有文件
> /codex-review plan --file docs/plan.md
> /codex-review code --file src/auth.ts

# 审查已有文件并附加指令
> /codex-review plan --file docs/plan.md 补充错误处理细节
> /codex-review code --file src/auth.ts 重构为中间件模式

# 审查当前对话中刚写的内容（不传参数）
> /codex-review plan
> /codex-review code
```

这是最方便的方式 — Claude Code 直接在当前会话中驱动循环，调用 Codex 审查、读取反馈、就地修改，无需额外进程。

### 方式二：独立 shell 命令

从终端作为独立进程运行：

```bash
# 安装
git clone https://github.com/haohappy/multi-agent-loop.git
cd multi-agent-loop
./install.sh            # 安装到 /usr/local/bin
# 或: ./install.sh ~/bin

# 使用
cc-review plan "构建一个带 JWT 认证的用户管理 REST API"
cc-review code "实现一个 Express 限流中间件"
cc-review plan --file docs/plan.md
cc-review code --file src/auth.ts "重构为使用 passport.js"
cc-review plan --max-rounds 10 --verbose "设计一个实时通知系统"
```

## 默认模型

- **Claude Code**：Claude Opus 4.6（用于计划/代码生成和修改）
- **Codex**：GPT-5.4（用于审查）

## 配置

通过 CLI 参数或环境变量配置：

| 参数 | 环境变量 | 默认值 | 说明 |
|---|---|---|---|
| `--max-rounds` | `CC_REVIEW_MAX_ROUNDS` | *（无限制）* | 最大 review 轮数（0 = 不限） |
| `--claude-model` | `CC_REVIEW_CLAUDE_MODEL` | Claude Opus 4.6 | Claude 生成模型 |
| `--codex-model` | `CC_REVIEW_CODEX_MODEL` | GPT-5.4 | Codex 审查模型 |
| `--output-dir` | `CC_REVIEW_OUTPUT_DIR` | .cc-review | 会话产物目录 |
| `--timeout` | `CC_REVIEW_TIMEOUT` | 300 | 每次 CLI 调用超时（秒） |
| `--verbose` | `CC_REVIEW_VERBOSE` | false | 显示调试输出 |

## 产物输出

每次会话在 `.cc-review/` 下创建一个带时间戳的目录：

```
.cc-review/
  20260329_143022_12345/
    round_1_claude.md           # 初始生成
    round_2_codex_review.md     # 第一轮审查
    round_2_claude_revised.md   # 第一轮修改
    round_3_codex_review.md     # 第二轮审查
    final.md                    # 最终版本
    status.txt                  # APPROVED 或 MAX_ROUNDS_REACHED
```

## Review 历史

使用 `--file` 审查文件时，工具会基于文件内容的 SHA-256 哈希自动追踪 review 历史（`.cc-review/history.json`）：

- **文件未变 + 已通过** → 自动跳过，提示"文件未修改，之前已通过审查"
- **文件未变 + 上次未通过** → 提示可以继续上次的反馈，或重新开始
- **文件已变** → 正常开始新一轮 review
- **强制重新审查**：使用 `--force` 跳过历史检查

## 使用建议

- **计划审查**：提供详细的需求描述，让 Claude Code 生成完整的计划，Codex 才有足够的上下文进行评估。
- **代码审查**：使用 `--file` 指向具体文件，进行聚焦审查。
- **审查严格度**：编辑 `cc-review.sh` 中的 review prompt 来调节 Codex 的审查标准。可以更严格（"只有完全没有问题才能通过"）或更宽松（"整体方案合理即可通过"）。
- **成本控制**：使用 `CC_REVIEW_CODEX_MODEL=gpt-4.1-mini` 或 `CC_REVIEW_MAX_ROUNDS=3` 来降低实验阶段的 API 开销。
