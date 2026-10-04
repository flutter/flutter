# Packages Autoroller

This script is executed [by a LUCI bot][LUCI] to generate PRs updating package
dependencies.

To run locally:

```sh
./dev/packages_autoroller/run
```

The recipe is located here and must be kept in sync:

<https://flutter.googlesource.com/recipes/+/refs/heads/main/recipes/pub_autoroller/pub_autoroller.py>

[luci]: https://ci.chromium.org/ui/p/flutter/builders/prod/Linux%20packages_autoroller
