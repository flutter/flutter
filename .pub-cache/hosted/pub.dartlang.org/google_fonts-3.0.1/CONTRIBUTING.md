# Contributing to the google_fonts package.

Thank you for your interest in contributing to the `google_fonts` package! We love receiving
contributions, and your work helps the whole community. This doc will walk you through the easiest
way to make a change and have it submitted to the `google_fonts` package.

## Developer workflow

The easiest workflow for adding a feature/fixing a bug is to test it out on the example app in this
repo.

### Environment

1.  Fork the [google-fonts-flutter](https://github.com/material-foundation/google-fonts-flutter)
    repo on github.
1.  Clone your fork of the `google-fonts-flutter` repo.
1.  Build and run the example app in `example/lib/main.dart` (from the `example/` directory, use
    `$ flutter run`).

### Development

1.  Make the changes to your local copy of the `google-fonts-flutter` package, testing the changes
    in the example app.
1.  Write a unit test for your change, if possible, in one of the files in `test/`.
1.  Update the `CHANGELOG.md` using [`cider`](https://pub.dev/packages/cider). For example:
    ```
    dart pub global activate cider
    cider log changed 'X now does Y'
    cider bump minor
    cider release
    ```
    making.

### Review

1.  Make sure all the existing tests are passing by using the following command (from the root of
    the project): `$ flutter test test/`.
1.  Make sure the repo is formatted using `$ flutter format .`.
1.  Create a PR to merge the branch on your fork into `google-fonts-flutter/main`.
1.  Add `johnsonmh` and `clocksmith` as reviewers on the PR. We will take a look and add any
    comments. When the PR is ready to be merged, we will merge it and update the package on
    [pub.dev](https://pub.dev/packages/google_fonts)!

## Updating the fonts

If you notice fonts that are on [fonts.google.com](https://fonts.google.com) that do not appear in
this package, it means that the generator needs to be run. The generator will
check [fonts.google.com](https://fonts.google.com) for any new fonts, manually test each URL, and
regenerate the dart code.

The generator is run multiple times a month by a GitHub [workflow](.github/workflows/update_fonts.yml).

To run it manually, navigate to the root of the project, and run `dart generator/generator.dart`.
