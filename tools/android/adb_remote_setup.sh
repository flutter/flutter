#!/bin/bash
# Copyright 2014 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# URL from which the latest version of this script can be downloaded.
# Gitiles returns the result as base64 formatted, so the result needs to be
# decoded. See https://code.google.com/p/gitiles/issues/detail?id=7 for
# more information about this security precaution.
script_url="https://chromium.googlesource.com/chromium/src.git/+/master"
script_url+="/tools/android/adb_remote_setup.sh"
script_url+="?format=TEXT"

# Replaces this file with the latest version of the script and runs it.
update-self() {
  local script="${BASH_SOURCE[0]}"
  local new_script="${script}.new"
  local updater_script="${script}.updater"
  curl -sSf "$script_url" | base64 --decode > "$new_script" || return
  chmod +x "$new_script" || return

  # Replace this file with the newly downloaded script.
  cat > "$updater_script" << EOF
#!/bin/bash
if mv "$new_script" "$script"; then
  rm -- "$updater_script"
else
  echo "Note: script update failed."
fi
ADB_REMOTE_SETUP_NO_UPDATE=1 exec /bin/bash "$script" $@
EOF
  exec /bin/bash "$updater_script" "$@"
}

if [[ "$ADB_REMOTE_SETUP_NO_UPDATE" -ne 1 ]]; then
  update-self "$@" || echo 'Note: script update failed'
fi

if [[ $# -ne 1 && $# -ne 2 ]]; then
  cat <<'EOF'
Usage: adb_remote_setup.sh REMOTE_HOST [REMOTE_ADB]

Configures adb on a remote machine to communicate with a device attached to the
local machine. This is useful for installing APKs, running tests, etc while
working remotely.

Arguments:
  REMOTE_HOST  hostname of remote machine
  REMOTE_ADB   path to adb on the remote machine (you can omit this if adb is in
               the remote host's path)
EOF
  exit 1
fi

remote_host="$1"
remote_adb="${2:-adb}"

# Ensure adb is in the local machine's path.
if ! which adb >/dev/null; then
  echo "error: adb must be in your local machine's path."
  exit 1
fi

# Ensure local and remote versions of adb are the same.
remote_adb_version=$(ssh "$remote_host" "$remote_adb version")
local_adb_version=$(adb version)
if [[ "$local_adb_version" != "$remote_adb_version" ]]; then
  echo >&2
  echo "WARNING: local adb is not the same version as remote adb." >&2
  echo "This should be fixed since it may result in protocol errors." >&2
  echo "  local adb:  $local_adb_version" >&2
  echo "  remote adb: $remote_adb_version" >&2
  echo >&2
  sleep 5
fi

# Kill the adb server on the remote host.
ssh "$remote_host" "$remote_adb kill-server"

# Start the adb server locally.
adb start-server

# Forward various ports from the remote host to the local host:
#   5037: adb
#   8001: http server
#   9031: sync server
#   9041: search by image server
#   9051: policy server
#   10000: net unittests
#   10201: net unittests
ssh -C \
    -R 5037:localhost:5037 \
    -L 8001:localhost:8001 \
    -L 9031:localhost:9031 \
    -L 9041:localhost:9041 \
    -L 9051:localhost:9051 \
    -R 10000:localhost:10000 \
    -R 10201:localhost:10201 \
    "$remote_host"
