#!/usr/bin/env bash
#
# Validates the EVE Mogul plugin package: manifest, MCP manifest, skills, and
# assets. This is the repeatable check for a declarative plugin that has no
# build step or dev server. It is safe to run repeatedly and requires no
# network access unless CHECK_MCP=1 is set.
#
# Usage:
#   scripts/validate-plugin.sh          # validate files only
#   CHECK_MCP=1 scripts/validate-plugin.sh   # also probe the MCP endpoint

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

fail=0
pass() { printf '  ok   %s\n' "$1"; }
err()  { printf '  FAIL %s\n' "$1"; fail=1; }

need() {
  command -v "$1" >/dev/null 2>&1 || { echo "Missing required tool: $1" >&2; exit 127; }
}
need jq
need python3

echo "Validating plugin manifest (.cursor-plugin/plugin.json)"
if jq -e . .cursor-plugin/plugin.json >/dev/null 2>&1; then
  pass "plugin.json is valid JSON"
  for field in name displayName version description; do
    if [ "$(jq -r --arg f "$field" 'has($f)' .cursor-plugin/plugin.json)" = "true" ]; then
      pass "plugin.json has \"$field\""
    else
      err "plugin.json missing \"$field\""
    fi
  done
  logo="$(jq -r '.logo // empty' .cursor-plugin/plugin.json)"
  if [ -n "$logo" ] && [ -f "$logo" ]; then
    pass "logo asset exists ($logo)"
  else
    err "logo asset missing (declared: ${logo:-none})"
  fi
else
  err "plugin.json is not valid JSON"
fi

echo "Validating MCP manifest (mcp.json)"
if jq -e . mcp.json >/dev/null 2>&1; then
  pass "mcp.json is valid JSON"
  servers="$(jq -r '.mcpServers | keys[]' mcp.json 2>/dev/null || true)"
  if [ -n "$servers" ]; then
    for s in $servers; do
      url="$(jq -r --arg s "$s" '.mcpServers[$s].url // empty' mcp.json)"
      if [[ "$url" =~ ^https?:// ]]; then
        pass "mcp server \"$s\" -> $url"
      else
        err "mcp server \"$s\" has no valid url"
      fi
    done
  else
    err "mcp.json has no mcpServers entries"
  fi
else
  err "mcp.json is not valid JSON"
fi

echo "Validating assets"
if [ -f assets/logo.svg ]; then
  if python3 -c "import xml.dom.minidom; xml.dom.minidom.parse('assets/logo.svg')" 2>/dev/null; then
    pass "logo.svg is well-formed XML"
  else
    err "logo.svg is not well-formed XML"
  fi
fi

echo "Validating skills"
shopt -s nullglob
skill_count=0
for f in skills/*/SKILL.md; do
  skill_count=$((skill_count + 1))
  name="$(python3 - "$f" <<'PY'
import re, sys
text = open(sys.argv[1], encoding="utf-8").read()
m = re.match(r"^---\s*\n(.*?)\n---\s*\n", text, re.S)
if not m:
    print("__NO_FRONTMATTER__"); sys.exit(0)
body = m.group(1)
fields = {}
for line in body.splitlines():
    if ":" in line:
        k, v = line.split(":", 1)
        fields[k.strip()] = v.strip()
missing = [k for k in ("name", "description") if not fields.get(k)]
print("__MISSING__:" + ",".join(missing) if missing else fields["name"])
PY
)"
  case "$name" in
    __NO_FRONTMATTER__) err "$f has no YAML frontmatter" ;;
    __MISSING__:*)      err "$f missing frontmatter fields: ${name#__MISSING__:}" ;;
    *)                  pass "skill \"$name\" ($f)" ;;
  esac
done
if [ "$skill_count" -eq 0 ]; then
  err "no skills found under skills/*/SKILL.md"
fi

if [ "${CHECK_MCP:-0}" = "1" ]; then
  echo "Probing MCP endpoint (CHECK_MCP=1)"
  url="$(jq -r '.mcpServers.evemogul.url // (.mcpServers | to_entries[0].value.url)' mcp.json)"
  code="$(curl -s -o /dev/null -m 30 -w '%{http_code}' -X POST "$url" \
    -H 'Content-Type: application/json' \
    -H 'Accept: application/json, text/event-stream' \
    -d '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2025-06-18","capabilities":{},"clientInfo":{"name":"validate-plugin","version":"0.0.0"}}}' \
    || echo "000")"
  # 401 is healthy: the server is up and correctly requires OAuth authorization.
  if [ "$code" = "401" ] || [ "$code" = "200" ]; then
    pass "MCP endpoint reachable (HTTP $code)"
  else
    err "MCP endpoint returned HTTP $code"
  fi
fi

echo
if [ "$fail" -eq 0 ]; then
  echo "Plugin validation passed."
else
  echo "Plugin validation FAILED." >&2
fi
exit "$fail"
