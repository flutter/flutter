---
name: checkout-pr
description: Check out a GitHub pull request into a local review branch using raw git, safely preserving any uncommitted local work first. Use whenever the user asks to review, check out, checkout, pull down, or look at a PR, given either a full GitHub PR URL or a bare PR number.
---

Check out a PR into a branch named `pr_review_<head_ref>_<pr_number>`, after
preserving the user's uncommitted work. Use plain `git` plus `curl` for
read-only metadata; never `gh`, since many contributors lack it.

Triggers: "review \<PR url\>", "check out 192932", "pull down PR 192932".

## Hard Rules

- NEVER run `git checkout -f`, `git reset --hard`, `git clean`, or
  `git stash drop`, or otherwise discard uncommitted work.
- NEVER push, force-push, or amend.
- NEVER create the review branch before local work is preserved.
- NEVER treat a skipped or ignored question as consent. A user re-sending
  their original request is impatience, not an answer. "This option is
  reversible" is not a reason to decide for them.
- NEVER carry an answer forward. Consent expires at the end of the turn it
  was given in. An answer from earlier in this conversation is not an answer
  to the question you are asking now, no matter how identical the situation
  looks.
- NEVER invent, default to, or recycle a branch name for the user's work.
  The name comes from the user, in their words, for this specific change.
  A name they coined for an earlier change is not a name for this one.
- NEVER characterize the user's uncommitted work ("looks like a typo",
  "probably debug code"). Report file paths and diffstat only.
- On any failure, STOP and report. Do not improvise a recovery that touches
  user changes.

## 1. Resolve the PR

Parse `https://github.com/<owner>/<repo>/pull/<number>`. For a bare number,
take `<owner>/<repo>` from `git remote -v` — prefer `upstream`, else
`origin`; ask if that remote is the user's fork and the target is ambiguous.

## 2. Read PR metadata

```bash
curl -sSL -H "Accept: application/vnd.github+json" \
  https://api.github.com/repos/<owner>/<repo>/pulls/<number> \
  | python3 -c "import json,sys; d=json.load(sys.stdin); print(d['head']['ref']); print(d['base']['ref']); print(d['state']); print(d['user']['login']); print(d['title'])"
```

Prints head ref, base ref, state, author, title.

- `"Not Found"` → wrong PR or repo. Stop.
- `closed` → tell the user, ask whether to continue.
- Request fails → don't stop. Use branch name `pr_review_<number>` and say
  the head ref couldn't be resolved.

## 3. Inspect local state

```bash
git rev-parse --abbrev-ref HEAD
git status --porcelain
git diff --stat
```

Git is the only source of truth. Never infer the working tree from editor
notifications, open files, or anything read earlier in the conversation —
those go stale within seconds. Re-run these immediately before step 4.

This applies to branches too. Never assert that a branch does or does not
exist based on earlier output — including your own `git switch` or
`git fetch` that succeeded minutes ago. Refs can disappear between turns.
Re-check at the moment you need the answer:

```bash
git rev-parse --verify --quiet refs/heads/<name>
```

If the user disputes a claim you made about repo state, re-run the command
and show the output before defending the claim.

`HEAD` means detached; treat it as "not on main", but mention the WIP commit
will land on a detached HEAD.

## 4. Preserve local work

| On main/master? | Dirty? | Action                                                             |
| --------------- | ------ | ------------------------------------------------------------------ |
| no              | no     | nothing                                                            |
| no              | yes    | `git add -A && git commit -m "WIP"`, then say which branch got it   |
| yes             | no     | nothing                                                            |
| yes             | yes    | ask — see below                                                    |

Dirty on `main`/`master` is the user's decision, not yours. Ask every time.

Ask even if you asked earlier in this conversation. Ask even if the user
answered five minutes ago, the modified file is the same file, and the
diffstat is byte-identical. Identical-looking changes are not the same
change, and an answer about the last one says nothing about this one. Do not
offer "same as last time" as a shortcut and do not preselect their previous
answer.

Ask:

1. **Abandon** → `git stash push -u -m "checkout-pr autostash before PR <number>"`,
   then mention `git stash pop` recovers it.
2. **Move to a new branch** → ask for the name, then
   `git switch -c <name> && git add -A && git commit -m "WIP"`.

Both the choice and the branch name must come from the user in the current
turn. Guessing either is a failure, even when the guess is convenient and
even when it turns out to be right. If they skip or ignore the question,
re-ask once as plain text and wait — an unanswered question blocks the
checkout.

## 5. Check out the PR

Branch name is `pr_review_<head_ref>_<pr_number>`, with every character
outside `[A-Za-z0-9._-]` in the head ref replaced by `_` (so head ref
`user/fix#1` on PR 42 → `pr_review_user_fix_1_42`).

If that branch already exists, ask whether to update or rename it. Never
delete it.

```bash
git fetch https://github.com/<owner>/<repo>.git refs/pull/<number>/head:<review_branch>
git switch <review_branch>
```

- `refs/pull/*` is read-only and exists for fork PRs too, so no extra remote
  is needed, and passing the URL works even when `origin` is the user's fork.
- To update an existing review branch, prefix the refspec with `+`.
- Git won't fetch into the currently checked-out branch. If already on
  `<review_branch>`, fetch `refs/pull/<number>/head` and
  `git merge --ff-only FETCH_HEAD`.
- An auth prompt means the repo is private; tell the user to configure
  credentials rather than retrying.

## 6. Report

- PR number, title, author, and the review branch now checked out.
- Where their prior work went and how to get it back — neutrally.
- The PR's changed files. Fetch the base last so `FETCH_HEAD` points at it:

  ```bash
  git fetch https://github.com/<owner>/<repo>.git <base_ref>
  git diff --stat FETCH_HEAD...HEAD
  ```
