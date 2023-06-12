Want to contribute? Great! First, read this page (including the small print at
the end).

### Before you contribute

Before we can use your code, you must sign the
[Google Individual Contributor License Agreement][CLA] (CLA), which you can do
online. The CLA is necessary mainly because you own the copyright to your
changes, even after your contribution becomes part of our codebase, so we need
your permission to use and distribute your code. We also need to be sure of
various other things—for instance that you'll tell us if you know that your code
infringes on other people's patents. You don't have to sign the CLA until after
you've submitted your code for review and a member has approved it, but you must
do it before we can put your code into our codebase.

Before you start working on a larger contribution, you should get in touch with
us first through the issue tracker with your idea so that we can help out and
possibly guide you. Coordinating up front makes it much easier to avoid
frustration later on.

[CLA]: https://cla.developers.google.com/about/google-individual

### Code reviews

All submissions, including submissions by project members, require review. We
recommend [forking the repository][fork], making changes in your fork, and
[sending us a pull request][pr] so we can review the changes and merge them into
this repository.

[fork]: https://help.github.com/articles/about-forks/
[pr]: https://help.github.com/articles/creating-a-pull-request/

Functional changes will require tests to be added or changed. The tests live in
the `test/` directory, and are run with `pub run test`. If you need to create
new tests, use the existing tests as a guideline for what they should look like.

Before you send your pull request, make sure all the tests pass!

### File headers

All files in the project must start with the following header.

    // Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
    // for details. All rights reserved. Use of this source code is governed by a
    // BSD-style license that can be found in the LICENSE file.

### The small print

Contributions made by corporations are covered by a different agreement than the
one above, the
[Software Grant and Corporate Contributor License Agreement][CCLA].

[CCLA]: https://developers.google.com/open-source/cla/corporate
