---
name: multiview-frame-state-auditor
description: >
  Audits platform view and layer compositing logic for multi-view concurrency safety per RFC 410.0000.
  Enforces the invariant that frame state (FlutterLayer slices, mutators, and bounds) must be keyed by
  FlutterViewId and captured by value in present_view_callback closures before dispatching to the platform thread.

  When to use:
  - When reviewing AndroidPlatformViewsController or compositor callbacks.
  - When supporting multi-window, presentation displays, or Add-to-App dual-view rendering.
  - To prevent cross-thread data races between consecutive frame presentations.
---

# Multi-View Frame State Auditor Skill

Per **RFC 410.0000**, in a multi-view or multi-window Android environment (foldable dual-screen, `android.app.Presentation` external displays, or Add-to-App), multiple views render concurrently:

> "The raster thread renders View A (`view_id = 0`) and immediately begins rasterizing View B (`view_id = 1`) while the platform thread is still applying View A's platform view layout mutations."

## The Hazard: Mutable Shared State Race

Storing per-frame composition state (such as `composition_order_`, `picture_bounds_`, or `views_to_recomposite_`) as mutable member fields on a shared controller causes cross-thread data races: View B's rasterization overwrites View A's layout metadata before the platform thread finishes applying View A's `SurfaceControl` transaction.

## The Mandatory Invariant: Value-Captured Frame State

`AndroidPlatformViewsController` must eliminate shared mutable fields by:
1. Keying active native window handles (`ANativeWindow*`) and layer trees strictly by `FlutterViewId`.
2. Capturing each view's ordered `FlutterLayer` slice and `FlutterPlatformViewMutation` parameters **by value** inside the `present_view_callback` closure before dispatching to the platform thread.

```cpp
// Correct: Frame state captured by value in the dispatch closure
void AndroidPlatformViewsController::OnPresentView(
    FlutterViewId view_id,
    const FlutterLayer** layers,
    size_t layers_count) {
  // Deep-copy layer slice and mutation structs by value
  std::vector<CapturedLayer> captured_layers =
      CaptureLayersByValue(layers, layers_count);

  platform_task_runner_->PostTask(
      [this, view_id, layers = std::move(captured_layers)] () {
        ApplyViewMutations(view_id, layers);
      });
}
```

## Audit Checklist

- [ ] Ensure `AndroidPlatformViewsController` does not hold transient per-frame arrays as class member variables.
- [ ] Confirm that `present_view_callback` copies the `FlutterLayer` array and mutations by value before returning from the callback.
- [ ] Verify that native window contexts and surface trees are partitioned in `std::unordered_map<FlutterViewId, ...>`.
