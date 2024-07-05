#!/usr/bin/env bash
# Copyright 2014 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

set -e

function script_location() {
  local script_location="${BASH_SOURCE[0]}"
  # Resolve symlinks
  while [[ -h "$script_location" ]]; do
    DIR="$(cd -P "$( dirname "$script_location")" >/dev/null && pwd)"
    script_location="$(readlink "$script_location")"
    [[ "$script_location" != /* ]] && script_location="$DIR/$script_location"
  done
  cd -P "$(dirname "$script_location")" >/dev/null && pwd
}

<<<<<<< HEAD
function generate_docs() {
    # Install and activate dartdoc.
    # When updating to a new dartdoc version, please also update
    # `dartdoc_options.yaml` to include newly introduced error and warning types.
    "$DART" pub global activate dartdoc 6.2.2

    # Install and activate the snippets tool, which resides in the
    # assets-for-api-docs repo:
    # https://github.com/flutter/assets-for-api-docs/tree/master/packages/snippets
    "$DART" pub global activate snippets 0.3.0

    # This script generates a unified doc set, and creates
    # a custom index.html, placing everything into dev/docs/doc.
    (cd "$FLUTTER_ROOT/dev/tools" && "$FLUTTER" pub get)
    (cd "$FLUTTER_ROOT/dev/tools" && "$DART" pub get)
    (cd "$FLUTTER_ROOT" && "$DART" --disable-dart-dev --enable-asserts "$FLUTTER_ROOT/dev/tools/dartdoc.dart")
    (cd "$FLUTTER_ROOT" && "$DART" --disable-dart-dev --enable-asserts "$FLUTTER_ROOT/dev/tools/java_and_objc_doc.dart")
}

# Zip up the docs so people can download them for offline usage.
function create_offline_zip() {
  # Must be run from "$FLUTTER_ROOT/dev/docs"
  echo "$(date): Zipping Flutter offline docs archive."
  rm -rf flutter.docs.zip doc/offline
  (cd ./doc; zip -r -9 -q ../flutter.docs.zip .)
}

# Generate the docset for Flutter docs for use with Dash, Zeal, and Velocity.
function create_docset() {
  # Must be run from "$FLUTTER_ROOT/dev/docs"
  # Must have dashing installed: go get -u github.com/technosophos/dashing
  # Dashing produces a LOT of log output (~30MB), so we redirect it, and just
  # show the end of it if there was a problem.
  echo "$(date): Building Flutter docset."
  rm -rf flutter.docset
  # If dashing gets stuck, Cirrus will time out the build after an hour, and we
  # never get to see the logs. Thus, we run it in the background and tail the logs
  # while we wait for it to complete.
  dashing_log=/tmp/dashing.log
  dashing build --source ./doc --config ./dashing.json > $dashing_log 2>&1 &
  dashing_pid=$!
  wait $dashing_pid && \
  cp ./doc/flutter/static-assets/favicon.png ./flutter.docset/icon.png && \
  "$DART" --disable-dart-dev --enable-asserts ./dashing_postprocess.dart && \
  tar cf flutter.docset.tar.gz --use-compress-program="gzip --best" flutter.docset
  if [[ $? -ne 0 ]]; then
      >&2 echo "Dashing docset generation failed"
      tail -200 $dashing_log
      exit 1
  fi
}

function deploy_docs() {
    case "$LUCI_BRANCH" in
        master)
            echo "$(date): Updating $LUCI_BRANCH docs: https://master-api.flutter.dev/"
            # Disable search indexing on the master staging site so searches get only
            # the stable site.
            echo -e "User-agent: *\nDisallow: /" > "$FLUTTER_ROOT/dev/docs/doc/robots.txt"
            ;;
        stable)
            echo "$(date): Updating $LUCI_BRANCH docs: https://api.flutter.dev/"
            # Enable search indexing on the master staging site so searches get only
            # the stable site.
            echo -e "# All robots welcome!" > "$FLUTTER_ROOT/dev/docs/doc/robots.txt"
            ;;
        *)
            >&2 echo "Docs deployment cannot be run on the $LUCI_BRANCH branch."
            exit 0
    esac
}

# Move the offline archives into place, after all the processing of the doc
# directory is done. This avoids the tools recursively processing the archives
# as part of their process.
function move_offline_into_place() {
  # Must be run from "$FLUTTER_ROOT/dev/docs"
  echo "$(date): Moving offline data into place."
  mkdir -p doc/offline
  mv flutter.docs.zip doc/offline/flutter.docs.zip
  du -sh doc/offline/flutter.docs.zip
  if [[ "$LUCI_BRANCH" == "stable" ]]; then
    echo -e "<entry>\n  <version>${FLUTTER_VERSION_STRING}</version>\n  <url>https://api.flutter.dev/offline/flutter.docset.tar.gz</url>\n</entry>" > doc/offline/flutter.xml
  else
    echo -e "<entry>\n  <version>${FLUTTER_VERSION_STRING}</version>\n  <url>https://master-api.flutter.dev/offline/flutter.docset.tar.gz</url>\n</entry>" > doc/offline/flutter.xml
  fi
  mv flutter.docset.tar.gz doc/offline/flutter.docset.tar.gz
  du -sh doc/offline/flutter.docset.tar.gz
}

=======
>>>>>>> 761747bfc538b5af34aa0d3fac380f1bc331ec49
# So that users can run this script from anywhere and it will work as expected.
SCRIPT_LOCATION="$(script_location)"
# Sets the Flutter root to be "$(script_location)/../..": This script assumes
# that it resides two directory levels down from the root, so if that changes,
# then this line will need to as well.
FLUTTER_ROOT="$(dirname "$(dirname "$SCRIPT_LOCATION")")"
export FLUTTER_ROOT

echo "$(date): Running docs.sh"

if [[ ! -d "$FLUTTER_ROOT" || ! -f "$FLUTTER_ROOT/bin/flutter" ]]; then
  >&2 echo "Unable to locate the Flutter installation (using FLUTTER_ROOT: $FLUTTER_ROOT)"
  exit 1
fi

FLUTTER_BIN="$FLUTTER_ROOT/bin"
DART_BIN="$FLUTTER_ROOT/bin/cache/dart-sdk/bin"
FLUTTER="$FLUTTER_BIN/flutter"
DART="$DART_BIN/dart"
PATH="$FLUTTER_BIN:$DART_BIN:$PATH"

# Make sure dart is installed by invoking Flutter to download it if it is missing.
# Also make sure the flutter command is ready to run before capturing output from
# it: if it has to rebuild itself or something, it'll spoil our JSON output.
"$FLUTTER" > /dev/null 2>&1
FLUTTER_VERSION="$("$FLUTTER" --version --machine)"
export FLUTTER_VERSION

# If the pub cache directory exists in the root, then use that.
FLUTTER_PUB_CACHE="$FLUTTER_ROOT/.pub-cache"
if [[ -d "$FLUTTER_PUB_CACHE" ]]; then
  # This has to be exported, because pub interprets setting it to the empty
  # string in the same way as setting it to ".".
  PUB_CACHE="${PUB_CACHE:-"$FLUTTER_PUB_CACHE"}"
  export PUB_CACHE
fi

function usage() {
  echo "Usage: $(basename "${BASH_SOURCE[0]}") [--keep-temp] [--output <output.zip>]"
  echo ""
  echo "  --keep-staging             Do not delete the staging directory created while generating"
  echo "                             docs. Normally the script deletes the staging directory after"
  echo "                             generating the output ZIP file."
  echo "  --output <output.zip>      specifies where the output ZIP file containing the documentation"
  echo "                             data will be written."
  echo "  --staging-dir <directory>  specifies where the temporary output files will be written while"
  echo "                             generating docs. This directory will be deleted after generation"
  echo "                             unless --keep-staging is also specified."
  echo ""
}

function parse_args() {
  local arg
  local args=()
  STAGING_DIR=
  KEEP_STAGING=0
  DESTINATION="$FLUTTER_ROOT/dev/docs/api_docs.zip"
  while (( "$#" )); do
    case "$1" in
      --help)
        usage
        exit 0
        ;;
      --staging-dir)
        STAGING_DIR="$2"
        shift
        ;;
      --keep-staging)
        KEEP_STAGING=1
        ;;
      --output)
        DESTINATION="$2"
        shift
        ;;
      *)
        args=("${args[@]}" "$1")
        ;;
    esac
    shift
  done
  if [[ -z $STAGING_DIR ]]; then
    STAGING_DIR=$(mktemp -d /tmp/dartdoc.XXXXX)
  fi
  DOC_DIR="$STAGING_DIR/doc"
  if [[ ${#args[@]}  != 0 ]]; then
    >&2 echo "ERROR: Unknown arguments: ${args[@]}"
    usage
    exit 1
  fi
}

function build_snippets_tool() (
  local snippets_dir="$FLUTTER_ROOT/dev/snippets"
  local output_dir="$FLUTTER_BIN/cache/artifacts/snippets"
  echo "Building snippets tool executable."
  command cd "$snippets_dir"
  mkdir -p "$output_dir"
  dart pub get
  dart compile exe -o "$output_dir/snippets" bin/snippets.dart
)

function generate_docs() {
    # Install and activate dartdoc.
    # When updating to a new dartdoc version, please also update
    # `dartdoc_options.yaml` to include newly introduced error and warning types.
    "$DART" pub global activate dartdoc 8.0.6

    # Build and install the snippets tool, which resides in
    # the dev/docs/snippets directory.
    build_snippets_tool

    # This script generates a unified doc set, and creates
    # a custom index.html, placing everything into DOC_DIR.

    # Make sure that create_api_docs.dart has all the dependencies it needs.
    (cd "$FLUTTER_ROOT/dev/tools" && "$FLUTTER" pub get)
    (cd "$FLUTTER_ROOT" && "$DART" --disable-dart-dev --enable-asserts "$FLUTTER_ROOT/dev/tools/create_api_docs.dart" --output-dir="$DOC_DIR")
}

function main() {
  echo "Writing docs build temporary output to $DOC_DIR"
  mkdir -p "$DOC_DIR"
  generate_docs
  # If the destination isn't an absolute path, make it into one.
  if ! [[ "$DESTINATION" =~ ^/ ]]; then
    DESTINATION="$PWD/$DESTINATION"
  fi

  # Make sure the destination has .zip as an extension, because zip will add it
  # anyhow, and we want to print the correct output location.
  DESTINATION=${DESTINATION%.zip}.zip

  # Zip up doc directory and write the output to the destination.
  (cd "$STAGING_DIR"; zip -r -9 -q "$DESTINATION" ./doc)
  if [[ $KEEP_STAGING -eq 1 ]]; then
    echo "Staging documentation output left in $STAGING_DIR"
  else
    echo "Removing staging documentation output from $STAGING_DIR"
    rm -rf "$STAGING_DIR"
  fi
  echo "Wrote docs ZIP file to $DESTINATION"
}

parse_args "$@"
main
