{
  pkgs,
  lib,
  ...
}:

let
  # eagle.nvim is not yet in nixpkgs; build directly from GitHub.
  # To update: run `nix-prefetch-url --unpack https://github.com/soulis-1256/eagle.nvim/archive/<rev>.tar.gz`
  eagle-nvim = pkgs.vimUtils.buildVimPlugin {
    pname = "eagle-nvim";
    version = "unstable-2025-02-13";
    src = pkgs.fetchFromGitHub {
      owner = "soulis-1256";
      repo = "eagle.nvim";
      rev = "d503b168932160b07d4d09551d90d5fbb388b641";
      hash = "sha256-Gug086B7EQ8qX6vKChnbjC5R2GroeqPuj3RWcbYOI9A=";
    };
  };
in
{
  programs.nixvim = {
    enable = true;

    # ─── Global options ─────────────────────────────────────────────────────
    globals = {
      mapleader = " ";
      maplocalleader = ",";
    };

    opts = {
      relativenumber = true;
      number = true;
      spell = false;
      signcolumn = "yes";
      wrap = false;
      cursorcolumn = true;
      # Tab / indent
      tabstop = 2;
      shiftwidth = 2;
      expandtab = true;
      # Search
      ignorecase = true;
      smartcase = true;
      # Splits
      splitbelow = true;
      splitright = true;
      # Misc
      scrolloff = 8;
      timeoutlen = 300;
      updatetime = 250;
      termguicolors = true;
      autoread = true; # needed for opencode.nvim
    };

    # ─── Colorscheme: catppuccin-mocha ──────────────────────────────────────
    colorschemes.catppuccin = {
      enable = true;
      settings = {
        flavour = "mocha";
        integrations = {
          blink_cmp = true;
          gitsigns = true;
          indent_blankline.enabled = true;
          mini.enabled = true;
          neo_tree = true;
          snacks = true;
          treesitter = true;
          which_key = true;
        };
      };
    };

    # ─── Extra packages injected into nvim's PATH wrapper ───────────────────
    extraPackages = with pkgs; [
      lsof
      fd
      tree-sitter
      sqlite
      stylua
      shfmt
      shellcheck
      nodePackages.prettier
      ruff
    ];

    # ─── Plugins ─────────────────────────────────────────────────────────────

    plugins = {

      # ── Web devicons ─────────────────────────────────────────────────────
      web-devicons.enable = true;

      # ── Completion: blink.cmp ────────────────────────────────────────────
      blink-cmp = {
        enable = true;
        settings = {
          keymap.preset = "default";
          appearance = {
            use_nvim_cmp_as_default = true;
            nerd_font_variant = "mono";
          };
          sources.default = [
            "lsp"
            "path"
            "snippets"
            "buffer"
          ];
          signature.enabled = true;
        };
      };

      # ── LSP ─────────────────────────────────────────────────────────────
      lsp = {
        enable = true;
        inlayHints = false; # default off; toggle with <Leader>uH

        servers = {
          # Lua
          lua_ls = {
            enable = true;
            settings.Lua.hint.enable = true;
          };

          # TypeScript / JavaScript
          vtsls = {
            enable = true;
            settings = {
              typescript.inlayHints = {
                parameterNames.enabled = "literals";
                parameterTypes.enabled = true;
                variableTypes.enabled = true;
                propertyDeclarationTypes.enabled = true;
                functionLikeReturnTypes.enabled = true;
                enumMemberValues.enabled = true;
              };
              javascript.inlayHints = {
                parameterNames.enabled = "literals";
                parameterTypes.enabled = true;
                variableTypes.enabled = true;
                propertyDeclarationTypes.enabled = true;
                functionLikeReturnTypes.enabled = true;
                enumMemberValues.enabled = true;
              };
            };
          };

          # Python
          basedpyright.enable = true;

          # Prisma — prisma-language-server is a top-level nixpkgs package, not nodePackages
          prismals = {
            enable = true;
            package = pkgs.prisma-language-server;
          };

          # Markdown
          marksman.enable = true;

          # JSON
          jsonls.enable = true;

          # HTML
          html.enable = true;

          # CSS
          cssls.enable = true;

          # Emmet
          emmet_language_server = {
            enable = true;
            filetypes = [
              "css"
              "eruby"
              "html"
              "javascript"
              "javascriptreact"
              "less"
              "sass"
              "scss"
              "pug"
              "typescriptreact"
            ];
            extraOptions = {
              init_options = {
                showAbbreviationSuggestions = true;
                showExpandedAbbreviation = "always";
                showSuggestionsAsSnippets = false;
              };
            };
          };

          # Docker
          dockerls.enable = true;
          docker_compose_language_service.enable = true;

          # Bash
          bashls.enable = true;

          # TailwindCSS
          tailwindcss.enable = true;

          # YAML
          yamlls.enable = true;

          # TOML
          taplo.enable = true;

          # Vue
          volar.enable = true;

          # GraphQL
          graphql.enable = true;
        };

        onAttach = ''
          -- Refresh codelens on insert-leave / buf-enter
          if client.supports_method("textDocument/codeLens") then
            vim.lsp.codelens.refresh({ bufnr = bufnr })
            vim.api.nvim_create_autocmd({ "InsertLeave", "BufEnter" }, {
              buffer = bufnr,
              callback = function()
                vim.lsp.codelens.refresh({ bufnr = bufnr })
              end,
            })
          end
        '';
      };

      # ── Rust: rustaceanvim (manages rust_analyzer) ───────────────────────
      rustaceanvim = {
        enable = true;
        settings.server = {
          settings."rust-analyzer".check.command = "clippy";
        };
      };

      # ── Formatting: conform.nvim ─────────────────────────────────────────
      conform-nvim = {
        enable = true;
        settings = {
          format_on_save = {
            timeout_ms = 1000;
            lsp_format = "fallback";
          };
          formatters_by_ft = {
            lua = [ "stylua" ];
            python = [
              "ruff_fix"
              "ruff_format"
            ];
            javascript = [ "prettier" ];
            javascriptreact = [ "prettier" ];
            typescript = [ "prettier" ];
            typescriptreact = [ "prettier" ];
            css = [ "prettier" ];
            scss = [ "prettier" ];
            html = [ "prettier" ];
            json = [ "prettier" ];
            jsonc = [ "prettier" ];
            yaml = [ "prettier" ];
            markdown = [ "prettier" ];
            vue = [ "prettier" ];
            sh = [ "shfmt" ];
            bash = [ "shfmt" ];
          };
        };
      };

      # ── Treesitter ───────────────────────────────────────────────────────
      treesitter = {
        enable = true;
        settings = {
          highlight.enable = true;
          indent.enable = true;
          incremental_selection = {
            enable = true;
            keymaps = {
              init_selection = "<CR>";
              node_incremental = "<CR>";
              node_decremental = "<BS>";
              scope_incremental = "<TAB>";
            };
          };
          ensure_installed = [
            "lua"
            "vim"
            "vimdoc"
            "bash"
            "tsx"
            "typescript"
            "javascript"
            "html"
            "css"
            "scss"
            "json"
            "jsonc"
            "yaml"
            "toml"
            "markdown"
            "markdown_inline"
            "rust"
            "python"
            "dockerfile"
            "graphql"
            "prisma"
            "vue"
            "styled"
            "regex"
            "query"
          ];
        };
      };

      treesitter-textobjects = {
        enable = true;
        settings = {
          select = {
            enable = true;
            lookahead = true;
            keymaps = {
              "af" = "@function.outer";
              "if" = "@function.inner";
              "ac" = "@class.outer";
              "ic" = "@class.inner";
              "aa" = "@parameter.outer";
              "ia" = "@parameter.inner";
            };
          };
          move = {
            enable = true;
            set_jumps = true;
            goto_next_start = {
              "]f" = "@function.outer";
              "]c" = "@class.outer";
            };
            goto_previous_start = {
              "[f" = "@function.outer";
              "[c" = "@class.outer";
            };
          };
        };
      };

      # ── Snacks (picker, terminal, notif, dashboard, etc.) ────────────────
      snacks = {
        enable = true;
        settings = {
          picker.enabled = true;
          terminal.enabled = true;
          notifier = {
            enabled = true;
            timeout = 3000;
          };
          dashboard = {
            enabled = true;
            sections = [
              { section = "header"; }
              {
                icon = " ";
                title = "Keymaps";
                section = "keys";
                indent = 2;
                padding = 1;
              }
              {
                icon = " ";
                title = "Recent Files";
                section = "recent_files";
                indent = 2;
                padding = 1;
              }
              {
                icon = " ";
                title = "Projects";
                section = "projects";
                indent = 2;
                padding = 1;
              }
              { section = "startup"; }
            ];
          };
          statuscolumn.enabled = true;
          words.enabled = true;
          bigfile.enabled = true;
          input.enabled = true;
          indent.enabled = false;
          scroll.enabled = false;
        };
      };

      # ── File explorer: neo-tree ──────────────────────────────────────────
      neo-tree = {
        enable = true;
        settings = {
          close_if_last_window = true;
          filesystem = {
            follow_current_file.enabled = true;
            hijack_netrw_behavior = "open_current";
          };
        };
      };

      # ── Statusline: lualine ──────────────────────────────────────────────
      lualine = {
        enable = true;
        settings.options = {
          theme = "catppuccin";
          globalstatus = true;
        };
      };

      # ── Bufferline ───────────────────────────────────────────────────────
      bufferline = {
        enable = true;
        settings.options = {
          diagnostics = "nvim_lsp";
          separator_style = "slant";
          show_buffer_close_icons = true;
          show_close_icon = false;
          offsets = [
            {
              filetype = "neo-tree";
              text = "File Explorer";
              highlight = "Directory";
              text_align = "left";
            }
          ];
        };
      };

      # ── Which-key ────────────────────────────────────────────────────────
      which-key = {
        enable = true;
        settings.spec = [
          {
            __unkeyed-1 = "<Leader>b";
            group = "Buffers";
          }
          {
            __unkeyed-1 = "<Leader>f";
            group = "Find";
          }
          {
            __unkeyed-1 = "<Leader>g";
            group = "Git";
          }
          {
            __unkeyed-1 = "<Leader>l";
            group = "LSP";
          }
          {
            __unkeyed-1 = "<Leader>t";
            group = "Terminal";
          }
          {
            __unkeyed-1 = "<Leader>u";
            group = "UI";
          }
          {
            __unkeyed-1 = "<Leader>a";
            group = "AI (opencode)";
          }
          {
            __unkeyed-1 = "<Leader>x";
            group = "Diagnostics";
          }
        ];
      };

      # ── Git signs ────────────────────────────────────────────────────────
      gitsigns = {
        enable = true;
        settings = {
          current_line_blame = false;
          signs = {
            add.text = "▎";
            change.text = "▎";
            delete.text = "";
            topdelete.text = "";
            changedelete.text = "▎";
            untracked.text = "▎";
          };
        };
      };

      # ── LazyGit ──────────────────────────────────────────────────────────
      lazygit.enable = true;

      # ── Flash (motion) ───────────────────────────────────────────────────
      flash.enable = true;

      # ── Mini plugins ─────────────────────────────────────────────────────
      mini = {
        enable = true;
        mockDevIcons = true;
        modules = {
          ai.n_lines = 500;
          surround = { };
          bracketed = { };
          icons = { };
        };
      };

      # ── Indent guides ────────────────────────────────────────────────────
      indent-blankline = {
        enable = true;
        settings = {
          indent.char = "│";
          scope.enabled = true;
        };
      };

      # ── Autopairs ────────────────────────────────────────────────────────
      nvim-autopairs.enable = true;

      # ── Comment ──────────────────────────────────────────────────────────
      comment.enable = true;

      # ── Trouble (diagnostics list) ───────────────────────────────────────
      trouble = {
        enable = true;
        settings.modes.lsp_references.focus = false;
      };

      # ── Scrollbar ────────────────────────────────────────────────────────
      nvim-scrollbar = {
        enable = true;
        settings.handlers.cursor = false;
      };

      # ── LSP signature hints ──────────────────────────────────────────────
      lsp-signature.enable = true;

      # ── Crates.nvim (Rust Cargo.toml) ────────────────────────────────────
      crates.enable = true;

      # ── Markdown enhanced rendering ──────────────────────────────────────
      render-markdown.enable = true;

      # ── LSP progress notifications ───────────────────────────────────────
      fidget.enable = true;
    };

    # ─── Extra plugins (not available as nixvim modules) ────────────────────
    extraPlugins = with pkgs.vimPlugins; [
      # nvim-spider: w/e/b through camelCase / snake_case words
      nvim-spider
      # debugprint.nvim: g?p / g?v debug-print helpers
      debugprint-nvim
      # eagle.nvim: hover docs popup
      eagle-nvim
      # smear-cursor: animated cursor transitions
      smear-cursor-nvim
      # opencode.nvim: Neovim integration for opencode AI assistant
      opencode-nvim
    ];

    # ─── Extra Lua for plugins not covered by nixvim modules ────────────────
    extraConfigLua = ''
      -- ── nvim-spider ───────────────────────────────────────────────────────
      require("spider").setup({ skipInsignificantPunctuation = true })
      vim.keymap.set({ "n", "o", "x" }, "w",  function() require("spider").motion("w")  end, { desc = "Spider w"  })
      vim.keymap.set({ "n", "o", "x" }, "e",  function() require("spider").motion("e")  end, { desc = "Spider e"  })
      vim.keymap.set({ "n", "o", "x" }, "b",  function() require("spider").motion("b")  end, { desc = "Spider b"  })
      vim.keymap.set({ "n", "o", "x" }, "ge", function() require("spider").motion("ge") end, { desc = "Spider ge" })

      -- ── debugprint.nvim ───────────────────────────────────────────────────
      require("debugprint").setup({
        keymaps = {
          normal = {
            plain_below    = "g?p",
            plain_above    = "g?P",
            variable_below = "g?v",
            variable_above = "g?V",
            textobj_below  = "g?o",
            textobj_above  = "g?O",
          },
          visual = {
            variable_below = "g?v",
            variable_above = "g?V",
          },
        },
      })

      -- ── eagle.nvim ────────────────────────────────────────────────────────
      require("eagle").setup({})

      -- ── smear-cursor.nvim ─────────────────────────────────────────────────
      require("smear_cursor").setup({})

      -- ── opencode.nvim ─────────────────────────────────────────────────────
      vim.g.opencode_opts = {}
      vim.o.autoread = true

      -- ── Sync kitty tab title with current working directory ───────────────
      vim.fn.system(string.format("kitty @ set-tab-title %q", vim.fs.basename(vim.fn.getcwd())))
      vim.api.nvim_create_autocmd("DirChanged", {
        pattern = "*",
        callback = function()
          vim.fn.system(string.format("kitty @ set-tab-title %q", vim.fs.basename(vim.fn.getcwd())))
        end,
      })
    '';

    # ─── Keymaps ─────────────────────────────────────────────────────────────
    keymaps = [
      # ── Command mode ──────────────────────────────────────────────────────
      {
        mode = "n";
        key = ";";
        action = ":";
        options.desc = "Command mode";
      }

      # ── Buffer navigation ──────────────────────────────────────────────────
      {
        mode = "n";
        key = "L";
        action = "<cmd>bnext<cr>";
        options.desc = "Next buffer";
      }
      {
        mode = "n";
        key = "H";
        action = "<cmd>bprev<cr>";
        options.desc = "Previous buffer";
      }
      {
        mode = "n";
        key = "]b";
        action = "<cmd>bnext<cr>";
        options.desc = "Next buffer";
      }
      {
        mode = "n";
        key = "[b";
        action = "<cmd>bprev<cr>";
        options.desc = "Previous buffer";
      }
      {
        mode = "n";
        key = "<Leader>bd";
        action = "<cmd>bdelete<cr>";
        options.desc = "Delete buffer";
      }
      {
        mode = "n";
        key = "<Leader>bn";
        action = "<cmd>tabnew<cr>";
        options.desc = "New tab";
      }

      # ── Save ──────────────────────────────────────────────────────────────
      {
        mode = [
          "n"
          "i"
        ];
        key = "<C-s>";
        action = "<cmd>update<cr><esc>";
        options.desc = "Save file";
      }

      # ── Copy whole file ───────────────────────────────────────────────────
      {
        mode = "n";
        key = "<C-c>";
        action = "<cmd>%y+<cr>";
        options.desc = "Copy file";
      }

      # ── Snacks picker ─────────────────────────────────────────────────────
      {
        mode = "n";
        key = "<Leader><Leader>";
        action.__raw = "function() Snacks.picker.files() end";
        options.desc = "Find files";
      }
      {
        mode = "n";
        key = "<Leader>/";
        action.__raw = "function() Snacks.picker.grep() end";
        options.desc = "Find words";
      }
      {
        mode = "n";
        key = "<Leader>,";
        action.__raw = "function() Snacks.picker.buffers() end";
        options.desc = "Find buffers";
      }
      {
        mode = "n";
        key = "<Leader>ff";
        action.__raw = "function() Snacks.picker.files() end";
        options.desc = "Find files";
      }
      {
        mode = "n";
        key = "<Leader>fg";
        action.__raw = "function() Snacks.picker.grep() end";
        options.desc = "Grep (find words)";
      }
      {
        mode = "n";
        key = "<Leader>fr";
        action.__raw = "function() Snacks.picker.recent() end";
        options.desc = "Recent files";
      }
      {
        mode = "n";
        key = "<Leader>fc";
        action.__raw = "function() Snacks.picker.command_history() end";
        options.desc = "Command history";
      }

      # ── Terminal ──────────────────────────────────────────────────────────
      {
        mode = "n";
        key = "<Leader>tf";
        action.__raw = "function() Snacks.terminal.toggle(nil, { win = { position = 'float' } }) end";
        options.desc = "Toggle float terminal";
      }
      {
        mode = "n";
        key = "<Leader>th";
        action.__raw = "function() Snacks.terminal.toggle(nil, { win = { position = 'bottom', height = 0.35 } }) end";
        options.desc = "Toggle horizontal terminal";
      }
      {
        mode = "n";
        key = "<Leader>tv";
        action.__raw = "function() Snacks.terminal.toggle(nil, { win = { position = 'right', width = 0.4 } }) end";
        options.desc = "Toggle vertical terminal";
      }
      {
        mode = "t";
        key = "<Leader>tf";
        action.__raw = "function() Snacks.terminal.toggle(nil, { win = { position = 'float' } }) end";
        options.desc = "Toggle float terminal";
      }
      {
        mode = "t";
        key = "<Leader>th";
        action.__raw = "function() Snacks.terminal.toggle(nil, { win = { position = 'bottom', height = 0.35 } }) end";
        options.desc = "Toggle horizontal terminal";
      }
      {
        mode = "t";
        key = "<Leader>tv";
        action.__raw = "function() Snacks.terminal.toggle(nil, { win = { position = 'right', width = 0.4 } }) end";
        options.desc = "Toggle vertical terminal";
      }
      {
        mode = "t";
        key = "<Esc><Esc>";
        action = "<C-\\><C-n>";
        options.desc = "Exit terminal mode";
      }

      # ── Insert mode cursor movement ────────────────────────────────────────
      {
        mode = "i";
        key = "<C-h>";
        action = "<Left>";
        options.desc = "Move left";
      }
      {
        mode = "i";
        key = "<C-j>";
        action = "<Down>";
        options.desc = "Move down";
      }
      {
        mode = "i";
        key = "<C-k>";
        action = "<Up>";
        options.desc = "Move up";
      }
      {
        mode = "i";
        key = "<C-l>";
        action = "<Right>";
        options.desc = "Move right";
      }

      # ── Git ───────────────────────────────────────────────────────────────
      {
        mode = "n";
        key = "<Leader>gg";
        action = "<cmd>LazyGit<cr>";
        options.desc = "LazyGit";
      }

      # ── File explorer ──────────────────────────────────────────────────────
      {
        mode = "n";
        key = "<Leader>e";
        action = "<cmd>Neotree toggle<cr>";
        options.desc = "Toggle file explorer";
      }

      # ── Diagnostics (Trouble) ──────────────────────────────────────────────
      {
        mode = "n";
        key = "<Leader>xx";
        action = "<cmd>Trouble diagnostics toggle<cr>";
        options.desc = "Diagnostics (Trouble)";
      }
      {
        mode = "n";
        key = "<Leader>xX";
        action = "<cmd>Trouble diagnostics toggle filter.buf=0<cr>";
        options.desc = "Buffer diagnostics (Trouble)";
      }
      {
        mode = "n";
        key = "<Leader>cs";
        action = "<cmd>Trouble symbols toggle<cr>";
        options.desc = "Symbols (Trouble)";
      }
      {
        mode = "n";
        key = "<Leader>cl";
        action = "<cmd>Trouble lsp toggle<cr>";
        options.desc = "LSP References (Trouble)";
      }

      # ── LSP ───────────────────────────────────────────────────────────────
      {
        mode = "n";
        key = "<Leader>uH";
        action.__raw = "function() vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled()) end";
        options.desc = "Toggle inlay hints";
      }

      # ── UI ────────────────────────────────────────────────────────────────
      {
        mode = "n";
        key = "<Leader>un";
        action.__raw = "function() Snacks.notifier.hide() end";
        options.desc = "Dismiss all notifications";
      }

      # ── opencode.nvim ─────────────────────────────────────────────────────
      {
        mode = [
          "n"
          "x"
        ];
        key = "<Leader>aa";
        action.__raw = "function() require('opencode').ask('@this: ', { submit = true }) end";
        options.desc = "Ask opencode";
      }
      {
        mode = [
          "n"
          "x"
        ];
        key = "<Leader>as";
        action.__raw = "function() require('opencode').select() end";
        options.desc = "Opencode actions";
      }
      {
        mode = [
          "n"
          "t"
        ];
        key = "<Leader>at";
        action.__raw = "function() require('opencode').toggle() end";
        options.desc = "Toggle opencode";
      }
      {
        mode = [
          "n"
          "x"
        ];
        key = "go";
        action.__raw = "function() return require('opencode').operator('@this ') end";
        options = {
          desc = "Send range to opencode";
          expr = true;
        };
      }
      {
        mode = "n";
        key = "goo";
        action.__raw = "function() return require('opencode').operator('@this ') .. '_' end";
        options = {
          desc = "Send line to opencode";
          expr = true;
        };
      }
      {
        mode = "n";
        key = "<S-C-u>";
        action.__raw = "function() require('opencode').command('session.half.page.up') end";
        options.desc = "Scroll opencode up";
      }
      {
        mode = "n";
        key = "<S-C-d>";
        action.__raw = "function() require('opencode').command('session.half.page.down') end";
        options.desc = "Scroll opencode down";
      }
    ];
  };
}
