# Authenticate only when an internal install needs the token. Shell startup
# must stay offline and must not fail when cloudflared is unavailable.
load-cloudflare-npm-token() {
  if (( ! $+commands[cloudflared] )); then
    print -u2 "cloudflared is required to authenticate to registry.cloudflare-ui.com"
    return 127
  fi

  local token
  token="$(cloudflared access login --no-verbose https://registry.cloudflare-ui.com)" || return
  export NPM_TOKEN="$token"
}
