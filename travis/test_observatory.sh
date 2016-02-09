echo "Testing sky_shell Observatory..."

PATH="$HOME/depot_tools:$PATH"

SKY_SHELL_BIN=out/Debug/sky_shell
OBSERVATORY_TEST=sky/shell/testing/observatory/test.dart
EMPTY_MAIN=sky/shell/testing/observatory/empty_main.dart

dart $OBSERVATORY_TEST $SKY_SHELL_BIN $EMPTY_MAIN
