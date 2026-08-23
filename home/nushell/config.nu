# Load user-scoped Nushell modules managed by Home Manager.
source "~/Library/Application Support/nushell/lib/path.nu"
source "~/Library/Application Support/nushell/lib/prompt.nu"
source "~/Library/Application Support/nushell/lib/aliases.nu"
source "~/Library/Application Support/nushell/lib/zoxide.nu"
source "~/Library/Application Support/nushell/lib/ds.nu"

$env.EDITOR = "hx"
$env.VISUAL = "hx"
$env.OPENCODE_ENABLE_EXA = "1"

let openclaw_gateway_token_file = ([$env.HOME ".secrets" "openclaw-gateway-token"] | path join)
if ($openclaw_gateway_token_file | path exists) {
  $env.OPENCLAW_GATEWAY_TOKEN = (open $openclaw_gateway_token_file | str trim)
}

let discord_bot_token_file = ([$env.HOME ".secrets" "openclaw-discord-bot-token"] | path join)
if ($discord_bot_token_file | path exists) {
  $env.DISCORD_BOT_TOKEN = (open $discord_bot_token_file | str trim)
}

use std/config dark-theme

$env.config = (($env.config? | default {}) | merge {
  show_banner: false
  highlight_resolved_externals: true
  color_config: (dark-theme)
})
