## Overview

Frequently, issues will be fixed in repositories other than `flutter/flutter`.  When this happens, it's common to want to know when the fix will be available in the framework.

Other times, issues will be root-caused to a particular commit, and it's common to want to know which Flutter versions are afflicted by the issue.

This page outlines the current process for determining that information.

## Process

### Finding the Dart SDK commit contained in Engine commit X

To find out which Dart SDK sha is contained in a particular commit of the Flutter engine:

1. Let the engine commit be _ENGINE_COMMIT_

1. Navigate to https://github.com/flutter/engine/blob/${ENGINE_COMMIT}/DEPS#L51 and search for the value corresponding to the _'dart_revision'_ key.

***

### Finding the versions that contain Framework commit X

To find the published Flutter versions that contain any given commit in `flutter/flutter`:

1. Navigate to the page for that commit.  You can do this by either:
  - clicking on the merged commit on a PR page

    <img width="583" alt="merge commit message" src="https://user-images.githubusercontent.com/6655696/224098265-dd368be5-ae2c-4cb0-a30c-efc8c0503d6f.png">

  - clicking on the commit from https://github.com/flutter/flutter/commits
  - constructing the URL manually: the URL format is `https://github.com/flutter/flutter/commit/<sha>`.

1. Look in the lower left corner of the commit description box for a list of version tags.  For example:

   <img src="https://user-images.githubusercontent.com/15253456/63279347-ace5d000-c25d-11e9-89a6-f2bd37359e8e.png" alt="Versions" width="65%;" />

   The list of versions here is comprehensive (it lists every individual version that contains the commit).

   If there are no versions listed there, it means that this commit has not yet been published and exists only on master.
   (We [no longer publish to the dev channel](https://medium.com/flutter/whats-new-in-flutter-2-8-d085b763d181#34c4), so this is
   quite common if there has not been a beta released recently.)

   If there are too many version tags to display cleanly, GitHub hides them behind an ellipsis.  For example:

   <img src="https://user-images.githubusercontent.com/15253456/63285807-73b45c80-c26b-11e9-9e6f-6e21a09cfe85.png" alt="Too many version tags get hidden" width="65%;" />

   Clicking on that ellipsis will expand the list out to show all version tags that contain the commit.  For example:

   <img src="https://user-images.githubusercontent.com/15253456/63285936-b413da80-c26b-11e9-9cc9-0d2754100a2e.png" alt="See all the version tags" width="65%;" />

***

### Finding the Framework commit that contains Engine commit X

To find out when a given engine change rolled into the framework:

1. Find the engine PR that corresponds to your desired commit.  For example, for commit [7292d47](https://github.com/flutter/engine/commit/7292d47e615aff38180c8a4c1e65091325b6aae7), the corresponding PR is [flutter/engine#11206](https://github.com/flutter/engine/pull/11206).

   If the commit in question does not have a corresponding PR (most commonly seen with Dart rolls), then use the newest commit _before_ your desired engine commit that has a corresponding PR as a proxy.

   Once you've identified an engine PR, navigate to that PR.

1. Somewhere in the comment stream for the PR (usually at or near the bottom), there will be a cross-referenced "_Roll engine &lt;commit&gt;..&lt;commit&gt;_" link with a "Merged" badge to the right of it.  For example:

   <img src="https://user-images.githubusercontent.com/15253456/63278598-6a6fc380-c25c-11e9-84e7-097bc0bc3fbe.png" alt="The commit at which it rolled into the framework" width="65%;" />

   That was the PR in which this engine commit merged into the framework.  Click on that link.

1. Near the bottom of the comment stream for the framework PR will be a line that says:

   "_&lt;user&gt; merged commit &lt;commit&gt;_"

   Usually, the user will be "_engine-flutter-autoroll_".  Click on the commit sha to navigate to the commit.

1. The full commit sha is contained in the URL.  It's also listed on the page:

   <img src="https://user-images.githubusercontent.com/15253456/63279082-39dc5980-c25d-11e9-9c95-bc6ed1fd5082.png" alt="The commit sha" width="65%;" />

1. To find the published Flutter versions that contain this commit, follow the process above for "Finding the versions that contain Framework commit X".

***

### Finding the Engine commit that contains Dart SDK commit X

To find out when a given Dart SDK change rolled into the engine:

1. If you're starting from the Dart review CL (e.g. https://dart-review.googlesource.com/c/sdk/+/113126), wait until the CL has merged.  You can see the status of a CL in the upper left corner of the page.  For example:

   <img src="https://user-images.githubusercontent.com/15253456/63281687-15cf4700-c262-11e9-8ed7-32cff0797fd5.png" alt="Merged CL" width="65%;" />

1. The merged badge then hyperlinks to the commit where it was merged.  The text says "_Merged as &lt;commit&gt;_", and the commit sha is a hyperlink.  Click on that link.

1. The commit page gives you the full sha of the Dart SDK commit.  For example:

   <img src="https://user-images.githubusercontent.com/15253456/63281947-a4dc5f00-c262-11e9-86b3-3435525d82b1.png" alt="Dart SDK commit sha" width="65%;" />

1. Note the time (and the timezone!) that the commit landed.  For example:

   <img src="https://user-images.githubusercontent.com/15253456/63282366-832fa780-c263-11e9-8413-5f6707bd2c76.png" alt="Commit timestamp" width="65%;" />

1. Navigate to https://github.com/flutter/engine/commits, and look for commits that landed shortly after the timestamp in question, where the commit description is "_Roll src/third_party/dart ..._".  These commits are "Dart SDK roll" commits.

   For each commit, GitHub says "_&lt;author&gt; committed &lt;time reference&gt;_" (e.g. "_skia-flutter-autoroll committed 8 hours ago_").  If you hover over the time reference, a tooltip shows you the exact commit time.

   **Important**: be sure to adjust for timezones when comparing times between the Dart SDK commit and the time when the engine commits landed.

1. Once you've found a candidate commit, click on the hyperlink of the commit description to go to the commit details page.  The full commit description will list what Dart SDK comitts were contained in the roll.  For example:

   <img src="https://user-images.githubusercontent.com/15253456/63283634-9ee87d00-c266-11e9-8960-3424cd2e8de1.png" alt="Commits contained in the Dart SDK roll" width="65%;" />

1. Keep searching newer Dart SDK roll commits until you find the roll that contains your desired Dart SDK commit.  This roll commit is the engine commit that contains your Dart SDK change.

1. To find out when this engine commit landed in the framework, follow the process above for "Finding the Framework commit that contains Engine commit X".

***

### Finding the Skia commit that contains Dart SDK commit X

To find out when a given Skia commit rolled into the engine, follow the same process as above for "Finding the Engine commit that contains Dart SDK commit X", with the following differences:

1. The review CLs will have URLs of the form `https://skia-review.googlesource.com/c/skia/+/<cl_number>` instead of `https://dart-review.googlesource.com/c/sdk/+/<cl_number>`.

1. The roll commits will start with "_Roll src/third_party/skia ..._" instead of "_Roll src/third_party/dart ..._".
