// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This file adds JavaScript APIs that are accessible to the C++ layer.
// See: https://emscripten.org/docs/porting/connecting_cpp_and_javascript/Interacting-with-code.html#implement-a-c-api-in-javascript

mergeInto(LibraryManager.library, {
  $skwasm_support_setup__postset: 'skwasm_support_setup();',
  $skwasm_support_setup: function() {
    const handleToCanvasMap = new Map();
    const associatedObjectsMap = new Map();

    // This value represents the difference between the time origin of the main
    // thread and whichever web worker this code is running on. This is so that
    // when we report frame timings, that they are in the same time domain
    // regardless of whether they are captured on the main thread or the web
    // worker.
    let timeOriginDelta;
    _skwasm_setAssociatedObjectOnThread = function(threadId, pointer, object) {
      PThread.pthreads[threadId].postMessage({
        skwasmMessage: 'setAssociatedObject',
        pointer,
        object,
      }, [object]);
    };
    _skwasm_getAssociatedObject = function(pointer) {
      return associatedObjectsMap.get(pointer);
    };
    _skwasm_syncTimeOriginForThread = function(threadId) {
      PThread.pthreads[threadId].postMessage({
        skwasmMessage: 'syncTimeOrigin',
        timeOrigin: performance.timeOrigin,
      });
    }
    _skwasm_registerMessageListener = function(threadId) {
      const eventListener = function({data}) {
        const skwasmMessage = data.skwasmMessage;
        if (!skwasmMessage) {
          return;
        }
        switch (skwasmMessage) {
          case 'syncTimeOrigin':
            timeOriginDelta = performance.timeOrigin - data.timeOrigin;
            return;
          case 'renderPictures':
            _surface_renderPicturesOnWorker(
              data.surface,
              data.pictures,
              data.pictureCount,
              data.callbackId,
              performance.now() + timeOriginDelta);
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
      if (!threadId) {
        addEventListener("message", eventListener);
      } else {
        PThread.pthreads[threadId].addEventListener("message", eventListener);
      }
    };
    _skwasm_dispatchRenderPictures = function(threadId, surfaceHandle, pictures, pictureCount, callbackId) {
      PThread.pthreads[threadId].postMessage({
        skwasmMessage: 'renderPictures',
        surface: surfaceHandle,
        pictures,
        pictureCount,
        callbackId,
      });
    };
    _skwasm_createOffscreenCanvas = function(width, height) {
      const canvas = new OffscreenCanvas(width, height);
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
      return contextHandle;
    };
    _skwasm_resizeCanvas = function(contextHandle, width, height) {
      const canvas = handleToCanvasMap.get(contextHandle);
      canvas.width = width;
      canvas.height = height;
    };
    _skwasm_captureImageBitmap = function(contextHandle, width, height, imagePromises) {
      if (!imagePromises) imagePromises = Array();
      const canvas = handleToCanvasMap.get(contextHandle);
      imagePromises.push(createImageBitmap(canvas, 0, 0, width, height));
      return imagePromises;
    };
    _skwasm_resolveAndPostImages = async function(surfaceHandle, imagePromises, rasterStart, callbackId) {
      const imageBitmaps = imagePromises ? await Promise.all(imagePromises) : [];
      const rasterEnd = performance.now() + timeOriginDelta;
      postMessage({
        skwasmMessage: 'onRenderComplete',
        surface: surfaceHandle,
        callbackId,
        imageBitmaps,
        rasterStart,
        rasterEnd,
      }, [...imageBitmaps]);
    };
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
    _skwasm_disposeAssociatedObjectOnThread = function(threadId, pointer) {
      PThread.pthreads[threadId].postMessage({
        skwasmMessage: 'disposeAssociatedObject',
        pointer,
      });
    };
    _skwasm_dispatchDisposeSurface = function(threadId, surface) {
      PThread.pthreads[threadId].postMessage({
        skwasmMessage: 'disposeSurface',
        surface,
      });
    }
    _skwasm_dispatchRasterizeImage = function(threadId, surface, image, format, callbackId) {
      PThread.pthreads[threadId].postMessage({
        skwasmMessage: 'rasterizeImage',
        surface,
        image,
        format,
        callbackId,
      });
    }
    _skwasm_postRasterizeResult = function(surface, data, callbackId) {
      postMessage({
        skwasmMessage: 'onRasterizeComplete',
        surface,
        data,
        callbackId,
      });
    }
  },
  skwasm_setAssociatedObjectOnThread: function () {},
  skwasm_setAssociatedObjectOnThread__deps: ['$skwasm_support_setup'],
  skwasm_getAssociatedObject: function () {},
  skwasm_getAssociatedObject__deps: ['$skwasm_support_setup'],
  skwasm_disposeAssociatedObjectOnThread: function () {},
  skwasm_disposeAssociatedObjectOnThread__deps: ['$skwasm_support_setup'],
  skwasm_syncTimeOriginForThread: function() {},
  skwasm_syncTimeOriginForThread__deps: ['$skwasm_support_setup'],
  skwasm_registerMessageListener: function() {},
  skwasm_registerMessageListener__deps: ['$skwasm_support_setup'],
  skwasm_dispatchRenderPictures: function() {},
  skwasm_dispatchRenderPictures__deps: ['$skwasm_support_setup'],
  skwasm_createOffscreenCanvas: function () {},
  skwasm_createOffscreenCanvas__deps: ['$skwasm_support_setup'],
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
  