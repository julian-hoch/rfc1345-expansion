#!/usr/bin/env bash
set -euo pipefail

show_help() {
  cat <<'HELP'
Generate a full RFC1345/Vim digraph AutoHotkey hotstring file.

Options:
  -p, --prefix STR          Trigger prefix. Default: ",". Use "" for none.
      --include-ascii       Include ASCII/spacing digraphs (SP, Nb, DO...). Default: on.
      --exclude-ascii       Exclude ASCII/spacing digraphs.
      --include-control     Include control-character digraphs. Default: off.
      --exclude-control     Exclude control-character digraphs.
  -O, --options STR         Hotstring options (without colons). Default: "*" (instant trigger).
  -o, --output PATH         Output file. Default: ~/Documents/AutoHotkey/rfc1345.ahk
  -h, --help                Show this help.

Notes:
- Generated file targets AutoHotkey v2; it uses SendText inside each hotstring block.
- After generating, reload your script (e.g., via AutoHotkey tray menu or restarting the runner).
HELP
}

prefix=","  # Trigger prefix (typed before each digraph)
include_ascii=true
include_control=false
hotstring_options="*"
output="${HOME}/Documents/AutoHotkey/rfc1345.ahk"

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
    -O|--options)
      hotstring_options="${2-}"
      shift 2
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

if [[ "$hotstring_options" == *:* ]]; then
  echo "Hotstring options should not contain colons; pass only the option letters." >&2
  exit 1
fi

mkdir -p "$(dirname "$output")"

PREFIX="$prefix" INCLUDE_ASCII="$include_ascii" INCLUDE_CTRL="$include_control" HOTSTRING_OPTS="$hotstring_options" python3 - <<'PY' >"$output"
import datetime, json, os, urllib.request

PREFIX = os.environ.get("PREFIX", ",")
INCLUDE_ASCII = os.environ.get("INCLUDE_ASCII", "true").lower() == "true"
INCLUDE_CTRL = os.environ.get("INCLUDE_CTRL", "false").lower() == "true"
HOTSTRING_OPTS = os.environ.get("HOTSTRING_OPTS", "*")
url = "https://raw.githubusercontent.com/vim/vim/master/runtime/doc/digraph.txt"
lines = urllib.request.urlopen(url).read().decode("utf-8").splitlines()

matches, seen = [], set()
for line in lines:
    cols = line.split("\t")
    if len(cols) < 3:
        continue
    _, digraph, hex_code = cols[0], cols[1], cols[2]
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
    trigger_raw = f"{PREFIX}{digraph}" if PREFIX is not None else digraph
    # Escape hotstring meta chars in trigger: colon (end marker) and backtick (escape char).
    trigger = trigger_raw.replace("`", "``").replace(":", "`:")
    matches.append((trigger, char))

stamp = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
print("#Requires AutoHotkey v2.0")
print(f"; Generated {stamp} from Vim digraph table ({url})")
print(f"; Prefix: {json.dumps(PREFIX)} | Include ASCII: {INCLUDE_ASCII} | Include control: {INCLUDE_CTRL} | Options: {HOTSTRING_OPTS}")
# Allow triggers containing characters like '(' or ':' by removing them from EndChars.
print("#Hotstring EndChars -[]{}'\"/\\\\,.?!`n`s`t")
print("")

option_block = f":{HOTSTRING_OPTS}:" if HOTSTRING_OPTS else "::"
for trig, ch in matches:
    print(f"{option_block}{trig}::")
    print("{")
    escaped = ch.replace("`", "``").replace("\"", "\"\"")
    print(f"    SendText \"{escaped}\"")
    print("}")
    print("")
PY

echo "Wrote $(wc -l <"$output") lines to $output"
echo "Reload the AutoHotkey script to apply changes"
