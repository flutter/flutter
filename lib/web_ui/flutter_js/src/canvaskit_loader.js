// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import { createWasmInstantiator } from "./instantiate_wasm.js";
import { joinPathSegments } from "./utils.js";

export const loadCanvasKit = (deps, config, browserEnvironment, canvasKitBaseUrl) => {
  if (window.flutterCanvasKit) {
    // The user has set this global variable ahead of time, so we just return that.
    return Promise.resolve(window.flutterCanvasKit);
  }
  window.flutterCanvasKitLoaded = new Promise((resolve, reject) => {
    const supportsChromiumCanvasKit = browserEnvironment.hasChromiumBreakIterators && browserEnvironment.hasImageCodecs;
    if (!supportsChromiumCanvasKit && config.canvasKitVariant == "chromium") {
      throw "Chromium CanvasKit variant specifically requested, but unsupported in this browser";
    }
    const useChromiumCanvasKit = supportsChromiumCanvasKit && (config.canvasKitVariant !== "full");
    let baseUrl = canvasKitBaseUrl;
    if (useChromiumCanvasKit) {
      baseUrl = joinPathSegments(baseUrl, "chromium");
    }
    let canvasKitUrl = joinPathSegments(baseUrl, "canvaskit.js");
    if (deps.flutterTT.policy) {
      canvasKitUrl = deps.flutterTT.policy.createScriptURL(canvasKitUrl);
    }
    const wasmInstantiator = createWasmInstantiator(joinPathSegments(baseUrl, "canvaskit.wasm"));
    const script = document.createElement("script");
    script.src = canvasKitUrl;
    if (config.nonce) {
      script.nonce = config.nonce;
    }
    script.addEventListener("load", async () => {
      try {
        const canvasKit = await CanvasKitInit({
          instantiateWasm: wasmInstantiator,
        });
        window.flutterCanvasKit = canvasKit;
        resolve(canvasKit);  
      } catch (e) {
        reject(e);
      }
    });
    script.addEventListener("error", reject);
    document.head.appendChild(script);
  });
  return window.flutterCanvasKitLoaded;
}
