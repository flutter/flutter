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
    DART_COMPILE_RELPATH,
    DART_SDK_ROOT,
    FLUTTER_DEPS,
    SUPPORTS_DART2WASM_JS,
    ComputeDartDeps,
    ExtractDart2WasmSupportExpression,
    FormatSupportsDart2WasmJs,
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

    def test_FormatSupportsDart2WasmJs(self):
        expr = "(WebAssembly.validate(new Uint8Array([1]))&&WebAssembly.validate(new Uint8Array([2])))"
        formatted = FormatSupportsDart2WasmJs(expr)
        self.assertIn("// GENERATED FILE. DO NOT EDIT.", formatted)
        self.assertIn("export const supportsDart2Wasm = () => {\n  return " + expr + ";\n};\n", formatted)

    def test_LiveSupportsDart2WasmJsParity(self):
        self.assertTrue(os.path.isfile(SUPPORTS_DART2WASM_JS))
        with open(SUPPORTS_DART2WASM_JS, "r", encoding="utf-8") as fp:
            supports_js_content = fp.read()
        self.assertIn("export const supportsDart2Wasm = () => {", supports_js_content)
        self.assertIn("return (WebAssembly.validate(", supports_js_content)

        local_compile_dart = os.path.join(
            os.path.dirname(FLUTTER_DEPS),
            DART_SDK_ROOT,
            DART_COMPILE_RELPATH,
        )
        if os.path.isfile(local_compile_dart):
            with open(local_compile_dart, "r", encoding="utf-8") as fp:
                compile_dart_content = fp.read()
            expected_expr = ExtractDart2WasmSupportExpression(compile_dart_content)
            expected_content = FormatSupportsDart2WasmJs(expected_expr)
            self.assertEqual(
                supports_js_content,
                expected_content,
                "supports_dart2wasm.js is out of sync with "
                "pkg/dart2wasm/lib/compile.dart. Run "
                "`python3 engine/src/tools/dart/create_updated_flutter_deps.py` to update.",
            )

    def test_ExtractDart2WasmSupportExpression_DoubleAndSingleQuotes(self):
        mixed_quotes_compile_dart = """
String _generateSupportJs(WasmCompilerOptions options) {
  const String supportsWasmGC = "WebAssembly.validate(new Uint8Array([0,97,115,109]))";
  const String supportsJsStringBuiltins =
      '!WebAssembly.validate(new Uint8Array([0]),{"builtins":["js-string"]})';
  final requiredFeatures = [
    supportsWasmGC,
    supportsJsStringBuiltins,
  ];
  return '(${requiredFeatures.join('&&')})';
}
"""
        self.assertEqual(
            ExtractDart2WasmSupportExpression(mixed_quotes_compile_dart),
            '(WebAssembly.validate(new Uint8Array([0,97,115,109]))&&!WebAssembly.validate(new Uint8Array([0]),{"builtins":["js-string"]}))',
        )

    def test_ResolveDartCompileFileContent_PrecedenceAndWarning(self):
        import argparse
        import io
        import tempfile
        from unittest import mock
        import create_updated_flutter_deps

        with tempfile.TemporaryDirectory() as tmpdir:
            local_sdk_dir = os.path.join(tmpdir, "pkg", "dart2wasm", "lib")
            os.makedirs(local_sdk_dir, exist_ok=True)
            local_compile = os.path.join(local_sdk_dir, "compile.dart")
            with open(local_compile, "w", encoding="utf-8") as fp:
                fp.write("// local stale compile.dart")
            fake_deps = os.path.join(tmpdir, "DEPS")
            with open(fake_deps, "w", encoding="utf-8") as fp:
                fp.write("vars = {}")

            # 1. When --dart_revision (-r) is passed, gitiles at that revision wins over stale local file.
            args_with_rev = argparse.Namespace(
                dart_compile_file=None,
                dart_revision="new_target_rev",
                dart_deps=fake_deps,
                flutter_deps=None,
            )
            with mock.patch(
                "create_updated_flutter_deps._FetchCompileDartFromGitiles",
                return_value="// fetched for new_target_rev",
            ) as mock_fetch:
                resolved = create_updated_flutter_deps.ResolveDartCompileFileContent(
                    args_with_rev, {"dart_revision": "old_flutter_rev"}
                )
                self.assertEqual(resolved, "// fetched for new_target_rev")
                mock_fetch.assert_called_once_with("new_target_rev")

            # 2. When no local file exists and --dart_revision is omitted, falls back to flutter_vars['dart_revision'].
            args_no_local = argparse.Namespace(
                dart_compile_file=None,
                dart_revision=None,
                dart_deps=None,
                flutter_deps=None,
            )
            with mock.patch(
                "create_updated_flutter_deps._FetchCompileDartFromGitiles",
                return_value="// fetched for flutter_vars_rev",
            ) as mock_fetch_fallback:
                resolved_fallback = create_updated_flutter_deps.ResolveDartCompileFileContent(
                    args_no_local, {"dart_revision": "flutter_vars_rev"}
                )
                self.assertEqual(resolved_fallback, "// fetched for flutter_vars_rev")
                mock_fetch_fallback.assert_called_once_with("flutter_vars_rev")

            # 3. SyncSupportsDart2WasmJs logs warning to stderr when compile.dart cannot be resolved.
            fake_supports_js = os.path.join(tmpdir, "supports_dart2wasm.js")
            args_missing = argparse.Namespace(
                supports_dart2wasm_js=fake_supports_js,
                dart_compile_file=None,
                dart_revision=None,
                dart_deps=None,
                flutter_deps=None,
            )
            stderr_buf = io.StringIO()
            with mock.patch("sys.stderr", stderr_buf):
                self.assertFalse(
                    create_updated_flutter_deps.SyncSupportsDart2WasmJs(args_missing, {})
                )
            self.assertIn("could not resolve pkg/dart2wasm/lib/compile.dart", stderr_buf.getvalue())


if __name__ == "__main__":
    unittest.main()


