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
component_framework_version=2
device_name=""
remote=false
only_serve_runners=false
while (($#)); do
  case "$1" in
    --out)
      out="$2"
      shift
      ;;
    -c)
      component_framework_version="$2"
      # for `pm serve` `config.json` and if "2" (the default for this script)
      # use `pkgctl add` (which is not supported on older instances of fuchsia)
      # instead of `amberctl add_src`.
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

if [[ ${component_framework_version} != [12] ]]; then
  engine-error "valid values for -c are 1 or 2"
  exit 1
fi

fuchsia_build_dir="$(<"${FUCHSIA_DIR}/.fx-build-dir")"
if [[ "${fuchsia_build_dir:0:1}" != "/" ]]; then
  fuchsia_build_dir="${FUCHSIA_DIR}/${fuchsia_build_dir}"
fi

# If remote, there is currently no equivalent check, but perhaps there could be?
if [[ $remote != true ]]; then
  # Warn if the package server for the fuchsia packages is not running. Test
  # runners and any fuchsia package dependencies not included in the fuchsia
  # system image (via `--with-base` instead of `--with`) typically require
  # running `fx serve` (or equivalent commands), for the default `fuchsia.com`
  # (`devhost`) package URL domain.
  active_fuchsia_repo=$(
    ps -eo args \
      | sed -nre \
          "s#.*\bpm .*\bserve\b.* -repo ($FUCHSIA_DIR/out/.*)/amber-files.*#\1#p"
  )
  if [[ "${active_fuchsia_repo}" == "" ]]; then
    engine-warning 'The default fuchsia package server may not be running.'
    echo 'If your test requires packages or test runners from fuchsia, those'
    echo 'packages will need to be bundled in the fuchsia system image (such as'
    echo 'via `fx set ... --with-base <package_target> ...). If your test'
    echo 'includes fuchsia package dependencies that need to be served, kill'
    echo 'this flutter "engine" package server first, run `fx serve` (in'
    echo 'another window or shell), and then re-run this `serve.sh` script.'
    echo '(The launch order is important.)'
  elif [[ "${active_fuchsia_repo}" != "${fuchsia_build_dir}" ]]; then
    engine-warning 'There default fuchsia package server may be'
    echo 'serving packages from the wrong build directory:'
    echo "  ${active_fuchsia_repo}"
    echo 'which does not match your current build directory:'
    echo "  ${fuchsia_build_dir}"
    echo 'It may be serving the wrong packages. If so, kill all package'
    echo 'servers, and restart them. Make sure you start the fuchsia package'
    echo 'server (for example, via `fx serve`) **before** starting this'
    echo '`serve.sh` script'
  fi
fi

# Start our package server
# TODO: Need to ask for the out directory to find the package list
# TODO: Generate the all_packages.list file
cd "${FLUTTER_ENGINE_SRC_DIR}/${out}" || exit

if ! [[ -d "${FLUTTER_ENGINE_SRC_DIR}/${out}/tuf" ]]; then
  # Create the repository to serve
  "${FLUTTER_ENGINE_FUCHSIA_SDK_DIR}/tools/pm" newrepo -vt \
    -repo "${FLUTTER_ENGINE_SRC_DIR}/${out}/tuf"
fi

# Serve packages (run as a background process)
"${FLUTTER_ENGINE_FUCHSIA_SDK_DIR}/tools/pm" serve -vt \
  -repo "${FLUTTER_ENGINE_SRC_DIR}/${out}/tuf" \
  -l ":${port}" \
  -c "${component_framework_version}" \
  -p "${FLUTTER_ENGINE_SRC_DIR}/flutter/tools/fuchsia/all_packages.list" \
    &
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

  ssh_config="${fuchsia_build_dir}/ssh-keys/ssh_config"
  if [[ ! -e $ssh_config ]]; then
    engine-error "No valid ssh_config at $ssh_config"
  fi

  if [[ $remote == true ]]; then
    ssh -F "${ssh_config}" -p 8022 ::1 "$@"
  else
    ssh -F "${ssh_config}" "$serve_updates_target_addr" "$@"
  fi
}

if [[ $remote != true && -z "${device_name}" ]]; then
  device_name="$(cat ${fuchsia_build_dir}.device)"
fi

echo -n "Connecting to "
if $remote; then
  echo -n "remote device via ssh tunnel on port 8022..."
else
  echo -n "device '${device_name}', port ${port}..."
fi
# State is used to prevent too much output
state="discover"
while true; do
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
    echo
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

    if [[ ${component_framework_version} == 2 ]]; then
      run_ssh_command pkgctl repo add url \
        -n "engine" \
        "${config_url}"
    else
      run_ssh_command amberctl add_src \
        -n "engine" \
        -f "${config_url}"
    fi
    err=$?

    if [[ $err -ne 0 ]]; then
      engine-error "Failed to add update source"
      exit 1
    fi

    if [[ $only_serve_runners == true ]]; then
      run_ssh_command "pkgctl rule replace json '$(cat <<EOF
{
  "version": "1",
  "content": [
    {
      "host_match": "fuchsia.com", "host_replacement": "engine",
      "path_prefix_match": "/flutter_jit_runner/", "path_prefix_replacement": "/flutter_jit_runner/"
    },
    {
      "host_match": "fuchsia.com", "host_replacement": "engine",
      "path_prefix_match": "/flutter_jit_runner", "path_prefix_replacement": "/flutter_jit_runner"
    },
    {
      "host_match": "fuchsia.com", "host_replacement": "engine",
      "path_prefix_match": "/flutter_aot_runner/", "path_prefix_replacement": "/flutter_aot_runner/"
    },
    {
      "host_match": "fuchsia.com", "host_replacement": "engine",
      "path_prefix_match": "/flutter_aot_runner", "path_prefix_replacement": "/flutter_aot_runner"
    },
    {
      "host_match": "fuchsia.com", "host_replacement": "engine",
      "path_prefix_match": "/dart_jit_runner/", "path_prefix_replacement": "/dart_jit_runner/"
    },
    {
      "host_match": "fuchsia.com", "host_replacement": "engine",
      "path_prefix_match": "/dart_jit_runner", "path_prefix_replacement": "/dart_jit_runner"
    },
    {
      "host_match": "fuchsia.com", "host_replacement": "engine",
      "path_prefix_match": "/dart_aot_runner/", "path_prefix_replacement": "/dart_aot_runner/"
    },
    {
      "host_match": "fuchsia.com", "host_replacement": "engine",
      "path_prefix_match": "/dart_aot_runner", "path_prefix_replacement": "/dart_aot_runner"
    },
    {
      "host_match": "fuchsia.com", "host_replacement": "devhost",
      "path_prefix_match": "/", "path_prefix_replacement": "/"
    }
  ]
}
EOF
)'"

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
  else
    sleep 1
    echo -n "."
  fi
done
