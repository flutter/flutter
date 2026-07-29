# FallbackFontService Design Document

## Section 0: The Problem Statement

In Flutter Web applications, text rendering depends on the fonts provided by the developer in the application's asset bundle. When a piece of text contains characters (such as CJK scripts, emojis, or rare symbols) that are not covered by any of the fonts included in the asset bundle, the engine invokes an automatic "font fallback" system. This system identifies the missing characters and attempts to download the appropriate "Noto" fonts from a CDN (typically Google Fonts) to ensure the text is legible.

Currently, this fallback system has a critical reliability flaw: **It does not gracefully handle network or server failures.**

If a required fallback font fails to download—whether due to a 404 error, a broken CDN link, or a transient network interruption—the engine enters an **infinite loop**. Because it does not track these failures effectively, it continuously attempts to download the same failing font. Each attempt notifies the application that "fonts have changed," triggering a UI relayout. This relayout rediscovers that the characters are still missing and restarts the download attempt immediately.

For the end-user and the business, this results in:
1.  **System Instability:** The infinite loop consumes excessive CPU and battery power, causing the web application to become laggy, hot, or unresponsive.
2.  **Network Abuse:** The application spams font servers with thousands of redundant requests, which can lead to rate-limiting, increased infrastructure costs, and a poor reputation for the app's network behavior.
3.  **Broken Aesthetics:** Users are left with "tofu" (empty boxes), and the engine fails to provide a "best-effort" recovery—such as attempting a secondary fallback font that might actually be reachable.
4.  **Operational Noise:** Browser consoles are flooded with identical error logs, making it nearly impossible for developers to debug other issues or maintain a production-grade application.

We need a solution that makes the font fallback system **autonomous and resilient**, ensuring it can recover from transient errors, find alternative fonts when primary ones fail, and—above all—terminate its attempts once it has exhausted all viable options.

## Section 1: The Technical Implementation Plan

To solve this problem, we are rebuilding the font fallback system as a dedicated, smart background service called the **FallbackFontService**. This service will act like a "concierge" for missing characters: instead of the rendering engine frantically trying to manage downloads on its own, it will simply hand a list of missing characters to this service and trust it to handle the rest.

The plan consists of four major components working together:

### 1. The "Request Queue" (Skia-Driven Discovery)
Currently, the engine manually checks every string of text to see if it *might* need a fallback font based on its own records. We will replace this manual check with a more direct approach: we will ask the underlying graphics engine (**Skia**) for the truth. During the "layout" phase (when the app calculates exactly where text should go), we will call a specific function to get the exact list of characters that the current fonts—including any fallback fonts already loaded—could not handle. These "unresolved" characters are added to a global "Unprocessed" list in the service. By letting Skia be the source of truth, we ensure the service only acts when a character is genuinely missing from the screen.

### 2. The Autonomous Manager (FallbackFontService)
The service manages its own state independently of the main application's UI cycle, using an event-driven "convergence" model. When new characters arrive in the "Unprocessed" list, the service:
*   **Filters out duplicates:** It ignores characters it is already trying to download or that it has already failed to find.
*   **Picks the best fonts:** It uses "greedy" logic to find the smallest number of fonts that cover the most missing characters.
*   **Consults the Fallback Data:** The service uses a mapping of characters to fonts stored in `lib/src/engine/font_fallback_data.dart`. This is a large, generated file that encodes exactly which Noto fonts provide glyphs for which Unicode ranges.
*   **Manages downloads:** It handles the actual HTTP requests, ensuring we don't overwhelm the user's connection by limiting how many fonts download at once.

### 3. The Smart Retry & Recovery System
This is the "brain" of the fix. If a font fails to download, the service doesn't just give up or loop forever. 
*   **Transient Errors:** If the network blips, it waits 1 second and tries again (up to 3 times).
*   **Permanent Failures:** If a font is simply not there (a 404 error) or fails all retries, the service marks that font as "Permanently Unavailable."
*   **Self-Healing:** The service then immediately re-evaluates the missing characters. Because it knows which fonts are broken, it will automatically look for the "next best" font to cover those characters. If no other fonts exist, it marks those characters as "Unsupported" and stops trying. This is what finally breaks the infinite loop.
*   **Global Kill Switch:** To protect against systemic misconfigurations (e.g., a broken `fontFallbackBaseUrl`), the service tracks total permanent failures. If 10 fonts fail permanently and zero have succeeded, the service declares itself "broken" and stops all future attempts for the session.
*   **Per-Component Cap:** To prevent a single character from triggering hundreds of requests (e.g., a common character covered by many fonts), the service limits the number of candidate fonts it will attempt for any single Unicode component to 5. If all 5 fail, the component is marked as unsupported.

### 4. The Feedback Loop
The service only talks back to the Flutter framework when it actually succeeds. When a font is successfully downloaded and registered, the service tells the framework: *"I have new fonts; please redraw the screen."* If a font fails and no replacement can be found, the service stays silent. The user will see a placeholder (like an empty box), but the app will remain stable and the network will go quiet.

### Ecosystem Fit
This feature sits deep within the "Web Engine" layer of Flutter. It bridges the gap between the high-level Flutter framework and the low-level browser environment. By moving this logic into a centralized service, we make the engine more efficient for all Flutter Web developers, providing a "fire and forget" system that handles the complexities of global typography and unreliable networks automatically.

## Section 2: Alternatives Considered

During the design process, we explored several other approaches but ultimately ruled them out in favor of the more robust `FallbackFontService` model.

### 1. Immediate "Best-Effort" Replacement
We considered a strategy where, if the primary font (Font A) failed even once, the service would immediately start downloading the secondary font (Font B). 
*   **Why we ruled it out:** This was deemed too aggressive and wasteful of the user's bandwidth. In many cases, a single network blip is temporary. By jumping to Font B immediately, we risked downloading multiple large fonts for the same set of characters, potentially causing "layout jitter" where text changes its appearance multiple times as different fonts arrive. We decided it was better to give the primary font a fair chance to succeed through retries before looking for a substitute.

### 2. Dependency on the Framework for Retries
One early thought was to keep the current model where the framework's "re-layout" signal drives the retry logic. In this model, we would simply stop the loop by marking a font as failed.
*   **Why we ruled it out:** This kept the engine in a "passive" state. If we failed to download any fonts in a batch and didn't notify the framework, the engine would essentially "fall asleep" and never try to find a replacement for those missing characters until some other unrelated UI change happened. We realized the engine needs to be **proactive**—it should be able to say, "Font A failed; let me immediately see if Font B can help," without needing the framework to ask it to try again.

### 3. Filtering characters before enqueuing them
We discussed filtering out characters that were already covered by "pending" downloads before they even entered the service's queue.
*   **Why we ruled it out:** This created a dangerous "memory loss" problem. If we filtered out a character because Font A was *supposed* to cover it, and then Font A failed to download, the service would have no record that the character still needed covering. By keeping all missing characters in the "Unprocessed" list until they are truly resolved or exhausted, we ensure that no requirement is ever forgotten, regardless of how many individual fonts fail.

### 4. Maintaining a manual "Shadow Cache" of fonts
We considered having the service maintain its own comprehensive list of every character covered by every font it has ever seen to avoid talking to Skia so often.
*   **Why we ruled it out:** This added unnecessary complexity and the risk of the service getting "out of sync" with the actual graphics engine. Since Skia is the ultimate authority on what it can and cannot render, it is much simpler and more accurate to ask it for the "unresolved" list directly during layout. This eliminates the need for the service to try and mirror Skia's complex internal font-matching logic.

## Section 3: Detailed Implementation Plan

This section outlines the surgical changes required to implement the `FallbackFontService` architecture. The goal is to centralize fallback logic, utilize Skia’s internal layout state, and implement a resilient retry/recovery loop.

### 1. New Core Infrastructure

*   **File: `lib/src/engine/font_fallback_service.dart` (New File)**
    *   **Rationale:** To house the `FallbackFontService` class. This centralizes the `_unprocessedCodePoints`, `_pendingFonts`, and `_permanentlyUnavailableFonts` state. It will contain the "Event-Driven Convergence" logic, the stateless greedy algorithm, and the smart fetcher.
*   **File: `lib/src/engine/noto_font.dart` (Refactor)**
    *   **Rationale:** To make the `NotoFont` data class stateless, removing any internal tracking that would interfere with the `FallbackFontService` greedy selection algorithm.
*   **File: `lib/src/engine/font_fallbacks.dart` (Major Refactor)**
    *   **Rationale:** We will refactor the existing `FontFallbackManager` and `_FallbackFontDownloadQueue` logic into the new service. The `NotoFont` and `FallbackFontComponent` classes must be made stateless (removing `coverCount` and `coverComponents`) to allow the greedy algorithm to run safely and predictably during autonomous re-evaluations.

### 2. Renderer Interface Updates

*   **File: `lib/src/engine/canvaskit/canvaskit_api.dart`**
    *   **Rationale:** Add the missing JS-Interop binding for `getUnresolvedCodepoints()` to the `SkParagraph` extension type. 
    *   **Technical Detail:** The underlying JS/WASM method on the `SkParagraph` object takes **no arguments** and returns a `JSArray<JSNumber>` representing the Unicode code points.
    *   **Usage:** This is the "source of truth" required to move away from string-based discovery.
*   **File: `lib/src/engine/skwasm/skwasm_impl/raw/text/raw_paragraph.dart`**
    *   **Rationale:** Ensure the FFI binding `paragraphGetUnresolvedCodePoints` is correctly exposed and documented for use in the unified fallback path.
*   **File: `lib/src/engine/font_fallbacks.dart` (Interface change)**
    *   **Rationale:** Update the `FallbackFontRegistry` abstract class. Change `loadFallbackFont(String name, String url)` to `Future<bool> loadFallbackFont(String name, Uint8List bytes)`. The return value indicates whether the renderer successfully registered the font. This shifts HTTP responsibility to the `FallbackFontService` and allows it to track registration failures.

### 3. Renderer Implementation Updates

*   **File: `lib/src/engine/canvaskit/fonts.dart` (`SkiaFontCollection`)**
*   **File: `lib/src/engine/skwasm/skwasm_impl/font_collection.dart` (`SkwasmFontCollection`)**
    *   **Rationale:** Both font collections now implement the unified `FlutterFontCollection` interface, which mandates the presence of a `FontFallbackManager` and a `FallbackFontRegistry`.
    *   **Architecture:** Each collection now owns its respective registry implementation (`SkiaFallbackRegistry` and `SkwasmFallbackRegistry`) and initializes a `FontFallbackManager` to bridge the gap between the `FallbackFontService` and the renderer-specific font stack.
    *   **State Management:** 
        *   `SkiaFontCollection` was updated to maintain a `registeredFallbackFonts` list, and its `_registerWithFontProvider()` method now rebuilds the Skia font provider by combining both asset fonts and dynamically loaded fallback fonts.
        *   `SkwasmFontCollection` now utilizes `setDefaultFontFamilies()` to synchronize the renderer's default font stack with the global fallback list managed by the service.
    *   **Lifecycle:** Added `debugResetFallbackFonts()` to both implementations to ensure clean state during unit and golden testing, allowing the `FallbackFontService` to be reset independently of the main font stack.

*   **File: `lib/src/engine/canvaskit/fonts.dart` (`SkiaFallbackRegistry`)**
*   **File: `lib/src/engine/skwasm/skwasm_impl/font_collection.dart` (`SkwasmFallbackRegistry`)**
    *   **Rationale:** These new registry classes implement the `FallbackFontRegistry` interface, providing the concrete logic for injecting font bytes into the respective WASM heaps and triggering the necessary font-provider updates.
    *   **Technical Detail:** 
        *   `loadFallbackFont(name, bytes)` handles the creation of a typeface from raw bytes.
        *   `updateFallbackFontFamilies(families)` triggers the renderer-specific logic to update the font-matching order (e.g., rebuilding the `TypefaceFontProvider` in Skia or updating the default text style in Skwasm).
*   **File: `lib/src/engine/canvaskit/text.dart` (`CkParagraph.layout`)**
*   **File: `lib/src/engine/skwasm/skwasm_impl/paragraph.dart` (`SkwasmParagraph.layout`)**
    *   **Rationale:** Update the `layout()` method in both renderers to call `getUnresolvedCodepoints()` from Skia. If unresolved characters are found, they will call `FallbackFontService.instance.addMissingCodePoints(list)`. This unified the discovery mechanism for both backends.
    *   **Optimization:** Added a `_hasCheckedForMissingCodePoints` flag to both paragraph implementations to ensure that we only query Skia once per paragraph life-cycle, avoiding redundant work during repeated layouts.
*   **File: `lib/src/engine/canvaskit/text.dart` (`CkParagraphBuilder.addText`)**
    *   **Rationale:** Remove the call to `ensureFontsSupportText()`. This eliminates the expensive string-based check during paragraph building, significantly improving performance for text-heavy applications.

### 4. Cleanup and Performance

*   **File: `lib/src/engine/font_change_util.dart`**
    *   **Rationale:** Verify the debouncing logic in `sendFontChangeMessage()`. We will rely on this to ensure that if multiple fonts in a batch succeed, we only trigger a single framework relayout per animation frame.
*   **File: `lib/src/engine/dom.dart`**
    *   **Rationale:** Ensure `httpFetch` is robustly exposed for the `FallbackFontService` to use for its "sophisticated" fetching (checking `response.ok` for 404s).

### 5. Testing and Validation

*   **File: `test/engine/font_fallback_service_test.dart` (New File)**
    *   **Rationale:** Create a suite of unit tests for the new service. These will mock network failures, 404s, and successful downloads to verify that the "True Missing" logic correctly falls back to alternative fonts and eventually terminates the retry loop.
*   **File: `test/ui/fallback_fonts_golden_test.dart`**
    *   **Rationale:** Update existing golden tests to use the new `waitForIdle()` definition and ensure that "Permanent Failures" correctly render as tofu without causing infinite test timeouts.
*   **File: `lib/src/engine/configuration.dart`**
    *   **Rationale:** Add a new configuration flag (e.g., `debugSkipFontRetryDelay`) to allow tests to run without waiting for the 1-second backoff timer.
