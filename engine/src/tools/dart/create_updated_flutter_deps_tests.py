#!/usr/bin/env python3
#
# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.
#
# Usage: python3 create_updated_flutter_deps_tests.py
#
# Unit tests for create_updated_flutter_deps.py script.

import unittest

from create_updated_flutter_deps import (
    DART_SDK_ROOT,
    ComputeDartDeps,
    PrettifySourcePathForDEPS,
)


class TestPrettifySourcePathForDEPS(unittest.TestCase):
    def test_PrettifySourcePathForDEPS_unversioned(self):
        with self.assertRaises(ValueError):
            PrettifySourcePathForDEPS(flutter_vars={}, dep_path="a", source="b")

    def test_PrettifySourcePathForDEPS_all_cases(self):
        a_git = "https://a.googlesource.com"
        b_git = "https://b.googlesource.com"
        flutter_vars = {
            "a_git": a_git,
            "dart_dep2_tag": "xyz",
            "dart_dep3_rev": "def",
        }

        deps = {
            "/no_repo_var/dep1": f"{b_git}/repos/dep1@whatever",
            "/no_repo_var/dep2": f"{b_git}/repos/dep2@whatever",
            "/no_repo_var/dep2/src": f"{b_git}/repos/dep2@whatever",
            "/no_repo_var/dep3": f"{b_git}/repos/dep3@whatever",
            "/no_repo_var/dep3/src": f"{b_git}/repos/dep3@whatever",
            "/a_git_repo/dep1": f"{a_git}/repos/dep1@whatever",
            "/a_git_repo/dep2": f"{a_git}/repos/dep2@whatever",
            "/a_git_repo/dep2/src": f"{a_git}/repos/dep2@whatever",
            "/a_git_repo/dep3": f"{a_git}/repos/dep3@whatever",
            "/a_git_repo/dep3/src": f"{a_git}/repos/dep3@whatever",
        }

        expected = {
            "/no_repo_var/dep1": f"'{b_git}/repos/dep1@whatever'",
            "/no_repo_var/dep2": f"'{b_git}/repos/dep2' + '@' + Var('dart_dep2_tag')",
            "/no_repo_var/dep2/src": f"'{b_git}/repos/dep2' + '@' + Var('dart_dep2_tag')",
            "/no_repo_var/dep3": f"'{b_git}/repos/dep3' + '@' + Var('dart_dep3_rev')",
            "/no_repo_var/dep3/src": f"'{b_git}/repos/dep3' + '@' + Var('dart_dep3_rev')",
            "/a_git_repo/dep1": "Var('a_git') + '/repos/dep1@whatever'",
            "/a_git_repo/dep2": "Var('a_git') + '/repos/dep2' + '@' + Var('dart_dep2_tag')",
            "/a_git_repo/dep2/src": "Var('a_git') + '/repos/dep2' + '@' + Var('dart_dep2_tag')",
            "/a_git_repo/dep3": "Var('a_git') + '/repos/dep3' + '@' + Var('dart_dep3_rev')",
            "/a_git_repo/dep3/src": "Var('a_git') + '/repos/dep3' + '@' + Var('dart_dep3_rev')",
        }

        for dep_path, source_path in deps.items():
            self.assertEqual(
                PrettifySourcePathForDEPS(flutter_vars, dep_path, source_path),
                expected[dep_path],
            )


class TestComputeDartDeps(unittest.TestCase):
    def test_ComputeDartDeps_nothing_to_do(self):
        # Note: DART_SDK_ROOT dependency itself should be simply ignored.
        self.assertEqual(
            ComputeDartDeps(
                flutter_vars={},
                flutter_deps={
                    DART_SDK_ROOT: "whatever",
                },
                dart_deps={
                    "sdk": "xyz",
                },
            ),
            {},
        )

    def test_ComputeDartDeps_unused_dep(self):
        a_git = "https://a.googlesource.com"
        self.assertEqual(
            ComputeDartDeps(
                flutter_vars={
                    "a_git": a_git,
                },
                flutter_deps={
                    f"{DART_SDK_ROOT}/third_party/dep": f"{a_git}/repos/dep@version",
                },
                dart_deps={},
            ),
            {},
        )

    def test_ComputeDartDeps_used_dep(self):
        a_git = "https://a.googlesource.com"
        self.assertEqual(
            ComputeDartDeps(
                flutter_vars={
                    "a_git": a_git,
                },
                flutter_deps={
                    f"{DART_SDK_ROOT}/third_party/dep": "whatever",
                },
                dart_deps={"sdk/third_party/dep": f"{a_git}/repos/dep@version"},
            ),
            {
                f"{DART_SDK_ROOT}/third_party/dep": "Var('a_git') + '/repos/dep@version'",
            },
        )


if __name__ == "__main__":
    unittest.main()
