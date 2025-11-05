// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This file adds JavaScript APIs that are accessible to the C++ layer.
// See: https://emscripten.org/docs/porting/connecting_cpp_and_javascript/Interacting-with-code.html#implement-a-c-api-in-javascript

mergeInto(LibraryManager.library, {
  $skwasm_support_setup__postset: 'skwasm_support_setup();',
  $skwasm_support_setup: function() {
    if (Module["skwasmSingleThreaded"]) {
      _skwasm_isSingleThreaded = function() {
        return true;
      };

      let messageListener;
      // In single threaded mode, we simply invoke the message listener as a
      // microtask, as it's much cheaper than doing a full postMessage
      skwasm_registerMessageListener = function(threadId, listener) {
        messageListener = listener;
      }
      skwasm_getCurrentTimestamp = function() {
        return performance.now();
      };
      skwasm_postMessage = function(message, transfers, threadId) {
        // If we're in single-threaded mode, we shouldn't use postMessage, as
        // it ends up being quite expensive. Instead, just queue a microtask.
        queueMicrotask(() => messageListener(message));
      };
    } else {
      _skwasm_isSingleThreaded = function() {
        return false;
      };

      // This value represents the difference between the time origin of the main
      // thread and whichever web worker this code is running on. This is so that
      // when we report frame timings, that they are in the same time domain
      // regardless of whether they are captured on the main thread or the web
      // worker.
      let timeOriginDelta = 0;
      skwasm_registerMessageListener = function(threadId, listener) {
        const eventListener = function({data}) {
          const skwasmMessage = data.skwasmMessage;
          if (!skwasmMessage) {
            return;
          }
          if (skwasmMessage == 'syncTimeOrigin') {
            timeOriginDelta = performance.timeOrigin - data.timeOrigin;
            return;
          }
          listener(data);
        };
        if (!threadId) {
          addEventListener("message", eventListener);
        } else {
          _wasmWorkers[threadId].addEventListener("message", eventListener);
          _wasmWorkers[threadId].postMessage({
            skwasmMessage: 'syncTimeOrigin',
            timeOrigin: performance.timeOrigin,
          });
        }
      };
      skwasm_getCurrentTimestamp = function() {
        return performance.now() + timeOriginDelta;
      };
      skwasm_postMessage = function(message, transfers, threadId) {
        if (threadId) {
          _wasmWorkers[threadId].postMessage(message, { transfer: transfers } );
        } else {
          postMessage(message, { transfer: transfers });
        }
      };
    }

    const handleToContextLostHandlerMap = new Map();
    const handleToCanvasMap = new Map();
    const associatedObjectsMap = new Map();

    _skwasm_connectThread = function(threadId) {
      const eventListener = function(data) {
        const skwasmMessage = data.skwasmMessage;
        if (!skwasmMessage) {
          return;
        }
        switch (skwasmMessage) {
          case 'transferCanvas':
            _surface_receiveCanvasOnWorker(
              data.surface,
              data.canvas,
              data.callbackId,
            );
            return;
          case 'onInitialized':
            _surface_onInitialized(data.surface, data.callbackId);
            return;
          case 'resizeSurface':
            _surface_resizeOnWorker(data.surface, data.width, data.height, data.callbackId);
            return;
          case 'onResizeComplete':
            _surface_onResizeComplete(data.surface, data.callbackId);
            return;
          case 'triggerContextLoss':
            _surface_triggerContextLossOnWorker(data.surface, data.callbackId);
            return;
          case 'onContextLossTriggered':
            _surface_onContextLossTriggered(data.surface, data.callbackId);
            return;
          case 'reportContextLost':
            _surface_reportContextLost(data.surface, data.callbackId);
            return;
          case 'renderPictures':
            _surface_renderPicturesOnWorker(
              data.surface,
              data.pictures,
              data.pictureCount,
              data.callbackId,
              skwasm_getCurrentTimestamp());
            return;
          case 'onRenderComplete':
            _surface_onRenderComplete(
              data.surface,
              data.callbackId, {
                "imageBitmaps": data.imageBitmaps,
                "rasterStartMilliseconds": data.rasterStart,
                "rasterEndMilliseconds": data.rasterEnd,
              },
            );
            return;
          case 'setAssociatedObject':
            associatedObjectsMap.set(data.pointer, data.object);
            return;
          case 'disposeAssociatedObject':
            const pointer = data.pointer;
            const object = associatedObjectsMap.get(pointer);
            if (object.close) {
              object.close();
            }
            associatedObjectsMap.delete(pointer);
            return;
          case 'disposeSurface':
            _surface_dispose(data.surface);
            return;
          case 'rasterizeImage':
            _surface_rasterizeImageOnWorker(
              data.surface,
              data.image,
              data.format,
              data.callbackId,
            );
            return;
          case 'onRasterizeComplete':
            _surface_onRasterizeComplete(
              data.surface,
              data.data,
              data.callbackId,
            );
            return;
          default:
            console.warn(`unrecognized skwasm message: ${skwasmMessage}`);
        }
      };
      skwasm_registerMessageListener(threadId, eventListener);
    };

    // Associated Objects
    _skwasm_setAssociatedObjectOnThread = function(threadId, pointer, object) {
      skwasm_postMessage({
        skwasmMessage: 'setAssociatedObject',
        pointer,
        object,
      }, [object], threadId);
    };
    _skwasm_getAssociatedObject = function(pointer) {
      return associatedObjectsMap.get(pointer);
    };
    _skwasm_disposeAssociatedObjectOnThread = function(threadId, pointer) {
      skwasm_postMessage({
        skwasmMessage: 'disposeAssociatedObject',
        pointer,
      }, [], threadId);
    };

    // Surface Lifecycle
    _skwasm_dispatchDisposeSurface = function(threadId, surface) {
      skwasm_postMessage({
        skwasmMessage: 'disposeSurface',
        surface,
      }, [], threadId);
    }

    // Surface Setup
    _skwasm_dispatchTransferCanvas = function (threadId, surfaceHandle, canvas, callbackId) {
      skwasm_postMessage({
        skwasmMessage: 'transferCanvas',
        surface: surfaceHandle,
        canvas,
        callbackId,
      }, [canvas], threadId);
    };
    _skwasm_reportInitialized = function (surfaceHandle, contextLostCallbackId, callbackId) {
      skwasm_postMessage({
        skwasmMessage: 'onInitialized',
        surface: surfaceHandle,
        contextLostCallbackId,
        callbackId,
      }, []);
    };

    // Resizing
    _skwasm_dispatchResizeSurface = function (threadId, surface, width, height, callbackId) {
      skwasm_postMessage({
        skwasmMessage: 'resizeSurface',
        surface,
        width,
        height,
        callbackId,
      }, [], threadId);
    }
    _skwasm_reportResizeComplete = function (surfaceHandle, callbackId) {
      skwasm_postMessage({
        skwasmMessage: 'onResizeComplete',
        surface: surfaceHandle,
        callbackId,
      }, []);
    };
    _skwasm_resizeCanvas = function(contextHandle, width, height) {
      const canvas = handleToCanvasMap.get(contextHandle);
      canvas.width = width;
      canvas.height = height;
    };

    // Rendering
    _skwasm_dispatchRenderPictures = function (threadId, surfaceHandle, pictures, pictureCount, callbackId) {
      skwasm_postMessage({
        skwasmMessage: 'renderPictures',
        surface: surfaceHandle,
        pictures,
        pictureCount,
        callbackId,
      }, [], threadId);
    };
    _skwasm_resolveAndPostImages = async function (surfaceHandle, imageBitmaps, rasterStart, callbackId) {
      if (!imageBitmaps) imageBitmaps = Array();
      const rasterEnd = skwasm_getCurrentTimestamp();
      skwasm_postMessage({
        skwasmMessage: 'onRenderComplete',
        surface: surfaceHandle,
        callbackId,
        imageBitmaps,
        rasterStart,
        rasterEnd,
      }, [...imageBitmaps]);
    };
    _skwasm_captureImageBitmap = function (contextHandle, imageBitmaps) {
      if (!imageBitmaps) imageBitmaps = Array();
      const canvas = handleToCanvasMap.get(contextHandle);
      imageBitmaps.push(canvas.transferToImageBitmap());
      return imageBitmaps;
    };

    // Image Rasterization
    _skwasm_dispatchRasterizeImage = function(threadId, surface, image, format, callbackId) {
      skwasm_postMessage({
        skwasmMessage: 'rasterizeImage',
        surface,
        image,
        format,
        callbackId,
      }, [], threadId);
    }
    _skwasm_postRasterizeResult = function(surface, data, callbackId) {
      skwasm_postMessage({
        skwasmMessage: 'onRasterizeComplete',
        surface,
        data,
        callbackId,
      });
    }

    // Context Loss
    _skwasm_dispatchTriggerContextLoss = function (threadId, surfaceHandle, callbackId) {
      skwasm_postMessage({
        skwasmMessage: 'triggerContextLoss',
        surface: surfaceHandle,
        callbackId,
      }, [], threadId);
    };
    _skwasm_reportContextLossTriggered = function (surfaceHandle, callbackId) {
      skwasm_postMessage({
        skwasmMessage: 'onContextLossTriggered',
        surface: surfaceHandle,
        callbackId,
      }, []);
    };
    _skwasm_reportContextLost = function (surfaceHandle, callbackId) {
      skwasm_postMessage({
        skwasmMessage: 'reportContextLost',
        surface: surfaceHandle,
        callbackId,
      }, []);
    };
    _skwasm_triggerContextLossOnCanvas = function () {
      const glCtx = GL.currentContext.GLctx;
      glCtx.getExtension("WEBGL_lose_context").loseContext();
    };

    // GL Context
    _skwasm_getGlContextForCanvas = function (canvas, surfaceHandle) {
      var contextAttributes = {
        majorVersion: 2,
        alpha: true,
        depth: true,
        stencil: true,
        antialias: false,
        premultipliedAlpha: true,
        preserveDrawingBuffer: false,
        powerPreference: 'default',
        failIfMajorPerformanceCaveat: false,
        enableExtensionsByDefault: true,
      };
      const contextHandle = GL.createContext(canvas, contextAttributes);
      handleToCanvasMap.set(contextHandle, canvas);

      // Register an event listener for the context lost event.
      var contextLostHandler;
      contextLostHandler = function (e) {
        e.preventDefault();
        _surface_onContextLost(surfaceHandle);
        canvas.removeEventListener('webglcontextlost', contextLostHandler);
      }
      canvas.addEventListener('webglcontextlost', contextLostHandler);
      handleToContextLostHandlerMap.set(contextHandle, contextLostHandler);
      return contextHandle;
    };
    _skwasm_destroyContext = function (contextHandle) {
      const canvas = handleToCanvasMap.get(contextHandle);
      const handler = handleToContextLostHandlerMap.get(contextHandle);
      if (canvas && handler) {
        canvas.removeEventListener('webglcontextlost', handler);
      }
      GL.deleteContext(contextHandle);
      handleToCanvasMap.delete(contextHandle);
      handleToContextLostHandlerMap.delete(contextHandle);
    };

    // Texture Sources
    _skwasm_createGlTextureFromTextureSource = function(textureSource, width, height) {
      const glCtx = GL.currentContext.GLctx;
      const newTexture = glCtx.createTexture();
      glCtx.bindTexture(glCtx.TEXTURE_2D, newTexture);
      glCtx.pixelStorei(glCtx.UNPACK_PREMULTIPLY_ALPHA_WEBGL, true);

      glCtx.texImage2D(glCtx.TEXTURE_2D, 0, glCtx.RGBA, width, height, 0, glCtx.RGBA, glCtx.UNSIGNED_BYTE, textureSource);

      glCtx.pixelStorei(glCtx.UNPACK_PREMULTIPLY_ALPHA_WEBGL, false);
      glCtx.bindTexture(glCtx.TEXTURE_2D, null);

      const textureId = GL.getNewId(GL.textures);
      GL.textures[textureId] = newTexture;
      return textureId;
    };
  },
  $skwasm_registerMessageListener: function() {},
  $skwasm_registerMessageListener__deps: ['$skwasm_support_setup'],
  $skwasm_getCurrentTimestamp: function () {},
  $skwasm_getCurrentTimestamp__deps: ['$skwasm_support_setup'],
  $skwasm_postMessage: function () {},
  $skwasm_postMessage__deps: ['$skwasm_support_setup'],
  skwasm_isSingleThreaded: function() {},
  skwasm_isSingleThreaded__deps: ['$skwasm_support_setup'],
  skwasm_setAssociatedObjectOnThread: function () {},
  skwasm_setAssociatedObjectOnThread__deps: ['$skwasm_support_setup', '$skwasm_postMessage'],
  skwasm_getAssociatedObject: function () {},
  skwasm_getAssociatedObject__deps: ['$skwasm_support_setup'],
  skwasm_disposeAssociatedObjectOnThread: function () {},
  skwasm_disposeAssociatedObjectOnThread__deps: ['$skwasm_support_setup'],
  skwasm_connectThread: function() {},
  skwasm_connectThread__deps: ['$skwasm_support_setup', '$skwasm_registerMessageListener', '$skwasm_getCurrentTimestamp'],
  skwasm_dispatchTransferCanvas: function () { },
  skwasm_dispatchTransferCanvas__deps: ['$skwasm_support_setup'],
  skwasm_reportInitialized: function () { },
  skwasm_reportInitialized__deps: ['$skwasm_support_setup'],
  skwasm_reportResizeComplete: function () { },
  skwasm_reportResizeComplete__deps: ['$skwasm_support_setup'],
  skwasm_getGlContextForCanvas: function () { },
  skwasm_getGlContextForCanvas__deps: ['$skwasm_support_setup'],
  skwasm_dispatchTriggerContextLoss: function () { },
  skwasm_dispatchTriggerContextLoss__deps: ['$skwasm_support_setup'],
  skwasm_triggerContextLossOnCanvas: function () { },
  skwasm_triggerContextLossOnCanvas__deps: ['$skwasm_support_setup'],
  skwasm_reportContextLossTriggered: function () { },
  skwasm_reportContextLossTriggered__deps: ['$skwasm_support_setup'],
  skwasm_reportContextLost: function () { },
  skwasm_reportContextLost__deps: ['$skwasm_support_setup'],
  skwasm_destroyContext: function () { },
  skwasm_destroyContext__deps: ['$skwasm_support_setup'],
  skwasm_dispatchResizeSurface: function () { },
  skwasm_dispatchResizeSurface__deps: ['$skwasm_support_setup'],
  skwasm_dispatchRenderPictures: function() {},
  skwasm_dispatchRenderPictures__deps: ['$skwasm_support_setup'],
  skwasm_resizeCanvas: function () {},
  skwasm_resizeCanvas__deps: ['$skwasm_support_setup'],
  skwasm_captureImageBitmap: function () {},
  skwasm_captureImageBitmap__deps: ['$skwasm_support_setup'],
  skwasm_resolveAndPostImages: function () {},
  skwasm_resolveAndPostImages__deps: ['$skwasm_support_setup'],
  skwasm_createGlTextureFromTextureSource: function () {},
  skwasm_createGlTextureFromTextureSource__deps: ['$skwasm_support_setup'],
  skwasm_dispatchDisposeSurface: function() {},
  skwasm_dispatchDisposeSurface__deps: ['$skwasm_support_setup'],
  skwasm_dispatchRasterizeImage: function() {},
  skwasm_dispatchRasterizeImage__deps: ['$skwasm_support_setup'],
  skwasm_postRasterizeResult: function() {},
  skwasm_postRasterizeResult__deps: ['$skwasm_support_setup'],
});
