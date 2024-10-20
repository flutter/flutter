Due to the newly added framework presubmit tests, if your engine commit breaks the framework in some way, **build_and_test_host** will likely catch it. In some cases, that breakage is intended and it requires a subsequent framework change (a.k.a., a manual engine roll) to fix the breakage.

While the breaking commit landed in the engine tree but the manual engine roll has not landed in the framework tree, all engine PRs could fail **build_and_test_host** unless those PRs are created based on an older engine tree without that breaking commit.

Therefore, for the author of the breaking commit that needs a manual roll, please notify others in
* Flutter engine,
* Flutter & Dart,
* Flutter & Skia chat rooms,
* and anyone who's rolling into the Flutter engine tree.

Feel free to @all to grab attentions as many people probably will skip any message without a red dot.

For authors of other PRs: please hold your PR until the manual roll finishes and rerun build_and_test_host for a green landing if it's not urgent. If your PR needs to fix something urgently, you may still land it on red build_and_test_host with an explicit explanation that the redness is caused by another commit.