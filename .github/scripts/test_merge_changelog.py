# Copyright 2014 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Unit tests for merge_changelog.py."""

import pathlib
import sys
import tempfile
import unittest

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
import merge_changelog  # noqa: E402

_PREAMBLE = """Header text.

<!--
INTERNAL NOTE
-->

"""


class MergeChangelogTest(unittest.TestCase):
    """Tests section-level merging of master and stable CHANGELOG.md files."""

    def test_preserves_older_minor_hotfixes_on_new_minor_release(self) -> None:
        """Preserves prior minor hotfixes on master when stable promotes a new minor."""
        master = (
            _PREAMBLE
            + """## Flutter 3.47 Changes

### [3.47.9](https://github.com/flutter/flutter/releases/tag/3.47.9)
- [flutter/194570](https://github.com/flutter/flutter/issues/194570) Fix MAX_PATH crash.

### [3.47.8](https://github.com/flutter/flutter/releases/tag/3.47.8)
#### Security advisory GHSA-frr6-h895-5pxp:
- [dart/568000](https://dart-review.googlesource.com/c/sdk/+/568000) BoringSSL update.

### [3.47.7](https://github.com/flutter/flutter/releases/tag/3.47.7)
- [flutter/182604](https://github.com/flutter/flutter/issues/182604) Fix OverlayPortal.
"""
        )
        stable = (
            _PREAMBLE
            + """## Flutter 3.50 Changes

### [3.50.1](https://github.com/flutter/flutter/releases/tag/3.50.1)
- [flutter/196412](https://github.com/flutter/flutter/issues/196412) Fix Gradle buildType.

### [3.50.0](https://github.com/flutter/flutter/releases/tag/3.50.0)

Learn about what's new in 3.50.


## Flutter 3.47 Changes

### [3.47.7](https://github.com/flutter/flutter/releases/tag/3.47.7)
- [flutter/182604](https://github.com/flutter/flutter/issues/182604) Fix OverlayPortal.
"""
        )

        merged = merge_changelog.merge_changelogs(master, stable)
        self.assertIn("### [3.50.1]", merged)
        self.assertIn("### [3.50.0]", merged)
        self.assertIn("### [3.47.9]", merged)
        self.assertIn("### [3.47.8]", merged)
        self.assertIn("GHSA-frr6-h895-5pxp", merged)
        self.assertIn("### [3.47.7]", merged)
        self.assertLess(merged.index("## Flutter 3.50 Changes"), merged.index("## Flutter 3.47 Changes"))
        self.assertLess(merged.index("### [3.47.9]"), merged.index("### [3.47.8]"))
        self.assertLess(merged.index("### [3.47.8]"), merged.index("### [3.47.7]"))

        # Re-running with the same stable input is a no-op.
        self.assertEqual(merge_changelog.merge_changelogs(merged, stable), merged)

        # Subsequent dot release (3.50.2) + wording edit in 3.50.1 updates cleanly without duplicating bullets.
        stable_3502 = stable.replace(
            "## Flutter 3.50 Changes\n\n### [3.50.1]",
            "## Flutter 3.50 Changes\n\n### [3.50.2](https://github.com/flutter/flutter/releases/tag/3.50.2)\n"
            "- [flutter/199999](https://github.com/flutter/flutter/issues/199999) Fix 3.50.2 issue.\n\n### [3.50.1]",
        ).replace("Fix Gradle buildType.", "Fix Android Gradle buildType.")

        merged_3502 = merge_changelog.merge_changelogs(merged, stable_3502)
        self.assertIn("### [3.50.2]", merged_3502)
        self.assertIn("Fix Android Gradle buildType.", merged_3502)
        self.assertNotIn("Fix Gradle buildType.", merged_3502)
        self.assertIn("### [3.47.9]", merged_3502)
        self.assertIn("### [3.47.8]", merged_3502)

    def test_merges_disjoint_patches_within_same_minor(self) -> None:
        """Orders disjoint patches within the same minor section in descending semver order."""
        master = (
            _PREAMBLE
            + """## Flutter 3.47 Changes

### [3.47.9](https://github.com/flutter/flutter/releases/tag/3.47.9)
- Patch 9.

### [3.47.7](https://github.com/flutter/flutter/releases/tag/3.47.7)
- Patch 7.
"""
        )
        stable = (
            _PREAMBLE
            + """## Flutter 3.47 Changes

### [3.47.8](https://github.com/flutter/flutter/releases/tag/3.47.8)
- Patch 8.

### [3.47.7](https://github.com/flutter/flutter/releases/tag/3.47.7)
- Patch 7.
"""
        )
        merged = merge_changelog.merge_changelogs(master, stable)
        self.assertLess(merged.index("### [3.47.9]"), merged.index("### [3.47.8]"))
        self.assertLess(merged.index("### [3.47.8]"), merged.index("### [3.47.7]"))

    def test_rejects_stray_h2_heading(self) -> None:
        """Raises ValueError if an unexpected H2 heading appears outside comments."""
        bad = _PREAMBLE + "## [3.50.1](https://example.com)\n- Typo H2 instead of H3.\n"
        good = _PREAMBLE + "## Flutter 3.50 Changes\n\n### [3.50.0](https://example.com)\n- Initial.\n"
        with self.assertRaises(ValueError):
            merge_changelog.merge_changelogs(good, bad)

    def test_handles_crlf_line_endings(self) -> None:
        """Normalizes CRLF inputs and writes LF output without stray CR characters."""
        master_crlf = (
            _PREAMBLE
            + "## Flutter 3.47 Changes\n\n"
            "### [3.47.9](https://github.com/flutter/flutter/releases/tag/3.47.9)\n"
            "- Patch 9.\n"
        ).replace("\n", "\r\n")
        stable_crlf = (
            _PREAMBLE
            + "## Flutter 3.47 Changes\n\n"
            "### [3.47.8](https://github.com/flutter/flutter/releases/tag/3.47.8)\n"
            "- Patch 8.\n"
        ).replace("\n", "\r\n")

        merged = merge_changelog.merge_changelogs(master_crlf, stable_crlf)
        self.assertNotIn("\r", merged)
        self.assertLess(merged.index("### [3.47.9]"), merged.index("### [3.47.8]"))

        with tempfile.TemporaryDirectory() as tmp:
            master_path = pathlib.Path(tmp) / "master.md"
            stable_path = pathlib.Path(tmp) / "stable.md"
            master_path.write_bytes(master_crlf.encode("utf-8"))
            stable_path.write_bytes(stable_crlf.encode("utf-8"))
            rc = merge_changelog.main(["merge_changelog.py", str(master_path), str(stable_path)])
            self.assertEqual(rc, 0)
            self.assertNotIn(b"\r", master_path.read_bytes())


if __name__ == "__main__":
    unittest.main()
