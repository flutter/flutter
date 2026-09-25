# Flutter RFCs & Design Documents

In the Flutter project, technical design documents are authored and reviewed as Requests for Comments (RFCs) in the [**`flutter/rfc`**](https://github.com/flutter/rfc) repository.

RFCs provide a collaborative, transparent space to share ideas early, explore trade-offs, align with subsystem maintainers, and build architectural consensus before writing production code.

---

## When to Write an RFC (The Threshold)

Not every contribution requires a formal RFC! The size and impact of your change guide the kind of documentation needed:

* **One-Pagers (Issue or PR description)**: Localized features, bug fixes, performance optimizations, or internal refactors within a single subsystem do not require an RFC. A clear description in a GitHub issue or pull request is often all you need.
* **Two-Pagers (Issue or PR description)**: Features that consume existing APIs across subsystems without altering public API/ABI contracts generally do not need an RFC. You can coordinate informally with the affected subsystem leads directly in GitHub issues or pull requests.
* **Full Design Docs / RFCs (Markdown in `flutter/rfc`)**: A formal RFC is required when proposing:
  * **Cross-Subsystem Architectural Impact**: Changes that cross or alter boundaries between major subsystems (e.g., Framework+Engine, Engine+Embedders).
  * **New Foundational Primitives**: New rendering backends, compilers, execution platforms, or embedder shells.
  * **File Formats & Protocols**: Wire protocols, packaging schemes, or tooling interop protocols.
  * **Breaking Changes & Deprecations**: Substantive alterations to public API/ABI contracts (see [Handling breaking changes](Tree-hygiene.md#handling-breaking-changes)).
  * **Governance, Release, & Infrastructure Policies**: Changes to release cycles, contributor standards, or the RFC process itself.
  * **Style Guide Changes**: Project-wide coding and formatting standards.

For complete threshold definitions and criteria, see [RFC 000.0002: When to Write an RFC](https://github.com/flutter/rfc/blob/main/rfc/000.0002-flutter-rfc-review-process.md#when-to-write-an-rfc-the-threshold).

---

## Seeking Approval on an RFC

An RFC Pull Request is where you propose your design and seek formal approval for your idea, architecture, or breaking change:

* **Approval happens on the RFC Pull Request**: Your pull request in `flutter/rfc` is the authoritative place where technical alignment, review feedback, and approvals are recorded. Gaining approval on the RFC gives you and the project confidence before investing time writing production code.
* **Meetings are for feedback, not decisions**: Discussion venues (chat, design forums, etc) are consultative spaces meant to gather broad feedback, discuss difficult trade-offs, and surface architectural blindspots. Binding decisions and approvals are finalized asynchronously on the GitHub RFC pull request.
* **Disentangling design from code review**: Agreeing on architecture and subsystem boundaries upfront frees subsequent code reviews in `flutter/flutter` and other repositories to focus strictly on implementation correctness, code quality, test coverage, and performance.

---

## How to Propose an RFC

The full specifications for RFC categories, formatting, and review stages are maintained in the `flutter/rfc` repository. A typical proposal follows these steps:

1. **Review Taxonomy & Guidelines**: Consult [RFC 000.0001](https://github.com/flutter/rfc/blob/main/rfc/000.0001-flutter-architecture-and-reference-taxonomy.md) to choose the primary 3-digit category for the subsystem being changed (e.g., `110` for Foundation, `130` for Widgets, `210` for Graphics) and follow the YAML frontmatter schema.
2. **Open a Draft PR**: Submit your draft as `rfc/AAA.0000-title.md` against [`flutter/rfc`](https://github.com/flutter/rfc).
3. **Open a Tracking Issue**: File a tracking issue in `flutter/flutter` using the [design doc issue template](https://github.com/flutter/flutter/issues/new?template=07_design_doc.yml) and apply the [`design doc`][] label so the community and triage bots can discover it.
4. **Iterate with Reviewers**: A Subsystem Tech Lead (TL) serves as the Shepherd for your RFC to guide review momentum, tag relevant domain leads, and help answer questions.
5. **Approval & Merging**: Once the necessary approvals are recorded on GitHub (and any optional Final Comment Period concludes), your RFC receives a permanent sequential number (`AAA.NNNN`) before it merges. Subsequent code implementation PRs link back to this merged RFC.

For complete details on roles, shepherding, and review stages, see [RFC 000.0002](https://github.com/flutter/rfc/blob/main/rfc/000.0002-flutter-rfc-review-process.md).

---

## Documenting Implementation in Source Code

When you implement an approved design, document it in detail directly in the codebase.

The API documentation is where architecture permanently lives for developers and future maintainers. It is normal and expected for API docs to be comprehensive, complete with diagrams and subheadings (e.g., see the docs for [`RenderBox`](https://master-api.flutter.dev/flutter/rendering/RenderBox-class.html)).

Do not assume someone will read your RFC after the discussion has concluded and the code has landed. Long after an RFC or PR is merged, the in-tree code comments and API docs remain the primary source of truth.

---

## Tips for Getting Helpful Feedback

Writing a design document can feel daunting, especially if it is your first time. Here are practical tips to help you get constructive and supportive feedback:

* **Start from first principles**: Clearly distinguish the problem you are solving from your proposed solution. Show example code, user scenarios, or error traces that illustrate the problem before diving into the solution.
* **Keep it focused**: If a proposal touches multiple systems, break it into smaller components that can be evaluated independently before combining them into a larger design.
* **Ask specific questions**: If there is a particular trade-off, API ergonomics choice, or edge case you are unsure about, call it out explicitly to invite targeted input.
* **Use diagrams**: Diagrams clarify architecture quickly. Because RFCs are Markdown files, you can embed native **[Mermaid](https://mermaid.js.org/)** diagrams (` ```mermaid `) directly in your document, or include SVG/PNG images.
* **Reach out**: Share your RFC tracking issue or PR on Discord (see [Chat](Chat.md)), in channels like `#hackers`, `#hackers-framework`, or `#hackers-engine`. Maintainers and community members are glad to help!

---

## Historical Design Documents & Google Docs

Historically, Flutter design documents were authored in Google Docs using `flutter.dev/go/template`. While existing Google Docs remain valuable historical records:

* **All new design proposals follow the [Flutter RFC process](https://github.com/flutter/rfc).** There are no one-off drafts in Google Docs.
* Contributors use standard GitHub accounts—no special Google Workspace accounts or drive sharing permissions are required.

### Archive Links

1. [`design doc`][] GitHub issue label: list of all design documents and RFC tracking issues.
2. [Archive of design documents][] from before the [`design doc`][] GitHub issue label was introduced.

[`design doc`]: https://github.com/flutter/flutter/issues?q=is%3Aopen+is%3Aissue+label%3A%22design+doc%22
[Archive of design documents]: https://github.com/flutter/flutter/issues/151486
