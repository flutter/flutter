// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import { createWasmInstantiator } from "./instantiate_wasm.js";
import { resolveUrlWithSegments } from "./utils.js";

export const loadSkwasm = async (deps, config, browserEnvironment, baseUrl) => {
  const needsHeavy = (!browserEnvironment.hasImageCodecs || !browserEnvironment.hasChromiumBreakIterators)
  const fileStem = needsHeavy
     ? 'skwasm_heavy'
     : (config.enableWimp ? 'wimp' : 'skwasm');
  const rawSkwasmUrl = resolveUrlWithSegments(baseUrl, `${fileStem}.js`)
  let skwasmUrl = rawSkwasmUrl;
  if (deps.flutterTT.policy) {
    skwasmUrl = deps.flutterTT.policy.createScriptURL(skwasmUrl);
  }
  const wasmInstantiator = createWasmInstantiator(resolveUrlWithSegments(baseUrl, `${fileStem}.wasm`));
  const skwasm = await import(skwasmUrl);
  return await skwasm.default({
    // Chrome extensions enforce strict CSP that blocks the dynamic script
    // loading required for multi-threaded workers. We force single-threaded
    // mode to prevent startup crashes.
    // See https://github.com/flutter/flutter/issues/177974.
    //
    // Also, as of right now, multi-threaded wimp is unstable and crashy.
    // See https://github.com/flutter/flutter/issues/178749 for more details.
    skwasmSingleThreaded: config.enableWimp || !browserEnvironment.crossOriginIsolated || browserEnvironment.isChromeExtension || config.forceSingleThreadedSkwasm,
    instantiateWasm: wasmInstantiator,
    locateFile: (filename, scriptDirectory) => {
      // The wasm workers API has a separate .ww.js file that bootstraps the
      // web worker. However, it turns out this worker bootstrapper doesn't
      // actually work with ES6 modules, which we have enabled. So we instead
      // pass our own bootstrapper that loads skwasm.js as an ES6 module, and
      // queues/flushes pending messages that were received during the
      // asynchronous load.
      if (filename.endsWith('.ww.js')) {
        return URL.createObjectURL(new Blob(
          [`
"use strict";

let eventListener;
eventListener = (message) => {
    const pendingMessages = [];
    const data = message.data;
    data["instantiateWasm"] = (info,receiveInstance) => {
        const instance = new WebAssembly.Instance(data["wasm"], info);
        return receiveInstance(instance, data["wasm"])
    };
    import(data.js).then(async (skwasm) => {
        await skwasm.default(data);

        removeEventListener("message", eventListener);
        for (const message of pendingMessages) {
            dispatchEvent(message);
        }
    });
    removeEventListener("message", eventListener);
    eventListener = (message) => {

        pendingMessages.push(message);
    };

    addEventListener("message", eventListener);
};
addEventListener("message", eventListener);
`
          ],
          { 'type': 'application/javascript' }));
      }
      const url = resolveUrlWithSegments(baseUrl, filename);
      return url;
    },
    // Because of the above workaround, the worker is just a blob and
    // can't locate the main script using a relative path to itself,
    // so we pass the main script location in.
    mainScriptUrlOrBlob: rawSkwasmUrl,
  });
}
