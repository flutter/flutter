This document talks about how to manage package as a package owners, and focus on
maintaining a package, including release, ci, and accepting contribution.

# Prerequisits

See [Plugins and Packages Structure](https://github.com/flutter/flutter/blob/master/docs/ecosystem/Plugins-and-Packages-repository-structure.md) for how a package is structured.

# Releases

Before owner a package, one must decide the release strategy for the package. There are two options:

- batched release
- Per-PR release

To choose a strategy, one must take a look at needs.

## Batched Release

If the package is expecting more PR traffic or one wants more controll on what and when to release. Consider choosing
this release strategy.

