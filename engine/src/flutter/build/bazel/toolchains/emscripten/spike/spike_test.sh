#!/bin/bash
# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# Runs the spike module in headless Chrome (phased_plan metric 0.6: "module
# loads and runs in headless Chrome"): serves the module's directory over
# HTTP -- an ES-module loader fetches its .wasm, which file: URLs do not
# allow -- opens spike.html, and reads the results the page writes into
# the document from Chrome's DOM dump. Chrome is the one named by CHROME
# in the environment (--test_env=CHROME=...), or the host's
# google-chrome; a hermetic browser is the web phase's (felt's CIPD
# Chrome).
#
# Usage: spike_test.sh <python3> <spike.html, in the directory of the module>
set -eu

python="$1"
site="$(dirname "$2")"
chrome="${CHROME:-$(command -v google-chrome || command -v chromium || echo /opt/google/chrome/chrome)}"
if [[ ! -x "$chrome" ]]; then
  echo "spike_test.sh: no Chrome: set CHROME (bazel test --test_env=CHROME=/path/to/chrome)" >&2
  exit 1
fi

scratch="$(mktemp -d "${TEST_TMPDIR:-${TMPDIR:-/tmp}}/spike_test.XXXXXX")"
server_pid=
clean_up() {
  if [[ -n "$server_pid" ]]; then
    kill "$server_pid" 2>/dev/null || :
    wait "$server_pid" 2>/dev/null || :
  fi
  rm -rf "$scratch"
}
trap clean_up EXIT

# Port 0: the server picks a free port and says which.
"$python" -u -m http.server --bind 127.0.0.1 --directory "$site" 0 >"$scratch/server.log" 2>&1 &
server_pid=$!
port=
for ((i = 0; i < 100; i++)); do
  port="$(sed -n 's/.*port \([0-9]*\).*/\1/p' "$scratch/server.log" | head -1)"
  if [[ -n "$port" ]]; then
    break
  fi
  if ! kill -0 "$server_pid" 2>/dev/null; then
    echo "spike_test.sh: the HTTP server exited:" >&2
    cat "$scratch/server.log" >&2
    exit 1
  fi
  sleep 0.1
done
if [[ -z "$port" ]]; then
  echo "spike_test.sh: the HTTP server did not report a port:" >&2
  cat "$scratch/server.log" >&2
  exit 1
fi

# The virtual time budget lets the page's asynchronous work (the module's
# instantiation) finish before the DOM is dumped.
"$chrome" --headless=new --no-sandbox --disable-gpu --no-first-run \
  --user-data-dir="$scratch/profile" --virtual-time-budget=20000 \
  --dump-dom "http://127.0.0.1:$port/spike.html" >"$scratch/dom.html" 2>"$scratch/chrome.log" || {
  echo "spike_test.sh: Chrome failed:" >&2
  cat "$scratch/chrome.log" >&2
  exit 1
}
results="$(sed -n '/<pre id="results">/,/<\/pre>/p' "$scratch/dom.html" | sed 's/<[^>]*>//g')"
echo "$results"
if [[ "$results" != *DONE* ]]; then
  echo "spike_test.sh: the page did not finish (no DONE in the DOM):" >&2
  cat "$scratch/dom.html" >&2
  exit 1
fi
if [[ "$results" == *FAIL* ]]; then
  exit 1
fi
