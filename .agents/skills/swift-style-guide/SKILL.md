---
name: swift-style-guide
description: Guidelines for enforcing and adhering to Google's Swift Style Guide when writing or reviewing Swift code.
---

# Google Swift Style Guide Rules & Enforcement

This document outlines the strict guidelines and best practices for writing, reviewing, and formatting Swift code in this repository. All Swift code must strictly adhere to the [Google Swift Style Guide](https://google.github.io/swift/).

---

## 🛡️ Core Directives & Verification

To ensure style consistency and prevent personal preferences or external conventions from leaking into the codebase, you must follow these rules:

1. **Mandatory Quote Verification**: Never flag a style violation or suggest a style change unless you can point to the exact section and provide a verbatim quote from the [Google Swift Style Guide](https://google.github.io/swift/).
2. **No External Style Contamination**: Do not carry over conventions from other popular style guides (e.g., Apple's API Design Guidelines or the Ray Wenderlich/Kodeco Swift Style Guide). If a rule is not explicitly documented in the Google Swift Style Guide, it is **not** a violation.
   * *Example*: The Google Swift Style Guide is silent on the use of the `self.` prefix outside of initializers (where it is required to disambiguate properties from parameter names). Therefore, using an explicit `self.` (e.g., `self.myMethod()`) is **not** a violation.

---

## 🏷️ Non-Formatting Issues

Pay extra attention to non-formatting issues, such as variable or file naming conventions, which are not detectable by the `swift-format` tool. For example, extension files should be named `<TypeName>+<ExtensionName>.swift` instead of `<TypeName>Extension.swift`.

---

## 🛠️ Known Issues in `swift-format`

Even if a developer runs `swift-format` on the code, there can still be formatting issues that violate Google's Swift Style Guide. You need to manually check and fix these issues.

### Line Wrapping
Google's style guide requires that comma-separated items be laid out in **only one direction**: entirely horizontally (on a single line) or entirely vertically (one element per line). **Mixed layouts are strictly forbidden.**

#### Good Example 1: Horizontal Layout
```swift
// 👍 Good: Horizontally laid out on one line
func myMethod(param1: Int, param2: Int)
```

#### Good Example 2: Vertical Layout
```swift
// 👍 Good: Vertically laid out, one per line
func myMethod(
  param1: Int,
  param2: Int,
  param3: Int,
  param4: Int,
  param5: Int,
  param6: Int
)
```

#### Bad Example: Mixed Layout (Style Violation)
```swift
// 👎 Bad: Mixed layout (violates the Line-Wrapping rule)
func myMethod(
  param1: Int, param2: Int, param3: Int,
  param4: Int, param5: Int, param6: Int
)
```

The last example violates the Google Swift Style Guide under the **Line-Wrapping** section:
* **Scenario #4**: *"The breakable comma-delimited list of formal arguments."*
* **Rule #2**: *"Comma-delimited lists are only laid out in one direction: horizontally or vertically. In other words, all elements must fit on the same line, or each element must be on its own line."*
