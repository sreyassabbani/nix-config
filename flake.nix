{
  description = "A flake template for nix-darwin and Determinate Nix";

  ########################################
  # Flake Inputs
  ########################################
  inputs = {
    nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/0";

    nix-darwin = {
      url = "https://flakehub.com/f/nix-darwin/nix-darwin/0";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    determinate = {
      url = "https://flakehub.com/f/DeterminateSystems/determinate/3";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";

    home-manager = {
      url = "https://flakehub.com/f/nix-community/home-manager/0";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-vscode-extensions.url = "github:nix-community/nix-vscode-extensions";
  };

  ########################################
  # Flake Outputs
  ########################################
  outputs =
    { self, ... }@inputs:
    let
      username = "sreysus";
      system = "aarch64-darwin";
      vscodeExtensionsOverlay = inputs.nix-vscode-extensions.overlays.default;
    in
    {
      ########################################
      # System Configuration (nix-darwin)
      ########################################
      darwinConfigurations."${username}-${system}" = inputs.nix-darwin.lib.darwinSystem {
        inherit system;

        modules = [
          ########################################
          # Determinate Nix
          ########################################
          inputs.determinate.darwinModules.default

          ########################################
          # nix-homebrew
          ########################################
          inputs.nix-homebrew.darwinModules.nix-homebrew
          {
            nix-homebrew = {
              enable = true;
              enableRosetta = true;
              user = username;
              autoMigrate = true;
            };
          }

          ########################################
          # Base nix-darwin Config
          ########################################
          self.darwinModules.base

          ########################################
          # Determinate Nix Config
          ########################################
          self.darwinModules.nixConfig

          ########################################
          # Inline nix-darwin module (empty)
          ########################################
          ({ pkgs, ... }: {
            nixpkgs.overlays = [ vscodeExtensionsOverlay ];
          })

          ########################################
          # Home Manager
          ########################################
          inputs.home-manager.darwinModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;

              users.${username} =
                { pkgs, ... }:
                {
                  home = {
                    username = username;
                    homeDirectory = "/Users/${username}";
                    enableNixpkgsReleaseCheck = false;
                    stateVersion = "25.05";
                    sessionVariables = {
                      EDITOR = "hx";
                    };
                  };

                  programs = {
                    direnv = {
                      enable = true;
                      enableBashIntegration = true; # see note on other shells below
                      nix-direnv.enable = true;
                    };

                    bash.enable = true; # see note on other shells below

                    home-manager.enable = true;

                    ########################################
                    # VSCode Config
                    ########################################
                    vscode = {
                      enable = true;
                      profiles.default = {
                        userSettings = {
                          "editor.formatOnSave" = true;
                          "workbench.colorTheme" = "Gruvbox Dark Soft";
                          "workbench.iconTheme" = "icons";
                          "git.autofetch" = true;
                        };

                        extensions = with pkgs.vscode-marketplace; [
                          openai.chatgpt
                          jnoortheen.nix-ide
                          jdinhlife.gruvbox
                          tal7aouy.icons
                        ];
                      };
                    };

                    ########################################
                    # Git Config
                    ########################################
                    git = {
                      enable = true;

                      signing = {
                        key = "688241BB0F9A860B";
                        signByDefault = true;
                      };

                      settings = {
                        user = {
                          name = "Sreyas Sabbani";
                          email = "sreyassabbani@gmail.com";
                        };

                        gpg.program = "gpg";

                        core = {
                          editor = "hx";
                          autocrlf = "input";
                        };

                        init.defaultBranch = "main";
                        pull.rebase = true;
                        merge.conflictstyle = "zdiff3";
                        color.ui = "auto";
                        commit.gpgsign = true;
                        tag.gpgsign = true;

                        alias = {
                          sl = "log --oneline";
                          st = "status -sb";
                          co = "checkout";
                          br = "branch";
                          ci = "commit";
                          lg = "log --oneline --graph --decorate --all";
                        };
                      };
                    };

                    ########################################
                    # SSH Config
                    ########################################
                    ssh = {
                      enable = true;
                      enableDefaultConfig = false;

                      matchBlocks."github.com" = {
                        hostname = "github.com";
                        user = "git";
                        identityFile = "~/.ssh/id_ed25519";

                        extraOptions = {
                          AddKeysToAgent = "yes";
                          UseKeychain = "yes";
                        };
                      };
                    };

                    ########################################
                    # zsh
                    ########################################
                    zsh = {
                      enable = true;

                      oh-my-zsh = {
                        enable = true;
                        plugins = [ "git" ];
                        theme = "robbyrussell";
                      };

                      shellAliases = {
                        dr = "sudo darwin-rebuild switch --flake ~/nix#${username}-${system}";
                      };

                      initContent = ''
                        setopt PROMPT_SUBST

                        function update_prompt() {
                          PROMPT=""

                          if [[ $PWD == $HOME ]]; then
                            PROMPT+=$'\n'
                          else
                            PROMPT+=$'\n%F{242}%~\n'
                          fi

                          PROMPT+=$'%F{130}%n %F{216}[λ]%f '
                        }

                        PS2=$'%F{242} [...]%f '

                        autoload -U add-zsh-hook
                        add-zsh-hook chpwd update_prompt
                        update_prompt

                        RPROMPT='%F{242}$(git rev-parse --is-inside-work-tree 2>/dev/null && echo "git:") %F{240}$(git rev-parse --abbrev-ref HEAD 2>/dev/null)%f'

                        ZSH_THEME_GIT_PROMPT_PREFIX="%{$fg_bold[245]%}[git:"
                        ZSH_THEME_GIT_PROMPT_SUFFIX="%{$reset_color%}"
                        ZSH_THEME_GIT_PROMPT_DIRTY="%{$fg[242]%}] ✖ %{$reset_color%}"
                        ZSH_THEME_GIT_PROMPT_CLEAN="%{$fg[242]%}] ✔%{$reset_color%}"
                      '';
                    };

                    ########################################
                    # Helix
                    ########################################
                    helix = {
                      enable = true;

                      settings = {
                        theme = "gruvbox";

                        editor = {
                          "line-number" = "relative";
                          bufferline = "multiple";
                          mouse = false;
                          rulers = [ 120 ];
                          "true-color" = true;
                          "end-of-line-diagnostics" = "hint";

                          "soft-wrap".enable = true;

                          "inline-diagnostics" = {
                            "cursor-line" = "error";
                            "other-lines" = "disable";
                          };

                          "cursor-shape" = {
                            insert = "bar";
                            normal = "block";
                            select = "underline";
                          };

                          "indent-guides" = {
                            character = "╎";
                            render = true;
                          };

                          "file-picker".hidden = false;

                          statusline.left = [
                            "mode"
                            "spinner"
                            "version-control"
                            "file-name"
                          ];
                        };

                        keys = {
                          normal = {
                            space = {
                              i = ":toggle lsp.display-inlay-hints";
                              x = ":buffer-close";
                              q = ":q!";
                              "/" = "toggle_comments";
                              ";" = "global_search";
                              b = ":new";
                              l = "select_all";
                              z = ":toggle soft-wrap.enable";
                            };

                            X = "select_line_above";
                            G = "goto_file_end";
                            tab = ":buffer-next";
                            "S-tab" = ":buffer-previous";

                            "A-j" = [
                              "extend_to_line_bounds"
                              "delete_selection"
                              "paste_after"
                            ];

                            "A-k" = [
                              "extend_to_line_bounds"
                              "delete_selection"
                              "move_line_up"
                              "paste_before"
                            ];

                            "*" = [
                              "move_prev_word_start"
                              "move_next_word_end"
                              "search_selection"
                              "search_next"
                            ];

                            "#" = [
                              "move_prev_word_start"
                              "move_next_word_end"
                              "search_selection"
                              "search_prev"
                            ];
                          };

                          select = {
                            X = "select_line_above";
                            space."/" = "toggle_comments";
                          };
                        };
                      };

                      languages = {
                        editor."auto-format" = true;

                        language = [
                          {
                            name = "typst";
                            formatter.command = "typstyle";
                            "auto-format" = true;
                          }

                          {
                            name = "python";
                            "language-servers" = [
                              "basedpyright"
                              "ruff"
                            ];
                            formatter = {
                              command = "ruff";
                              args = [
                                "format"
                                "-"
                              ];
                            };
                            "auto-format" = true;
                          }

                          {
                            name = "c";
                            "file-types" = [ "c" ];
                            indent = {
                              "tab-width" = 4;
                              unit = "  ";
                            };
                          }

                          {
                            name = "json";
                            indent = {
                              "tab-width" = 4;
                              unit = "  ";
                            };
                          }

                          {
                            name = "typescript";
                            "auto-format" = true;
                          }

                          {
                            name = "latex";
                            "file-types" = [ "tex" ];
                            "language-servers" = [ "texlab" ];
                          }

                          {
                            name = "scss";
                            "file-types" = [ "scss" ];
                            grammar = "scss";
                          }

                          {
                            name = "cpp";
                            scope = "source.cpp";
                            "file-types" = [
                              "cpp"
                              "h"
                              "c"
                              "hpp"
                            ];
                            "language-servers" = [ "clangd" ];
                            formatter = {
                              command = "clang-format";
                              args = [ "--style=file" ];
                            };
                            "auto-format" = true;
                            indent = {
                              "tab-width" = 4;
                              unit = "    ";
                            };
                          }

                          {
                            name = "nix";
                            "file-types" = [ "nix" ];
                            roots = [
                              "flake.nix"
                              "shell.nix"
                              "default.nix"
                            ];
                            formatter = {
                              command = "nixfmt";
                            };
                          }
                        ];

                        "language-server" = {
                          basedpyright = {
                            command = "basedpyright-langserver";
                            args = [ "--stdio" ];
                          };

                          ruff = {
                            command = "ruff";
                            args = [ "server" ];
                          };
                        };
                      };

                    };

                    ghostty = {
                      enable = true;

                      # Important: don't use pkgs.ghostty on macOS right now, it's broken.
                      package = null;

                      # Optional, but safe: avoids bat-syntax issues on mac
                      installBatSyntax = false;

                      settings = {
                        theme = "Gruvbox Dark";

                        window-padding-x = 30;
                        # window-padding-y = "40,0"; # if you want this later

                        font-size = 16;

                        keybind = [
                          "global:cmd+grave_accent=toggle_quick_terminal"
                          "shift+enter=text:\\n"
                        ];
                      };
                    };
                  };

                };
            };
          }
        ];
      };

      ########################################
      # nix-darwin Modules
      ########################################
      darwinModules = {
        base =
          { config, pkgs, ... }:
          {
            system.stateVersion = 6;
            system.configurationRevision = self.rev or self.dirtyRev or null;
            system.primaryUser = username;
            system.activationScripts.defaultBrowser.text = ''
              # See available names:
              #   ${pkgs.defaultbrowser}/bin/defaultbrowser -l
              ${pkgs.defaultbrowser}/bin/defaultbrowser "Zen Browser"
            '';

            users.users.${username} = {
              name = username;
              home = "/Users/${username}";
            };

            ########################################
            # System Packages
            ########################################
            environment.systemPackages = with pkgs; [
              helix
              mkalias
              gnupg
              pinentry_mac
              fastfetch
              git
              ripgrep
              defaultbrowser
              fd
              nixfmt-rfc-style
            ];

            ########################################
            # Homebrew
            ########################################
            homebrew = {
              enable = true;

              brews = [
                "mas"
                "gh"
                "tldr"
                "tree"
              ];

              casks = [
                "hammerspoon"
                "codex"
                "skim"
                "slack"
                "ghostty"
                "iina"
                "google-drive"
                "zotero"
                "spotify"
                "notion-calendar"
                "anki"
                "antigravity"
                "visual-studio-code"
                "chatgpt-atlas"
                "the-unarchiver"
                "zen-browser"
              ];

              masApps = { };

              onActivation.cleanup = "zap";
              onActivation.autoUpdate = true;
              onActivation.upgrade = true;
            };

            ########################################
            # Symlink Applications
            ########################################
            system.activationScripts.applications.text =
              let
                env = pkgs.buildEnv {
                  name = "system-applications";
                  paths = config.environment.systemPackages;
                  pathsToLink = [ "/Applications" ];
                };
              in
              pkgs.lib.mkForce ''
                echo "setting up /Applications..." >&2
                rm -rf /Applications/Nix\ Apps
                mkdir -p /Applications/Nix\ Apps

                find ${env}/Applications -maxdepth 1 -type l -exec readlink '{}' + |
                while read -r src; do
                  app_name=$(basename "$src")
                  echo "copying $src" >&2
                  ${pkgs.mkalias}/bin/mkalias "$src" "/Applications/Nix Apps/$app_name"
                done
              '';

            ########################################
            # macOS Defaults
            ########################################
            system.keyboard.enableKeyMapping = true;
            system.keyboard.remapCapsLockToEscape = true;

            system.defaults = {
              dock = {
                autohide = true;
                show-recents = false;
                tilesize = 25;
                largesize = 60;
                orientation = "bottom";

                persistent-apps = [
                  { app = "/Applications/Ghostty.app"; }
                  { app = "/Applications/ChatGPT Atlas.app"; }
                  { app = "/Applications/Zen.app"; }
                  { app = "/Applications/Notion Calendar.app"; }
                  { app = "/Applications/Zotero.app"; }
                ];

                persistent-others = [ ];
              };
            };

            ########################################
            # Fonts
            ########################################
            fonts.packages = with pkgs; [
              nerd-fonts.jetbrains-mono
              nerd-fonts.symbols-only
            ];
            nixpkgs.config.allowUnfree = true;
          };

        ########################################
        # Determinate Nix Config Module
        ########################################
        nixConfig =
          { ... }:
          {
            nix.enable = false;

            determinate-nix.customSettings = {
              eval-cores = 0;

              extra-experimental-features = [
                "build-time-fetch-tree"
                "parallel-eval"
              ];
            };
          };
      };

      ########################################
      # DevShell
      ########################################
      devShells.${system}.default =
        let
          pkgs = import inputs.nixpkgs { inherit system; };
        in
        pkgs.mkShellNoCC {
          packages = with pkgs; [
            (writeShellApplication {
              name = "apply-nix-darwin-configuration";
              runtimeInputs = [
                inputs.nix-darwin.packages.${system}.darwin-rebuild
              ];
              text = ''
                echo "> Applying nix-darwin configuration..."
                echo "> Running darwin-rebuild switch as root..."
                sudo darwin-rebuild switch --flake .#"${username}-${system}"
                echo "> darwin-rebuild switch was successful ✅"
                echo "> macOS config was successfully applied 🚀"
              '';
            })

            self.formatter.${system}
          ];
        };

      ########################################
      # Formatter
      ########################################
      formatter.${system} = inputs.nixpkgs.legacyPackages.${system}.nixfmt-rfc-style;
    };
}
