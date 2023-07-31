# 2.3.0
- Added support for the platforms tag. The current system would read the platforms keyword but when writting would ouput the likes of 'linux: null'. pub.dev does not like the null.
- removed an unused async in a unit test.

# 2.2.0
- Fixed #2. The executable script now returns the correct path even if the script value in pubspec.yaml is empty.
- added logic to deal with hosted dependencies where the version is in the yaml before the hosted key. The pub get command supports this odd order and so must we.
- fix: external hosted reference

# 2.1.0
Resolves https://github.com/j4qfrost/pubspec/issues/3 for self hosted pub

# 1.0.0
Change the sdk constraint according to the guide lines.
renamed pubspec.dart to pubspec.dart

# 1.0.0
Temporary release until real pubspec becomes nnbd ready.
Looks like the recommendation now is to push a stable nndb release so I've updated the version no. to 1.0.0 and changed imports to relative (unrelated.)
the nnbd version of uri has now been published as 1.0.0 so I've updated the dependency. I also had the incorrect sdk version as it was too specific.
Removed funding.yml.
Updated version no. to 1.0.0-nullsafety.0.
Null safe version. Currently relies on unpublished version of uri but it looks like its about to be published and once done this code will work. All unit tests are passing using a local copy of uri.
Merge branch 'master' of github.com:Andersmholmgren/pubspec into nullsafety
start of null saftey upgrade
Create FUNDING.yml
bump version
Merge pull request #21 from bsutton/master
Released 0.1.4
removed unused import.
Exported Executable.
Added support for 'exectuables' map in the pubspec.
Merge pull request #17 from adrianjagielak/feature/addPubdevExample
Add pub.dev example and fix example in README
bump version
Merge pull request #16 from nicholasspencer/master
Add path support to git dependencies
Merge pull request #13 from bsutton/master
removed library clause which is no longer needed.
removed the dependency on stuff has it had a dependency on mirrors. The result is that you couldn't do a native compile of any package dependent on pubspec. Copied the class Json_utils.dart from stuff package to make this possible.
Merge pull request #10 from SergeShkurko/master
Export yamlToString util
Fixed the ubiquitous use of quotes & small syntax refactoring
Merge pull request #8 from f3ath/allow-empty-version
Allow empty version
 load from file - replace deprecated isInstanceOf
Merge pull request #6 from f3ath/deprecated-member
Merge pull request #7 from f3ath/load-from-file
Add PubSpec.loadFile(). Fixes #5
isInstanceOf is deprecated
Merge branch 'release/0.1.0'

# 0.1.4
Added support for 'executables' map in the pubspec.
Exported Executable.

# Changelog
## 0.1.3
Demoved the dependency on the stuff package has it had a dependency on mirrors. The result is that you couldn't do a native compile of any package dependent on pubspec. Copied the class Json_utils.dart from stuff package to make this possible.

## 0.1.1

- load from file
- replace deprecated isInstanceOf

## 0.1.0

- Dart 2

## 0.0.11

- additional constructor

## 0.0.10

- tidied a few things

## 0.0.9

- Bug Fix. publish_to was serialising to publishTo

## 0.0.8

- upgraded some dependencies

## 0.0.7

- add publish_to

## 0.0.6

- tidy dependencies

## 0.0.3

- Added property `allDependencies` which combines `dependencies` with
  `devDependencies`

## 0.0.2

- Added == and hashCode to dependency reference classes

## 0.0.1

- Initial version, created by Stagehand
