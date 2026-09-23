// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/**
 * Creates a WASM instantiator that uses Cross-Origin Storage (COS) if available.
 *
 * @param {string} url The URL to fetch the WASM module from.
 * @param {string} filename The filename for COS lookup (e.g., "canvaskit.wasm").
 * @returns {Function} A function that takes imports and a success callback.
 */
export const createWasmInstantiator = (url, filename) => {
  const wasmHashes = window._flutter?.buildConfig?.wasmHashes;
  let hash = wasmHashes?.[filename];
  if (!hash && filename.includes('/')) {
    const basename = filename.split('/').pop();
    hash = wasmHashes?.[basename];
  }

  const supportsCrossOriginStorage = 'crossOriginStorage' in navigator && 'requestFileHandle' in navigator.crossOriginStorage;
  if (supportsCrossOriginStorage) {
    console.log('Cross-Origin Storage is supported. See https://wicg.github.io/cross-origin-storage/ for more details.');
  }

  // Cross-Origin Storage verifies the bytes against the hash before it hands
  // them back, so the stored MIME type is never consulted and a fixed
  // `Content-Type` is safe here.
  const wasmResponseInit = { headers: { 'Content-Type': 'application/wasm' } };

  /**
   * Tries to get the WASM module from Cross-Origin Storage.
   * (Only used when Cross-Origin Storage is supported.)
   *
   * @returns {Promise<Response|undefined>} The response from Cross-Origin Storage if available, undefined otherwise.
   */
  const tryGettingResponseFromCrossOriginStorage = async () => {
    const cosHash = { algorithm: 'SHA-256', value: hash };
    try {
      const handle = await navigator.crossOriginStorage.requestFileHandle(cosHash);
      const file = await handle.getFile();
      // Stream the stored bytes so that compilation overlaps reading them,
      // the same way it overlaps the download on a cache miss.
      return new Response(file.stream(), wasmResponseInit);
    } catch (err) {
      if (err.name === 'NotAllowedError') {
        console.warn(`Not allowed to retrieve ${filename} (hash: ${hash}).`);
      } else if (err.name !== 'NotFoundError') {
        console.warn(`Unexpected error during retrieval of ${filename} (hash: ${hash}).`, err);
      }
    }
  }

  /**
   * Stores one branch of the network response in Cross-Origin Storage while
   * the other branch is being compiled. Never awaited, so a slow or denied
   * write cannot hold up startup.
   * (Only used when Cross-Origin Storage is supported.)
   *
   * @param {ReadableStream} stream The branch of the response body to store.
   */
  const storeResponseInCrossOriginStorage = (stream) => {
    const cosHash = { algorithm: 'SHA-256', value: hash };
    (async () => {
      try {
        const handle = await navigator.crossOriginStorage.requestFileHandle(cosHash, {
          create: true,
          // CanvasKit and Skwasm are the same bytes for every app built
          // against a given engine revision, so any origin may read them
          // back once they have been stored.
          origins: '*',
        });
        const writableStream = await handle.createWritable();
        // `pipeTo()` closes the writable stream once the body is exhausted,
        // which is when the hash is verified, so there is no `write()` or
        // `close()` call to make here.
        await stream.pipeTo(writableStream);
      } catch (err) {
        // Release the branch that will now never be read, otherwise `tee()`
        // keeps buffering the whole module for it.
        stream.cancel().catch(() => {});
        if (err.name === 'NotAllowedError') {
          console.warn(`Not allowed to store ${filename} (hash: ${hash}).`);
        } else {
          console.warn(`Unexpected error while storing ${filename} (hash: ${hash}).`, err);
        }
      }
    })();
  }

  const getResponse = async () => {
    // Try to get the response from Cross-Origin Storage.
    if (supportsCrossOriginStorage && hash) {
      const response = await tryGettingResponseFromCrossOriginStorage();
      if (response) {
        return response;
      }
    }
    // Cross-Origin Storage is not available or we failed to retrieve the file, try fetching it from the network.
    const response = await fetch(url);
    if (supportsCrossOriginStorage && hash && response.ok && response.body) {
      // Split the body in two: one branch is compiled as it arrives, the other
      // is stored. Buffering the module into a `Blob` first would throw away
      // the download/compile overlap that `compileStreaming()` exists for.
      const [compileStream, storeStream] = response.body.tee();
      storeResponseInCrossOriginStorage(storeStream);
      return new Response(compileStream, wasmResponseInit);
    }
    return response;
  };

  const modulePromise = WebAssembly.compileStreaming(getResponse());
  return (imports, successCallback) => {
    (async () => {
      const module = await modulePromise;
      const instance = await WebAssembly.instantiate(module, imports);
      successCallback(instance, module);
    })();
    return {};
  };
}
