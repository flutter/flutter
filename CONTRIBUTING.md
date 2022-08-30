<!-- when editing this file also update https://github.com/flutter/.github/blob/main/CONTRIBUTING.md -->

Contributing to Flutter
=======================

_tl;dr: join [Discord](https://github.com/flutter/flutter/wiki/Chat), be [courteous](CODE_OF_CONDUCT.md), follow the steps below to set up a development environment; if you stick around and contribute, you can [join the team](https://github.com/flutter/flutter/wiki/Contributor-access) and get commit access._

Welcome
-------

We invite you to join the Flutter team, which is made up of volunteers and sponsored folk alike!
There are many ways to contribute, including writing code, filing issues on GitHub, helping people
on our mailing lists, our chat channels, or on Stack Overflow, helping to triage, reproduce, or
fix bugs that people have filed, adding to our documentation,
doing outreach about Flutter, or helping out in any other way.

We grant commit access (which includes full rights to the issue
database, such as being able to edit labels) to people who have gained
our trust and demonstrated a commitment to Flutter. For more details
see the [Contributor access](https://github.com/flutter/flutter/wiki/Contributor-access)
page on our wiki.

We communicate primarily over GitHub and [Discord](https://github.com/flutter/flutter/wiki/Chat).

Before you get started, we encourage you to read these documents which describe some of our community norms:

1. [Our code of conduct](CODE_OF_CONDUCT.md), which stipulates explicitly
   that everyone must be gracious, respectful, and professional. This
   also documents our conflict resolution policy and encourages people
   to ask questions.

2. [Values](https://github.com/flutter/flutter/wiki/Values),
   which talks about what we care most about.

Helping out in the issue database
---------------------------------

Triage is the process of going through bug reports and determining if they are valid, finding out
how to reproduce them, catching duplicate reports, and generally making our issues list
useful for our engineers.

If you want to help us triage, you are very welcome to do so!

1. Join the #hackers-triage [Discord channel](https://github.com/flutter/flutter/wiki/Chat).

2. Read [our code of conduct](CODE_OF_CONDUCT.md), which stipulates explicitly
   that everyone must be gracious, respectful, and professional. If you're helping out
   with triage, you are representing the Flutter team, and so you want to make sure to
   make a good impression!

3. Help out as described in our wiki: https://github.com/flutter/flutter/wiki/Triage
   You won't be able to add labels at first, so instead start by trying to
   do the other steps, e.g. trying to reproduce the problem and asking for people to
   provide enough details that you can reproduce the problem, pointing out duplicates,
   and so on. Chat on the #hackers-triage channel to let us know what you're up to!

4. Familiarize yourself with our
   [issue hygiene](https://github.com/flutter/flutter/wiki/Issue-hygiene) wiki page,
   which covers the meanings of some important GitHub labels and
   milestones.

5. Once you've been doing this for a while, someone will invite you to the flutter-hackers
   team on GitHub and you'll be able to add labels too. See the
   [contributor access](https://github.com/flutter/flutter/wiki/Contributor-access) wiki
   page for details.


Quality Assurance
-----------------

One of the most useful tasks, closely related to triage, is finding and filing bug reports. Testing
beta releases, looking for regressions, creating test cases, adding to our test suites, and
other work along these lines can really drive the quality of the product up. Creating tests
that increase our test coverage, writing tests for issues others have filed, all these tasks
are really valuable contributions to open source projects.

If this interests you, you can jump in and submit bug reports without needing anyone's permission!
The #qa channel on our [Discord server](https://github.com/flutter/flutter/wiki/Chat)
is a good place to talk about what you're doing. We're especially eager for QA testing when
we announce a beta release. See https://github.com/flutter/flutter/wiki/Quality-Assurance for
more details.

If you want to contribute test cases, you can also submit PRs. See the next section
for how to set up your development environment, or ask in #hackers-test on Discord.

> As a personal side note, this is exactly the kind of work that first got me into open
> source. I was a Quality Assurance volunteer on the Mozilla project, writing test cases for
> browsers, long before I wrote a line of code for any open source project. —Hixie


Developing for Flutter
----------------------

If you would prefer to write code, you may wish to start with our list of [good first contributions](https://github.com/flutter/flutter/issues?q=is%3Aopen+is%3Aissue+label%3A%22good+first+contribution%22).

To develop for Flutter, you will eventually need to become familiar
with our processes and conventions. This section lists the documents
that describe these methodologies. The following list is ordered: you
are strongly recommended to go through these documents in the order
presented.

1. [Setting up your engine development environment](https://github.com/flutter/flutter/wiki/Setting-up-the-Engine-development-environment),
   which describes the steps you need to configure your computer to
   work on Flutter's engine. If you only want to write code for the
   Flutter framework, you can skip this step. Flutter's engine mainly
   uses C++, Java, and Objective-C.

2. [Setting up your framework development environment](https://github.com/flutter/flutter/wiki/Setting-up-the-Framework-development-environment),
   which describes the steps you need to configure your computer to
   work on Flutter's framework. Flutter's framework mainly uses Dart.

3. [Tree hygiene](https://github.com/flutter/flutter/wiki/Tree-hygiene),
   which covers how to land a PR, how to do code review, how to
   handle breaking changes, how to handle regressions, and how to
   handle post-commit test failures.

4. [Our style guide](https://github.com/flutter/flutter/wiki/Style-guide-for-Flutter-repo),
   which includes advice for designing APIs for Flutter, and how to
   format code in the framework.

5. [Flutter design doc template](https://flutter.dev/go/template),
   which should be used when proposing a new technical design.  This is a good
   practice to do before coding more intricate changes.

[![How to contribute to Flutter](https://img.youtube.com/vi/4yBgOBAOx_A/0.jpg)](https://www.youtube.com/watch?v=4yBgOBAOx_A)

In addition to the documents, there is a video linked above on **How to contribute to Flutter**
from the [Flutter](https://youtube.com/c/flutterdev) YouTube channel,
there are many pages on [our Wiki](https://github.com/flutter/flutter/wiki/),
and an article [Contributing to Flutter: Getting Started](https://medium.com/@ayushbherwani/contributing-to-flutter-getting-started-a0db68cbcd5b)
on Medium that may be of interest. For a curated list of pages see the sidebar
on the wiki's home page. They are more or less listed in order of importance.


Outreach
--------

If your interests lie in the direction of developer relations and developer outreach,
whether advocating for Flutter, answering questions in fora like
[Stack Overflow](https://stackoverflow.com/questions/tagged/flutter?sort=Newest&filters=NoAnswers,NoAcceptedAnswer&edited=true)
or [Reddit](https://www.reddit.com/r/flutterhelp/new/?f=flair_name%3A%22OPEN%22),
or creating content for our [documentation](https://docs.flutter.dev/)
or sites like [YouTube](https://www.youtube.com/results?search_query=flutter&sp=EgQIAxAB),
the best starting point is to join the #hackers-devrel [Discord channel](https://github.com/flutter/flutter/wiki/Chat).
From there, you can describe what you're interested in doing, and go ahead and do it!
As others become familiar with your work, they may have feedback, be interested in
collaborating, or want to coordinate their efforts with yours.


API documentation
-----------------

Another great area to contribute in is sample code and API documentation. If this is an area that interests you, join our
[Discord](https://github.com/flutter/flutter/wiki/Chat) server and introduce yourself on the #hackers-deverl, #hackers-framework,
or #hackers-engine channels, describing your area of interest. As our API docs are integrated into our source code, see the
"developing for Flutter" section above for a guide on how to set up your developer environment.

To contribute API documentation, an excellent command of the English language is particularly helpful, as is a careful attention to detail.
We have a [whole section in our style guide](https://github.com/flutter/flutter/wiki/Style-guide-for-Flutter-repo#documentation-dartdocs-javadocs-etc)
that you should read before you write API documentation. It includes notes on the "Flutter Voice", such as our word and grammar conventions.

In general, a really productive way to improve documentation is to use Flutter and stop any time your have a question: find the answer, then
document the answer where you first looked for it.

We also keep [a list of areas that need better API documentation](https://github.com/flutter/flutter/issues?q=is%3Aopen+is%3Aissue+label%3A%22d%3A+api+docs%22+sort%3Areactions-%2B1-desc).
In many cases, we have written down what needs to be said in the relevant issue, we just haven't gotten around to doing it!

We're especially eager to add sample code and diagrams to our API documentation. Diagrams are generated from Flutter code that
draws to a canvas, and stored in a [special repository](https://github.com/flutter/assets-for-api-docs/#readme). It can be a lot of fun
to create new diagrams for the API docs.


Releases
--------

If you are interested in participating in our release process, which may involve writing release notes and blog posts, coordinating the actual
generation of binaries, updating our release tooling, and other work of that nature, then reach out on the #hackers-releases
channel of our [Discord](https://github.com/flutter/flutter/wiki/Chat) server.


Social events in the contributor community
------------------------------------------

Finally, one area where you could have a lot of impact is in contributing to social interactions among the Flutter contributor community itself.
This could take the form of organizing weekly video chats on our Discord, or planning tech talks from contributors, for example.
If this is an area that is of interest to you, please join our [Discord](https://github.com/flutter/flutter/wiki/Chat) and ping Hixie on the #hackers
channel!
