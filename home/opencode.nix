{ config, ... }:
{
  xdg.configFile."opencode/opencode.json".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nix/home/opencode.json";
}
