// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import { createWasmInstantiator } from "./instantiate_wasm.js";

export const loadSkwasm = (deps, config, browserEnvironment, engineRevision) => {
  return new Promise((resolve, reject) => {
    const baseUrl = config.canvasKitBaseUrl ?? `https://www.gstatic.com/flutter-canvaskit/${engineRevision}/`;
    let skwasmUrl = `${baseUrl}skwasm.js`;
    if (deps.flutterTT.policy) {
      skwasmUrl = deps.flutterTT.policy.createScriptURL(skwasmUrl);
    }
    const wasmInstantiator = createWasmInstantiator(`${baseUrl}skwasm.wasm`);
    const script = document.createElement("script");
    script.src = skwasmUrl;
    if (config.nonce) {
      script.nonce = config.nonce;
    }
    script.addEventListener('load', async () => {
      try {
        const skwasmInstance = await skwasm({
          instantiateWasm: wasmInstantiator,
          locateFile: (fileName, scriptDirectory) => {
            // When hosted via a CDN or some other url that is not the same
            // origin as the main script of the page, we will fail to create
            // a web worker with the .worker.js script. This workaround will
            // make sure that the worker JS can be loaded regardless of where
            // it is hosted.
            const url = scriptDirectory + fileName;
            if (url.endsWith('.worker.js')) {
              return URL.createObjectURL(new Blob(
                [`importScripts('${url}');`],
                { 'type': 'application/javascript' }));
            }
            return url;
          }
        });
        resolve(skwasmInstance);
      } catch (e) {
        reject(e);
      }
    });
    script.addEventListener('error', reject);
    document.head.appendChild(script);
  });
}
