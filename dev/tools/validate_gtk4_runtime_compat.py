#!/usr/bin/env python3
"""Builds and tests GTK4 runtime compatibility against a selected sysroot."""

from __future__ import annotations

import argparse
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tempfile

OPTIONAL_SYMBOLS = (
    "gtk_accessible_set_accessible_parent",
    "gtk_accessible_announce",
)

HOST_SYSTEM_LIBRARIES = (
    "libanl.so",
    "libatomic.so",
    "libc.so",
    "libcrypt.so",
    "libdl.so",
    "libgcc_s.so",
    "libm.so",
    "libpthread.so",
    "libresolv.so",
    "librt.so",
    "libstdc++.so",
    "libutil.so",
)

GTK_RUNTIME_PREFIXES = (
    "libatk",
    "libcairo",
    "libepoxy",
    "libgdk",
    "libgio",
    "libglib",
    "libgobject",
    "libgraphene",
    "libgtk",
    "libharfbuzz",
    "libpango",
)


def run(
    command: list[str],
    *,
    cwd: Path,
    env: dict[str, str] | None = None,
    quiet: bool = False,
) -> str:
    print("+", " ".join(command), flush=True)
    result = subprocess.run(
        command,
        cwd=cwd,
        env=env,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
    )
    if result.stdout and (not quiet or result.returncode != 0):
        print(result.stdout, end="")
    result.check_returncode()
    return result.stdout


def gtk_version(sysroot: Path) -> tuple[int, int, int]:
    pc_file = sysroot / "usr/lib/pkgconfig/gtk4.pc"
    match = re.search(r"^Version:\s*(\d+)\.(\d+)\.(\d+)", pc_file.read_text(),
                      re.MULTILINE)
    if match is None:
        raise RuntimeError(f"Unable to read GTK version from {pc_file}")
    return tuple(int(component) for component in match.groups())


def find_gtk_library(sysroot: Path) -> Path:
    library = sysroot / "usr/lib/x86_64-linux-gnu/libgtk-4.so.1"
    if not library.exists():
        raise RuntimeError(f"GTK runtime library not found: {library}")
    return library.resolve()


def dynamic_symbols(repo: Path, library: Path) -> str:
    return run(["readelf", "--wide", "--dyn-syms",
                str(library)],
               cwd=repo,
               quiet=True)


def verify_sysroot_symbols(repo: Path, sysroot: Path,
                           version: tuple[int, int, int]) -> None:
    symbols = dynamic_symbols(repo, find_gtk_library(sysroot))
    expected = {
        "gtk_accessible_set_accessible_parent": version >= (4, 10, 0),
        "gtk_accessible_announce": version >= (4, 14, 0),
    }
    for symbol, should_exist in expected.items():
        exists = re.search(rf"\b{re.escape(symbol)}(?:@@?\S+)?$", symbols,
                           re.MULTILINE) is not None
        if exists != should_exist:
            raise RuntimeError(
                f"{symbol}: expected exported={should_exist} for GTK {version}, got {exists}"
            )


def verify_no_optional_imports(repo: Path, library: Path) -> None:
    symbols = dynamic_symbols(repo, library)
    for line in symbols.splitlines():
        if " UND " in line and any(symbol in line
                                   for symbol in OPTIONAL_SYMBOLS):
            raise RuntimeError(
                f"Compatibility artifact directly imports optional GTK symbol: {line}"
            )


def sysroot_runtime_command(sysroot: Path) -> list[str]:
    loader = sysroot / "lib/x86_64-linux-gnu/ld-linux-x86-64.so.2"
    if not loader.exists():
        raise RuntimeError(f"Dynamic loader not found: {loader}")
    library_dirs = [
        sysroot / "lib/x86_64-linux-gnu",
        sysroot / "usr/lib/x86_64-linux-gnu",
        sysroot / "lib",
        sysroot / "usr/lib",
    ]
    library_path = ":".join(str(path) for path in library_dirs)
    base = [str(loader), "--inhibit-cache", "--library-path", library_path]
    return base


def host_loader() -> Path:
    for candidate in (
            Path("/lib64/ld-linux-x86-64.so.2"),
            Path("/lib/x86_64-linux-gnu/ld-linux-x86-64.so.2"),
    ):
        if candidate.exists():
            return candidate
    raise RuntimeError("Unable to find the host x86_64 dynamic loader")


def stage_host_runtime_libraries(
        sysroot: Path) -> tempfile.TemporaryDirectory[str]:
    staging = tempfile.TemporaryDirectory(prefix="flutter-gtk4-runtime-")
    staging_path = Path(staging.name)
    library_dirs = (
        sysroot / "lib/x86_64-linux-gnu",
        sysroot / "usr/lib/x86_64-linux-gnu",
    )
    for library_dir in library_dirs:
        for library in library_dir.glob("*.so*"):
            if any(
                    library.name.startswith(prefix)
                    for prefix in HOST_SYSTEM_LIBRARIES):
                continue
            destination = staging_path / library.name
            if not destination.exists():
                destination.symlink_to(library)
    return staging


def host_runtime_command(staging: Path) -> list[str]:
    return [
        str(host_loader()),
        "--inhibit-cache",
        "--library-path",
        str(staging),
    ]


def run_container_test(
    repo: Path,
    output_dir: Path,
    image: str,
    runtime: str,
) -> None:
    if shutil.which(runtime) is None:
        raise RuntimeError(f"Container runtime not found: {runtime}")
    install_packages = " ".join(("libgtk-4-1", "libgtk-3-0", "libepoxy0"))
    container_script = (
        "set -eu; "
        "apt-get update -qq; "
        f"DEBIAN_FRONTEND=noninteractive apt-get install -y -qq {install_packages} >/dev/null; "
        "cp /opt/flutter/flutter_linux_gtk4_unittests /tmp/flutter_linux_gtk4_unittests; "
        "chmod +x /tmp/flutter_linux_gtk4_unittests; "
        "/tmp/flutter_linux_gtk4_unittests --gtest_filter=FlGtk4RuntimeApiTest.*"
    )
    run(
        [
            runtime,
            "run",
            "--rm",
            "--pull=missing",
            "--network=host",
            "--security-opt",
            "label=disable",
            "-v",
            f"{output_dir}:/opt/flutter:ro",
            image,
            "sh",
            "-c",
            container_script,
        ],
        cwd=repo,
    )


def verify_runtime_closure(
    repo: Path,
    sysroot: Path,
    executable: Path,
    base_command: list[str],
    host_runtime: bool,
) -> None:
    output = run([*base_command, "--list", str(executable)], cwd=repo)
    allowed_roots = (str(sysroot.resolve()), str(executable.parent.resolve()))
    for line in output.splitlines():
        match = re.search(r"=>\s+(/\S+)", line)
        if match is None:
            continue
        resolved = str(Path(match.group(1)).resolve())
        library_name = Path(resolved).name
        if host_runtime and library_name.startswith(GTK_RUNTIME_PREFIXES):
            if not resolved.startswith(str(sysroot.resolve())):
                raise RuntimeError(
                    f"GTK runtime dependency escaped selected sysroot: {line.strip()}"
                )
            continue
        if not resolved.startswith(allowed_roots) and not host_runtime:
            raise RuntimeError(
                f"Runtime dependency escaped selected sysroot: {line.strip()}")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--sysroot",
                        choices=("bullseye", "trixie"),
                        default="bullseye")
    parser.add_argument("--skip-build", action="store_true")
    parser.add_argument(
        "--runtime-loader",
        choices=("container", "host", "sysroot"),
        default="container",
        help=
        "Use a matching distro container, staged host libraries, or sysroot.",
    )
    parser.add_argument("--container-runtime", default="podman")
    parser.add_argument("--container-image", default=None)
    parser.add_argument(
        "--skip-runtime",
        action="store_true",
        help=
        "Only run sysroot, artifact, and link checks; do not execute tests.",
    )
    args = parser.parse_args()

    repo = Path(__file__).resolve().parents[2]
    engine_src = repo / "engine/src"
    sysroot = engine_src / f"build/linux/debian_{args.sysroot}_amd64-sysroot"
    output_name = f"host_debug_unopt_{args.sysroot}_gtk4_compat"
    output_dir = engine_src / "out" / output_name
    version = gtk_version(sysroot)
    print(
        f"Selected {args.sysroot} sysroot with GTK {'.'.join(map(str, version))}"
    )

    verify_sysroot_symbols(repo, sysroot, version)

    if not args.skip_build:
        environment = os.environ.copy()
        environment[
            "VPYTHON_BYPASS"] = "manually managed python not supported by chrome operations"
        gn_args = (
            f'angle_use_wayland=false linux_x64_sysroot_variant="{args.sysroot}" '
            "gtk4_runtime_api_compat=true gtk4_native_accessibility_tree=false"
        )
        run(
            [
                "python3",
                "engine/src/flutter/tools/gn",
                "--unoptimized",
                "--runtime-mode=debug",
                f"--target-dir={output_name}",
                f"--gn-args={gn_args}",
            ],
            cwd=repo,
            env=environment,
        )
        run(
            [
                "autoninja",
                "-C",
                str(output_dir),
                "flutter_linux_gtk4",
                "flutter_linux_gtk4_unittests",
            ],
            cwd=repo,
        )

    library = output_dir / "libflutter_linux_gtk4.so"
    test_binary = output_dir / "flutter_linux_gtk4_unittests"
    if not library.exists() or not test_binary.exists():
        raise RuntimeError(
            f"Expected build outputs are missing from {output_dir}")

    verify_no_optional_imports(repo, library)
    if args.skip_runtime:
        print(
            "Build and artifact validation passed; runtime execution skipped.")
        return 0

    environment = os.environ.copy()
    environment.pop("LD_LIBRARY_PATH", None)
    environment.pop("LD_PRELOAD", None)
    environment["FLUTTER_LINUX_GTK_DEBUG"] = "1"
    if args.runtime_loader == "container":
        image = args.container_image
        if image is None:
            image = "debian:bookworm" if args.sysroot == "bullseye" else "debian:trixie"
        run_container_test(
            repo,
            output_dir,
            image,
            args.container_runtime,
        )
    elif args.runtime_loader == "host":
        with stage_host_runtime_libraries(sysroot) as staging:
            runtime_command = host_runtime_command(Path(staging))
            verify_runtime_closure(repo,
                                   sysroot,
                                   test_binary,
                                   runtime_command,
                                   host_runtime=True)
            run(
                [
                    *runtime_command,
                    str(test_binary),
                    "--gtest_filter=FlGtk4RuntimeApiTest.*",
                ],
                cwd=repo,
                env=environment,
            )
    else:
        runtime_command = sysroot_runtime_command(sysroot)
        verify_runtime_closure(repo,
                               sysroot,
                               test_binary,
                               runtime_command,
                               host_runtime=False)
        run(
            [
                *runtime_command,
                str(test_binary),
                "--gtest_filter=FlGtk4RuntimeApiTest.*",
            ],
            cwd=repo,
            env=environment,
        )
    print(f"GTK4 runtime compatibility validation passed for {args.sysroot}")
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except (OSError, RuntimeError, subprocess.CalledProcessError) as error:
        print(f"error: {error}", file=sys.stderr)
        sys.exit(1)
