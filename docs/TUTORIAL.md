# Loopwise 自动化评审实战教程

> 基于真实项目的计划评审过程
>
> 工具: Claude Code `/loopwise` slash command + OpenAI Codex CLI (GPT-5.4)

---

## 1. 什么是 Loopwise

Loopwise 是一个自动化评审工具，在 Claude Code 和 Codex 之间建立反馈循环：

```
Claude Code 写计划/代码 → Codex 评审 → Claude Code 修改 → Codex 再评审 → 循环直到通过
```

本质是让两个顶级 AI 模型（Claude Opus 4.6 + GPT-5.4）互相审查，产出质量显著高于单模型输出。

**适用场景：**
- 架构设计文档评审
- 重构计划可行性检查
- 代码实现审查
- 任何需要"第二双眼睛"的场景

**两种使用方式：**
- `/loopwise` — Claude Code 内的斜杠命令（推荐）
- `loopwise` — 独立 shell 命令

---

## 2. 安装与准备

### 2.1 安装斜杠命令（推荐方式）

```bash
git clone https://github.com/haohappy/loopwise.git
cp loopwise/.claude/commands/loopwise.md ~/.claude/commands/
```

安装后在任何 Claude Code 会话中即可使用 `/loopwise`。

### 2.2 安装独立命令（可选）

```bash
cd loopwise
./install.sh
```

### 2.3 安装 Codex CLI

```bash
npm install -g @openai/codex
codex --version
# codex-cli 0.117.0
```

### 2.4 确认可用模型

不同账号支持的模型不同：

| 模型 | ChatGPT 账号 | API 账号 |
|------|-------------|---------|
| o3 | 不支持 | 支持 |
| o4-mini | 不支持 | 支持 |
| gpt-5.4 | 支持 | 支持 |

如果遇到 `model is not supported` 错误，通过 `--model` 参数切换模型。

---

## 3. 基本用法

### 3.1 评审已有文件（最常用）

```
/loopwise plan --file docs/REFACTORING_PLAN.md
```

- `plan` — 评审模式（plan 或 code）
- `--file` — 指定要评审的文件路径

### 3.2 评审当前对话中刚写的内容

```
/loopwise plan
```

不传 `--file`，自动评审当前对话中最近产出的计划。

### 3.3 从 prompt 生成并评审

```
/loopwise plan Design a REST API for user management with JWT auth
```

Claude Code 先生成计划，然后自动送 Codex 评审。

### 3.4 评审代码

```
/loopwise code --file src/auth.ts
```

代码模式评审：正确性、性能、错误处理、可读性、安全性、测试覆盖。

### 3.5 可选参数

```
/loopwise plan --file docs/plan.md --max-rounds 5      # 限制最多 5 轮
/loopwise code --file src/auth.ts --model o3            # 指定 Codex 模型
/loopwise plan --file docs/plan.md --force              # 跳过历史检查，强制重新评审
```

---

## 4. 实战过程复盘

以下是使用 Loopwise 评审一个支付架构重构计划的完整过程。

### Round 1: 基础架构问题

**启动命令：**
```
/loopwise plan --file docs/REFACTORING_PLAN.md
```

**Codex 反馈（5 个问题）：**

| # | 严重度 | 问题 |
|---|--------|------|
| 1 | HIGH | Phase 1 只重构了 outbound，webhook/deposit 入口仍耦合 |
| 2 | HIGH | Wallet 唯一键设计有缺陷，同链多资产无法共存 |
| 3 | HIGH | Chain 枚举硬编码，缺迁移策略 |
| 4 | MEDIUM | 回填脚本缺过滤条件 |
| 5 | MEDIUM | 双写无崩溃恢复机制 |

**修改要点：** 新增抽象层、修复模型设计、添加迁移策略、改用 DB 事务。

> **关键洞察：** Round 1 的问题最有价值——它们是架构级缺陷，如果带到实现阶段才发现，修复成本是 10x。

### Round 2: 完整性与安全

**Codex 发现了 7 个问题**，包括遗漏的调用方、race condition、事务内 dispatch 不安全等。

> **关键洞察：** Codex 发现了 Claude 遗漏的调用方。单靠一个模型很难做到全量覆盖。

### Round 3: 运维与部署安全

**Codex 反馈 6 个问题**，全部转向运维层面：缺索引、缺并发控制、部署序列有 race condition 等。

> **关键洞察：** 到 Round 3，架构问题已全部解决，反馈转向"部署安全"——这是计划走向生产就绪的信号。

### Round 4-5: 一致性与实现细节

后续轮次的反馈逐渐聚焦在命名不一致、边界案例、幂等语义等实现级细节。

---

## 5. 评审轮次的规律

| 轮次 | 问题层级 | 典型问题 |
|------|---------|---------|
| **Round 1** | 架构级 | 缺失的抽象层、错误的耦合方向、模型设计缺陷 |
| **Round 2** | 完整性 | 遗漏的调用方、未考虑的路径、安全缺陷 |
| **Round 3** | 运维级 | 部署序列、索引、并发、监控 |
| **Round 4** | 一致性 | 文档内部不一致、边界条件、命名冲突 |
| **Round 5** | 实现级 | 幂等边界、重试语义、状态排序、恢复路径 |

> **结论：前 3 轮最有价值。** 如果你只能跑 3 轮，就跑 3 轮。后面的轮次回报递减但仍有帮助。

---

## 6. 输出产物

每次评审结束后，Loopwise 会自动生成：

### Review Report

根据模式生成不同文件名：
- Plan 模式 → `PLAN_REVIEW_REPORT.md`
- Code 模式 → `CODE_REVIEW_REPORT.md`

报告包含每轮的反馈摘要和修复情况，方便事后回溯。

### 评审历史

使用 `--file` 模式时，Loopwise 会在 `.loopwise/history.json` 中记录评审历史（基于文件内容的 SHA-256 哈希）。再次评审同一文件时：

- **文件未变 + 已通过** → 自动跳过，提示"文件未修改，之前已通过审查"
- **文件未变 + 上次未通过** → 提示可以继续上次的反馈
- **文件已变** → 正常开始新一轮 review
- **`--force`** → 跳过历史检查，强制重新评审

### 独立命令的产物

使用 `loopwise` 独立命令时，每次会话在 `.loopwise/` 下创建带时间戳的目录：

```
.loopwise/
  20260329_143022_12345/
    round_1_claude.md           # 初始生成
    round_2_codex_review.md     # 第一轮审查
    round_2_claude_revised.md   # 第一轮修改
    round_3_codex_review.md     # 第二轮审查
    final.md                    # 最终版本
    status.txt                  # APPROVED 或 MAX_ROUNDS_REACHED
```

---

## 7. 最佳实践

### 7.1 文件组织

把计划写成 Markdown 文件放到项目 `docs/` 目录。好处：
- 可以版本控制
- 每轮修改有 git diff
- 团队可以看到演进过程

### 7.2 模型选择

- **计划评审：** 用 `gpt-5.4`（默认，推理能力强）
- **代码评审：** 也用 `gpt-5.4`（能结合项目上下文）
- 切换模型：`/loopwise plan --model o3 --file docs/plan.md`

### 7.3 每轮只改 Codex 指出的问题

不要过度修改。每轮只针对反馈点改，否则：
- 可能引入新问题
- 难以追踪改了什么
- Codex 下一轮可能因为上下文变化给出不相关反馈

### 7.4 Commit 每轮结果

每轮 Codex 反馈修复后都 commit + push：

```bash
git commit -m "Refactoring plan v3: fix Codex round 2 feedback (7 issues)"
```

这样每个版本都有记录，团队可以 review 演进过程。

### 7.5 知道何时停止

- **APPROVED** — Codex 通过，可以开工
- **Round 3-4 反馈进入操作细节** — 架构已稳，可以开工
- **Round 5 仍有架构级问题** — 可能需要重新思考方向

> 对于复杂系统，不要追求 APPROVED——追求的是"反馈层级从架构降到实现"。

---

## 8. 常见问题

### Q: Codex 总是给反馈不给 APPROVED，是不是永远通不过？

Codex 的指令是"有任何建议就不要说 APPROVED"。对于复杂系统计划，这意味着它会持续找到细节问题。关注反馈的层级变化比关注是否 APPROVED 更重要。

### Q: Codex 反馈和 Claude 的判断冲突怎么办？

以你的工程判断为准。Codex 的反馈是建议，不是命令。有些反馈可能过度设计，可以记录但暂不实施。

### Q: plan 和 code 模式有什么区别？

- `plan` 模式评审：完整性、可行性、边界案例、架构、安全
- `code` 模式评审：正确性、性能、错误处理、可读性、安全、测试

### Q: 模型报错 "not supported" 怎么办？

换模型。`gpt-5.4` 兼容性最好，是默认选择。

### Q: 重复评审同一个没改过的文件会浪费 token 吗？

不会。Loopwise 会基于文件内容哈希自动检测，如果文件未变且上次已通过，会跳过评审。用 `--force` 可以强制重新评审。

---

## 9. 快速参考

```bash
# 评审已有计划文档
/loopwise plan --file docs/my-plan.md

# 评审已有代码文件
/loopwise code --file src/auth.ts

# 生成计划并评审
/loopwise plan Design a caching layer for the API

# 生成代码并评审
/loopwise code Implement rate limiter middleware

# 评审当前对话中刚写的内容
/loopwise plan
/loopwise code

# 限制轮数
/loopwise plan --file docs/plan.md --max-rounds 3

# 指定模型
/loopwise code --file src/auth.ts --model o3

# 强制重新评审
/loopwise plan --file docs/plan.md --force
```

---

## 10. 评审成果示例

| 指标 | 数值 |
|------|------|
| 评审轮次 | 5 |
| 发现问题总数 | 36 |
| 已修复 | 26（前 4 轮） |
| 记录待实现 | 10（第 5 轮） |
| 文档行数增长 | 942 行 → 1600+ 行 |
| 新增附录 | 11 个 |
| Codex 最终评价 | "direction is good...sound choices" |

> 两个 AI 互相审查的价值在于：Claude 擅长生成完整方案，Codex 擅长挑出遗漏和边界问题。组合使用的覆盖率远超单模型。
