# -*- bazel-starlark -*-
# Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.
"""Siso configuration main entry."""

load("@builtin//encoding.star", "json")
load("@builtin//lib/gn.star", "gn")
load("@builtin//struct.star", "module")
load("./clang.star", "clang")
load("./simple.star", "simple")

def init(ctx):
    step_config = {
        "platforms": {
            "default": {
                "OSFamily": "Linux",
                "container-image": "docker://gcr.io/cloud-marketplace/google/debian12@sha256:b93235fea71bd454ee11e8f857eb7c1672d033d426d9c0401c53df3c71fd52e7",
            },
            "default_windows": {
                "OSFamily": "Windows",
                "container-image": "docker://gcr.io/chops-private-images-prod/rbe/chromium-browser-clang/windows@sha256:a9bfec46093aa4b8fc077a2b2da6bb8de3e8f13f86c9010a08182d9d3f0171f3",
            },
        },
        "input_deps": {},
        "rules": [],
        "executables": [],
    }
    filegroups = {}
    handlers = {}
    for m in [
        clang,
        simple,
    ]:
        step_config = m.step_config(ctx, step_config)
        filegroups.update(m.filegroups(ctx))
        handlers.update(m.handlers)

    use_rbe = False
    if "args.gn" in ctx.metadata:
        use_rbe = gn.args(ctx).get("use_rbe") == "true"
    if not use_rbe:
        for rule in step_config["rules"]:
            rule["remote"] = False

    return module(
        "config",
        step_config = json.encode(step_config),
        filegroups = filegroups,
        handlers = handlers,
    )
