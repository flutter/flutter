set -e # abort CI if an error happens
cd $1
flutter packages get
flutter format --set-exit-if-changed lib test
flutter analyze --no-current-package lib test/
flutter test --no-pub --coverage
# resets to the original state
cd -
