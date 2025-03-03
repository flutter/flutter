// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import { createWasmInstantiator } from "./instantiate_wasm.js";
import { resolveUrlWithSegments } from "./utils.js";

export const loadSkwasm = async (deps, config, browserEnvironment, baseUrl) => {
  const fileStem = (browserEnvironment.crossOriginIsolated && !config.forceSingleThreadedSkwasm) ? "skwasm" : "skwasm_st";
  const rawSkwasmUrl = resolveUrlWithSegments(baseUrl, `${fileStem}.js`)
  let skwasmUrl = rawSkwasmUrl;
  console.log(`skwasmUrl: ${skwasmUrl}`);
  if (deps.flutterTT.policy) {
    skwasmUrl = deps.flutterTT.policy.createScriptURL(skwasmUrl);
  }
  const wasmInstantiator = createWasmInstantiator(resolveUrlWithSegments(baseUrl, `${fileStem}.wasm`));
  const skwasm = await import(skwasmUrl);
  return await skwasm.default({
    skwasmSingleThreaded: !(browserEnvironment.crossOriginIsolated && !config.forceSingleThreadedSkwasm),
    instantiateWasm: wasmInstantiator,
    locateFile: (filename, scriptDirectory) => {
      // When hosted via a CDN or some other url that is not the same
      // origin as the main script of the page, we will fail to create
      // a web worker with the .worker.js script. This workaround will
      // make sure that the worker JS can be loaded regardless of where
      // it is hosted.
      if (filename.endsWith('.ww.js')) {
        const url = resolveUrlWithSegments(baseUrl, filename);
        return URL.createObjectURL(new Blob(
          [`
"use strict";

let eventListener;
eventListener = (message) => {
    const pendingMessages = [];
    const d = message.data;
    d["instantiateWasm"] = (info,receiveInstance) => {
        var instance=new WebAssembly.Instance(d["wasm"],info);
        return receiveInstance(instance,d["wasm"])
    };
    import(d.js).then(async (skwasm)=>{
        await skwasm.default(d);

        console.log("removing queueing listener");
        removeEventListener("message", eventListener);
        for (const message of pendingMessages) {
            console.log("flushing message");
            dispatchEvent(message);
        }
    });
    console.log("removing initial listener");
    removeEventListener("message", eventListener);
    eventListener = (message) => {
        console.log("queueing message: "+ JSON.stringify(message));
        pendingMessages.push(message);
    };
    console.log("adding queuing listener");
    addEventListener("message", eventListener);
};
console.log("adding initial listener");
addEventListener("message", eventListener);
`
          ],
          { 'type': 'application/javascript' }));
      }
      return url;
    },
    // Because of the above workaround, the worker is just a blob and
    // can't locate the main script using a relative path to itself,
    // so we pass the main script location in.
    mainScriptUrlOrBlob: rawSkwasmUrl,

    // // When hosted via a CDN or some other url that is not the same
    // // origin as the main script of the page, we will fail to create
    // // a web worker with the bootstrapping script. This workaround will
    // // make sure that the worker JS can be loaded regardless of where
    // // it is hosted.
    // mainScriptUrlOrBlob: new Blob(
    //   [`import '${skwasmUrl}'`],
    //   { 'type': 'application/javascript' },
    // ),
  });
}
