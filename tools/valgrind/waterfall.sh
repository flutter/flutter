#!/bin/bash

# Copyright (c) 2011 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# This script can be used by waterfall sheriffs to fetch the status
# of Valgrind bots on the memory waterfall and test if their local
# suppressions match the reports on the waterfall.

set -e

THISDIR=$(dirname "${0}")
LOGS_DIR=$THISDIR/waterfall.tmp
WATERFALL_PAGE="http://build.chromium.org/p/chromium.memory/builders"
WATERFALL_FYI_PAGE="http://build.chromium.org/p/chromium.memory.fyi/builders"

download() {
  # Download a file.
  # $1 = URL to download
  # $2 = Path to the output file
  # {{{1
  if [ "$(which curl)" != "" ]
  then
    if ! curl -s -o "$2" "$1"
    then
      echo
      echo "Failed to download '$1'... aborting"
      exit 1
    fi
  elif [ "$(which wget)" != "" ]
  then
    if ! wget "$1" -O "$2" -q
    then
      echo
      echo "Failed to download '$1'... aborting"
      exit 1
    fi
  else
    echo "Need either curl or wget to download stuff... aborting"
    exit 1
  fi
  # }}}
}

fetch_logs() {
  # Fetch Valgrind logs from the waterfall {{{1

  # TODO(timurrrr,maruel): use JSON, see
  # http://build.chromium.org/p/chromium.memory/json/help

  rm -rf "$LOGS_DIR" # Delete old logs
  mkdir "$LOGS_DIR"

  echo "Fetching the list of builders..."
  download $1 "$LOGS_DIR/builders"
  SLAVES=$(grep "<a href=\"builders\/" "$LOGS_DIR/builders" | \
           grep 'td class="box"' | \
           sed "s/.*<a href=\"builders\///" | sed "s/\".*//" | \
           sort | uniq)

  for S in $SLAVES
  do
    SLAVE_URL=$1/$S
    SLAVE_NAME=$(echo $S | sed -e "s/%20/ /g" -e "s/%28/(/g" -e "s/%29/)/g")
    echo -n "Fetching builds by slave '${SLAVE_NAME}'"
    download $SLAVE_URL?numbuilds=${NUMBUILDS} "$LOGS_DIR/slave_${S}"

    # We speed up the 'fetch' step by skipping the builds/tests which succeeded.
    # TODO(timurrrr): OTOH, we won't be able to check
    # if some suppression is not used anymore.
    #
    # The awk script here joins the lines ending with </td> to make it possible
    # to find the failed builds.
    LIST_OF_BUILDS=$(cat "$LOGS_DIR/slave_$S" | \
                     awk 'BEGIN { buf = "" }
                          {
                            if ($0 ~ /<\/td>/) { buf = (buf $0); }
                            else {
                              if (buf) { print buf; buf="" }
                              print $0
                            }
                          }
                          END {if (buf) print buf}' | \
                     grep "success\|failure" | \
                     head -n $NUMBUILDS | \
                     grep "failure" | \
                     grep -v "failed compile" | \
                     sed "s/.*\/builds\///" | sed "s/\".*//")

    for BUILD in $LIST_OF_BUILDS
    do
      # We'll fetch a few tiny URLs now, let's use a temp file.
      TMPFILE=$(mktemp -t memory_waterfall.XXXXXX)
      download $SLAVE_URL/builds/$BUILD "$TMPFILE"

      REPORT_FILE="$LOGS_DIR/report_${S}_${BUILD}"
      rm -f $REPORT_FILE 2>/dev/null || true  # make sure it doesn't exist

      REPORT_URLS=$(grep -o "[0-9]\+/steps/memory.*/logs/[0-9A-F]\{16\}" \
                    "$TMPFILE" \
                    || true)  # `true` is to succeed on empty output
      FAILED_TESTS=$(grep -o "[0-9]\+/steps/memory.*/logs/[A-Za-z0-9_.]\+" \
                     "$TMPFILE" | grep -v "[0-9A-F]\{16\}" \
                     | grep -v "stdio" || true)

      for REPORT in $REPORT_URLS
      do
        download "$SLAVE_URL/builds/$REPORT/text" "$TMPFILE"
        echo "" >> "$TMPFILE"  # Add a newline at the end
        cat "$TMPFILE" | tr -d '\r' >> "$REPORT_FILE"
      done

      for FAILURE in $FAILED_TESTS
      do
        echo -n "FAILED:" >> "$REPORT_FILE"
        echo "$FAILURE" | sed -e "s/.*\/logs\///" -e "s/\/.*//" \
          >> "$REPORT_FILE"
      done

      rm "$TMPFILE"
      echo $SLAVE_URL/builds/$BUILD >> "$REPORT_FILE"
    done
    echo " DONE"
  done
  # }}}
}

match_suppressions() {
  PYTHONPATH=$THISDIR/../python/google \
             python "$THISDIR/test_suppressions.py" $@ "$LOGS_DIR/report_"*
}

match_gtest_excludes() {
  for PLATFORM in "Linux" "Chromium%20Mac" "Chromium%20OS" "Windows"
  do
    echo
    echo "Test failures on ${PLATFORM}:" | sed "s/%20/ /"
    grep -h -o "^FAILED:.*" -R "$LOGS_DIR"/*${PLATFORM}* | \
         grep -v "FAILS\|FLAKY" | sort | uniq | \
         sed -e "s/^FAILED://" -e "s/^/  /"
    # Don't put any operators between "grep | sed" and "RESULT=$PIPESTATUS"
    RESULT=$PIPESTATUS

    if [ "$RESULT" == 1 ]
    then
      echo "  None!"
    else
      echo
      echo "  Note: we don't check for failures already excluded locally yet"
      echo "  TODO(timurrrr): don't list tests we've already excluded locally"
    fi
  done
  echo
  echo "Note: we don't print FAILS/FLAKY tests and 1200s-timeout failures"
}

usage() {
  cat <<EOF
usage: $0 fetch|match options

This script can be used by waterfall sheriffs to fetch the status
of Valgrind bots on the memory waterfall and test if their local
suppressions match the reports on the waterfall.

OPTIONS:
   -h      Show this message
   -n N    Fetch N builds from each slave.

COMMANDS:
  fetch    Fetch Valgrind logs from the memory waterfall
  match    Test the local suppression files against the downloaded logs

EOF
}

NUMBUILDS=3

CMD=$1
if [ $# != 0 ]; then
  shift
fi

# Arguments for "match" are handled in match_suppressions
if [ "$CMD" != "match" ]; then
  while getopts “hn:” OPTION
  do
    case $OPTION in
      h)
        usage
        exit
        ;;
      n)
        NUMBUILDS=$OPTARG
        ;;
      ?)
        usage
        exit
        ;;
    esac
  done
  shift $((OPTIND-1))
  if [ $# != 0 ]; then
    usage
    exit 1
  fi
fi

if [ "$CMD" = "fetch" ]; then
  echo "Fetching $NUMBUILDS builds"
  fetch_logs $WATERFALL_PAGE
  fetch_logs $WATERFALL_FYI_PAGE
elif [ "$CMD" = "match" ]; then
  match_suppressions $@
  match_gtest_excludes
elif [ "$CMD" = "blame" ]; then
  echo The blame command died of bitrot. If you need it, please reimplement it.
  echo Reimplementation is blocked on http://crbug.com/82688
else
  usage
  exit 1
fi
