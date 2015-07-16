#!/bin/sh
# Copyright (c) 2012 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# Scape errors from the valgrind bots, reproduce them locally,
# save logs as regrind-TESTNAME.log, and display any errors found.
# Also save files regrind-failed.txt listing failed tests,
# and regrind-failed-map.txt showing which bot URLs have which failed tests
# (handy when filing bugs).
#
# Only scrapes linux layout bot at the moment.
# TODO: handle layout tests that don't have obvious path to test file
# TODO: extend script to handle more kinds of errors and more tests

# where the valgrind layout bot results live
LAYOUT_URL="http://build.chromium.org/p/chromium.memory.fyi/builders/Webkit%20Linux%20(valgrind%20layout)"
# how many builds back to check
LAYOUT_COUNT=250

# regexp to match valgrind errors
PATTERN="are definitely|uninitialised|Unhandled exception|\
Invalid read|Invalid write|Invalid free|Source and desti|Mismatched free|\
unaddressable byte|vex x86|the 'impossible' happened|\
valgrind:.*: Assertion.*failed|VALGRIND INTERNAL ERROR"

usage() {
  echo "Usage: regrind.sh [--noscrape][--norepro][--keep]"
  echo "--noscrape: don't scrape bots, just use old regrind-failed.txt"
  echo "--norepro: don't reproduce locally"
  echo "--keep: keep temp files"
  exit 1
}

# Given a log on stdin, list all the tests that failed in that log.
layout_list_failed_tests() {
  grep "Command:.*LayoutTests" |
    sed 's/<.*>//' |
    sed 's/.*LayoutTests/LayoutTests/' |
    sort -u |
    tr -d '\015'
}

# Generate a list of failed tests in regrind-failed.txt by scraping bot.
# Scrape most recent first, so if user interrupts, he is left with fresh-ish data.
scrape_layout() {
  rm -f regrind-*.tmp* regrind-failed.txt regrind-failed-map.txt
  touch regrind-failed.txt

  # First, grab the number of the latest complete build.
  wget -q -O regrind-builds.html "$LAYOUT_URL"
  latest=`grep "<li><font .*" < regrind-builds.html | head -1 | sed 's/.*#//;s/<.*//'`

  echo "Fetching $LAYOUT_COUNT logs from bot"
  # Scrape the desired number of runs (150 is about one cycle)
  first=`expr $latest - $LAYOUT_COUNT`
  i=$latest
  while test $i -ge $first
  do
    url="$LAYOUT_URL/builds/$i/steps/valgrind%20test:%20layout/logs/stdio"
    wget -q -O regrind-$i.tmp "$url"
    # Did any tests fail in this file?
    layout_list_failed_tests < regrind-$i.tmp > regrind-$i.tmp.failed
    if test -s regrind-$i.tmp.failed
    then
      # Yes.  Log them to stdout,
      echo "$url"
      cat regrind-$i.tmp.failed
      # to the table regrind-failed-map.txt,
      cat regrind-$i.tmp.failed | sed "s,^,$url ,"   >> regrind-failed-map.txt
      # and, if not already there, to regrind-failed.txt.
      for test in `cat regrind-$i.tmp.failed`
      do
        fgrep "$test" regrind-failed.txt > /dev/null 2>&1 || echo "$test" >> regrind-failed.txt
      done
    else
      rm regrind-$i.tmp.failed
    fi
    # Sleep 1/3 sec per fetch
    case $i in
    *[036]) sleep 1;;
    esac
    i=`expr $i - 1`
  done

  # Finally, munge the logs to identify tests that probably failed.
  sh c.sh -l regrind-*.tmp > regrind-errfiles.txt
  cat `cat regrind-errfiles.txt` | layout_list_failed_tests > regrind-failed.txt
}

# Run the tests identified in regrind-failed.txt locally under valgrind.
# Save logs in regrind-$TESTNAME.log.
repro_layout() {
  echo Running `wc -l < regrind-failed.txt` layout tests.
  for test in `cat regrind-failed.txt`
  do
    logname="`echo $test | tr / _`"
    echo "sh tools/valgrind/valgrind_webkit_tests.sh $test"
    sh tools/valgrind/valgrind_webkit_tests.sh "$test" > regrind-"$logname".log 2>&1
    egrep "$PATTERN" < regrind-"$logname".log | sed 's/==.*==//'
  done
}

do_repro=1
do_scrape=1
do_cleanup=1
while test ! -z "$1"
do
  case "$1" in
  --noscrape) do_scrape=0;;
  --norepro) do_repro=0;;
  --keep) do_cleanup=0;;
  *) usage;;
  esac
  shift
done

echo "WARNING: This script is not supported and may be out of date"

if test $do_scrape = 0 && test $do_repro = 0
then
  usage
fi

if test $do_scrape = 1
then
  scrape_layout
fi

if test $do_repro = 1
then
  repro_layout
fi

if test $do_cleanup = 1
then
  rm -f regrind-errfiles.txt regrind-*.tmp*
fi
