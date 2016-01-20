Directory to support running Flutter builds/tests on Chromium Infra.

Following documentation at:
https://github.com/luci/recipes-py/blob/master/doc/cross_repo.md

recipes.cfg is a protobuf dump (no comment support) explaining
where to store build and recipe_engine dependencies needed for running
a recipe.

recipes.py is for bootstrapping and is taken from
https://chromium.googlesource.com/chromium/tools/build.git/+/master/scripts/slave/recipes.py
at 18df86c, modified to have correct hard-coded paths for flutter.
