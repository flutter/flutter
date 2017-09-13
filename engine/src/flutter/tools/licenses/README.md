To update the golden license files, make sure you've rebased your branch to the latest upstream master and then run the following in this directory:

```
pub get
gclient sync
dart lib/main.dart --src ../../.. --out ../../../out/licenses --golden ../../travis/licenses_golden
```

Then copy any affected files from `../../../out/licenses` to `../../travis/licenses_golden` and add them to your change.

The `sky/packages/sky_engine/LICENSE` file is included in product releases and should be updated any time the golden file changes in a way that involves changes to anything other than the FILE lines.  To update this file, run:

```
pub get
gclient sync
dart lib/main.dart --release --src ../../.. --out ../../../out/licenses > ../../sky/packages/sky_engine/LICENSE
```
