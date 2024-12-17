#!/usr/bin/env bash
# Copyright 2014 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# ---------------------------------- NOTE ---------------------------------- #
#
# We must keep the logic in this file consistent with the logic in the
# `engine_hash.dart` script in the same directory to ensure that Flutter
# continues to work across all platforms!
#
# -------------------------------------------------------------------------- #

# TODO(codefu): Add a test that this always outputs the same hash as
# `engine_hash.dart` when the repositories are merged

STRATEGY=head

HELP=$(
    cat <<EOF
Calculate the hash signature for the Flutter Engine\n
\t-s|--strategy\t<head,mergeBase>\n
\t\tthead:      hash from git HEAD\n
\t\tmergeBase: hash from the merge-base of HEAD and upstream/master\n
EOF
)

function print_help() {
    if [ "${1:-0}" -eq 0 ]; then
        echo -e $HELP
        exit 0
    else
        echo >&2 -e $HELP
        exit $1
    fi
}

while [[ "$#" -gt 0 ]]; do
    case $1 in
    -s | --strategy)
        STRATEGY="$2"
        shift # past argument
        shift # past value
        ;;
    -h | --help)
        print_help
        ;;
    -* | --*)
        echo >&2 -e "Unknown option $1\n"
        print_help 1
        ;;
    esac
done

BASE=HEAD
case $STRATEGY in
head) ;;
mergeBase)
    BASE=$(git merge-base upstream/master HEAD)
    ;;
*)
    echo >&2 -e "Unknown strategy $1\n"
    print_help 1
    ;;
esac

LSTREE=$(git ls-tree -r $BASE engine DEPS)
if [ ${#LSTREE} -eq 0 ]; then
    echo >&2 Error calculating engine hash: Not in a monorepo
    exit 1
else
    HASH=$(echo "$LSTREE" | sha1sum | head -c 40)
    echo $HASH
fi
