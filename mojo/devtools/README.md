# Devtools packages

Unopinionated tools for **running**, **debugging** and **testing** Mojo apps
available to Mojo consumers.

Individual subdirectories are mirrored as separate repositories.

 - **common** is the main toolset supporting mostly language-independent needs
   on all Mojo platforms
 - further subdirectories TBD might contain heavy language-specific tooling

## Principles

The toolsets are intended for consumption by Mojo consumers as **separate
checkouts**. No dependencies on files outside of devtools are allowed.

The toolsets should make no assumptions about particular **build system** or
**file layout** in any checkout where it is consumed. Consumers can add thin
wrappers adding a layer of convenience on top of them.
