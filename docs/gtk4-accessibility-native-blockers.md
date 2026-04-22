# GTK4 Native Accessibility Blockers

## Purpose

This document explains why the Flutter Linux GTK4 embedder cannot yet switch
from the current synthetic accessibility export to a real native GTK4
`GtkAccessible` tree in this repo, even though the long-term direction is clear.

The short version is:

- the current engine baseline builds against an older GTK4 sysroot
- that sysroot exposes only the older `GtkAccessible` declaration
- it does not expose the newer tree-oriented GTK4 accessibility interface used
  to model custom accessible objects directly
- because of that, a true native `GtkAccessible` implementation cannot be
  compiled here yet without changing the build split or the sysroot

## Current State

Today the repo is in a valid intermediate state:

- GTK4 accessibility semantics are retained in `FlAccessibilityBridgeGtk4`
- bridge-managed GTK4 nodes exist as `FlAccessibleNodeGtk4`
- bridge nodes now track `GdkDisplay` and expose a root-node lookup entry point
- the runtime still uses the synthetic widget-backed accessibility export path
- the current state builds and runs

This is intentional. It preserves forward progress without landing code that
cannot compile against the engine's baseline GTK4 headers.

## The Concrete Constraint

The engine builds against the GTK4 sysroot at:

`engine/src/build/linux/debian_bullseye_amd64-sysroot/usr/include/gtk-4.0/gtk`

In that sysroot:

- `gtkaccessible.h` declares `GtkAccessible`
- but it does not define the newer tree traversal interface members
- it does not provide the newer parent/child/sibling accessors needed for a
  custom native accessibility tree
- it does not provide the newer platform-state enum used by that interface

Practically, this means code like the following cannot be compiled in this
baseline:

- implementing `GtkAccessibleInterface` virtuals for parent/child traversal
- using `GtkAccessiblePlatformState`
- calling `gtk_accessible_set_accessible_parent`
- building a full non-widget custom accessible tree directly in the embedder

## Why GTK3 Did Not Hit This Problem

GTK3 uses the older ATK model, and Flutter's Linux embedder already has a
custom accessibility path there.

GTK4 moved to its newer accessibility stack. The desired GTK4-native solution
is real, but it depends on API surface that is not available in the current
engine sysroot. So this is not a design dead end. It is a baseline/header
availability problem.

## What This Means For The Architecture

There are now three distinct layers to think about:

1. Semantics state.
   Flutter semantics updates are stored in a GTK4 bridge-local model.

2. Current export path.
   Accessibility is still exposed through synthetic widget-backed GTK4 nodes.

3. Future native path.
   The bridge/node model is being prepared so it can later back a real GTK4
   native accessible tree once the required API surface is available.

That separation is important. It lets us keep improving semantics ownership and
bridge structure now, while deferring the actual native GTK4 tree swap until
the build baseline can support it.

## What Was Landed To Prepare For The Native Path

The current bridge plumbing work is still useful even though the final native
tree is blocked:

- `FlAccessibleNodeGtk4` is a dedicated GTK4-side node model
- `FlAccessibilityBridgeGtk4` owns those nodes by semantics id
- nodes can now inherit the relevant `GdkDisplay`
- the bridge can return the root node directly

These are not throwaway changes. They reduce the eventual migration from:

- `FlView` owns synthetic proxy widgets and ad hoc tree shaping

to:

- `FlView` consumes a bridge-owned native GTK4 accessibility root

## Viable Options To Unblock Native GTK4 Accessibility

### Option 1: Keep the current synthetic export for now

This is the least risky short-term option.

Use it when:

- the goal is to keep GTK4 accessibility functional now
- the engine must continue building against the current sysroot
- we want more incremental cleanup before touching the build baseline

### Option 2: Add a build split for newer GTK4 accessibility APIs

This is likely the cleanest technical bridge if we want to begin landing native
GTK4 accessibility code before globally raising the sysroot baseline.

That would mean:

- detect whether the build environment exposes the newer GTK4 accessibility API
- compile native-tree code only when that API is available
- keep the synthetic path as the fallback for the current baseline

This is more complex than a plain code change because it introduces an API
surface split inside the Linux embedder.

### Option 3: Move the engine baseline to a newer GTK4 sysroot

This is the most direct path to a real native GTK4 tree.

That would allow:

- implementing custom `GtkAccessible` nodes in the embedder
- exposing true parent/child/sibling traversal
- removing the synthetic proxy approach entirely

But this is also the broadest change because it affects the engine build
baseline and potentially other Linux GTK4 assumptions.

## Recommended Near-Term Plan

1. Keep the current synthetic GTK4 export path as the shipping path.
2. Continue improving the bridge-owned GTK4 node model and semantics ownership.
3. Document exactly which GTK4 API boundary is missing in the sysroot.
4. Decide explicitly between:
   - a temporary build split, or
   - a sysroot/baseline upgrade
5. Only then switch `FlView` from synthetic export to a real native GTK4
   accessible root.

## Risks If We Ignore This Constraint

If we pretend the newer GTK4 tree API is always available, we will land code
that:

- compiles on some developer machines
- fails in the engine build environment
- creates a confusing split between local experimentation and real CI results

That is worse than keeping the synthetic path a little longer.

## Validation Implication

As long as the synthetic path remains the runtime path, validation should keep
focusing on:

- correct AT-SPI export
- no layout or rendering regressions
- no extra visible proxy widgets
- no regressions in focus or interaction

The separate validation procedure lives in:

- `docs/gtk4_accessibility_validation.md`

## Summary

The blocker is not that native GTK4 accessibility is the wrong design.

The blocker is that the current engine sysroot does not expose the newer GTK4
accessibility tree interface needed to compile that design here today.

The right response is not to abandon the native direction. The right response
is to keep shaping the bridge and node model now, while making an explicit
decision about either:

- adding a build split for newer GTK4 accessibility APIs, or
- upgrading the engine's GTK4 sysroot baseline.
