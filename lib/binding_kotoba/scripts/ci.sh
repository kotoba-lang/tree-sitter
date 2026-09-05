#!/bin/sh
# Compile the Kotoba binding to wasm and run fixture tests on the web target.
set -eu
root=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
cd "$root"

if ! command -v kotoba >/dev/null 2>&1; then
  echo "kotoba CLI is required (kotoba-lang/kotoba v0.7.2)" >&2
  exit 1
fi

compile_wasm() {
  src=$1
  out=$2
  json=$(kotoba compile "$src" --target wasm --output "$out" --json)
  echo "$json" | python3 -c '
import json,sys
d=json.load(sys.stdin)
ok=d.get("kotoba.cli/ok?")
code=d.get("kotoba.cli/code")
print(sys.argv[1], ok, code, d.get("kotoba.cli/message") or "")
if not ok or code != "emitted":
    sys.exit(1)
' "$src"
  python3 -c '
import sys
b=open(sys.argv[1],"rb").read()
if b[:4] != b"\x00asm":
    print("not wasm magic", sys.argv[1], file=sys.stderr)
    sys.exit(1)
' "$out"
}

mkdir -p /tmp/binding-kotoba-ci
compile_wasm src/tree_sitter.kotoba /tmp/binding-kotoba-ci/tree_sitter.wasm

for guest in examples/walk_fixture.kotoba test/fixtures.kotoba; do
  bundled=/tmp/binding-kotoba-ci/$(basename "$guest")
  scripts/bundle.sh "$bundled" "$guest"
  compile_wasm "$bundled" "/tmp/binding-kotoba-ci/$(basename "$guest" .kotoba).wasm"
done

scripts/bundle.sh /tmp/binding-kotoba-ci/fixtures.kotoba test/fixtures.kotoba
web_json=$(kotoba compile /tmp/binding-kotoba-ci/fixtures.kotoba --target web --output /tmp/binding-kotoba-ci/fixtures.mjs --json)
echo "$web_json" | python3 -c '
import json,sys
d=json.load(sys.stdin)
print("fixtures web", d.get("kotoba.cli/ok?"), d.get("kotoba.cli/code"), d.get("kotoba.cli/message") or "")
if not d.get("kotoba.cli/ok?") or d.get("kotoba.cli/code") != "emitted":
    sys.exit(1)
'

node scripts/run-fixtures.mjs /tmp/binding-kotoba-ci/fixtures.mjs
