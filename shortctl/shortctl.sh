# Packaged with Bash, curl, and jq by writeShellApplication.
usage() {
  echo 'Usage: shortctl [--server URL] create URL | stats CODE'
}

server="${SHORTCTL_SERVER:-}"
if [[ "${1:-}" == --server ]]; then
  if [[ $# -lt 2 || -z "$2" ]]; then
    usage >&2
    exit 2
  fi
  server="$2"
  shift 2
fi
if [[ "${1:-}" == --help || "${1:-}" == -h ]]; then
  usage
  exit 0
fi
if [[ $# -ne 2 ]]; then
  usage >&2
  exit 2
fi

config_file="${XDG_CONFIG_HOME:-$HOME/.config}/shortctl/config.json"
if [[ -z "$server" && -f "$config_file" ]]; then
  server=$(jq -er '.server | select(type == "string" and length > 0)' "$config_file")
fi
server="${server:-http://127.0.0.1:8000}"
server="${server%/}"
if [[ "$server" != http://* && "$server" != https://* ]]; then
  echo 'shortctl: server must use http:// or https://' >&2
  exit 2
fi

case "$1" in
  create)
    payload=$(jq -n --arg url "$2" '{url: $url}')
    response=$(curl --silent --show-error --fail-with-body --connect-timeout 5 --max-time 30 \
      --header 'Content-Type: application/json' --data "$payload" "$server/links")
    code=$(jq -er '.code | select(type == "string" and length > 0)' <<< "$response")
    printf '%s/%s\n' "$server" "$code"
    ;;
  stats)
    if [[ ! "$2" =~ ^[A-Za-z0-9_-]+$ ]]; then
      echo 'shortctl: expected a link code (not a URL)' >&2
      exit 2
    fi
    curl --silent --show-error --fail-with-body --connect-timeout 5 --max-time 30 \
      "$server/$2/stats" | jq .
    ;;
  *) usage >&2; exit 2 ;;
esac
