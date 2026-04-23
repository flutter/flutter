#!/usr/bin/env python3
"""Inspect and validate an application's exported AT-SPI tree.

This script talks to AT-SPI the same way Orca does: as a client on the
accessibility bus. It is useful for checking whether a Flutter/Linux embedder
is exporting a tree with the expected names, roles, states, and hierarchy.

Dependencies:
  sudo apt install python3-pyatspi

Examples:
  python3 dev/tools/validate_atspi_export.py --app-name Runner --dump-tree
  python3 dev/tools/validate_atspi_export.py --pid 12345 --expect-name "Save"
  python3 dev/tools/validate_atspi_export.py --app-name Runner \
      --expect-role push button --expect-name Save --expect-state focused
"""

from __future__ import annotations

import argparse
import sys
from dataclasses import dataclass
from typing import Iterable, Iterator, Optional

import pyatspi


@dataclass(frozen=True)
class NodeView:
    accessible: object
    depth: int


def iter_children(accessible: object) -> Iterator[object]:
    try:
        count = accessible.childCount
    except Exception:
        return
    for index in range(count):
        try:
            child = accessible.getChildAtIndex(index)
        except Exception:
            continue
        if child is not None:
            yield child


def walk_tree(root: object, max_depth: Optional[int]) -> Iterator[NodeView]:
    stack = [NodeView(root, 0)]
    while stack:
        current = stack.pop()
        yield current
        if max_depth is not None and current.depth >= max_depth:
            continue
        children = list(iter_children(current.accessible))
        for child in reversed(children):
            stack.append(NodeView(child, current.depth + 1))


def safe_name(accessible: object) -> str:
    try:
        return accessible.name or ""
    except Exception:
        return ""


def safe_role_name(accessible: object) -> str:
    try:
        return accessible.getRoleName() or ""
    except Exception:
        return ""


def safe_description(accessible: object) -> str:
    try:
        return accessible.description or ""
    except Exception:
        return ""


def safe_state_names(accessible: object) -> list[str]:
    try:
        state_set = accessible.getState()
        return sorted(
            pyatspi.stateToString(int(state)).lower().replace("_", " ")
            for state in state_set.getStates()
        )
    except Exception:
        return []


def normalize(text: str) -> str:
    return " ".join(text.strip().lower().split())


def find_application(app_name: Optional[str], pid: Optional[int]) -> object:
    desktop = pyatspi.Registry.getDesktop(0)
    for application in desktop:
        if application is None:
            continue
        if app_name is not None and normalize(safe_name(application)) == normalize(
            app_name
        ):
            return application
        if pid is not None:
            try:
                if application.get_process_id() == pid:
                    return application
            except Exception:
                pass
    raise LookupError(
        f"Could not find application for app_name={app_name!r} pid={pid!r}"
    )


def matches_expected(node: object, expect_name: str, expect_role: str) -> bool:
    if expect_name and normalize(safe_name(node)) != normalize(expect_name):
        return False
    if expect_role and normalize(safe_role_name(node)) != normalize(expect_role):
        return False
    return True


def states_contain(node: object, required_states: Iterable[str]) -> bool:
    node_states = {normalize(state) for state in safe_state_names(node)}
    return all(normalize(state) in node_states for state in required_states)


def dump_tree(root: object, max_depth: Optional[int]) -> None:
    for item in walk_tree(root, max_depth):
        node = item.accessible
        indent = "  " * item.depth
        name = safe_name(node) or "<unnamed>"
        role = safe_role_name(node) or "<no-role>"
        states = ", ".join(safe_state_names(node))
        description = safe_description(node)
        line = f"{indent}- {role}: {name}"
        if states:
            line += f" [states: {states}]"
        if description:
            line += f" [description: {description}]"
        print(line)


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Inspect and validate an app's exported AT-SPI tree."
    )
    target = parser.add_mutually_exclusive_group(required=True)
    target.add_argument("--app-name", help="Accessible application name to inspect")
    target.add_argument("--pid", type=int, help="Process ID of the application")
    parser.add_argument(
        "--dump-tree",
        action="store_true",
        help="Print the accessible tree for the matched application",
    )
    parser.add_argument(
        "--max-depth",
        type=int,
        default=4,
        help="Maximum depth when dumping or searching the tree",
    )
    parser.add_argument(
        "--expect-name",
        help="Require a node with this exact accessible name",
    )
    parser.add_argument(
        "--expect-role",
        help="Require a node with this exact role name, for example 'push button'",
    )
    parser.add_argument(
        "--expect-state",
        action="append",
        default=[],
        help="Require matched node to include this state; can be repeated",
    )
    parser.add_argument(
        "--list-apps",
        action="store_true",
        help="List top-level app names on the AT-SPI desktop before validating",
    )
    args = parser.parse_args()

    if args.list_apps:
        desktop = pyatspi.Registry.getDesktop(0)
        print("Applications on AT-SPI desktop:")
        for application in desktop:
            if application is None:
                continue
            app_label = safe_name(application) or "<unnamed>"
            try:
                app_pid = application.get_process_id()
            except Exception:
                app_pid = "?"
            print(f"- {app_label} (pid={app_pid})")
        print()

    try:
        application = find_application(args.app_name, args.pid)
    except LookupError as error:
        print(str(error), file=sys.stderr)
        return 2

    app_label = safe_name(application) or "<unnamed>"
    print(f"Matched application: {app_label}")

    if args.dump_tree:
        dump_tree(application, args.max_depth)

    if not args.expect_name and not args.expect_role and not args.expect_state:
        return 0

    for item in walk_tree(application, args.max_depth):
        node = item.accessible
        if not matches_expected(node, args.expect_name or "", args.expect_role or ""):
            continue
        if not states_contain(node, args.expect_state):
            continue

        print("Found matching node:")
        print(f"- name: {safe_name(node) or '<unnamed>'}")
        print(f"- role: {safe_role_name(node) or '<no-role>'}")
        node_states = safe_state_names(node)
        if node_states:
            print(f"- states: {', '.join(node_states)}")
        return 0

    print("No matching node found.", file=sys.stderr)
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
