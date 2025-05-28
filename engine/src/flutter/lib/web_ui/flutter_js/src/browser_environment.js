// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/** @type {import("./types").WasmAllowList} */
export const defaultWasmSupport = {
  "blink": true,
  "gecko": false,
  "webkit": false,
  "unknown": false,
}

/**
 * @returns {import("./types").BrowserEngine}
 */
const getBrowserEngine = () => {
  if ((navigator.vendor === 'Google Inc.') ||
    (navigator.userAgent.includes('Edg/'))) {
    return "blink";
  }
  if (navigator.vendor === "Apple Computer, Inc.") {
    return "webkit";
  }
  if (navigator.vendor === "" && navigator.userAgent.includes('Firefox')) {
    return "gecko";
  }
  return "unknown";
}

/** @type {import("./types").BrowserEnvironment} */
const browserEngine = getBrowserEngine();

const hasImageCodecs = () => {
  if (typeof ImageDecoder === "undefined") {
    return false;
  }
  // TODO(yjbanov): https://github.com/flutter/flutter/issues/122761
  // Frequently, when a browser launches an API that other browsers already
  // support, there are subtle incompatibilities that may cause apps to crash if,
  // we blindly adopt the new implementation. This check prevents us from picking
  // up potentially incompatible implementations of ImagdeDecoder API. Instead,
  // when a new browser engine launches the API, we'll evaluate it and enable it
  // explicitly.
  return browserEngine === "blink";
}

const hasChromiumBreakIterators = () => {
  return (typeof Intl.v8BreakIterator !== "undefined") &&
    (typeof Intl.Segmenter !== "undefined");
}

const supportsWasmGC = () => {
  // This attempts to instantiate a wasm module that only will validate if the
  // final WasmGC spec is implemented in the browser.
  //
  // Copied from https://github.com/GoogleChromeLabs/wasm-feature-detect/blob/main/src/detectors/gc/index.js
  const bytes = [0, 97, 115, 109, 1, 0, 0, 0, 1, 5, 1, 95, 1, 120, 0];
  return WebAssembly.validate(new Uint8Array(bytes));
}

/** @type {import("./types").BrowserEnvironment} */
export const browserEnvironment = {
  browserEngine: browserEngine,
  hasImageCodecs: hasImageCodecs(),
  hasChromiumBreakIterators: hasChromiumBreakIterators(),
  supportsWasmGC: supportsWasmGC(),
  crossOriginIsolated: window.crossOriginIsolated,
};
