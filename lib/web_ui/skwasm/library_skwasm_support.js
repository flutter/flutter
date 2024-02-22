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
    _skwasm_registerMessageListener = function(threadId) {
      const eventListener = function({data}) {
        const skwasmMessage = data.skwasmMessage;
        if (!skwasmMessage) {
          return;
        }
        switch (skwasmMessage) {
          case 'renderPicture':
            _surface_renderPictureOnWorker(data.surface, data.picture, data.callbackId);
            return;
          case 'onRenderComplete':
            _surface_onRenderComplete(data.surface, data.callbackId, data.imageBitmap);
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
    _skwasm_dispatchRenderPicture = function(threadId, surfaceHandle, pictureHandle, callbackId) {
      PThread.pthreads[threadId].postMessage({
        skwasmMessage: 'renderPicture',
        surface: surfaceHandle,
        picture: pictureHandle,
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
    _skwasm_captureImageBitmap = async function(surfaceHandle, contextHandle, callbackId, width, height) {
      const canvas = handleToCanvasMap.get(contextHandle);
      const imageBitmap = await createImageBitmap(canvas, 0, 0, width, height);
      postMessage({
        skwasmMessage: 'onRenderComplete',
        surface: surfaceHandle,
        callbackId,
        imageBitmap,
      }, [imageBitmap]);
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
  },
  skwasm_setAssociatedObjectOnThread: function () {},
  skwasm_setAssociatedObjectOnThread__deps: ['$skwasm_support_setup'],
  skwasm_getAssociatedObject: function () {},
  skwasm_getAssociatedObject__deps: ['$skwasm_support_setup'],
  skwasm_disposeAssociatedObjectOnThread: function () {},
  skwasm_disposeAssociatedObjectOnThread__deps: ['$skwasm_support_setup'],
  skwasm_registerMessageListener: function() {},
  skwasm_registerMessageListener__deps: ['$skwasm_support_setup'],
  skwasm_dispatchRenderPicture: function() {},
  skwasm_dispatchRenderPicture__deps: ['$skwasm_support_setup'],
  skwasm_createOffscreenCanvas: function () {},
  skwasm_createOffscreenCanvas__deps: ['$skwasm_support_setup'],
  skwasm_resizeCanvas: function () {},
  skwasm_resizeCanvas__deps: ['$skwasm_support_setup'],
  skwasm_captureImageBitmap: function () {},
  skwasm_captureImageBitmap__deps: ['$skwasm_support_setup'],
  skwasm_createGlTextureFromTextureSource: function () {},
  skwasm_createGlTextureFromTextureSource__deps: ['$skwasm_support_setup'],
});
  