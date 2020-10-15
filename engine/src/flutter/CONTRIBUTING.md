Contributing to the Flutter engine
==================================

[![Build Status](https://api.cirrus-ci.com/github/flutter/engine.svg)][build_status]

_See also: [Flutter's code of conduct][code_of_conduct]_

Welcome
-------

For an introduction to contributing to Flutter, see [our contributor
guide][contrib_guide].

For specific instructions regarding building Flutter's engine, see [Setting up
the Engine development environment][engine_dev_setup] on our wiki. Those
instructions are part of the broader onboarding instructions described in the
contributing guide.

### Style

The Flutter engine follows Google style for the languages it uses:
- [C++](https://google.github.io/styleguide/cppguide.html)
  - **Note**: The Linux embedding generally follows idiomatic GObject-based C style.
    Use of C++ is discouraged in that embedding to avoid creating hybrid code that
    feels unfamiliar to either developers used to working with GObject or C++ developers.
    E.g., do not use STL collections or std::string. Exceptions:
      - C-style casts are forbidden; use C++ casts.
      - Use `nullptr` rather than `NULL`.
      - Avoid `#define`; for internal constants use `static constexpr` instead.
- [Objective-C](https://google.github.io/styleguide/objcguide.html) (including
  [Objective-C++](https://google.github.io/styleguide/objcguide.html#objective-c))
- [Java](https://google.github.io/styleguide/javaguide.html)

C/C++ and Objective-C/C++ files are formatted with `clang-format`, and GN files with `gn format`.

[build_status]: https://cirrus-ci.com/github/flutter/engine
[code_of_conduct]: https://github.com/flutter/flutter/blob/master/CODE_OF_CONDUCT.md
[contrib_guide]: https://github.com/flutter/flutter/blob/master/CONTRIBUTING.md
[engine_dev_setup]: https://github.com/flutter/flutter/wiki/Setting-up-the-Engine-development-environment


### Fuchsia Contributions from Googlers

Googlers contributing to Fuchsia should follow the additional steps at: go/flutter-fuchsia-pr-policy.
