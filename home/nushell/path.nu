$env.config = (($env.config? | default {}) | merge {
  show_banner: false
})

let base_path = [
  "/Users/sreysus/.bun/bin"
  "/Users/sreysus/.nix-profile/bin"
  "/nix/var/nix/profiles/default/bin"
  "/opt/homebrew/bin"
  "/opt/homebrew/sbin"
  "/etc/profiles/per-user/sreysus/bin"
  "/run/current-system/sw/bin"
  "/usr/local/bin"
  "/usr/bin"
  "/bin"
  "/usr/sbin"
  "/sbin"
]

$env.PATH = (($env.PATH? | default []) ++ $base_path | uniq)
