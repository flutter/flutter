# GitHub actions at Flutter

Action workflows can be enabled by writing a yaml file inside .github/workflows
folder of a given repository. These workflows run arbitrary code from GitHub
repositories and with read/write permissions in the repository assets. This can
be dangerous as anyone with write permissions to the repository can enable
workflows using malicious code. To mitigate this only workflows with pinned
commits within an allowed list can be executed.

Flutter repositories have workflows enabled with readonly ACLs by default. The
ACLs can be overwritten providing specific permissions in the configuration
file.

Determining whether a given workflow is secure or not goes well beyond flutter's
capacity and it is the responsibility of the person enabling the workflow to
diligently check the workflow for any potential security issues.

## Adding a new GitHub Actions workflow

To add a new workflow please open a new bug using the [ticket queue process](Infra-Ticket-Queue.md). The following data points are required:

*   Description/reason to enable this workflow
*   workflow repository
*   pinned commit

## Updating a GitHub Actions workflow

To update an existing workflow please open a new bug using the [ticket queue process](Infra-Ticket-Queue.md). The following data points are required:

*   Description/reason to update the pinned version
*   workflow/old_pinned_version
*   workflow/new_pinned_version

## flutter/engine and flutter/flutter

***flutter/engine*** please do not add any action workflows to this repository.
The preferred way of building and testing is to use LUCI. This allows to plan
for scalability, security and maintainability.

***flutter/flutter*** the main use of workflows in this repo is to process bugs,
projects, etc. Please do not use action workflows to build, run tests or release
artifacts.

## Responding to pull requests

Do not use the `pull_request_target` trigger. It runs with the base
repository's secrets and a write token on events from forks, and GitHub blocks
it by default in public repositories.

`pull_request` is safe for untrusted code, but runs from forks get a read-only
token and no secrets, so they can't comment, label, or push. Workflows that need
to do that are split into two halves, using the same names as in flutter/flutter
(for example `revert-trigger.yml` and `revert.yml`):

1. **The trigger** (`on: pull_request`) has a read-only token and no secrets.
   - Put cheap gates (label name, base branch, PR author) in the job-level
     `if:`, so events that don't match never allocate a runner.
   - When it applies, it uploads a small artifact with only context about the
     event: usually just the PR number, plus anything that can't be looked up
     later (such as the cherry-pick channel).
2. **The privileged workflow** (`on: workflow_run`) runs from the default
   branch, with access to secrets. It downloads the artifact and does the work.

The artifact is **untrusted**: a PR can change the trigger workflow, because
`pull_request` runs the workflow file from the PR's own merge commit. The
privileged workflow must:

- Check that `github.event.workflow_run.event == 'pull_request'` and that
  `github.event.workflow_run.path` is the expected trigger file.
  `workflow_run` matches workflows by `name:`, which a PR could copy.
- Bind the PR number to the triggering run: fetch the PR from the API and check
  that its head SHA and head repository match
  `github.event.workflow_run.head_sha` and `head_repository`.
- Read everything else (labels, merged state, merge commit, base branch, etc.)
  from the GitHub API rather than from the artifact. Any gate that made the
  trigger skip must be checked again here.
- Never check out or run code from the PR, and never interpolate artifact
  contents into scripts with `${{ }}`. Pass them through environment variables
  or files instead.

Only comment on a PR for problems the PR author can fix (for example, the PR
isn't merged, or a "reason for revert" comment is missing). Unexpected states
should fail the workflow instead.

Things to keep in mind:

- **First-time contributors:** their `pull_request` runs wait for a maintainer
  to approve them. Until then, the run is created already concluded as
  `action_required`, with no artifact, and it fires `workflow_run` with type
  `requested` but not `completed`. If the privileged workflow must handle these
  PRs right away (as `labeler.yml` does), also listen for `requested` and look
  up the PR from the run's `head_repository.owner.login`, `head_branch` and
  `head_sha`.
- **The trigger file must be in the PR's merge commit:** label-triggered
  automation won't work for PRs merged before its trigger workflow existed, or
  for PRs targeting release branches that don't have it. Consider adding a
  `workflow_dispatch` entry point to the privileged workflow as a fallback, as
  `revert.yml` and `easy-cp.yml` do.
- **zizmor** flags every `workflow_run` trigger as `dangerous-triggers`. Once
  the workflow follows the rules above, suppress it with a comment explaining
  why it is safe.

## Checklist

New workflow:

*   Does it have an associated bug?
*   Was the workflow/commit added to the allow list? Is the workflow pinned to a
    given commit?
*   If the workflow require write access, is it overriding the ACLs explicitly?
*   If the target repository has branch protection, is the configuration using
    ***secrets.FLUTTERGITHUBBOT_TOKEN*** instead of the default one?
*   Is the workflow configured to not run on forks?
*   Does it avoid `pull_request_target`? If it needs to act on pull requests
    from forks, does it follow the [pattern above](#responding-to-pull-requests)?

Update workflow:

*   Does it have an associated bug?
*   Was the workflow with old and new commits added to the allowed list?