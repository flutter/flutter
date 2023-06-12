# Contributing to Equatable

👍🎉 First off, thanks for taking the time to contribute! 🎉👍

The following is a set of guidelines for contributing to Equatable and its packages. These are mostly guidelines, not rules. Use your best judgment, and feel free to propose changes to this document in a pull request.

## Proposing a Change

If you intend to change the public API, or make any non-trivial changes to the implementation, we recommend filing an issue. This lets us reach an agreement on your proposal before you put significant effort into it.

If you’re only fixing a bug, it’s fine to submit a pull request right away but we still recommend to file an issue detailing what you’re fixing. This is helpful in case we don’t accept that specific fix but want to keep track of the issue.

## Creating a Pull Request

Before creating a pull request please:

1. Fork the repository and create your branch from `master`.
2. Install all dependencies (`flutter packages get` or `pub get`).
3. Squash your commits and ensure you have a meaningful commit message.
4. If you’ve fixed a bug or added code that should be tested, add tests! Pull Requests without 100% test coverage will not be approved.
5. Ensure the test suite passes.
6. If you've changed the public API, make sure to update/add documentation.
7. Format your code (`dartfmt -w .`).
8. Analyze your code (`dartanalyzer --fatal-infos --fatal-warnings .`).
9. Create the Pull Request.
10. Verify that all status checks are passing.

While the prerequisites above must be satisfied prior to having your pull request reviewed, the reviewer(s) may ask you to complete additional design work, tests, or other changes before your pull request can be ultimately accepted.

## Getting in Touch

If you want to just ask a question or get feedback on an idea you can post it on [gitter](https://gitter.im/equatable_package/community).

## License

By contributing to Equatable, you agree that your contributions will be licensed under its MIT license.
