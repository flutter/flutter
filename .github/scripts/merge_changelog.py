# Copyright 2014 The Flutter Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Merges release sections from stable CHANGELOG.md into master CHANGELOG.md.

Unlike a raw file overwrite, this preserves hotfix entries on older minor
release series that landed on master after the current stable branch forked.
"""

from __future__ import annotations

from dataclasses import dataclass
import pathlib
import re
import sys

_H2_RE = re.compile(r"^## Flutter (\d+)\.(\d+) Changes[ \t]*$", re.MULTILINE)
_STRAY_H2_RE = re.compile(r"^## (?!Flutter \d+\.\d+ Changes[ \t]*$).+$", re.MULTILINE)
_H3_RE = re.compile(r"^### (.+)$", re.MULTILINE)
_SEMVER_RE = re.compile(r"^\[?(\d+)\.(\d+)\.(\d+)(?:\]|\s|$)")


@dataclass(frozen=True)
class _PatchEntry:
    key: str
    version: tuple[int, int, int] | None
    raw: str


@dataclass(frozen=True)
class _MinorSection:
    minor: tuple[int, int]
    header: str
    patches: tuple[_PatchEntry, ...]
    raw: str


def _strip_html_comments(text: str) -> str:
    return re.sub(r"<!--.*?-->", "", text, flags=re.DOTALL)


def _parse_changelog(text: str) -> tuple[str, dict[tuple[int, int], _MinorSection]]:
    stray = _STRAY_H2_RE.findall(_strip_html_comments(text))
    if stray:
        raise ValueError(f"Unexpected H2 heading(s) in CHANGELOG.md: {stray}")

    matches = list(_H2_RE.finditer(text))
    if not matches:
        raise ValueError("No '## Flutter X.Y Changes' sections found in CHANGELOG.md.")

    preamble = text[: matches[0].start()]
    sections: dict[tuple[int, int], _MinorSection] = {}

    for idx, match in enumerate(matches):
        minor = (int(match.group(1)), int(match.group(2)))
        if minor in sections:
            raise ValueError(f"Duplicate minor section: Flutter {minor[0]}.{minor[1]}")
        end = matches[idx + 1].start() if idx + 1 < len(matches) else len(text)
        raw = text[match.start() : end]

        h3_matches = list(_H3_RE.finditer(raw))
        header = raw[: h3_matches[0].start()] if h3_matches else raw
        patches: list[_PatchEntry] = []
        for j, h3_match in enumerate(h3_matches):
            p_end = h3_matches[j + 1].start() if j + 1 < len(h3_matches) else len(raw)
            p_raw = raw[h3_match.start() : p_end]
            title = h3_match.group(1).strip()
            sv = _SEMVER_RE.match(title)
            if sv:
                ver = (int(sv.group(1)), int(sv.group(2)), int(sv.group(3)))
                key = f"{ver[0]}.{ver[1]}.{ver[2]}"
            else:
                ver = None
                key = title
            patches.append(_PatchEntry(key=key, version=ver, raw=p_raw))

        sections[minor] = _MinorSection(
            minor=minor,
            header=header,
            patches=tuple(patches),
            raw=raw,
        )

    return preamble, sections


def _extract_semver_list(text: str) -> list[tuple[int, int, int]]:
    versions: list[tuple[int, int, int]] = []
    for h3_match in _H3_RE.finditer(text):
        sv = _SEMVER_RE.match(h3_match.group(1).strip())
        if sv:
            versions.append((int(sv.group(1)), int(sv.group(2)), int(sv.group(3))))
    return versions


def _merge_minor_section(
    master_sec: _MinorSection,
    stable_sec: _MinorSection,
    *,
    prefer_stable: bool,
) -> str:
    m_keys = {p.key for p in master_sec.patches}
    s_keys = {p.key for p in stable_sec.patches}

    if prefer_stable and m_keys.issubset(s_keys):
        return stable_sec.raw
    if not prefer_stable and s_keys.issubset(m_keys):
        return master_sec.raw

    primary = stable_sec if prefer_stable else master_sec
    secondary = master_sec if prefer_stable else stable_sec

    by_key = {p.key: p for p in secondary.patches}
    by_key.update({p.key: p for p in primary.patches})

    semver_patches = sorted(
        (p for p in by_key.values() if p.version is not None),
        key=lambda p: p.version,  # type: ignore[arg-type]
        reverse=True,
    )
    seen_non_semver: set[str] = set()
    other_patches: list[_PatchEntry] = []
    for p in (*primary.patches, *secondary.patches):
        if p.version is None and p.key not in seen_non_semver:
            seen_non_semver.add(p.key)
            other_patches.append(by_key[p.key])

    ordered = [*semver_patches, *other_patches]
    trailing_newlines = len(primary.raw) - len(primary.raw.rstrip("\n"))
    if trailing_newlines == 0:
        trailing_newlines = 2

    body = "\n\n".join(p.raw.rstrip("\n") for p in ordered)
    return f"{primary.header}{body}" + ("\n" * trailing_newlines)


def merge_changelogs(master_text: str, stable_text: str) -> str:
    """Merges release sections from stable CHANGELOG.md into master CHANGELOG.md.

    Normalizes CRLF/CR line endings to LF, lets stable win for the active stable
    minor series, and preserves hotfix entries on older minor release series
    present on master.

    Args:
        master_text: Contents of CHANGELOG.md from the master branch.
        stable_text: Contents of CHANGELOG.md from the stable branch.

    Returns:
        The merged CHANGELOG.md text using LF line endings.

    Raises:
        ValueError: If headings are malformed, duplicated, or lost during merge.
    """
    master_text = master_text.replace("\r\n", "\n").replace("\r", "\n")
    stable_text = stable_text.replace("\r\n", "\n").replace("\r", "\n")

    preamble, master_minors = _parse_changelog(master_text)
    _, stable_minors = _parse_changelog(stable_text)

    active_stable_minor = max(stable_minors.keys())
    all_minors = sorted(set(master_minors) | set(stable_minors), reverse=True)

    blocks: list[str] = [preamble]
    for idx, minor in enumerate(all_minors):
        is_last = idx == len(all_minors) - 1
        m_sec = master_minors.get(minor)
        s_sec = stable_minors.get(minor)
        if m_sec is None:
            assert s_sec is not None
            block = s_sec.raw
            if not is_last and not block.endswith("\n\n"):
                block = block.rstrip("\n") + "\n\n"
        elif s_sec is None:
            block = m_sec.raw
        else:
            prefer_stable = minor == active_stable_minor
            block = _merge_minor_section(
                m_sec,
                s_sec,
                prefer_stable=prefer_stable,
            )
            if prefer_stable and not is_last and not block.endswith("\n\n"):
                block = block.rstrip("\n") + "\n\n"
        blocks.append(block)

    merged = "".join(blocks)

    master_vers = _extract_semver_list(master_text)
    stable_vers = _extract_semver_list(stable_text)
    merged_vers = _extract_semver_list(merged)
    if len(merged_vers) != len(set(merged_vers)):
        raise ValueError("Merged CHANGELOG.md contains duplicate version headings.")
    expected = set(master_vers) | set(stable_vers)
    if set(merged_vers) != expected:
        missing = expected - set(merged_vers)
        raise ValueError(f"Merged CHANGELOG.md lost version headings: {sorted(missing)}")

    return merged


def main(argv: list[str]) -> int:
    """CLI entry point that merges stable CHANGELOG.md into master in place.

    Args:
        argv: Command-line arguments (`[prog, master_path, stable_path]`).

    Returns:
        Process exit code (`0` on success, `2` on usage error).
    """
    if len(argv) != 3:
        print(
            "Usage: merge_changelog.py <master_changelog_path> <stable_changelog_path>",
            file=sys.stderr,
        )
        return 2

    master_path = pathlib.Path(argv[1])
    stable_path = pathlib.Path(argv[2])

    merged = merge_changelogs(
        master_path.read_text(encoding="utf-8"),
        stable_path.read_text(encoding="utf-8"),
    )
    master_path.write_text(merged, encoding="utf-8", newline="\n")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
