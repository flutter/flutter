#!/usr/bin/env bash
# Copyright 2014 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# Pre-push hook that detects pushes to branches associated with a PR
# and automatically starts the presubmit monitor loop.

while read -r local_ref local_sha remote_ref remote_sha; do
  branch="${local_ref#refs/heads/}"
  if [ -n "$branch" ] && command -v gh >/dev/null 2>&1; then
    pr_num=$(gh pr list --head "$branch" --json number -q '.[0].number' 2>/dev/null)
    if [ -n "$pr_num" ] && [ "$pr_num" != "null" ]; then
      echo "===================================================="
      echo "[PRE-PUSH] Detected PR #$pr_num for branch $branch"
      echo "[PRE-PUSH] Target Commit: $local_sha"
      echo "[PRE-PUSH] Launching Presubmit Monitor Loop..."
      echo "===================================================="
      (
        nohup dart .agents/skills/presubmit-monitor-loop/scripts/presubmit_monitor_loop.dart "$pr_num" > /tmp/presubmit_monitor_pr"${pr_num}".log 2>&1 &
      ) >/dev/null 2>&1
      echo "[PRE-PUSH] Presubmit monitor active in background: /tmp/presubmit_monitor_pr${pr_num}.log"
    fi
  fi
done

exit 0
