### Stable (example: 3.3.0)
Flutter releases are identified by a modified [CalVer](https://calver.org/) scheme.

X: Major - Incremented when the product team decides there are features impactful enough to increment this value.

Y: Minor - Incremented on a monthly basis.
- Example:  Flutter 3.0.0 shipped May 2022, meaning an August 2022 release would put the Flutter version at 3.3.0 as it is 3 months after the last stable release.

Z: Patch - Incremented whenever a hotfix is applied to the current stable release.
### Beta (example: 3.3.0-5.0.pre)
X: Major - Same as above

Y: Minor - Same as above

Z: Reserved - This number is always 0.

M: Branch Identifier - When bringing the repository into Google3, we ensure that commits do not break tests.  Once testing is complete and changes have been brought in to Google3, we create a branch based on the current snapshot that has passed all tests.  These snapshots are named flutter-X.Y-candidate.M

N: Patch - Incremented whenever a hotfix is applied to the beta release.

Pre: pre-release - Identifies the release as a beta.

### Tagging Releases
Each release is tagged during the release process.  These tags are a snapshot of the repository at a specific commit. Tagged releases can be found [here](https://github.com/flutter/flutter/tags).
Example: Flutter 3.3.0 is tagged as [3.3.0](https://github.com/flutter/flutter/releases/tag/3.0.0) aliasing commit [ee4e09c](https://github.com/flutter/flutter/commit/ee4e09cce01d6f2d7f4baebd247fde02e5008851).