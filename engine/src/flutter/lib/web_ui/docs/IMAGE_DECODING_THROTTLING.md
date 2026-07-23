# Image Decoding Throttling in Flutter Web

## Section Zero: Business Problem Description

The primary goal of this feature is to eliminate silent application crashes and rendering failures in Flutter Web applications that handle high volumes of image assets, specifically on browsers that rely on the `HTMLImageElement.decode()` API for image processing.

Modern browsers that support the high-performance `ImageDecoder` (WebCodecs) API, such as Chrome, are generally robust when handling concurrent image decodes. However, for browsers where this API is unavailable—most notably **iOS Safari**—or in scenarios where the engine must fall back to using the standard HTML `<img>` element for decoding, the system is highly susceptible to resource exhaustion.

When a Flutter Web app attempts to decode many large images simultaneously using this fallback path, it can overwhelm the browser's internal image subsystem. This manifests in two critical ways:
1.  **Silent Crashes (iOS Safari):** The most severe failure mode, where the entire web page crashes or reloads without any logged errors, providing a poor user experience.
2.  **Encoding Errors:** On other browsers, forcing many simultaneous decodes through the `HTMLImageElement` path can trigger "EncodingErrors," causing assets to fail to render entirely.

Currently, the Flutter Web engine issues these decoding requests as fast as the framework demands them. By introducing a "traffic controller" specifically for the `HTMLImageElement` decoding path, we aim to:

*   **Ensure Application Stability:** Prevent fatal browser crashes on mobile devices by smoothing out the resource demand and staying within the browser's concurrent processing limits.
*   **Improve Rendering Reliability:** Ensure that every image intended for display is successfully processed, rather than failing due to browser-level synchronization or memory limits.
*   **Optimize Memory Lifecycle:** Implement aggressive signaling to the browser to release heavy bitmap memory as soon as it is no longer needed, reducing the cumulative memory pressure that leads to these crashes.

## Section One: Technical Implementation Plan

The technical implementation introduces a centralized resource coordinator to manage the concurrency and memory impact of the `HTMLImageElement.decode()` execution path. By moving from an "eager" decoding model to a "throttled" model, we can prevent the browser's background decoding threads from exceeding system resource limits.

### Core Components

1.  **The `ImageDecodingManager` (Resource Coordinator):**
    A centralized singleton responsible for tracking active decoding operations. It manages a FIFO (First-In-First-Out) queue and enforces two primary safety constraints:
    *   **Concurrency Limit:** A maximum of 8 simultaneous `decode()` operations.
    *   **Memory Footprint Limit:** A maximum cumulative estimated footprint (128MB) for all in-flight decodes.
    *   **The "Greedy First" Rule:** To prevent deadlocks when an image exceeds the total budget (e.g., a single 200MB asset), the manager always allows the first item in the queue to proceed if no other decodes are active.
    *   **`cancel(Request request)`:** The manager provides an explicit `cancel` method. If an image is disposed of while waiting in the queue, this method is used to remove the request and reclaim the potential slot immediately.
    *   **Defensive Timeout:** To prevent a "hung" browser decode from permanently leaking a resource slot, a defensive timeout (e.g., 30 seconds) will be implemented. If `img.decode()` does not resolve within this window, the slot will be forcibly released to prevent a system-wide deadlock.

2.  **Refactored Codec Lifecycle:**
    The `HtmlImageElementCodec` will be updated to split the image preparation into two distinct asynchronous phases:
    *   **Phase 1 (Sizing):** The image `src` is set, and we wait for the browser's `onload` or `onerror` event. If `onerror` fires, the process terminates with an error before requesting a slot from the manager. If `onload` fires, we obtain the `naturalWidth` and `naturalHeight` required to estimate the memory footprint (`width * height * 4`).
    *   **Phase 2 (Throttled Decode):** The codec requests a slot from the `ImageDecodingManager`. Once granted, it executes the high-latency `img.decode()` call. A `finally` block ensures that the manager is notified to release the resource slot regardless of the outcome.
    *   **Disposal during Queueing:** If `dispose()` is called while the codec is waiting in Phase 2, the codec must call `ImageDecodingManager.instance.cancel(request)` to remove itself from the queue and abort the process. This prevents wasting budget and avoid late-failure errors.

3.  **Aggressive Resource Reclamation:**
    To mitigate "sticky" memory in iOS Safari, we will update the `ImageSource` disposal logic. Instead of relying solely on garbage collection, we will explicitly clear the `src` attribute and revoke object URLs immediately upon disposal. This signals the browser to purge the associated bitmap from its internal cache.

### System Interaction Flow

When the Flutter framework requests an image via `instantiateImageCodec`, the system follows this coordinated path:

1.  **Preparation:** The codec initializes the `HTMLImageElement` and waits for the metadata to load (`onload`).
2.  **Accounting:** The codec calculates the estimated RGBA footprint and enters the `ImageDecodingManager` queue.
3.  **Throttling:** The manager pauses the execution of the codec's `decode()` call until the active concurrency and memory usage fall within safe thresholds.
4.  **Execution:** The browser performs the background CPU/GPU work to decompress the image data.
5.  **Resolution:** The manager releases the reserved capacity, and the framework receives a `ui.Image` ready for rendering.
6.  **Disposal:** When the framework disposes of the image, the engine explicitly unlinks the resource to reclaim memory.

### Ecosystem Integration

This change is internal to the Flutter Web engine's implementation of `dart:ui`. It specifically hardens the `HTMLImageElement` fallback path used by browsers like Safari without affecting the high-performance `ImageDecoder` (WebCodecs) path used by Chrome.

## Section Two: Alternatives Considered

### 1. Eliminating the `decode()` Call Entirely
We considered removing the call to `HTMLImageElement.decode()` and simply waiting for the `onload` event.
*   **Why it was ruled out:** Removing `decode()` forces the browser to perform image decompression synchronously on the main thread during the next frame paint. This would introduce significant "jank" (dropped frames). Furthermore, it would remove our mechanism for controlling concurrency, potentially leading to the same crashes when multiple images are drawn for the first time in a single frame.

### 2. Throttling Based on Encoded File Size
We initially discussed using the size of the encoded image bytes as the primary metric.
*   **Why it was ruled out:** Encoded size is an unreliable proxy for actual memory pressure. A highly compressed 1MB JPEG could expand into a massive 40MB bitmap. Additionally, we cannot easily determine the file size of a URL-based image without an extra network request. Using a dimension-based estimate (`width * height * 4`) provides a more accurate and consistent measure.

### 3. Automatic Dimension Sniffing via Header Parsing
We explored the idea of "sniffing" image file headers to determine dimensions before starting the loading process.
*   **Why it was ruled out:** Image formats have complex bytecode standards. Writing a robust, cross-format header parser adds significant complexity. Waiting for the browser’s native `onload` event is a much more reliable way to obtain accurate dimensions.

### 4. Implementing a "Retry-on-Error" Strategy
Since Chrome returns a catchable `EncodingError` when it is overwhelmed, we considered simply catching that error and retrying.
*   **Why it was ruled out:** This approach does not work for **iOS Safari**, which simply crashes the entire process without throwing a catchable error. A proactive throttling strategy is required.

## Section Three: Detailed Implementation Plan

### 1. Core Logic & Coordination

**File:** `lib/src/engine/image_decoding_manager.dart` (New File)
*   **Rationale:** Central coordinator for image decoding resources.
*   **Implementation:** Singleton `ImageDecodingManager` tracking `activeDecodesCount` and `activeDecodesBytes` with a FIFO queue and "Greedy First" logic.

**File:** `lib/src/engine.dart`
*   **Rationale:** Export the new manager.

### 2. Refactoring the HTML Decoding Path

**File:** `lib/src/engine/html_image_element_codec.dart`
*   **Rationale:** Update base class for `<img>` based decoding to support the throttled two-phase process.
*   **Implementation:** Refactor `decode()` to wait for `onload`, then wait for a manager slot, then call `img.decode()`. Update `dispose()` to clear `src`.

### 3. Backend-Specific Codec Updates

**File:** `lib/src/engine/canvaskit/image.dart`
*   **Rationale:** Update CanvasKit image sources for aggressive reclamation.
*   **Implementation:** Update `_doClose()` in `ImageElementImageSource` and `ImageBitmapImageSource` to explicitly release browser resources.

**File:** `lib/src/engine/skwasm/skwasm_impl/codecs.dart`
*   **Rationale:** Ensure Skwasm-specific codecs benefit from the new logic.

### 4. Verification & Testing

**File:** `test/engine/image_decoding_manager_test.dart` (New File)
*   **Rationale:** Unit test the manager's throttling and queueing logic.

**File:** `test/ui/image/html_image_element_codec_test.dart` (Existing File)
*   **Rationale:** Verify that the codec respects concurrency limits and correctly clears resources on disposal.

**File:** `test/canvaskit/image_test.dart` (Existing File)
*   **Rationale:** Regression testing for the CanvasKit pipeline.
