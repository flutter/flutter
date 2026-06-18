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

  /**
   * Tries to get the WASM module from Cross-Origin Storage.
   * (Only used when Cross-Origin Storage is supported.)
   *
   * @param {string} hash The hash of the WASM module.
   * @returns {Promise<Response|undefined>} The response from Cross-Origin Storage if available, undefined otherwise.
   */
  const tryGettingResponseFromCrossOriginStorage = async (hash) => {
    const cosHash = { algorithm: 'SHA-256', value: hash };
    try {
      const handle = await navigator.crossOriginStorage.requestFileHandle(cosHash);
      const fileBlob = await handle.getFile();
      return new Response(fileBlob, {
        headers: { 'Content-Type': 'application/wasm' },
      });
    } catch {
      // Any error (not found, not allowed, …) — fall through to network fetch.
    }
  }

  const getResponse = async () => {
    // Try to get the response from Cross-Origin Storage.
    if (supportsCrossOriginStorage && hash) {
      const response = await tryGettingResponseFromCrossOriginStorage(hash);
      if (response) {
        return response;
      }
    }
    // Cross-Origin Storage is not available or we failed to retrieve the file, try fetching it from the network.
    const response = await fetch(url);
    if (supportsCrossOriginStorage && hash && response.ok) {
      const cosHash = { algorithm: 'SHA-256', value: hash };
      const clonedResponse = response.clone();
      (async () => {
        try {
          const blob = await clonedResponse.blob();
          const handle = await navigator.crossOriginStorage.requestFileHandle(cosHash, { create: true });
          const writableStream = await handle.createWritable();
          await writableStream.write(blob);
          await writableStream.close();
        } catch (err) {
          console.warn(`Error storing ${filename} (hash: ${hash}):`, err);
        }
      })();
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
