#!/bin/bash
# Copyright 2013 The Chromium Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.
#
# Script for printing recent commits in a buildbot run.

# Return the sha1 of the given tag.  If not present, return "".
# $1: path to repo
# $2: tag name
tt_sha1_for_tag() {
  oneline=$(cd $1 && git log -1 $2 --format='%H' 2>/dev/null)
  if [ $? -eq 0 ] ; then
    echo $oneline
  fi
}

# Return the sha1 of HEAD, or ""
# $1: path to repo
tt_sha1_for_head() {
  ( cd $1 && git log HEAD -n1 --format='%H' | cat )
}

# For the given repo, set tag to HEAD.
# $1: path to repo
# $2: tag name
tt_tag_head() {
  ( cd $1 && git tag -f $2 )
}

# For the given repo, delete the tag.
# $1: path to repo
# $2: tag name
tt_delete_tag() {
  ( cd $1 && git tag -d $2 )
}

# For the given repo, set tag to "three commits ago" (for testing).
# $1: path to repo
# $2: tag name
tt_tag_three_ago() {
 local sh=$(cd $1 && git log --pretty=oneline -n 3 | tail -1 | awk '{print $1}')
  ( cd $1 && git tag -f $2 $sh )
}

# List the commits between the given tag and HEAD.
# If the tag does not exist, only list the last few.
# If the tag is at HEAD, list nothing.
# Output format has distinct build steps for repos with changes.
# $1: path to repo
# $2: tag name
# $3: simple/short repo name to use for display
tt_list_commits() {
  local tag_sha1=$(tt_sha1_for_tag $1 $2)
  local head_sha1=$(tt_sha1_for_head $1)
  local display_name=$(echo $3 | sed 's#/#_#g')
  if [ "${tag_sha1}" = "${head_sha1}" ] ; then
    return
  fi
  if [ "${tag_sha1}" = "" ] ; then
    echo "@@@BUILD_STEP Recent commits in repo $display_name@@@"
    echo "NOTE: git tag was not found so we have no baseline."
    echo "Here are some recent commits, but they may not be new for this build."
    ( cd $1 && git log -n 10 --stat | cat)
  else
    echo "@@@BUILD_STEP New commits in repo $display_name@@@"
    ( cd $1 && git log -n 500 $2..HEAD --stat | cat)
  fi
}

# Clean out the tree truth tags in all repos.  For testing.
tt_clean_all() {
 for project in $@; do
   tt_delete_tag $CHROME_SRC/../$project tree_truth
 done
}

# Print tree truth for all clank repos.
tt_print_all() {
 for project in $@; do
   local full_path=$CHROME_SRC/../$project
   tt_list_commits $full_path tree_truth $project
   tt_tag_head $full_path tree_truth
 done
}

# Print a summary of the last 10 commits for each repo.
tt_brief_summary() {
  echo "@@@BUILD_STEP Brief summary of recent CLs in every branch@@@"
  for project in $@; do
    echo $project:
    local full_path=$CHROME_SRC/../$project
    (cd $full_path && git log -n 10 --format="   %H %s   %an, %ad" | cat)
    echo "================================================================="
  done
}

CHROME_SRC=$1
shift
PROJECT_LIST=$@
tt_brief_summary $PROJECT_LIST
tt_print_all $PROJECT_LIST
