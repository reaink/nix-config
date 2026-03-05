{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:

{
  # ─────────────────────────────────────────────
  #  OpenCode global configuration (home-manager)
  #  All files land in ~/.config/opencode/
  # ─────────────────────────────────────────────

  # ── Main runtime config ──────────────────────
  xdg.configFile."opencode/opencode.json".text = builtins.toJSON {
    "$schema" = "https://opencode.ai/config.json";

    autoupdate = true;

    # Context compaction
    compaction = {
      auto = true;
      prune = true;
      reserved = 12000;
    };

    # File watcher: ignore noisy dirs
    watcher.ignore = [
      "node_modules/**"
      "dist/**"
      ".git/**"
      "target/**"
      ".direnv/**"
      "result/**"
    ];

    # Permission defaults: bash 和 webfetch 操作前询问，edit 直接允许
    permission = {
      bash = "ask";
      edit = "allow";
      webfetch = "allow";
    };

    # Custom agents
    agent = {
      # Override built-in build agent: add custom system prompt
      build = {
        model = "github-copilot/claude-sonnet-4.6";
        prompt = "{file:prompts/build.md}";
        permission = {
          bash = {
            "*" = "ask";
            # Safe read-only commands: auto-allow
            "git status*" = "allow";
            "git log*" = "allow";
            "git diff*" = "allow";
            "git show*" = "allow";
            "ls*" = "allow";
            "cat*" = "allow";
            "echo*" = "allow";
            "which*" = "allow";
            "type *" = "allow";
            "pwd" = "allow";
            "env*" = "allow";
            "rg *" = "allow";
            "fd *" = "allow";
            "find *" = "allow";
            "grep *" = "allow";
          };
        };
      };

      # Override built-in plan agent
      plan = {
        model = "github-copilot/claude-sonnet-4.6";
        temperature = 0.1;
      };

      # Code review subagent (read-only)
      review = {
        description = "Reviews code for quality, bugs, security and best practices without making changes";
        mode = "subagent";
        temperature = 0.1;
        tools = {
          write = false;
          edit = false;
          patch = false;
          bash = false;
        };
      };

      # Debug / investigation subagent
      debug = {
        description = "Investigates bugs by reading logs, traces, and source code. Suggests fixes without applying them.";
        mode = "subagent";
        temperature = 0.2;
        tools = {
          write = false;
          edit = false;
          patch = false;
        };
        permission.bash = {
          "*" = "ask";
          "git *" = "allow";
          "rg *" = "allow";
          "grep *" = "allow";
          "cat *" = "allow";
          "ls *" = "allow";
        };
      };

      # Documentation writer subagent
      docs = {
        description = "Writes and maintains project documentation. Never modifies source code.";
        mode = "subagent";
        temperature = 0.4;
        tools = {
          bash = false;
        };
      };
    };

    # Custom slash commands
    command = {
      # /review — review current diff with read-only plan agent
      review = {
        description = "Review staged/unstaged changes for quality and issues";
        agent = "review";
        subtask = true;
        template = ''
          Please review the following changes:
          !`git diff HEAD`

          Focus on:
          - Correctness and logic bugs
          - Security vulnerabilities
          - Performance implications
          - Code style and maintainability
          - Missing error handling

          Be concise and actionable. Group findings by severity: Critical / Warning / Suggestion.
        '';
      };

      # /commit — generate a conventional commit message
      commit = {
        description = "Generate a conventional commit message for staged changes";
        agent = "build";
        template = ''
          Generate a conventional commit message for the following staged changes:
          !`git diff --cached`

          Rules:
          - Use conventional commits format: <type>(<scope>): <description>
          - Types: feat, fix, docs, style, refactor, perf, test, chore, ci, build
          - Keep subject line under 72 characters
          - Add a short body if the change needs explanation
          - Do NOT include "Co-authored-by" or any AI attribution
          - Output ONLY the commit message, nothing else
        '';
      };

      # /explain — explain what a piece of code does
      explain = {
        description = "Explain the current codebase or a specific area";
        agent = "review";
        subtask = true;
        template = ''
          Explain the following in clear, concise language suitable for a developer
          who is new to this codebase: $ARGUMENTS

          Include:
          - High-level purpose
          - Key data flows
          - Important design decisions
          - Anything non-obvious
        '';
      };

      # /test — run tests and analyse failures
      test = {
        description = "Run tests and analyse any failures";
        agent = "build";
        template = ''
          Run the project's test suite and report results.

          1. Detect the test command from package.json / Makefile / Cargo.toml / etc.
          2. Run it.
          3. For any failures: explain the root cause and suggest a minimal fix.
          4. Do NOT modify test files unless explicitly asked.
        '';
      };

      # /nix-rebuild — rebuild NixOS and report errors
      nix-rebuild = {
        description = "Rebuild NixOS configuration and fix any errors";
        agent = "build";
        template = ''
          Run the NixOS rebuild command and handle any errors:

          !`sudo nixos-rebuild switch --flake ~/nix-config#nixos 2>&1 | tail -50`

          If there are errors:
          1. Identify the root cause
          2. Locate the relevant nix file(s)
          3. Apply minimal fixes
          4. Re-run the rebuild to confirm it succeeds
        '';
      };
    };

    mcp = { };
  };

  # ── TUI config ───────────────────────────────
  xdg.configFile."opencode/tui.json".text = builtins.toJSON {
    "$schema" = "https://opencode.ai/tui.json";

    theme = "catppuccin-mocha";

    # Smooth scrolling
    scroll_speed = 3;
    scroll_acceleration.enabled = true;

    diff_style = "auto";
  };

  # ── Global AGENTS.md (system prompt / rules) ─
  xdg.configFile."opencode/AGENTS.md".source = ./opencode/AGENTS.md;

  # ── Build agent system prompt ─────────────────
  xdg.configFile."opencode/prompts/build.md".source = ./opencode/prompts/build.md;

  # ── Official skills via `npx skills` CLI ──────────────────────────────
  # Installed to ~/.agents/skills/; OpenCode reads them via ~/.claude/skills/ symlink.
  # Runs once per activation; re-runs only when the skill list changes.
  home.activation.opencodeSkills = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    export PATH="${pkgs.nodejs}/bin:${pkgs.git}/bin:$PATH"
    export HOME="$HOME"

    install_skill() {
      local repo="$1" name="$2"
      local dest="$HOME/.agents/skills/$name"
      if [ ! -d "$dest" ]; then
        $DRY_RUN_CMD ${pkgs.nodejs}/bin/npx --yes skills add "$repo" --global --yes 2>&1 || true
      fi
    }

    # Ensure ~/.claude/skills -> ~/.agents/skills symlink exists
    if [ ! -L "$HOME/.claude/skills" ] && [ ! -d "$HOME/.claude/skills" ]; then
      $DRY_RUN_CMD mkdir -p "$HOME/.claude"
      $DRY_RUN_CMD ln -s "$HOME/.agents/skills" "$HOME/.claude/skills"
    fi

    install_skill "vercel-labs/agent-skills/packages/vercel-react-best-practices" "vercel-react-best-practices"
    install_skill "vercel-labs/agent-skills/packages/web-design-guidelines"        "web-design-guidelines"
    install_skill "github/awesome-copilot/skills/conventional-commit"              "conventional-commit"
  '';
}
