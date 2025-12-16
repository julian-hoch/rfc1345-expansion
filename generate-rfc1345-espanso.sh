#!/usr/bin/env bash
set -euo pipefail

show_help() {
  cat <<'HELP'
Generate a full RFC1345/Vim digraph espanso match file.

Options:
  -p, --prefix STR       Trigger prefix. Default: ",". Use "" for none.
      --include-ascii    Include ASCII/spacing digraphs (SP, Nb, DO...). Default: on.
      --exclude-ascii    Exclude ASCII/spacing digraphs.
      --include-control  Include control-character digraphs. Default: off.
      --exclude-control  Exclude control-character digraphs.
  -o, --output PATH      Output file. Default: ~/.config/espanso/match/rfc1345.yml
  -h, --help             Show this help.

After generating, restart espanso: espanso restart
HELP
}

prefix=","
include_ascii=true
include_control=false
output="${HOME}/.config/espanso/match/rfc1345.yml"

while [[ $# -gt 0 ]]; do
  case "$1" in
    -p|--prefix)
      prefix="${2-}"
      shift 2
      ;;
    --include-ascii)
      include_ascii=true
      shift
      ;;
    --exclude-ascii)
      include_ascii=false
      shift
      ;;
    --include-control)
      include_control=true
      shift
      ;;
    --exclude-control)
      include_control=false
      shift
      ;;
    -o|--output)
      output="${2-}"
      shift 2
      ;;
    -h|--help)
      show_help
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      show_help
      exit 1
      ;;
  esac
done

mkdir -p "$(dirname "$output")"

PREFIX="$prefix" INCLUDE_ASCII="$include_ascii" INCLUDE_CTRL="$include_control" python3 - <<'PY' >"$output"
import os, json, urllib.request

PREFIX = os.environ.get("PREFIX", ",")
INCLUDE_ASCII = os.environ.get("INCLUDE_ASCII", "true").lower() == "true"
INCLUDE_CTRL = os.environ.get("INCLUDE_CTRL", "false").lower() == "true"
url = "https://raw.githubusercontent.com/vim/vim/master/runtime/doc/digraph.txt"
lines = urllib.request.urlopen(url).read().decode("utf-8").splitlines()

matches, seen = [], set()
for line in lines:
    cols = line.split("\t")
    if len(cols) < 3:
        continue
    char_repr, digraph, hex_code = cols[0], cols[1], cols[2]
    if len(digraph) != 2:
        continue
    try:
        cp = int(hex_code, 16)
        char = chr(cp)
    except Exception:
        continue
    if not INCLUDE_ASCII and cp < 0x80:
        continue
    if not INCLUDE_CTRL and (cp < 0x20 or cp == 0x7F):
        continue
    if digraph in seen:
        continue
    seen.add(digraph)
    trigger = f"{PREFIX}{digraph}" if PREFIX is not None else digraph
    matches.append((trigger, char))

print("matches:")
for trig, ch in matches:
    print(f"  - trigger: {json.dumps(trig)}")
    print(f"    replace: {json.dumps(ch, ensure_ascii=False)}")
PY

echo "Wrote $(wc -l <"$output") lines to $output"
echo "Run: espanso restart"
