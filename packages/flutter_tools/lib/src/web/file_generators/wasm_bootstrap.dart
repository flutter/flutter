// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

String generateWasmBootstrapFile() {
  return r'''
// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

(async function () {
  let dart2wasm_runtime;
  let moduleInstance;
  try {
    const dartModulePromise = WebAssembly.compileStreaming(fetch("main.dart.wasm"));
    dart2wasm_runtime = await import('./main.dart.mjs');
    moduleInstance = await dart2wasm_runtime.instantiate(dartModulePromise, {});
  } catch (exception) {
    console.error(`Failed to fetch and instantiate wasm module: ${exception}`);
  }

  if (moduleInstance) {
    try {
      await dart2wasm_runtime.invoke(moduleInstance);
    } catch (exception) {
      console.error(`Exception while invoking test: ${exception}`);
    }
  }
})();
''';
}
