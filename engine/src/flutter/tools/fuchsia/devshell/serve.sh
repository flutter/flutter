#!/bin/bash
# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.


### Serves the out directory
## usage:
##   --out <out_dir> Required. The out directory (ex: out/fuchsia_debug_x64).
##   -p <port> Optional. The port for "pm serve" to listen on. Defaults to 8084.
##   -d <device_name> Required for local workflows. The device_name to use for connecting.
##   -r Optional. Serve to a remote target.
##   --only-serve-runners Optional. Only serve the flutter and dart runners.

#TODO: Take an out directory and use that to find the list of packages to publish

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"/lib/vars.sh || exit $?

# We need to use the fuchsia checkout still, make sure it is there
ensure_fuchsia_dir

out=""
port="8084"
device_name=""
remote=false
only_serve_runners=false
while (($#)); do
  case "$1" in
    --out)
      out="$2"
      shift
      ;;
    -p)
      port="$2"
      shift
      ;;
    -d)
      device_name="$2"
      shift
      ;;
    -r)
      remote=true
      ;;
    --only-serve-runners)
      only_serve_runners=true
      ;;
    *)
      echo 2>&1 "Unknown argument: \"${1}\" ignored"
      ;;
  esac
  shift
done

if [[ -z "${out}" ]]; then
  engine-error "Must specify an out directory, such as out/fuchsia_debug_x64"
  exit 1
fi

# Start our package server
# TODO: Need to ask for the out directory to find the package list
# TODO: Generate the all_packages.list file
cd "${FLUTTER_ENGINE_SRC_DIR}" || exit
"${FLUTTER_ENGINE_FUCHSIA_SDK_DIR}/tools/pm" serve -vt \
  -repo "${FLUTTER_ENGINE_FUCHSIA_SDK_DIR}/${out}/tuf" \
  -l ":${port}" \
  -p "${FLUTTER_ENGINE_SRC_DIR}/flutter/tools/fuchsia/all_packages.list"&
serve_pid=$!

# Add debug symbols to the symbol index.
"${FLUTTER_ENGINE_FUCHSIA_SDK_DIR}/tools/symbol-index" add \
  "${FLUTTER_ENGINE_SRC_DIR}/${out}/.build-id" \
  "${FLUTTER_ENGINE_SRC_DIR}/${out}"

# Start our server and loop to check if our device is up give some slack time
# to ensure that pm has started
sleep 1

ffx="${FLUTTER_ENGINE_FUCHSIA_SDK_DIR}/tools/x64/ffx"

serve_updates_target_addr=""
resolve_local_target() {
  if [[ -z "${device_name}" ]]; then
    engine-error "Must specify a device name with -d if using a local workflow"
    exit 1
  fi
  result=$("${ffx}" target list "${device_name}" --format a 2> /dev/null)

  if [[ $? == 0 ]]; then
    serve_updates_target_addr=$result
  fi
}

resolve_target() {
  if [[ $remote == true ]]; then
    serve_updates_target_addr="-p 8022 ::1"
  else
    resolve_local_target
  fi
}

clear_target_addr() {
  serve_updates_target_addr=""
}

kill_child_processes() {
  child_pids=$(jobs -p)
  if [[ -n "${child_pids}" ]]; then
    # Note: child_pids must be expanded to args here.
    kill ${child_pids} 2> /dev/null
    wait 2> /dev/null
  fi
}
trap kill_child_processes EXIT

run_ssh_command() {
  # Enusre we have a target to ssh to
  if [[ -z $serve_updates_target_addr ]]; then
    return 1
  fi

  build_dir="$(<"${FUCHSIA_DIR}/.fx-build-dir")"
  ssh_config="${FUCHSIA_DIR}/${build_dir}/ssh-keys/ssh_config"
  if [[ ! -e $ssh_config ]]; then
    engine-error "No valid ssh_config at $ssh_config"
  fi

  if [[ $remote == true ]]; then
    ssh -F "${ssh_config}" -p 8022 ::1 "$@"
  else
    ssh -F "${ssh_config}" "$serve_updates_target_addr" "$@"
  fi
}

# State is used to prevent too much output
state="discover"
while true; do
  sleep 1
  if ! kill -0 "${serve_pid}" 2> /dev/null; then
    echo "Server died, exiting"
    serve_pid=
    exit 1
  fi

  if [[ "$state" == "discover" ]]; then
    # While we're still trying to connect to the device, clear the target
    # address state so we re-resolve.
    clear_target_addr
    resolve_target
    run_ssh_command exit 2>/dev/null
    ping_result=$?
  else
    run_ssh_command -O check > /dev/null 2>&1
    ping_result=$?
  fi

  if [[ "$state" == "discover" && "$ping_result" == 0 ]]; then
    echo "Device up"
    state="config"
  fi

  if [[ "$state" == "config" ]]; then
    echo "Registering engine as update source"

    # Get our ssh host address
    addr=$(run_ssh_command 'echo $SSH_CONNECTION' | cut -d ' ' -f 1)
    if [[ $? -ne 0 || -z "${addr}" ]]; then
      engine-error "unable to determine host address as seen from the target.  Is the target up?"
      exit 1
    fi

    addr="$(echo "${addr}" | sed 's/%/%25/g')"
    if [[ "${addr}" =~ : ]]; then
      addr="[${addr}]"
    fi

    config_url="http://${addr}:${port}/config.json"
    run_ssh_command amberctl add_src \
      -n "engine" \
      -f "${config_url}"
    err=$?

    if [[ $err -ne 0 ]]; then
      engine-error "Failed to add update source"
      exit 1
    fi

    if [[ $only_serve_runners == true ]]; then
      run_ssh_command "pkgctl rule replace json '
        {
          \"version\": \"1\",
          \"content\": [
            {
              \"host_match\": \"fuchsia.com\", \"host_replacement\": \"engine\",
              \"path_prefix_match\": \"/flutter_jit_runner/\", \"path_prefix_replacement\": \"/flutter_jit_runner/\"
            },
            {
              \"host_match\": \"fuchsia.com\", \"host_replacement\": \"engine\",
              \"path_prefix_match\": \"/flutter_jit_runner\", \"path_prefix_replacement\": \"/flutter_jit_runner\"
            },
            {
              \"host_match\": \"fuchsia.com\", \"host_replacement\": \"engine\",
              \"path_prefix_match\": \"/flutter_aot_runner/\", \"path_prefix_replacement\": \"/flutter_aot_runner/\"
            },
            {
              \"host_match\": \"fuchsia.com\", \"host_replacement\": \"engine\",
              \"path_prefix_match\": \"/flutter_aot_runner\", \"path_prefix_replacement\": \"/flutter_aot_runner\"
            },
            {
              \"host_match\": \"fuchsia.com\", \"host_replacement\": \"engine\",
              \"path_prefix_match\": \"/dart_jit_runner/\", \"path_prefix_replacement\": \"/dart_jit_runner/\"
            },
            {
              \"host_match\": \"fuchsia.com\", \"host_replacement\": \"engine\",
              \"path_prefix_match\": \"/dart_jit_runner\", \"path_prefix_replacement\": \"/dart_jit_runner\"
            },
            {
              \"host_match\": \"fuchsia.com\", \"host_replacement\": \"engine\",
              \"path_prefix_match\": \"/dart_aot_runner/\", \"path_prefix_replacement\": \"/dart_aot_runner/\"
            },
            {
              \"host_match\": \"fuchsia.com\", \"host_replacement\": \"engine\",
              \"path_prefix_match\": \"/dart_aot_runner\", \"path_prefix_replacement\": \"/dart_aot_runner\"
            },
            {
              \"host_match\": \"fuchsia.com\", \"host_replacement\": \"devhost\",
              \"path_prefix_match\": \"/\", \"path_prefix_replacement\": \"/\"
          }]
        }'"
      err=$?
      if [[ $err -ne 0 ]]; then
        engine-error "Failed to add runner rewrite rules"
        exit 1
      fi
    fi

    state="ready"
  fi

  if [[ "$state" == "ready" ]]; then
    if [[ "$ping_result" != 0 ]]; then
      echo "Device lost"
      state="discover"
    else
      sleep 1
    fi
  fi
done

