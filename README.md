- [Espanso](#org79c2971)
      - [AutoHotkey](#org76a9c2c)

![AI Status](https://img.shields.io/badge/AI-Assisted-orange)

If you use Vim, you might be familiar with [RFC1345](https://www.rfc-editor.org/rfc/rfc1345) digraphs. You can use them for all sorts of interesting characters, even the now infamouse em-dash (Code: `-M`, rendered as `—`).

Emacs also supports these via the rfc1345 input method. However I wanted this to be available globally in all applications. On Linux based systems I use [Espanso](https://espanso.org/), on Windows I use [Autohotkey](https://www.autohotkey.com/). It's not hard to add support for these digraphs in both tools, and the helper scripts provided in this repository make it very easy.

The two provided scripts pull the Vim digraph table from GitHub on demand. Shared options:

-   `-p/--prefix STR` (default `,`) to set the trigger prefix; pass `""` for none.
-   `--exclude-ascii` to skip ASCII/spacing digraphs
-   `--include-control` to include control chars.


<a id="org79c2971"></a>

# Espanso

Run `generate-rfc1345-espanso.sh`, this builds `~/.config/espanso/match/rfc1345.yml` by default.

<div class="source" id="orgf0b6aa7">
<p>
./generate-rfc1345-espanso.sh [-p ,] [&ndash;exclude-ascii] [&ndash;include-control] [-o /path/to/match.yml]
espanso restart
</p>

</div>


<a id="org76a9c2c"></a>

# AutoHotkey

Run `generate-rfc1345-autohotkey.sh`, this builds `~/Documents/AutoHotkey/rfc1345.ahk` by default (AutoHotkey v2 hotstrings).

<div class="source" id="orgd3bb675">
<p>
./generate-rfc1345-autohotkey.sh [-p ,] [&ndash;exclude-ascii] [&ndash;include-control] [-O *] [-o /path/to/rfc1345.ahk]
</p>

</div>

-   Uses `:*:` hotstring options by default for instant expansion; override with `-O/--options` (do not include colons).
-   Reload/restart your AutoHotkey script after generating.
-   Prefer PowerShell on Windows? Use `generate-rfc1345-autohotkey.ps1` with equivalent flags, e.g.:

<div class="source" id="orgpsahk">
<p>
pwsh ./generate-rfc1345-autohotkey.ps1 -Prefix , -ExcludeAscii -IncludeControl -Options * -Output ~/Documents/AutoHotkey/rfc1345.ahk
</p>

</div>
