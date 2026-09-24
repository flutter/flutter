#!/usr/bin/env python3
#
# Copyright 2013 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.
#
# Usage: python3 create_updated_flutter_deps_tests.py
#
# Unit tests for create_updated_flutter_deps.py script.

import os
import unittest

from create_updated_flutter_deps import (
    BROWSER_ENVIRONMENT_JS,
    DART_COMPILE_RELPATH,
    DART_SDK_ROOT,
    FLUTTER_DEPS,
    ComputeDartDeps,
    ExtractBrowserEnvironmentSupportExpression,
    ExtractDart2WasmSupportExpression,
    PrettifySourcePathForDEPS,
    UpdateBrowserEnvironmentJsContent,
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


class TestDart2WasmSupportSync(unittest.TestCase):
    def test_ExtractDart2WasmSupportExpression_across_epochs(self):
        # Epoch 1: WasmGC unconditional, js-string conditional.
        epoch1 = """
String _generateSupportJs(TranslatorOptions options) {
  const String supportsWasmGC = 'WebAssembly.validate(new Uint8Array([1]))';
  const String supportsJsStringBuiltins = '!WebAssembly.validate(new Uint8Array([2]),{"builtins":["js-string"]})';
  final requiredFeatures = [
    supportsWasmGC,
    if (options.requireJsStringBuiltin) supportsJsStringBuiltins
  ];
  return '(${requiredFeatures.join('&&')})';
}
"""
        self.assertEqual(
            ExtractDart2WasmSupportExpression(epoch1),
            "(WebAssembly.validate(new Uint8Array([1])))",
        )

        # Epoch 2: WasmGC + SIMD + js-string unconditional, multi-memory conditional.
        epoch2 = """
String _generateSupportJs({required bool requiresMultiMemory}) {
  const String supportsWasmGC = 'WebAssembly.validate(new Uint8Array([1]))';
  const String supportsWasmSimd = 'WebAssembly.validate(new Uint8Array([2]))';
  const String supportsWasmMultiMemory = 'WebAssembly.validate(new Uint8Array([3]))';
  const String supportsJsStringBuiltins = '!WebAssembly.validate(new Uint8Array([4]),{"builtins":["js-string"]})';
  final requiredFeatures = [
    supportsWasmGC,
    supportsWasmSimd,
    supportsJsStringBuiltins,
    if (requiresMultiMemory) supportsWasmMultiMemory,
  ];
  return '(${requiredFeatures.join('&&')})';
}
"""
        self.assertEqual(
            ExtractDart2WasmSupportExpression(epoch2),
            "(WebAssembly.validate(new Uint8Array([1]))&&WebAssembly.validate(new Uint8Array([2]))&&!WebAssembly.validate(new Uint8Array([4]),{\"builtins\":[\"js-string\"]}))",
        )

        # Epoch 3: try_table added unconditionally.
        epoch3 = """
String _generateSupportJs({required bool requiresMultiMemory}) {
  const String supportsWasmGC = 'WebAssembly.validate(new Uint8Array([1]))';
  const String supportsWasmSimd = 'WebAssembly.validate(new Uint8Array([2]))';
  const String supportsWasmMultiMemory = 'WebAssembly.validate(new Uint8Array([3]))';
  const String supportsJsStringBuiltins = '!WebAssembly.validate(new Uint8Array([4]),{"builtins":["js-string"]})';
  const String supportsTryTable = 'WebAssembly.validate(new Uint8Array([5]))';
  final requiredFeatures = [
    supportsWasmGC,
    supportsWasmSimd,
    supportsJsStringBuiltins,
    supportsTryTable,
    if (requiresMultiMemory) supportsWasmMultiMemory,
  ];
  return '(${requiredFeatures.join('&&')})';
}
"""
        self.assertEqual(
            ExtractDart2WasmSupportExpression(epoch3),
            "(WebAssembly.validate(new Uint8Array([1]))&&WebAssembly.validate(new Uint8Array([2]))&&!WebAssembly.validate(new Uint8Array([4]),{\"builtins\":[\"js-string\"]})&&WebAssembly.validate(new Uint8Array([5])))",
        )

    def test_UpdateBrowserEnvironmentJsContent(self):
        sample_js = """const supportsDart2Wasm = () => {
  // Comment
  return (WebAssembly.validate(new Uint8Array([1]))&&WebAssembly.validate(new Uint8Array([2])));
}
"""
        new_expr = "(WebAssembly.validate(new Uint8Array([1]))&&WebAssembly.validate(new Uint8Array([2]))&&WebAssembly.validate(new Uint8Array([3])))"
        updated = UpdateBrowserEnvironmentJsContent(sample_js, new_expr)
        self.assertEqual(
            ExtractBrowserEnvironmentSupportExpression(updated),
            new_expr,
        )
        # Idempotent when applied again.
        self.assertEqual(
            UpdateBrowserEnvironmentJsContent(updated, new_expr),
            updated,
        )

    def test_LiveBrowserEnvironmentJsParity(self):
        self.assertTrue(os.path.isfile(BROWSER_ENVIRONMENT_JS))
        with open(BROWSER_ENVIRONMENT_JS, "r", encoding="utf-8") as fp:
            browser_env_content = fp.read()
        current_expr = ExtractBrowserEnvironmentSupportExpression(browser_env_content)
        self.assertTrue(current_expr.startswith("(WebAssembly.validate("))

        local_compile_dart = os.path.join(
            os.path.dirname(FLUTTER_DEPS),
            DART_SDK_ROOT,
            DART_COMPILE_RELPATH,
        )
        if os.path.isfile(local_compile_dart):
            with open(local_compile_dart, "r", encoding="utf-8") as fp:
                compile_dart_content = fp.read()
            expected_expr = ExtractDart2WasmSupportExpression(compile_dart_content)
            self.assertEqual(
                current_expr,
                expected_expr,
                "supportsDart2Wasm() in browser_environment.js is out of sync with "
                "pkg/dart2wasm/lib/compile.dart. Run "
                "`python3 engine/src/tools/dart/create_updated_flutter_deps.py` to update.",
            )


if __name__ == "__main__":
    unittest.main()

