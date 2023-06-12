# How to contribute

### Before you contribute

Before we can use your code, you must sign the [Google Individual Contributor
License Agreement][cla] (CLA), which you can do online. The CLA is necessary
mainly because you own the copyright to your changes even after your
contribution becomes part of our codebase, so we need your permission to use and
distribute your code. We also need to be sure of various other things—for
instance that you'll tell us if you know that your code infringes on other
people's patents. You'll only need to do this once.

Before you start working on a larger contribution, you should get in touch with
us first through the  [Issue Tracker][issues] with your idea so that we can help
out and possibly guide you. Co-ordinating up front makes it much easier to avoid
frustration later on.

All submissions, including submissions by project members, require review.

### Contribution Guidelines

We welcome your pull requests, issue reports and enhancement requests. To make
the process as smooth as possible, we request the following:

   * Sign the [CLA][cla] (see above) before sending your pull request.
     It's quick, we promise!
   * Have test cases for your changes and ensure that the existing ones still
     pass.
   * Ensure your code is consistent with the [Style Guide][style_guide].
   * Run your changes through `dartfmt`. Follow the installation instructions in
     the [dart_style][dartfmt_usage] README for more info.
   * Squash your commits into a single commit with a good description. You can
     use `git rebase -i` for this. For more details on rebasing, check out
     Atlassian's [tutorial][rebase_tutorial].
   * During code review, go ahead and pile up commits addressing review
     comments. Once you get an LGTM (looks good to me) on the review, we'll
     squash your commits and merge!
   * If you're not already listed as an author in `AUTHORS`, remember to add
     yourself and claim your rightful place amongst the Quiverati.

[cla]: https://developers.google.com/open-source/cla/individual
[issues]: https://github.com/google/quiver-dart/issues
[style_guide]: https://dart.dev/guides/language/effective-dart
[dartfmt_usage]: https://github.com/dart-lang/dart_style
[rebase_tutorial]: https://www.atlassian.com/git/tutorials/rewriting-history
