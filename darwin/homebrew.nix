{ config, ... }:
{
  nix-homebrew = {
    enable = true;
    enableRosetta = true;
    user = config.system.primaryUser;
    autoMigrate = true;
  };

  homebrew = {
    enable = true;

    # Prefer Homebrew for fast-moving, self-updating macOS apps and CLIs. Nix
    # remains the owner of reproducible system and development dependencies.

    taps = [
      "modem-dev/tap"
      "sreyassabbani/tap"
      "steipete/tap"
      "anomalyco/tap"
    ];

    brews = [
      "anomalyco/tap/opencode"
      "ghostscript"
      "mas"
      "bun"
      "bat"
      "ffmpeg"
      "spogo"
      "poppler"
      "gh"
      "tldr"
      "gemini-cli"
      "tcl-tk"
      "python"
      "sreyassabbani/tap/saterminal"
      "go"
      "tree"
      "googleworkspace-cli"
      "hunk"
    ];

    casks = [
      "onedrive"
      "opencode-desktop"
      # "gcloud-cli"
      # "blender"
      # "firefox"
      "helium-browser"
      "hammerspoon"
      "notion"
      "microsoft-word"
      # "inkscape"
      "obsidian"
      "discord"
      "cursor"
      "microsoft-powerpoint"
      # "zoom"
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
      "codex"
      {
        name = "chatgpt";
        greedy = true;
      }
      "the-unarchiver"
      # "zen"
    ];

    masApps = { };

    # Remove undeclared apps without deleting their preferences or user data.
    onActivation.cleanup = "uninstall";

    # Keep system activation idempotent and independent of vendor download
    # availability. Upgrade Homebrew packages explicitly instead.
    onActivation.autoUpdate = false;
    onActivation.upgrade = false;
  };
}
