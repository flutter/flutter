#!/bin/bash
# Copyright (c) 2010 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

about="Given a grep expression, creates a graph of occurrences of that
expression in the recent history of the tree.

Prerequisites: git and GNU R (apt-get install r-base).
"

set -e

target="$1"

if [ -z $target ]; then
    echo "usage: $0 <grep-compatible expression>"
    echo
    echo "$about"
    exit 1
fi

datafile=$(mktemp -t tmp.XXXXXXXXXX)
trap "rm -f $datafile" EXIT

echo 'ago count' > $datafile
for ago in {90..0}; do
    commit=$(git rev-list -1 --until="$ago days ago" origin/trunk)
    git checkout -q -f $commit
    count=$(git grep -E "$target" -- '*.cc' '*.h' '*.m' '*.mm' | wc -l)
    echo "-$ago $count" >> $datafile
    echo -n '.'
done

R CMD BATCH <(cat <<EOF
data = read.delim("$datafile", sep=' ')
png(width=600, height=300)
plot(count ~ ago, type="l", main="$target", xlab='days ago', data=data)
EOF
) /dev/null

echo done.  # Primarily to add a newline after all the dots.
