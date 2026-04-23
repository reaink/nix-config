# Unified NixOS & nix-darwin Configuration

Personal configuration管理 NixOS（桌面）和 macOS（笔记本），共享开发环境和工具链。

## 特性

- **统一管理**: 单一 flake 管理 Linux 和 macOS 系统配置
- **模块化架构**: 按主机、共享模块、用户配置分层组织
- **跨平台 Home Manager**: 80% 配置共享，平台差异隔离
- **桌面环境**: KDE Plasma 6 with Wayland（NixOS）
- **密钥管理**: sops-nix with age 加密（NixOS）
- **开发工具**: Rust、Node.js、Python 完整工具链
- **输入法**: fcitx5（Linux）、Rime 输入法配置（跨平台）

## 快速开始

### NixOS

```bash
# 首次应用配置
sudo nixos-rebuild switch --flake ~/nix-config#nixos

# 测试配置（不切换 boot entry）
sudo nixos-rebuild test --flake ~/nix-config#nixos

# 更新 flake inputs
nix flake update
```

### macOS

```bash
# 首次应用配置
darwin-rebuild switch --flake ~/nix-config#mac

# 检查配置
darwin-rebuild check --flake ~/nix-config#mac
```

### 快捷命令（已配置 Zsh 别名）

```bash
rebuild      # 重新构建并切换系统配置
test         # 测试配置（NixOS）
gc           # 垃圾回收
clean        # 深度清理 + 优化存储
flake-update # 更新 flake 依赖
```

## 项目结构

```
nix-config/
├── flake.nix                 # 统一 flake 入口（NixOS + Darwin）
├── flake.lock                # 依赖版本锁定
│
├── hosts/                    # 主机特定配置
│   ├── nixos/                # NixOS 桌面
│   │   ├── default.nix       # 主机入口
│   │   ├── configuration.nix # 系统配置（硬件、桌面、服务）
│   │   ├── hardware-configuration.nix
│   │   └── sunshine.nix      # 自定义模块
│   └── mac/                  # macOS 笔记本
│       └── default.nix       # Darwin 系统配置
│
├── modules/                  # 跨平台共享模块
│   ├── nix-settings.nix      # Nix 配置（镜像源、GC、实验性功能）
│   └── locale.nix            # 时区和区域设置
│
├── overlays/                 # 自定义包覆盖层
│   ├── vscode-latest.nix     # VSCode 最新版本自动获取
│   └── README.md             # 覆盖层文档
│
├── home/                     # Home Manager 用户配置
│   └── rea/
│       ├── default.nix       # 用户入口（条件导入）
│       ├── common.nix        # 跨平台配置（CLI、开发工具、Zsh、Git）
│       ├── linux.nix         # Linux 特有（GTK/Qt 主题、KDE、游戏）
│       └── darwin.nix        # macOS 特有（最小配置）
│
├── secrets/                  # SOPS 加密密钥（NixOS）
│   └── secrets.yaml
│
├── update-vscode-hash.sh     # VSCode 版本更新脚本
│
└── shells
    └── rust-shell.nix
```

## 配置共享策略

### 完全共享（`modules/` 和 `home/rea/common.nix`）
- Nix 核心设置（镜像源、缓存、GC）
- 开发工具链（Rust、Node.js、Python、CLI 工具）
- 跨平台 GUI（VSCode Latest、Chrome、Telegram、Obsidian）
- Shell 配置（Zsh 插件、别名、工具集成）
- Git 配置

### 自定义包（`overlays/`）
- **VSCode Latest**: 自动从官方获取最新稳定版本
  - 运行 `./update-vscode-hash.sh` 更新到最新版本
  - 详见 `overlays/README.md`

### 平台隔离
- **NixOS 特有** (`hosts/nixos/` + `home/rea/linux.nix`):
  - 硬件驱动（NVIDIA、AMD 混合显卡）
  - KDE Plasma 6 桌面环境
  - 游戏支持（Steam、Sunshine 串流）
  - 虚拟化（libvirt、Docker）
  - GTK/Qt 主题、Fontconfig

- **macOS 特有** (`hosts/mac/` + `home/rea/darwin.nix`):
  - Nix daemon 配置
  - 未来：Homebrew 集成、macOS 系统设置

## 系统信息

### NixOS 桌面
- **用户**: rea
- **主机名**: nixos
- **架构**: x86_64-linux
- **内核**: Linux latest
- **CPU**: AMD Ryzen 9 9950X（Zen 5，16 核 32 线程）
- **GPU 1**: NVIDIA RTX 4070 Super（discrete，12GB VRAM）
- **GPU 2**: AMD Radeon 890M（integrated，RDNA 3.5，PRIME Sync 模式下由 NVIDIA 主渲染）
- **内存**: 64GB
- **桌面**: KDE Plasma 6 (Wayland)

### macOS 笔记本
- **用户**: rea
- **主机名**: mac
- **架构**: aarch64-darwin (Apple Silicon)
- **芯片**: M4 Pro（16 核 CPU，20 核 GPU），24GB 统一内存

## Open WebUI + llama.cpp 本地 AI 配置

open-webui 作为 NixOS 系统服务运行，通过 OpenAI 兼容 API 连接 llama.cpp 推理后端。

### 架构

```
llama-server（llama-cpp）→ OpenAI 兼容 API → open-webui（浏览器访问）
```

### 访问地址

rebuild 后 open-webui 自动启动：[http://localhost:11111](http://localhost:11111)

### 启动推理后端（NixOS）

```bash
# 基本启动（CPU）
llama-server -m /path/to/model.gguf

# GPU 加速（RTX 4070 Super，推荐）
llama-server -m /path/to/model.gguf \
  --n-gpu-layers 99 \         # 将所有层卸载到 GPU
  --port 8081                  # 默认 8080，与 open-webui 冲突时修改

# Ryzen 9950X（Zen 5，AVX-512 优化，CPU 推理）
llama-server -m /path/to/model.gguf \
  --threads 16                 # 9950X 有 32 线程，建议留一半给系统
```

### 在 open-webui 中添加 llama.cpp 连接

1. 打开 [http://localhost:8080](http://localhost:8080)
2. Settings → Connections → OpenAI API
3. URL 填 `http://localhost:8081/v1`（llama-server 的端口）
4. API Key 填任意字符串（如 `none`）
5. 点击保存，模型列表会自动出现

### macOS（M4 Pro）

llama-cpp 在 aarch64-darwin 上**自动启用 Metal**，直接运行：

```bash
llama-server -m /path/to/model.gguf --n-gpu-layers 99
```

open-webui 在 macOS 上不作为系统服务，可用 Homebrew 或 Docker 单独安装，或直接使用浏览器访问 NixOS 机器的 open-webui。

## 密钥管理（NixOS）

使用 [sops-nix](https://github.com/Mic92/sops-nix) 管理 PostgreSQL 密码等敏感信息。

### 关键文件
- `secrets/secrets.yaml` - 加密的密钥文件
- `/home/rea/.config/sops/age/keys.txt` - Age 私钥 ⚠️ **务必备份**

### 编辑密钥
```bash
EDITOR=nvim sops secrets/secrets.yaml
sudo nixos-rebuild switch --flake .#nixos
```

详见 `PASSWORD_MANAGEMENT.md`。

## 添加新主机

1. 在 `hosts/` 下创建新目录（如 `hosts/nixos-laptop/`）
2. 复制 `hosts/nixos/default.nix` 作为模板
3. 修改主机特定配置
4. 在 `flake.nix` 添加新的 `nixosConfigurations` 或 `darwinConfigurations` 条目

## 维护命令

```bash
# 更新系统
rebuild              # 使用别名
# 或完整命令：
sudo nixos-rebuild switch --flake .#nixos      # NixOS
darwin-rebuild switch --flake .#mac           # macOS

# 更新依赖
nix flake update

# 垃圾回收
sudo nix-collect-garbage -d           # NixOS
nix-collect-garbage -d                # macOS

# 存储优化
sudo nix-store --optimize             # NixOS
nix-store --optimize                  # macOS

# 查看历史版本
sudo nix-env --list-generations --profile /nix/var/nix/profiles/system  # NixOS
nix-env --list-generations --profile /nix/var/nix/profiles/system       # macOS

# 回滚系统
sudo nixos-rebuild switch --rollback  # NixOS
darwin-rebuild switch --rollback      # macOS
```

## 故障排查

### NixOS 配置问题
```bash
# 检查 flake 语法
nix flake check

# 试运行（不实际应用）
sudo nixos-rebuild dry-build --flake .#nixos

# 查看详细日志
sudo nixos-rebuild switch --flake .#nixos --show-trace
```

### macOS 首次应用
如果 Darwin 配置首次失败，可能需要：
```bash
# 确保 nix-daemon 已启动
sudo launchctl load -w /Library/LaunchDaemons/org.nixos.nix-daemon.plist

# 检查权限
sudo chown -R $(whoami) /nix/var/nix/profiles/per-user/$(whoami)
```
