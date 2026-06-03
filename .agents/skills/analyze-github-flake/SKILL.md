---
name: analyze-github-flake
description:
  Expertise in analyzing flake github issues in the flutter/flutter repository. Use when a user wants to analyze the flakiness of a specific link to a flutter github issue.
---
<!--
Host assumptions:
    Installed and on path:
        * dart
        * git
        * gh
    Had authentication setup:
        * gh
-->
# Flake analysis instructions

*Context*
flutter/flutter repo has the following folder structure.
* dev/ contains utilities for working on or with the repository, as well as integration test code.
* bin/ shell scripts which can invoke the flutter tool.
* packages/ contains dart packages and flutter plugins that are maintained by the flutter team. Each folder is either a dart packages or a root directory for a group of flutter plugins. Importantly, it contains the code for the flutter tool.
* docs/ contains documentation about the repository.
* engine/ contains the source code for the flutter engine, including the core c++ code and the platform specific "embedders".

*Rules*
You should not modify ANY files - you are only to provide an analysis of the why the specific check is flaking.
You should only look at the issue body, as well as comments containing links to additional builds.
You should not attempt to solve the flakes or pinpoint root causes inside of flutter/, just provide a high level summary of what is going on and bucket the failures into distinct types.

## Collecting the list of failing builds and obtaining the logs

Github issue urls take the form of https://github.com/flutter/flutter/issues/<issue-number>. Where issue-number is a number.

Get information about the issue by using `gh issue view <issue-number> --repo flutter/flutter --json=author,body,id,labels,number,state,title,url`

For example to find information about the issue https://github.com/flutter/flutter/issues/174116 you can call `gh issue view 174116 --repo flutter/flutter --json=author,body,id,labels,number,state,title,url`

The title will contain the name of the flaking check, and the body will contain urls which link to instances where the check failed or flaked, each on a new line, directly after "Flaky builds:". You should also inspect the comments and find each comment made by "login": "fluttergithubbot", and extract the urls from there as well (the format will be the same, with an example flake at the top, and the full list immediately after the "Flaky builds:" header).

To find information about the specific failure take one of the urls listed in the issue body.
That link takes the format `"https://ci.chromium.org/ui/p/flutter/builders/prod/<check_name>/<buildNumber>/overview",`

Example `https://ci.chromium.org/ui/p/flutter/builders/prod/Windows%20plugin_test/16247/overview` where `Windows%20plugin_test` is the <check_name> and `16247` is the <buildNumber>.


The use the <buildNumber> to get the test logs metadata by running the following command.

<!-- TODO include a .gitignored directory where agent can dump local files in flutter/packages -->

```
curl 'https://cr-buildbucket.appspot.com/prpc/buildbucket.v2.Builds/GetBuild' \
  -H 'accept: application/json' \
  -H 'accept-language: en-US,en;q=0.9,es;q=0.8' \
  -H 'cache-control: no-cache' \
  -H 'content-type: application/json' \
  -H 'origin: https://ci.chromium.org' \
  -H 'pragma: no-cache' \
  -H 'priority: u=1, i' \
  -H 'referer: https://ci.chromium.org/' \
  -H 'sec-ch-ua: "Chromium";v="146", "Not-A.Brand";v="24", "Google Chrome";v="146"' \
  -H 'sec-ch-ua-mobile: ?0' \
  -H 'sec-ch-ua-platform: "macOS"' \
  -H 'sec-fetch-dest: empty' \
  -H 'sec-fetch-mode: cors' \
  -H 'sec-fetch-site: cross-site' \
  -H 'user-agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36' \
  -H 'x-return-encrypted-headers: all' \
  --data-raw '{"builder":{"project":"flutter","bucket":"try","builder":"Linux repo_checks"},"buildNumber":<buildNumber>,"mask":{"fields":"id,builder,builderInfo,number,canceledBy,createdBy,createTime,startTime,endTime,cancelTime,status,statusDetails,summaryMarkdown,output,steps,tags,schedulingTimeout,executionTimeout,gracePeriod,ancestorIds,retriable"}}'
```
Ignore the characters `)]}'` that start the response and treat the rest like json.

Inspect the content of the logs to determine the cause of the failure.

Do this for each of the urls in the issue body. Collect the logs for each of the specific failures, and categorize them by the type of failure in to a high level summary.
