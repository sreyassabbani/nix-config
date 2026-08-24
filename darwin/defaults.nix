{ ... }:
{
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
        { app = "/Applications/Anki.app"; }
        { app = "/Applications/Ghostty.app"; }
        { app = "/Applications/ChatGPT.app"; }
        { app = "/Applications/Google Chrome.app"; }
        { app = "/Applications/Obsidian.app"; }
        { app = "/Applications/Notion Calendar.app"; }
        { app = "/Applications/Zotero.app"; }
      ];

      persistent-others = [ ];
    };
  };
}
