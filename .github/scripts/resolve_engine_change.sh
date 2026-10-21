#!/usr/bin/env bash
# Copyright 2014 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# Resolves whether engine-tracked files changed for the current GitHub Actions
# event and identifies the commit SHA whose prebuilt engine artifacts should be
# used when waiting on LUCI.
#
# For stacked pull requests (where PR_BASE_REF is a parent feature branch rather
# than master/main/stable/beta/release-candidate) or fork pull requests,
# bin/internal/content_aware_hash.sh falls back to the merge-base with
# upstream/master (or origin/master). Diffing only against PR_BASE_SHA misses
# engine changes introduced in an earlier unmerged branch of the stack.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
cd "$REPO_ROOT"

EVENT_NAME="${EVENT_NAME:-}"
GITHUB_REPOSITORY="${GITHUB_REPOSITORY:-flutter/flutter}"
PR_BASE_REF="${PR_BASE_REF:-}"
PR_BASE_SHA="${PR_BASE_SHA:-}"
PR_HEAD_SHA="${PR_HEAD_SHA:-$(git rev-parse HEAD)}"
MERGE_GROUP_BASE_SHA="${MERGE_GROUP_BASE_SHA:-}"
PUSH_BEFORE_SHA="${PUSH_BEFORE_SHA:-}"
EMPTY_SHA="0000000000000000000000000000000000000000"

resolve_trunk_ref() {
  if git show-ref --verify --quiet refs/remotes/upstream/master; then
    echo "upstream/master"
  elif git show-ref --verify --quiet refs/remotes/upstream/main; then
    echo "upstream/main"
  elif git show-ref --verify --quiet refs/remotes/origin/master; then
    echo "origin/master"
  elif git show-ref --verify --quiet refs/remotes/origin/main; then
    echo "origin/main"
  else
    echo ""
  fi
}

is_release_branch() {
  local ref="$1"
  case "$ref" in
    stable|beta|flutter-*-candidate.*)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

is_trunk_branch() {
  local ref="$1"
  case "$ref" in
    master|main)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

CHANGED="false"
ENGINE_SHA=""

if [ "$EVENT_NAME" = "pull_request" ]; then
  if [ "$GITHUB_REPOSITORY" != "flutter/flutter" ] && ! is_release_branch "$PR_BASE_REF"; then
    # On fork repositories, LUCI does not build flutter_archives_v2 and
    # content_aware_hash.sh always resolves prebuilt engine artifacts from the
    # merge-base with upstream/master (or origin/master), even if the fork's own
    # master or stacked parent branch differs.
    BASE_REF="$(resolve_trunk_ref)"
    if [ -z "$BASE_REF" ]; then
      BASE_REF="$PR_BASE_SHA"
    fi
    echo "Fork PR detected (repo: '$GITHUB_REPOSITORY', base ref: '${PR_BASE_REF:-unknown}'); comparing against: $BASE_REF"
    CHANGED_FILES="$("$SCRIPT_DIR/git_files_changed.sh" "$BASE_REF")"
    echo "Changed files relative to $BASE_REF:"
    echo "$CHANGED_FILES"
    if [ "$(printf '%s\n' "$CHANGED_FILES" | "$SCRIPT_DIR/did_engine_change.sh")" = "true" ]; then
      CHANGED="true"
      ENGINE_SHA="$PR_HEAD_SHA"
    fi
  else
    PR_DIRECT_CHANGED="false"
    if [ -n "$PR_BASE_SHA" ]; then
      echo "Comparing PR diff against base SHA: $PR_BASE_SHA"
      PR_CHANGED_FILES="$("$SCRIPT_DIR/git_files_changed.sh" "$PR_BASE_SHA")"
      echo "Changed files in PR diff:"
      echo "$PR_CHANGED_FILES"
      if [ "$(printf '%s\n' "$PR_CHANGED_FILES" | "$SCRIPT_DIR/did_engine_change.sh")" = "true" ]; then
        PR_DIRECT_CHANGED="true"
      fi
    fi

    if [ "$PR_DIRECT_CHANGED" = "true" ]; then
      CHANGED="true"
      ENGINE_SHA="$PR_HEAD_SHA"
    elif ! is_trunk_branch "$PR_BASE_REF" && ! is_release_branch "$PR_BASE_REF"; then
      TRUNK_REF="$(resolve_trunk_ref)"
      if [ -n "$TRUNK_REF" ]; then
        echo "Stacked PR detected (base ref: '${PR_BASE_REF:-unknown}'); comparing against trunk ref: $TRUNK_REF"
        STACK_CHANGED_FILES="$("$SCRIPT_DIR/git_files_changed.sh" "$TRUNK_REF")"
        echo "Changed files relative to $TRUNK_REF:"
        echo "$STACK_CHANGED_FILES"
        if [ "$(printf '%s\n' "$STACK_CHANGED_FILES" | "$SCRIPT_DIR/did_engine_change.sh")" = "true" ]; then
          CHANGED="true"
          MERGE_BASE="$(git merge-base "$TRUNK_REF" HEAD)"
          ENGINE_SHA="$(git log -1 --pretty=format:%H "$MERGE_BASE..HEAD" -- \
            DEPS engine bin/internal/content_aware_hash.sh bin/internal/content_aware_hash.ps1 bin/internal/release-candidate-branch.version)"
          if [ -z "$ENGINE_SHA" ]; then
            ENGINE_SHA="$PR_HEAD_SHA"
          fi
        fi
      fi
    fi
  fi
else
  if [ "$EVENT_NAME" = "merge_group" ]; then
    BASE_REF="$MERGE_GROUP_BASE_SHA"
  elif [ "$EVENT_NAME" = "push" ] && [ -n "$PUSH_BEFORE_SHA" ] && [ "$PUSH_BEFORE_SHA" != "$EMPTY_SHA" ]; then
    BASE_REF="$PUSH_BEFORE_SHA"
  else
    BASE_REF="$(resolve_trunk_ref)"
  fi

  echo "Comparing against base SHA: $BASE_REF"
  CHANGED_FILES="$("$SCRIPT_DIR/git_files_changed.sh" "$BASE_REF")"
  echo "Changed files in this branch:"
  echo "$CHANGED_FILES"

  if [ "$(printf '%s\n' "$CHANGED_FILES" | "$SCRIPT_DIR/did_engine_change.sh")" = "true" ]; then
    CHANGED="true"
    ENGINE_SHA="$PR_HEAD_SHA"
  fi
fi

if [ "$CHANGED" = "true" ]; then
  echo "Engine files changed (engine_sha=$ENGINE_SHA)."
else
  echo "No engine files changed."
fi

if [ -n "${GITHUB_OUTPUT:-}" ]; then
  {
    echo "changed=$CHANGED"
    echo "engine_sha=$ENGINE_SHA"
  } >> "$GITHUB_OUTPUT"
fi
