// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import { createWasmInstantiator } from "./instantiate_wasm.js";
import { resolveUrlWithSegments } from "./utils.js";

export const loadSkwasm = async (deps, config, browserEnvironment, baseUrl) => {
  const rawSkwasmUrl = resolveUrlWithSegments(baseUrl, "skwasm.js")
  let skwasmUrl = rawSkwasmUrl;
  if (deps.flutterTT.policy) {
    skwasmUrl = deps.flutterTT.policy.createScriptURL(skwasmUrl);
  }
  const wasmInstantiator = createWasmInstantiator(resolveUrlWithSegments(baseUrl, "skwasm.wasm"));
  const skwasm = await import(skwasmUrl);
  return await skwasm.default({
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
    },
    // Because of the above workaround, the worker is just a blob and
    // can't locate the main script using a relative path to itself,
    // so we pass the main script location in.
    mainScriptUrlOrBlob: rawSkwasmUrl,
  });
}
