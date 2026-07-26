# 本地 Claude Code 多 Claude 账号与 Session 隔离调研

- 调研日期：2026-07-26
- 本机平台：macOS arm64
- 本机 Claude Code：`2.1.220 (Claude Code)`
- 调研范围：Claude Code CLI；账号均采用 Claude.ai/Claude subscription 浏览器 OAuth 登录，不讨论 API key 轮换
- 操作约束：全程未执行登录、登出、凭据写入或用户配置修改。仅查看 CLI help、官方文档/仓库，并在 `/tmp` 下用空配置目录做只读状态探测。

## 结论先行

当前最方便、也有官方文档背书的做法是：**每个额外 Claude 账号固定一个 `CLAUDE_CONFIG_DIR`，再用 shell function 或 alias 暴露成不同命令**。本机使用 `cc` 进入默认账号、`cc2` 进入第二账号；以后所有启动、`auth status`、`--continue`、`--resume`、插件和后台 agent 命令都始终走对应入口。

针对这台机器，默认 `~/.claude` 已经登录，不需要搬迁或重新登录：`cc` 清除 `CLAUDE_CONFIG_DIR` 后使用默认存储规则，只有 `cc2` 固定使用 `~/.claude-2`。

本机最终采用更短的命令名：`cc` 清除 profile 目录覆盖后使用现有默认账号；`cc2` 固定使用 `~/.claude-2`。两者都保留原有的 `--dangerously-skip-permissions` 启动参数。

这能隔离：

- 账号登录状态和账号元数据
- 用户级 settings、hooks、skills、agents、plugins、personal MCP 配置
- 每个项目的本地 conversation transcript、prompt history、file history、auto memory、task state
- macOS 上当前版本使用的 Keychain 凭据查询命名空间

但它**不隔离**：

- 仓库内的 `CLAUDE.md`、`.claude/settings.json`、`.claude/settings.local.json`、`.mcp.json` 等项目级文件
- 同一个工作目录里的源码、未提交修改和 Git index
- 系统/企业下发的 managed settings
- Claude Desktop、Claude Code on the web、VS Code extension 各自维护的独立 session/history surface

所以：

1. 只想把不同账号和历史分开：固定 config-dir wrapper 足够。
2. 两个账号要同时改同一仓库：在 config-dir wrapper 之外，再使用不同 Git worktree 或不同 clone。
3. 需要包括应用、浏览器、Keychain、项目文件在内的强隔离：使用不同 macOS 用户账户最稳，但便利性明显较差。

## 1. 当前登录、登出、状态命令

本机 `claude --help` 与 `claude auth ... --help` 显示：

```text
claude auth login [--claudeai] [--console] [--email <email>] [--sso]
claude auth logout
claude auth status [--json] [--text]
```

- `claude auth login` 默认走 Claude subscription；`--claudeai` 可以显式说明意图。
- `--email` 只是给网页登录页预填邮箱，不是账号强绑定或校验。
- `--console` 是 Anthropic Console/API usage billing，不符合本次“都是 Claude 账户登录”的目标。
- `claude auth status` 默认 JSON，也支持 `--text`；官方说明已登录返回退出码 `0`，未登录返回 `1`。
- 交互会话里也可用 `/login`、`/logout`、`/status`。

官方 CLI reference：[CLI reference](https://code.claude.com/docs/en/cli-usage)。官方认证流程：[Authentication](https://code.claude.com/docs/en/team)。

本机 `2.1.220` 的 `auth status --json` 字段包括：

```text
loggedIn
authMethod
apiProvider
email
orgId
orgName
subscriptionType
```

因此初始化后可以用以下命令核对是否登录到了正确账号，而不必发起模型请求：

```bash
cc2 auth status --text
cc auth status --text
```

## 2. 是否有官方 multi-profile/account 功能

### 有“隔离机制”，没有“一等 profile UX”

截至本机 `2.1.220`：

- `claude --help` 没有 `--profile`、`--account` 参数。
- `claude` 没有 `profile list/switch` 子命令。
- 官方 CLI reference 也没有 named profile 管理命令。
- 官方仓库中的 named profile 功能请求仍是 open：[Support for multiple accounts / profiles #24963](https://github.com/anthropics/claude-code/issues/24963)。该 issue 是用户请求/行为讨论，不是官方规格。

不过，官方环境变量文档已经明确把 `CLAUDE_CONFIG_DIR` 描述为：覆盖默认 `~/.claude` 配置目录，保存 settings、session history、plugins；Linux/Windows 的 credentials 也在其中；并明确给出“multiple accounts side by side”的 alias 示例。见 [Environment variables](https://code.claude.com/docs/en/env-vars)。

所以准确表述是：

> Claude Code 目前没有原生 named profile 切换器，但官方支持用固定的 `CLAUDE_CONFIG_DIR` 手工建立多个隔离 profile。

## 3. 配置、凭据和 Session 存储位置

### 3.1 默认与自定义目录

官方文档列出的主要用户级数据如下：[Explore the .claude directory](https://code.claude.com/docs/en/claude-directory)。

| 数据 | 默认位置 | 设置 `CLAUDE_CONFIG_DIR=/path/profile` 后 | 是否按账号 profile 隔离 |
|---|---|---|---|
| 用户 settings | `~/.claude/settings.json` | `/path/profile/settings.json` | 是 |
| App state、账号元数据、personal MCP、UI 状态 | `~/.claude.json` | 当前 CLI 使用 `/path/profile/.claude.json` | 是 |
| Session transcripts | `~/.claude/projects/<project>/<session-id>.jsonl` | `/path/profile/projects/...` | 是 |
| Prompt history | `~/.claude/history.jsonl` | `/path/profile/history.jsonl` | 是 |
| File snapshots | `~/.claude/file-history/` | `/path/profile/file-history/` | 是 |
| Auto memory | `~/.claude/projects/<project>/memory/` | `/path/profile/projects/.../memory/` | 是 |
| Plugins | `~/.claude/plugins/` | `/path/profile/plugins/` | 是 |
| Linux/Windows OAuth credentials | `~/.claude/.credentials.json` | `/path/profile/.credentials.json` | 是 |
| macOS OAuth credentials | macOS login Keychain | 仍在 Keychain，但当前 CLI 按 config dir 使用不同 service namespace | 当前 `2.1.220` 是 |

官方特别提醒，transcript、history、tool output 等是明文文件，依赖操作系统文件权限保护；工具读取的文件内容、命令输出甚至误打印的 secret 都可能进入 transcript。见 [Application data and plaintext storage](https://code.claude.com/docs/en/claude-directory)。因此建议 profile 目录权限至少为仅本人可访问：

```bash
mkdir -m 700 "$HOME/.claude-2"
```

首次启动时 Claude Code 也会自行创建缺失目录；提前创建主要是为了明确权限和路径。

### 3.2 `CLAUDE_CONFIG_DIR` 不覆盖的内容

`CLAUDE_CONFIG_DIR` 替换的是用户级 `~/.claude` 数据根，不会把项目级文件搬走。以下仍从当前仓库/工作目录读取：

```text
CLAUDE.md
CLAUDE.local.md
.claude/settings.json
.claude/settings.local.json
.claude/rules/
.claude/skills/
.claude/agents/
.mcp.json
.worktreeinclude
```

官方目录文档明确区分了 project scope 和 global scope：[Explore the .claude directory](https://code.claude.com/docs/en/claude-directory)。这意味着两个账号从同一 checkout 启动时：

- 会共享项目指令和 tracked project settings；这是团队配置的预期行为。
- 也会看到同一份 `.claude/settings.local.json`，即使它通常被 gitignore；若其中包含个人权限/路径偏好，就不算强隔离。
- 会操作同一批源码文件和同一 Git working tree。

系统/企业 managed settings 的路径由 OS/管理策略决定，优先级高于用户配置，也不受 `CLAUDE_CONFIG_DIR` 控制。

## 4. macOS Keychain 是否随 config dir 隔离

### 4.1 官方文档层面的答案

官方认证文档说 macOS 凭据存放在 encrypted macOS Keychain，而 Linux/Windows 使用 `.credentials.json`；官方环境变量文档同时把 `CLAUDE_CONFIG_DIR` 推荐为多账号并行方案：[Authentication / credential management](https://code.claude.com/docs/en/team)、[Environment variables](https://code.claude.com/docs/en/env-vars)。

文档没有公开 Keychain item 的具体命名算法，因此仅靠文档无法判断它是一个全局 singleton，还是 Keychain 内按 config dir namespaced。

### 4.2 本机 `2.1.220` 只读验证

本次用一个临时 `security` shim 记录 Claude Code 发给 macOS `/usr/bin/security` 的**参数名**，然后原样转发给真实命令。没有输出或保存 password/token，也没有执行 login/logout。

默认配置目录的查询：

```text
find-generic-password -a <mac-user> -w -s Claude Code-credentials
find-generic-password -a <mac-user> -w -s Claude Code
```

自定义 config dir A 的查询：

```text
Claude Code-credentials-beabbcd8
Claude Code-beabbcd8
```

同一个 config dir A 重复运行得到相同后缀；另一个 config dir B 得到不同后缀：

```text
Claude Code-credentials-80a52d4a
Claude Code-80a52d4a
```

这里的后缀只是临时路径对应的观测值，不应写死或手工管理。

只读 `auth status` 也验证了：默认 profile 已登录时，一个全新的 custom config dir 返回 `loggedIn: false`，不会直接吃到默认 profile 的登录状态。

因此，对**当前本机 Claude Code `2.1.220`**，结论是：

> 凭据物理上仍在同一个 macOS login Keychain，但 Claude Code 按 `CLAUDE_CONFIG_DIR` 使用不同 Keychain service namespace；不同固定 config dir 可以各自登录，并能同时启动。

### 4.3 与旧 issue 的冲突如何理解

官方仓库 open issue [#24963](https://github.com/anthropics/claude-code/issues/24963) 的部分用户评论曾声称 macOS Keychain 是全局 singleton、`CLAUDE_CONFIG_DIR` 无法隔离。那是用户在旧版本上的行为报告，不是官方保证；它与当前 `2.1.220` 的实际 Keychain 查询不一致。

另一个官方仓库 issue [#20553](https://github.com/anthropics/claude-code/issues/20553) 的用户评论记录称，namespacing 在 `2.1.56` 已出现，并观察到 config-dir path hash 后缀；这与本机 `2.1.220` 的结果吻合，但 issue/comment 同样只作为版本行为证据，不视为稳定 API。

官方仓库还有要求文档化内部变量 `CLAUDE_SECURESTORAGE_CONFIG_DIR` 的 open issue [#79223](https://github.com/anthropics/claude-code/issues/79223)。该变量目前不在官方环境变量 reference 中，而且即使只改变 secure-storage namespace，也不能同时隔离 settings、plugins 和 sessions。本案不应依赖它；直接使用已文档化的 `CLAUDE_CONFIG_DIR` 即可覆盖完整目标。

建议：

- 以当前官方文档和当前安装版本的 `auth status` 为准。
- 升级 Claude Code 后，先分别执行两个 profile 的 `auth status --text` 再开始工作。
- 不要用 `security delete-generic-password`、token swapper 或手工复制 Keychain password；这些方案容易删错、覆盖 refresh token，并且已经没有必要。
- config dir 的绝对路径要固定。当前 Keychain service 后缀明显与 config dir 相关；移动/改名、混用 symlink 或不同路径拼写，可能让 CLI 看起来像“未登录”，需要重新认证。

## 5. Session 如何识别、恢复和隔离

官方 Session 文档说明：一个 session 是“绑定到 project directory 的已保存 conversation”，transcript 路径为：

```text
~/.claude/projects/<project>/<session-id>.jsonl
```

`<project>` 由 working directory path 派生。设置 `CLAUDE_CONFIG_DIR` 后，整个 session root 随 profile 改变。见 [Manage sessions](https://code.claude.com/docs/en/sessions)。

命令行为：

| 命令 | 行为 |
|---|---|
| `claude --continue` / `claude -c` | 恢复当前目录最近一次 session |
| `claude --resume` / `claude -r` | 打开 session picker |
| `claude --resume <name-or-id>` | 按 session name 或 UUID 恢复 |
| `claude --continue --fork-session` | 从最近 session 分叉出新 session ID，原 session 不变 |
| `claude --resume <id> --fork-session` | 从指定 session 分叉 |
| `claude -n <name>` | 启动时命名 session，便于后续恢复 |

在多账号 wrapper 下，实际效果是：

```bash
cc2 -c
```

只会在 work config dir 的 session history 里找“当前目录最近 session”；

```bash
cc -c
```

只会在默认 config dir 里找。即使 working directory 相同，两边 transcript root 也不同，所以 conversation 不会串。

`--resume` picker 默认从当前 worktree 的 session 开始，可扩展到同仓库所有 worktree或本机所有 project；但它能看到的是**当前 config dir 中保存的数据**。另一个账号 profile 的 transcript 不在该 root 下，不会自然出现。

重要并发风险：官方文档明确说，如果在两个终端恢复同一个 session 且不 fork，两个终端的消息会写进同一个 transcript、相互交错。需要并行尝试时使用 `--fork-session`。见 [Manage sessions / Branch a session](https://code.claude.com/docs/en/sessions)。

## 6. 推荐可执行方案

### 6.1 用 Zsh aliases 固定账号入口

这台机器的 Zsh 由 Home Manager 管理，配置位于 `home/rea/common.nix`：

```nix
shellAliases = {
  cc = "env -u CLAUDE_CONFIG_DIR -u CLAUDE_SECURESTORAGE_CONFIG_DIR claude --dangerously-skip-permissions";
  cc2 = "env -u CLAUDE_SECURESTORAGE_CONFIG_DIR CLAUDE_CONFIG_DIR=$HOME/.claude-2 claude --dangerously-skip-permissions";
};
```

默认账号必须让 `CLAUDE_CONFIG_DIR` 保持 unset。显式设置为 `"$HOME/.claude"` 会让当前 Claude Code 在 `~/.claude/.claude.json` 查找另一套状态，导致现有默认登录显示为未登录。`cc2` 则固定使用独立的 `~/.claude-2` 数据根。两条 alias 都清除未文档化的 `CLAUDE_SECURESTORAGE_CONFIG_DIR`，防止外部环境把凭据指向错误 profile。

官方认证优先级仍会让 cloud provider、`ANTHROPIC_AUTH_TOKEN`、`ANTHROPIC_API_KEY`、`apiKeyHelper`、`CLAUDE_CODE_OAUTH_TOKEN` 排在 `/login` subscription OAuth 前面。见 [Authentication precedence](https://code.claude.com/docs/en/team)。本机当前没有这些覆盖变量；若以后使用，应为相应认证方式建立单独、明确命名的入口。

### 6.2 初始化两个账号

```bash
mkdir -p -m 700 "$HOME/.claude-2"
chmod 700 "$HOME/.claude-2"

cc auth status --text
cc2 auth login --claudeai --email second@example.com

cc auth status --text
cc2 auth status --text
```

首次 OAuth 时：

- `--email` 只是预填，仍要确认浏览器里实际选中的 Claude 账号。
- 最稳妥是分别用对应 Chrome/Safari profile 完成授权；若自动打开了错误 profile，可在 CLI 登录界面按 `c` 复制 OAuth URL，再粘到正确 browser profile。
- 以 `auth status --text` 显示的 email、organization、subscription type 作为最终校验。

### 6.3 日常使用

```bash
cd /path/to/project

cc2 -n second-auth-refactor
cc2 -c
cc2 --resume second-auth-refactor

cc -n primary-experiment
cc -c
```

必须坚持“所有命令都走 wrapper”，包括：

```bash
cc2 auth status --text
cc2 auth logout
cc2 plugin list
cc2 agents
cc2 --resume
```

裸跑 `claude` 会回到默认 `~/.claude`（这里也就是 `primary` profile），但为了让账号选择显式可见，日常仍建议使用 wrapper。

### 6.4 同时改同一个仓库时加 worktree

config dir 只隔离 Claude 状态，不隔离文件。两个 Claude 进程在同一个 checkout 中同时编辑，仍可能覆盖文件、互相看到未提交修改或争用 Git index。

官方推荐用 `--worktree` 启动隔离 checkout：[Run parallel sessions with worktrees](https://code.claude.com/docs/en/worktrees)。

```bash
cd /path/to/repo

cc2 --worktree second-auth-fix
cc --worktree primary-experiment
```

worktree name应包含账号/任务前缀，避免两个 profile 都请求同一个 `.claude/worktrees/<name>` 路径。第一次在某个 profile 对仓库使用 `--worktree` 前，先普通启动一次并完成该 profile 的 workspace trust 确认。

若项目不是 Git repo，或者希望把 untracked secrets、dependency caches、project-local `.claude/settings.local.json` 也完全分开，使用不同 clone/目录更直观。

## 7. 风险清单

### 高优先级

1. **启动错 wrapper**：裸 `claude`、错误 terminal tab 或脚本绕过 wrapper，会进入错误 profile。每个 profile 初始和升级后运行 `auth status --text`。
2. **上位凭据覆盖 OAuth**：`ANTHROPIC_API_KEY` 等环境变量优先级高于网页登录。检查 shell profile、direnv、IDE launch environment。
3. **同一 checkout 并发编辑**：session 隔离不等于文件隔离。并行写代码必须使用 worktree/clone。
4. **同一 session 被双重 resume**：同 profile 下两个终端 resume 同一 session 会交错写 transcript；使用 `--fork-session`。

### 中优先级

5. **项目级配置仍共享**：尤其 `.claude/settings.local.json`、`.mcp.json` 和 repo `CLAUDE.md`。需要严格分离时使用不同 worktree/clone。
6. **profile 路径漂移**：改名、移动、symlink、相对路径可能改变 macOS Keychain namespace。使用固定绝对路径。
7. **插件/skills 重复管理**：每个 config dir 的用户级 plugins、skills、hooks 是独立副本。优点是安全隔离，代价是要分别安装/更新。
8. **transcript 明文**：账号分开不等于磁盘加密。目录权限设为 `0700`，不要让工具读取或打印 secrets。

### Surface 边界

9. **Terminal wrapper 不自动控制 GUI**：Claude Desktop、web、VS Code extension 各自维护 session history。官方 Session 文档明确区分这些 surface。shell alias/function 只保证从该 shell 启动的 CLI 进程。
10. **旧 issue/博客可能已过时**：特别是“macOS Keychain 永远只有一个全局 Claude Code credential”这一结论，与本机 `2.1.220` 的 namespaced 查询不符。

## 8. 方案对比

| 方案 | 便利性 | OAuth 隔离 | Session/配置隔离 | 文件隔离 | 建议 |
|---|---:|---:|---:|---:|---|
| 每次 logout/login | 低 | 只有当前账号 | 否 | 否 | 不建议 |
| 固定 `CLAUDE_CONFIG_DIR` aliases | 高 | 是，当前 macOS `2.1.220` 已 namespaced | 是，用户级状态完整分离 | 否 | 默认推荐 |
| aliases + Git worktrees | 中高 | 是 | 是 | 是 | 并行开发推荐 |
| 不同 clone + aliases | 中 | 是 | 是 | 是，最直观 | 非 Git worktree 场景 |
| 不同 macOS 用户 | 低 | 最强 | 最强 | 取决于 repo 放置 | 合规/强隔离兜底 |
| 手工 Keychain token swapper | 很低且危险 | 脆弱 | 不完整 | 否 | 不建议 |

## 9. 一手来源

1. Anthropic Claude Code Docs — [Environment variables](https://code.claude.com/docs/en/env-vars)：`CLAUDE_CONFIG_DIR` 的官方定义与 multi-account alias 示例。
2. Anthropic Claude Code Docs — [Authentication](https://code.claude.com/docs/en/team)：登录方式、macOS Keychain、Linux/Windows `.credentials.json`、认证优先级。
3. Anthropic Claude Code Docs — [CLI reference](https://code.claude.com/docs/en/cli-usage)：`auth login/logout/status`、`--continue`、`--resume`。
4. Anthropic Claude Code Docs — [Manage sessions](https://code.claude.com/docs/en/sessions)：project-directory session identity、picker、fork、transcript 路径。
5. Anthropic Claude Code Docs — [Explore the .claude directory](https://code.claude.com/docs/en/claude-directory)：global/project scope、application data、plaintext transcript。
6. Anthropic Claude Code Docs — [Run parallel sessions with worktrees](https://code.claude.com/docs/en/worktrees)：文件编辑隔离与 `--worktree`。
7. Anthropic official GitHub — [Feature request #24963](https://github.com/anthropics/claude-code/issues/24963)：截至调研日仍 open 的 named profile 请求；仅作为功能状态/历史行为讨论，不作为官方规格。
8. Anthropic official GitHub — [Issue #20553](https://github.com/anthropics/claude-code/issues/20553)：用户评论中的 `2.1.56` namespacing 行为记录；仅作为历史行为证据。
9. Anthropic official GitHub — [Docs issue #79223](https://github.com/anthropics/claude-code/issues/79223)：未文档化 secure-storage 变量的讨论，用于说明为什么不应采用该内部变量。
10. 本机 Claude Code `2.1.220` 自带 `--help` 与只读 Keychain command trace：用于确认当前命令面、无 `--profile`，以及 custom config dir 的 Keychain service namespacing。

## 最终建议

采用“**默认账号清除 config-dir 覆盖 + 额外账号固定 config dir + 显式 shell alias**”，首次分别登录并核对 `auth status`。日常使用 `cc` 或 `cc2`，不要裸跑 `claude`。如果两个账号会同时处理同一个仓库，再给每个 session 使用唯一命名的 `--worktree`。这是目前在便利性、可恢复 session、配置隔离和 macOS OAuth 安全之间最平衡的方案。
