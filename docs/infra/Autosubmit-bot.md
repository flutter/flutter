# What is the Autosubmit Bot

The Flutter autosubmit bot is a tool that helps developers submit changes to the Flutter codebase. It automates the process of validating pull requests, test validation, and merging changes. This frees up developers to focus on writing code, and makes it easier to contribute to the Flutter project.

# The Autosubmit Workflow

## Submitting a Pull Request

When a developer opens a pull request against any of the currently supported repositories, the cocoon backend will schedule tests and checks against that pull request. Rather than have the developer wait around to make sure all these tests and validations have completed, they can add a label and the Autosubmit bot will then queue that pull request for merge upon successfully passing all checks and validations. It will look something like this:

1. You have a change you would like to contribute to flutter so you open a pull request.
2. Dozens of tests will start in the background against your changes.
3. You can add the `autosubmit` label to notify the Autosubmit bot that you would like it to merge the pull request upon successful validation.
4. If all validations are successful the Autosubmit bot will merge the pull request.

## What Validations does the Autosubmit Bot Perform

### Code Reviews

The following are the rules for code reviews:
* If the author is a member of the GitHub `flutter-hackers` org then they will need **at least 1 other review** from a member of the `flutter-hackers` org, preferable a code owner from that repository.
* If the author is not a member of the GitHub `flutter-hackers` org then they will need **at least 2 other reviews** from members of the `flutter-hackers` org.
* If any reviewer requests changes then regardless of the number of approvals you have the pull request will not be merged by the Autosubmit bot and the `autosubmit` label will be removed until the reviewer who requested changes has approved the pull request.

### Check Runs and Statuses

When a pull request is opened the Cocoon backend service will create a number of test runs that will be used to validate the code change that was submitted. Once the `autosubmit` label is added, the Autosubmit bot will check the statuses of those tests and will not merge the pull request until all of them have succeeded. If any of the tests have failed the `autosubmit` label will be removed and the bot will no longer process that pull request. However the developer can re-trigger the test and add the label again to retry.

### Other Checks

The Autosubmit bot will make several other checks to determine viability of the pull request up until the moment the pull request is queued for merge. They are:
* merge-ability - this is a GitHub status that says the code can be merged into the mainline branch.
* code conflicts - the bot will check for this and notify the author in the event conflicts happen before merging of the pull request.

## Submitting a Revert Request

Autosubmit can also undo a change automatically simply by adding a label and a comment to a pull request. By adding the label 'revert' to a closed pull request the autosubmit bot will know to create a new request to revert this change and provide the specified reason in the body of the resulting revert request.

## Conditions on creating a Revert Request

* The initiator of the revert request must be a member of the flutter-hackers team.
* The pull request being targeted for revert must have been merged less than 24 hours ago.
* The initiator of the revert must supply a reason for the revert. In order to do this they must add a comment that begins with 'Reason for revert:' and then supply a reason for the revert.

If an empty reason is supplied then the 'revert' label will be removed and a comment supplied that you must supply a reason.

# How it Works

## Basic Design

The Autosubmit bot is a service hosted within GCP that listens to GitHub's webhook events utilizing PubSub to store the messages it is interested in for further processing. A cron job calls the service every two minutes to look for new events from GitHub to see if any new pull requests need to be processed.

If an event contains a new pull request we look at it for the 'autosubmit' label. If the pull request is valid, i.e. it came from GitHub then we send it in a message to our PubSub topic.

A cron job will then call the Autosubmit service which will pull messages from the topic for processing and validation. If the pull request has passed the validations outlined above then it will be merged and the PubSub message acknowledged. Autosubmit will no longer process that pull request.

{TODO add a diagram of the components}

## Configuration

The Autosubmit bot gets its configuration from a configuration file in the Orgs `.github` repository, specifically at `.github/autosubmit/autosubmit.yml`. These configurations govern the validations that the Autosubmit will perform and can be updated on the fly. These configs can also be overridden in other repositories so that the configuration can be tuned according to the repositories code owners liking.

### Configuration Values

| Config Name | Optional | Type | Default Value | Explanation |
| --- | --- | --- | --- | --- |
| `default_branch` | Yes | String | 'main' | the default branch of the repository where pull requests are merged into. This can be provided in the configuration but if it is not, the bot will collect this from a call to the Github API. |
| `allow_config_override` | Yes | boolean | false | flag to allow specific repositories to override the values defined at the Org level for Autosubmit. See below. |
| `auto_approval_accounts` | Yes | Array of String | [ ] | the accounts that can submit pull requests automatically with automatic review approval. The values here should be reserved for trusted entities such as dependabot or org created accounts. |
| `approving_reviews` | Yes | integer | 2 | Integer, the number of reviews required before Auto-submit will merge a pull request upon approval. |
| `approval_group` | No | String | | the group a pull request author must get approval from in order to merge their pull request into the repository. See the rules on Approvals above. |
| `run_ci_checks` | Yes | boolean | true | a flag to determine whether or not to run target checks from ci.yaml or not. Not all repositories may want to do this initially. It is strongly recommended that this be set to True always. |
| `support_no_review_revert` | Yes | boolean | true | flag to toggle condition of reviews required on revert requests. Flutter does not require an initial review but other repos may not want this. |
| `required_checkruns_on_revert` | Yes | Array of String | [ ] | a list of check runs that Auto-submit will require to complete before merging a revert pull request regardless of what `support_no_review_revert` is set to. |

### Configuration File Examples

Here is an example of a full Autosubmit bot configuration file:

```yaml
default_branch: main
allow_config_override: false
auto_approval_accounts:
  - skia-flutter-autoroll
  - engine-flutter-autoroll
  - dependabot[bot]
  - dependabot
  - DartDevtoolWorkflowBot
approving_reviews: 2
approval_group: flutter-hackers
run_ci: true
support_no_review_revert: true
required_checkruns_on_revert:
  - ci.yaml validation
```

An example of the minimum configuration file

```yaml
approval_group: flutter-hackers
```

### Allowing Configuration Overrides

All repositories within an Org need not follow the same rules. Some may want more Approvals for a review, some may not want to allow Reverts without a review. Autosubmit allows this by allowing an override configuration file to be defined in the repositories .github directory. This is different than the Org .github repository.

In order to override the configuration at the Org level, the `allow_config_override` flag must be set to `true`. This tells Autosubmit that it will need to look in the local repositories .github directory for an autosubmit.yml file. Specifically that file will need to be places here: `<repo>/.github/autosubmit/autosubmit.yml`.

The following rules will apply to override values:
* Non array values will overwrite the Org level config.
* Array values will be additive, meaning that anything specified in the local config will be 'in addition to' what is defined in the Org level config.
* The number of approving reviews may not be set lower than what is defined in the Org level config.

An example of Config Override:

The Org level config is defined as follows:

```yaml
allow_config_override: true
auto_approval_accounts:
  - skia-flutter-autoroll
  - engine-flutter-autoroll
approving_reviews: 2
approval_group: flutter-hackers
run_ci: true
support_no_review_revert: true
required_checkruns_on_revert:
  - ci.yaml validation
```

At the repository level the team would like to add a few more accounts to the `auto_approval_accounts` for automation purposes and required 1 more review but also would like revert requests to require reviews. So the repository level config would define the new values as follows:

```yaml
auto_approval_accounts:
  - dependabot[bot]
  - dependabot
  - DartDevtoolWorkflowBot
approving_reviews: 3
support_no_review_revert: false
```

The final merged configuration for the repository would then become:

```yaml
auto_approval_accounts:
  - skia-flutter-autoroll
  - engine-flutter-autoroll
  - dependabot[bot]
  - dependabot
  - DartDevtoolWorkflowBot
approving_reviews: 3
approval_group: flutter-hackers
run_ci: true
support_no_review_revert: false
required_checkruns_on_revert:
  - ci.yaml validation
```

# Where it Lives

The code for the Autosubmit bot is part of the flutter infra tools and can be found here: https://github.com/flutter/cocoon

# Onboarding with Autosubmit {WIP}

### Installing the Autosubmit App

Currently the bot is not available from the GitHub marketplace so it is only available to support internal Google Repositories.
In order to install the App you will need to:
1. Open a request with the Flutter Infrastructure team and request 'Autosubmit Support for ORG/REPO' in the title.
2. A Flutter Infrastructure Admin will then install the App on that repository so you must look out for a request from Autosubmit for the installation.
3. Next the bot will need to be added as a Pusher to the repository it will be servicing. This is done in the Branch Protections section of the repository.

### Adding the Configuration

After the app is installed you will need to place a configuration file into your ORGs .github repository. If you do not have one then you will need to create onc in your ORG level .github repository.

Once the repository is created then you will need to add the Autosubmit configuration file at .github/autosubmit/autosubmit.yml. This is the primary location that Autosubmit will check first for the configuration. Repositories in your ORG can override the ORG level configs by placing a configuration file at repo/.github/autosubmit/autosubmit.yml. See the section on [configuration](Autosubmit-bot.md#configuration) above on the fields you may want to include in your configuration.

Make sure that the App has read write access to the ORG level .github repository.

### Configuring the Repository

In order for the Autosubmit bot to merge pull requests it will need write access on the repository and it will need to be added to the branch protection section on who can push to the repository.

An 'autosubmit' label will also need to be created for the supported repository. You can visit this [page](https://docs.github.com/en/issues/using-labels-and-milestones-to-track-work/managing-labels#creating-a-label) to view instructions on creating the label.

### Usage

Once the Autosubmit app has been installed in the repository, the configuration has been added and the target repository has been configured for write access you are ready to utilize the Autosubmit bot. In order to use the Autosubmit on pull requests in the target repository, follow these steps:
1. Open a pull request for review.
2. Make sure the pull request has tests as the bot will warn about this.
3. Get at least 1 other team member to review your pull request.
4. Once you have a review add the 'autosubmit' label.
5. Autosubmit will validate the pull request and if everything is okay it will automatically merge the pull request for you. No need to wait around to merge it!