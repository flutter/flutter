_**TL;DR** To facilitate a smooth ecosystem migration, a package author may ask dependent packages to migrate to a 1.0.0 version with a `>=0.x.y+z <2.0.0` constraint rather than a `^1.0.0`._

API stability* is an important milestone in a package’s lifetime and bumping the version to 1.0.0 is an exciting way to celebrate this moment.

This is what the [Semantic Versioning Specification](https://semver.org/#spec-item-4) (2.0.0) is saying about pre 1.0.0 versions:

> Major version zero (0.y.z) is for initial development. Anything MAY change at any time. The public API SHOULD NOT be considered stable.

Pub on the other hand treats pre 1.0.0 versions semantically (see [pub_semver corner cases](https://pub.dev/packages/pub_semver)), shifting the numbers by one position.

Often, at the time a package author is ready to announce API stability their package is versioned 0.x.y+z. Bumping a package version from 0.x.y+z to 1.0.0 is a major version bump in the Dart ecosystem. Migrations across a major version bump are slower, and may result in some period of ecosystem fragmentation (when some dependent packages are only willing to take ^0.x.y+z and some require ^1.0.0).

To go through an ecosystem migration to 1.0.0 in a smoother way, users of the newly API-stable package (particularly dependent packages) are encouraged to update their constraints to `>=0.a.b+c <2.0.0` instead of `^1.0.0`, this reduces friction during the transition period while some dependents have updated to post 1.0.0 and some have not.


&ast; While an API can never be guaranteed to be stable, version 1.0.0 is the milestone in which the package author is feeling comfortable to let others depend on the current API, and does not have concrete plans to change it in a breaking way.