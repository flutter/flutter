[![Dart CI](https://github.com/dart-lang/pub_semver/actions/workflows/test-package.yml/badge.svg)](https://github.com/dart-lang/pub_semver/actions/workflows/test-package.yml)
[![Pub](https://img.shields.io/pub/v/pub_semver.svg)](https://pub.dev/packages/pub_semver)
[![package publisher](https://img.shields.io/pub/publisher/pub_semver.svg)](https://pub.dev/packages/pub_semver/publisher)

Handles version numbers and version constraints in the same way that [pub][]
does.

## Semantics

The semantics here very closely follow the
[Semantic Versioning spec version 2.0.0-rc.1][semver]. It differs from semver
in a few corner cases:

 *  **Version ordering does take build suffixes into account.** This is unlike
    semver 2.0.0 but like earlier versions of semver. Version `1.2.3+1` is
    considered a lower number than `1.2.3+2`.

    Since a package may have published multiple versions that differ only by
    build suffix, pub still has to pick one of them *somehow*. Semver leaves
    that issue unresolved, so we just say that build numbers are sorted like
    pre-release suffixes.

 *  **Pre-release versions are excluded from most max ranges.** Let's say a
    user is depending on "foo" with constraint `>=1.0.0 <2.0.0` and that "foo"
    has published these versions:

     *  `1.0.0`
     *  `1.1.0`
     *  `1.2.0`
     *  `2.0.0-alpha`
     *  `2.0.0-beta`
     *  `2.0.0`
     *  `2.1.0`

    Versions `2.0.0` and `2.1.0` are excluded by the constraint since neither
    matches `<2.0.0`. However, since semver specifies that pre-release versions
    are lower than the non-prerelease version (i.e. `2.0.0-beta < 2.0.0`, then
    the `<2.0.0` constraint does technically allow those.

    But that's almost never what the user wants. If their package doesn't work
    with foo `2.0.0`, it's certainly not likely to work with experimental,
    unstable versions of `2.0.0`'s API, which is what pre-release versions
    represent.

    To handle that, `<` version ranges don't allow pre-release versions of the
    maximum unless the max is itself a pre-release, or the min is a pre-release
    of the same version. In other words, a `<2.0.0` constraint will prohibit not
    just `2.0.0` but any pre-release of `2.0.0`. However, `<2.0.0-beta` will
    exclude `2.0.0-beta` but allow `2.0.0-alpha`. Likewise, `>2.0.0-alpha
    <2.0.0` will exclude `2.0.0-alpha` but allow `2.0.0-beta`.

 *  **Pre-release versions are avoided when possible.** The above case
    handles pre-release versions at the top of the range, but what about in
    the middle? What if "foo" has these versions:

     *  `1.0.0`
     *  `1.2.0-alpha`
     *  `1.2.0`
     *  `1.3.0-experimental`

    When a number of versions are valid, pub chooses the best one where "best"
    usually means "highest numbered". That follows the user's intuition that,
    all else being equal, they want the latest and greatest. Here, that would
    mean `1.3.0-experimental`. However, most users don't want to use unstable
    versions of their dependencies.

    We want pre-releases to be explicitly opt-in so that package consumers
    don't get unpleasant surprises and so that package maintainers are free to
    put out pre-releases and get feedback without dragging all of their users
    onto the bleeding edge.

    To accommodate that, when pub is choosing a version, it uses *priority*
    order which is different from strict comparison ordering. Any stable
    version is considered higher priority than any unstable version. The above
    versions, in priority order, are:

     *  `1.2.0-alpha`
     *  `1.3.0-experimental`
     *  `1.0.0`
     *  `1.2.0`

    This ensures that users only end up with an unstable version when there are
    no alternatives. Usually this means they've picked a constraint that
    specifically selects that unstable version -- they've deliberately opted
    into it.

 *  **There is a notion of compatibility between pre-1.0.0 versions.** Semver
    deems all pre-1.0.0 versions to be incompatible.  This means that the only
    way to ensure compatibility when depending on a pre-1.0.0 package is to
    pin the dependency to an exact version. Pinned version constraints prevent
    automatic patch and pre-release updates. To avoid this situation, pub
    defines the "next breaking" version as the version which increments the
    major version if it's greater than zero, and the minor version otherwise,
    resets subsequent digits to zero, and strips any pre-release or build
    suffix.  For example, here are some versions along with their next breaking
    ones:

    `0.0.3` -> `0.1.0`
    `0.7.2-alpha` -> `0.8.0`
    `1.2.3` -> `2.0.0`

    To make use of this, pub defines a "^" operator which yields a version
    constraint greater than or equal to a given version, but less than its next
    breaking one.

[pub]: https://pub.dev
[semver]: https://semver.org/spec/v2.0.0-rc.1.html
