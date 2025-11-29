{
  description = "A flake template for nix-darwin and Determinate Nix";

  # Flake inputs
  inputs = {
    # Stable Nixpkgs (use 0.1 for unstable)
    nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/0";
    # Stable nix-darwin (use 0.1 for unstable)
    nix-darwin = {
      url = "https://flakehub.com/f/nix-darwin/nix-darwin/0";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Determinate 3.* module
    determinate = {
      url = "https://flakehub.com/f/DeterminateSystems/determinate/3";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # nix-homebrew to let nix-darwin manage Homebrew installation
    nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";
  };

  # Flake outputs
  outputs =
    { self, ... }@inputs:
    let
      # Your macOS login username (matches what you see as `sreysus@...`)
      username = "sreysus";

      # Your system type (Apple Silicon)
      system = "aarch64-darwin";
    in
    {
      # nix-darwin configuration output
      darwinConfigurations."${username}-${system}" =
        inputs.nix-darwin.lib.darwinSystem {
          inherit system;
          modules = [
            # Determinate Nix module (writes /etc/nix/nix.custom.conf)
            inputs.determinate.darwinModules.default

            # nix-homebrew module to manage Homebrew itself
            inputs.nix-homebrew.darwinModules.nix-homebrew
            {
              nix-homebrew = {
                enable = true;
                enableRosetta = true;
                user = username;
                autoMigrate = true;
              };
            }

            # Base system config (user, packages, fonts, zsh, keyboard, etc)
            self.darwinModules.base

            # Nix configuration (delegated to Determinate)
            self.darwinModules.nixConfig

            # You can still add more modules here if you want

            (
              { config, pkgs, lib, ... }:
              {
                # Inline nix-darwin configuration (currently empty)
              }
            )
          ];
        };

      # nix-darwin module outputs
      darwinModules = {
        # Some base configuration
        base =
          { config, pkgs, lib, ... }:
          {
            ########################################
            # Core system + user
            ########################################

            # Backwards-compat version; 6 is what you were using before
            system.stateVersion = 6;

            # Show git revision in `darwin-version`
            system.configurationRevision = self.rev or self.dirtyRev or null;

            # Primary user for this machine
            system.primaryUser = username;

            # Define your macOS user
            users.users.${username} = {
              name = username;
              home = "/Users/${username}";
            };

            ########################################
            # Packages
            ########################################

            environment.systemPackages = with pkgs; [
              helix
              mkalias
              gnupg
              pinentry_mac
              # ghostty-bin
              git
              ripgrep
              fd
              rustc
              cargo
              # If you later enable zen-browser as a flake,
              # you can add it here via inputs.zen-browser...
            ];

            ########################################
            # Homebrew (same style as your earlier config)
            ########################################

            homebrew = {
              enable = true;

              brews = [
                "stow"
                "mas"
                "tldr"
                "tree"
              ];

              casks = [
                "hammerspoon"
                "firefox"
                "ghostty"
                "iina"
                "the-unarchiver"
                "zen-browser"
              ];

              masApps = { };

              onActivation.cleanup = "zap";
              onActivation.autoUpdate = true;
              onActivation.upgrade = true;
            };

            ########################################
            # Apps in /Applications/Nix Apps via mkalias
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
                # Set up applications.
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
            # Keyboard / defaults / fonts / shell
            ########################################

            system.keyboard.enableKeyMapping = true;
            system.keyboard.remapCapsLockToEscape = true;

            system.defaults = {
              dock.autohide = true;
            };

            fonts.packages = with pkgs; [
              nerd-fonts.jetbrains-mono
              nerd-fonts.symbols-only
            ];

            # Create /etc/zshrc that loads the nix-darwin environment
            programs.zsh.enable = true;
          };

        # Nix configuration
        nixConfig =
          { config, pkgs, lib, ... }:
          {
            # Let Determinate Nix handle your Nix configuration
            nix.enable = false;

            # Custom Determinate Nix settings written to /etc/nix/nix.custom.conf
            determinate-nix.customSettings = {
              # Enables parallel evaluation (0 = auto)
              eval-cores = 0;

              # Extra experimental features for Nix (Determinate’s pattern)
              extra-experimental-features = [
                "build-time-fetch-tree" # Enables build-time flake inputs
                "parallel-eval"         # Enables parallel evaluation
                # Determinate Nix already enables `nix-command` and `flakes`
                # by default, so you don't strictly need to add them here.
              ];

              # You could add other Nix settings here if you want.
            };
          };

        # Add other module outputs here
      };

      # Development environment
      devShells.${system}.default =
        let
          pkgs = import inputs.nixpkgs { inherit system; };
        in
        pkgs.mkShellNoCC {
          packages = with pkgs; [
            # Script for applying the nix-darwin configuration.
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

      # Nix formatter (RFC 166 style)
      formatter.${system} =
        inputs.nixpkgs.legacyPackages.${system}.nixfmt-rfc-style;
    };
}
