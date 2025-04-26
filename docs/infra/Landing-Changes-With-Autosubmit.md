# Using the Auto-submit Bot

This page details the workflow for Flutter's Auto-submit bot and how to use it to submit your changes into Flutter owned repositories.

## Auto-submit Labels

### Label descriptions and Who Applies these Labels

The following is a table of the labels that Auto-submit currently responds to
and who adds them.

| Label | Description | Human | Bot | Why? |
| --- | --- | :---: | :---: | --- |
| `autosubmit` | Merge a pull request when the tree becomes green. | X | | Merge on a validated pull request. |
| `revert` | Label used to initiate a revert request on a closed and merged PR. | X | | Revert a particular change that has been merged. |
| `revert of` | Tracking label for the revert request generated from the closed and merged original pull request. | | X | To track the new pull request that reverts a previous change. |
| `warning: land on red to fix tree breakage` | Override the tree-status check and land even when tree is closed. | X | | To submit a potential fix for the current tree-status |

Note: that `warning: land on red to fix tree breakage` cannot be used on its own
and should be used in conjunction with the `autosubmit` label.

### Usage Examples

#### Merging a change (tree is open)

This is the happy path. The tree is green and you just need to make
sure validations pass and have the correct number of reviews.

**Labels to use:** [ `autosubmit` ]

**Validations:**

* ci checks
* approvals (2 from flutter hackers)
* mergeability

#### Merging a fix on red tree-status (tree is closed)

This path should only be done in the event you have a change that will
contribute a fix to the status of the tree.

**Labels to use:** [ `autosubmit`, `warning: land on red to fix tree breakage` ]

**Validations:**

* ci checks
* approvals (2 from flutter hackers)
* mergeability
* ignores the results of the tree status check.

Warning: if you are not merging a fix for the tree you should not use the
`warning: land on red to fix tree breakage` label. You will need to wait for the
tree to open again.

#### Reverting a change from the tree

This path is a way to revert a broken change from the tree that is
within 24 hours old.

The reasoning behind this is that there will be someone with context as to
why the change needed to be reverted.

Note: that it might make sense to add the `warning: land on red to fix tree breakage`
label to a revert request but you do not need to do this. The revert request is
assumed to be done out of urgency.

**Labels to use:** [ `revert` ]

**Validations:**

* "required" ci checks \*
* mergeability

\* There are two types of required 'ci checks'. Ones that are controlled
by/through GitHub and those enforced through our auto-submit configuration
(TODO add link to the config). Currently there is only one required check in
both cases but the later can be extended to support additional checks.

#### Reverting older changes from the tree

This path describes what you should do in order to revert a change that is
older than 24 hours.

In this case you will need to open the revert request in the traditional way.
That is by navigating to your change in the GitHub UI and clicking the
'Revert' button from the pull request page.

The pull request will then need to be treated as a regular pull request where
you will need to wait for all ci checks to complete and gather 2 reviews from
members of the 'flutter-hackers' team. See
[Merging a change (tree is open)]() above.
