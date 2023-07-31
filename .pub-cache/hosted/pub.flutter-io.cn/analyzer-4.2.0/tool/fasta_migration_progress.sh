#!/usr/bin/env bash
# Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

# Script that collects progress metrics of the analyzer/FE integration.

# Metric 1: parser tests via fasta

# Run the suite to extract the total number of tests from the runner output.
# TODO(sigmund): don't require `dart` to be on the path.
total=$(find pkg/analyzer/test -name parser_fasta_test.dart -exec dart {} \; \
    -or -name *_kernel_test.dart -exec dart {} \; 2>/dev/null | \
  egrep '(All tests passed|Some tests failed)' | \
  sed -e "s/.*+\([0-9]*\)[^0-9].*All tests passed.*$/\1/" | \
  # For failures, parse +10 -1 into 10+1 so we can call bc
  sed -e "s/.*+\([0-9]*\)[^0-9].*-\([0-9]*\)[^0-9].*Some tests failed.*$/\1+\2/" | \
  # concatenate with + and call bc to add up failures
  paste -sd+ | \
  bc)

# Count tests marked with the @failingTest annotation.
fail=$(cat pkg/analyzer/test/generated/parser_fasta_test.dart \
    $(find pkg/analyzer/test -name *_kernel_test.dart) | \
  grep failingTest | wc -l)

pass_rate=$(bc <<< "scale=1; 100*($total-$fail)/$total")
echo "CFE enabled tests:          $(($total - $fail))/$total ($pass_rate%)"

# Metric 2: analyzer tests with fasta enabled.

# Run analyzer tests forcing the fasta parser, then process the logged output to
# count the number of individual tests (a single test case in a test file) that
# are passing or failing.

echo "Analyzer tests files (with fasta enabled):"
logfile=$1
delete=0

# If a log file is provided on the command line, reuse it and don't run the
# suite again.
if [[ $logfile == '' ]]; then
  logfile=$(mktemp log-XXXXXX.txt)
  echo "  Log file: $logfile"
  # TODO: delete by default and stop logging the location of the file.
  # delete=1
  python3 tools/test.py -m release --checked --use-sdk \
     --vm-options="-DuseFastaParser=true" \
     --print-passing-stdout \
     pkg/analy > $logfile
fi

pass=$(tail -1 $logfile | sed -e "s/.*+\s*\([0-9]*\) |.*$/\1/")
fail=$(tail -1 $logfile | sed -e "s/.* -\s*\([0-9]*\)\].*$/\1/")
pass_rate=$(bc <<< "scale=1; 100*$pass/($pass + $fail)")

echo "  Test files passing:       $pass/$(($pass + $fail)) ($pass_rate%)"

# Tests use package:test, which contains a summary line saying how many tests
# passed and failed.
#
# Files in which all tests pass end in:
#
#    MM:SS  +pp: All tests passed
#
# with some extra crap for color highlighting. Count those tests up:
passing_tests_temp=$(cat $logfile | \
  grep "All tests passed" | \
  sed -e "s/.*+\([0-9]*\).*All tests passed.*/\1/" |
  paste -sd+ | # concatenate with +
  bc) # sum

# Test files which had at least one failure end in:
#
#    MM:SS  +pp -ff: Some tests failed
#
# but also contains some escape sequences for color highlighting. The code below
# extracts the passing (pp) and failing (ff) numbers, plus the all-tests-passed
# counts, and prints the results:
cat $logfile | \
  grep "Some tests failed" | \
  sed -e "s/.*+\([0-9]*\).* -\([0-9]*\).*/\1 \2/" | \
   awk '
  {
    pass += $1
    total += $1 + $2
  } BEGIN {
    total = pass = '$passing_tests_temp'
  } END {
    printf ("  Individual tests passing: %d/%d (%.1f%)\n", \
      pass/2, total/2,(100 * pass / total))
  }'

if [[ $delete == 1 ]]; then
  echo "rm $logfile"
fi

# TODO: Add metric 3 - coverage of error codes
