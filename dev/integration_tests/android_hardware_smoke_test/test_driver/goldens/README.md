# Reference Golden Images Directory

This directory serves as the storage location for reference golden images used by this integration test suite.

## Golden Management Model: Local vs. CI

1. **Local Runs & Standalone OEM mode**:
   * Baseline reference images are stored locally in this directory.
   * You can capture or update these local baseline images on your host PC by running the **Host-Driven Driver Mode** with the `UPDATE_GOLDENS=1` environment variable active:
     ```sh
     UPDATE_GOLDENS=1 flutter drive -v \
       --driver=test_driver/driver_test.dart \
       --target=integration_test/integration_test_wrapper.dart
     ```
   * These reference PNGs are compiled as read-only assets within the instrumented test APK during standalone on-device executions.

2. **CI Runs (Skia Gold)**:
   * **Do not commit your generated reference PNG images to the repository.**
   * In the CI pipeline, all host-side visual comparisons are routed automatically to the central **Skia Gold backend** for state-of-the-art pixel comparisons, triage handling, and approval workflows.

---

*Note: This `README.md` file exists to ensure Git preserves this directory, preventing Flutter asset packaging warnings during CI presubmit checks.*
