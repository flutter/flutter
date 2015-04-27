// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

library window_manager.mojom;

import 'dart:async';

import 'package:mojo/public/dart/bindings.dart' as bindings;
import 'package:mojo/public/dart/core.dart' as core;
import 'package:mojo/services/input_events/public/interfaces/input_events.mojom.dart' as input_events_mojom;
import 'package:mojo/public/interfaces/application/service_provider.mojom.dart' as service_provider_mojom;


class WindowManagerEmbedParams extends bindings.Struct {
  static const List<bindings.StructDataHeader> kVersions = const [
    const bindings.StructDataHeader(24, 0)
  ];
  String url = null;
  Object services = null;
  Object exposedServices = null;

  WindowManagerEmbedParams() : super(kVersions.last.size);

  static WindowManagerEmbedParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static WindowManagerEmbedParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    WindowManagerEmbedParams result = new WindowManagerEmbedParams();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if (mainDataHeader.version <= kVersions.last.version) {
      // Scan in reverse order to optimize for more recent versions.
      for (int i = kVersions.length - 1; i >= 0; --i) {
        if (mainDataHeader.version >= kVersions[i].version) {
          if (mainDataHeader.size != kVersions[i].size)
            throw new bindings.MojoCodecError(
                'Header doesn\'t correspond to any known version.');
        }
      }
    } else if (mainDataHeader.size < kVersions.last.size) {
      throw new bindings.MojoCodecError(
        'Message newer than the last known version cannot be shorter than '
        'required by the last known version.');
    }
    if (mainDataHeader.version >= 0) {
      
      result.url = decoder0.decodeString(8, false);
    }
    if (mainDataHeader.version >= 0) {
      
      result.services = decoder0.decodeInterfaceRequest(16, true, service_provider_mojom.ServiceProviderStub.newFromEndpoint);
    }
    if (mainDataHeader.version >= 0) {
      
      result.exposedServices = decoder0.decodeServiceInterface(20, true, service_provider_mojom.ServiceProviderProxy.newFromEndpoint);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kVersions.last);
    
    encoder0.encodeString(url, 8, false);
    
    encoder0.encodeInterfaceRequest(services, 16, true);
    
    encoder0.encodeInterface(exposedServices, 20, true);
  }

  String toString() {
    return "WindowManagerEmbedParams("
           "url: $url" ", "
           "services: $services" ", "
           "exposedServices: $exposedServices" ")";
  }
}

class WindowManagerSetCaptureParams extends bindings.Struct {
  static const List<bindings.StructDataHeader> kVersions = const [
    const bindings.StructDataHeader(16, 0)
  ];
  int viewId = 0;

  WindowManagerSetCaptureParams() : super(kVersions.last.size);

  static WindowManagerSetCaptureParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static WindowManagerSetCaptureParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    WindowManagerSetCaptureParams result = new WindowManagerSetCaptureParams();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if (mainDataHeader.version <= kVersions.last.version) {
      // Scan in reverse order to optimize for more recent versions.
      for (int i = kVersions.length - 1; i >= 0; --i) {
        if (mainDataHeader.version >= kVersions[i].version) {
          if (mainDataHeader.size != kVersions[i].size)
            throw new bindings.MojoCodecError(
                'Header doesn\'t correspond to any known version.');
        }
      }
    } else if (mainDataHeader.size < kVersions.last.size) {
      throw new bindings.MojoCodecError(
        'Message newer than the last known version cannot be shorter than '
        'required by the last known version.');
    }
    if (mainDataHeader.version >= 0) {
      
      result.viewId = decoder0.decodeUint32(8);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kVersions.last);
    
    encoder0.encodeUint32(viewId, 8);
  }

  String toString() {
    return "WindowManagerSetCaptureParams("
           "viewId: $viewId" ")";
  }
}

class WindowManagerSetCaptureResponseParams extends bindings.Struct {
  static const List<bindings.StructDataHeader> kVersions = const [
    const bindings.StructDataHeader(16, 0)
  ];
  bool success = false;

  WindowManagerSetCaptureResponseParams() : super(kVersions.last.size);

  static WindowManagerSetCaptureResponseParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static WindowManagerSetCaptureResponseParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    WindowManagerSetCaptureResponseParams result = new WindowManagerSetCaptureResponseParams();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if (mainDataHeader.version <= kVersions.last.version) {
      // Scan in reverse order to optimize for more recent versions.
      for (int i = kVersions.length - 1; i >= 0; --i) {
        if (mainDataHeader.version >= kVersions[i].version) {
          if (mainDataHeader.size != kVersions[i].size)
            throw new bindings.MojoCodecError(
                'Header doesn\'t correspond to any known version.');
        }
      }
    } else if (mainDataHeader.size < kVersions.last.size) {
      throw new bindings.MojoCodecError(
        'Message newer than the last known version cannot be shorter than '
        'required by the last known version.');
    }
    if (mainDataHeader.version >= 0) {
      
      result.success = decoder0.decodeBool(8, 0);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kVersions.last);
    
    encoder0.encodeBool(success, 8, 0);
  }

  String toString() {
    return "WindowManagerSetCaptureResponseParams("
           "success: $success" ")";
  }
}

class WindowManagerFocusWindowParams extends bindings.Struct {
  static const List<bindings.StructDataHeader> kVersions = const [
    const bindings.StructDataHeader(16, 0)
  ];
  int viewId = 0;

  WindowManagerFocusWindowParams() : super(kVersions.last.size);

  static WindowManagerFocusWindowParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static WindowManagerFocusWindowParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    WindowManagerFocusWindowParams result = new WindowManagerFocusWindowParams();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if (mainDataHeader.version <= kVersions.last.version) {
      // Scan in reverse order to optimize for more recent versions.
      for (int i = kVersions.length - 1; i >= 0; --i) {
        if (mainDataHeader.version >= kVersions[i].version) {
          if (mainDataHeader.size != kVersions[i].size)
            throw new bindings.MojoCodecError(
                'Header doesn\'t correspond to any known version.');
        }
      }
    } else if (mainDataHeader.size < kVersions.last.size) {
      throw new bindings.MojoCodecError(
        'Message newer than the last known version cannot be shorter than '
        'required by the last known version.');
    }
    if (mainDataHeader.version >= 0) {
      
      result.viewId = decoder0.decodeUint32(8);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kVersions.last);
    
    encoder0.encodeUint32(viewId, 8);
  }

  String toString() {
    return "WindowManagerFocusWindowParams("
           "viewId: $viewId" ")";
  }
}

class WindowManagerFocusWindowResponseParams extends bindings.Struct {
  static const List<bindings.StructDataHeader> kVersions = const [
    const bindings.StructDataHeader(16, 0)
  ];
  bool success = false;

  WindowManagerFocusWindowResponseParams() : super(kVersions.last.size);

  static WindowManagerFocusWindowResponseParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static WindowManagerFocusWindowResponseParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    WindowManagerFocusWindowResponseParams result = new WindowManagerFocusWindowResponseParams();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if (mainDataHeader.version <= kVersions.last.version) {
      // Scan in reverse order to optimize for more recent versions.
      for (int i = kVersions.length - 1; i >= 0; --i) {
        if (mainDataHeader.version >= kVersions[i].version) {
          if (mainDataHeader.size != kVersions[i].size)
            throw new bindings.MojoCodecError(
                'Header doesn\'t correspond to any known version.');
        }
      }
    } else if (mainDataHeader.size < kVersions.last.size) {
      throw new bindings.MojoCodecError(
        'Message newer than the last known version cannot be shorter than '
        'required by the last known version.');
    }
    if (mainDataHeader.version >= 0) {
      
      result.success = decoder0.decodeBool(8, 0);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kVersions.last);
    
    encoder0.encodeBool(success, 8, 0);
  }

  String toString() {
    return "WindowManagerFocusWindowResponseParams("
           "success: $success" ")";
  }
}

class WindowManagerActivateWindowParams extends bindings.Struct {
  static const List<bindings.StructDataHeader> kVersions = const [
    const bindings.StructDataHeader(16, 0)
  ];
  int viewId = 0;

  WindowManagerActivateWindowParams() : super(kVersions.last.size);

  static WindowManagerActivateWindowParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static WindowManagerActivateWindowParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    WindowManagerActivateWindowParams result = new WindowManagerActivateWindowParams();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if (mainDataHeader.version <= kVersions.last.version) {
      // Scan in reverse order to optimize for more recent versions.
      for (int i = kVersions.length - 1; i >= 0; --i) {
        if (mainDataHeader.version >= kVersions[i].version) {
          if (mainDataHeader.size != kVersions[i].size)
            throw new bindings.MojoCodecError(
                'Header doesn\'t correspond to any known version.');
        }
      }
    } else if (mainDataHeader.size < kVersions.last.size) {
      throw new bindings.MojoCodecError(
        'Message newer than the last known version cannot be shorter than '
        'required by the last known version.');
    }
    if (mainDataHeader.version >= 0) {
      
      result.viewId = decoder0.decodeUint32(8);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kVersions.last);
    
    encoder0.encodeUint32(viewId, 8);
  }

  String toString() {
    return "WindowManagerActivateWindowParams("
           "viewId: $viewId" ")";
  }
}

class WindowManagerActivateWindowResponseParams extends bindings.Struct {
  static const List<bindings.StructDataHeader> kVersions = const [
    const bindings.StructDataHeader(16, 0)
  ];
  bool success = false;

  WindowManagerActivateWindowResponseParams() : super(kVersions.last.size);

  static WindowManagerActivateWindowResponseParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static WindowManagerActivateWindowResponseParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    WindowManagerActivateWindowResponseParams result = new WindowManagerActivateWindowResponseParams();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if (mainDataHeader.version <= kVersions.last.version) {
      // Scan in reverse order to optimize for more recent versions.
      for (int i = kVersions.length - 1; i >= 0; --i) {
        if (mainDataHeader.version >= kVersions[i].version) {
          if (mainDataHeader.size != kVersions[i].size)
            throw new bindings.MojoCodecError(
                'Header doesn\'t correspond to any known version.');
        }
      }
    } else if (mainDataHeader.size < kVersions.last.size) {
      throw new bindings.MojoCodecError(
        'Message newer than the last known version cannot be shorter than '
        'required by the last known version.');
    }
    if (mainDataHeader.version >= 0) {
      
      result.success = decoder0.decodeBool(8, 0);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kVersions.last);
    
    encoder0.encodeBool(success, 8, 0);
  }

  String toString() {
    return "WindowManagerActivateWindowResponseParams("
           "success: $success" ")";
  }
}

class WindowManagerGetFocusedAndActiveViewsParams extends bindings.Struct {
  static const List<bindings.StructDataHeader> kVersions = const [
    const bindings.StructDataHeader(16, 0)
  ];
  Object observer = null;

  WindowManagerGetFocusedAndActiveViewsParams() : super(kVersions.last.size);

  static WindowManagerGetFocusedAndActiveViewsParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static WindowManagerGetFocusedAndActiveViewsParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    WindowManagerGetFocusedAndActiveViewsParams result = new WindowManagerGetFocusedAndActiveViewsParams();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if (mainDataHeader.version <= kVersions.last.version) {
      // Scan in reverse order to optimize for more recent versions.
      for (int i = kVersions.length - 1; i >= 0; --i) {
        if (mainDataHeader.version >= kVersions[i].version) {
          if (mainDataHeader.size != kVersions[i].size)
            throw new bindings.MojoCodecError(
                'Header doesn\'t correspond to any known version.');
        }
      }
    } else if (mainDataHeader.size < kVersions.last.size) {
      throw new bindings.MojoCodecError(
        'Message newer than the last known version cannot be shorter than '
        'required by the last known version.');
    }
    if (mainDataHeader.version >= 0) {
      
      result.observer = decoder0.decodeServiceInterface(8, true, WindowManagerObserverProxy.newFromEndpoint);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kVersions.last);
    
    encoder0.encodeInterface(observer, 8, true);
  }

  String toString() {
    return "WindowManagerGetFocusedAndActiveViewsParams("
           "observer: $observer" ")";
  }
}

class WindowManagerGetFocusedAndActiveViewsResponseParams extends bindings.Struct {
  static const List<bindings.StructDataHeader> kVersions = const [
    const bindings.StructDataHeader(24, 0)
  ];
  int captureViewId = 0;
  int focusedViewId = 0;
  int activeViewId = 0;

  WindowManagerGetFocusedAndActiveViewsResponseParams() : super(kVersions.last.size);

  static WindowManagerGetFocusedAndActiveViewsResponseParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static WindowManagerGetFocusedAndActiveViewsResponseParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    WindowManagerGetFocusedAndActiveViewsResponseParams result = new WindowManagerGetFocusedAndActiveViewsResponseParams();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if (mainDataHeader.version <= kVersions.last.version) {
      // Scan in reverse order to optimize for more recent versions.
      for (int i = kVersions.length - 1; i >= 0; --i) {
        if (mainDataHeader.version >= kVersions[i].version) {
          if (mainDataHeader.size != kVersions[i].size)
            throw new bindings.MojoCodecError(
                'Header doesn\'t correspond to any known version.');
        }
      }
    } else if (mainDataHeader.size < kVersions.last.size) {
      throw new bindings.MojoCodecError(
        'Message newer than the last known version cannot be shorter than '
        'required by the last known version.');
    }
    if (mainDataHeader.version >= 0) {
      
      result.captureViewId = decoder0.decodeUint32(8);
    }
    if (mainDataHeader.version >= 0) {
      
      result.focusedViewId = decoder0.decodeUint32(12);
    }
    if (mainDataHeader.version >= 0) {
      
      result.activeViewId = decoder0.decodeUint32(16);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kVersions.last);
    
    encoder0.encodeUint32(captureViewId, 8);
    
    encoder0.encodeUint32(focusedViewId, 12);
    
    encoder0.encodeUint32(activeViewId, 16);
  }

  String toString() {
    return "WindowManagerGetFocusedAndActiveViewsResponseParams("
           "captureViewId: $captureViewId" ", "
           "focusedViewId: $focusedViewId" ", "
           "activeViewId: $activeViewId" ")";
  }
}

class WindowManagerObserverOnCaptureChangedParams extends bindings.Struct {
  static const List<bindings.StructDataHeader> kVersions = const [
    const bindings.StructDataHeader(16, 0)
  ];
  int captureViewId = 0;

  WindowManagerObserverOnCaptureChangedParams() : super(kVersions.last.size);

  static WindowManagerObserverOnCaptureChangedParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static WindowManagerObserverOnCaptureChangedParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    WindowManagerObserverOnCaptureChangedParams result = new WindowManagerObserverOnCaptureChangedParams();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if (mainDataHeader.version <= kVersions.last.version) {
      // Scan in reverse order to optimize for more recent versions.
      for (int i = kVersions.length - 1; i >= 0; --i) {
        if (mainDataHeader.version >= kVersions[i].version) {
          if (mainDataHeader.size != kVersions[i].size)
            throw new bindings.MojoCodecError(
                'Header doesn\'t correspond to any known version.');
        }
      }
    } else if (mainDataHeader.size < kVersions.last.size) {
      throw new bindings.MojoCodecError(
        'Message newer than the last known version cannot be shorter than '
        'required by the last known version.');
    }
    if (mainDataHeader.version >= 0) {
      
      result.captureViewId = decoder0.decodeUint32(8);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kVersions.last);
    
    encoder0.encodeUint32(captureViewId, 8);
  }

  String toString() {
    return "WindowManagerObserverOnCaptureChangedParams("
           "captureViewId: $captureViewId" ")";
  }
}

class WindowManagerObserverOnFocusChangedParams extends bindings.Struct {
  static const List<bindings.StructDataHeader> kVersions = const [
    const bindings.StructDataHeader(16, 0)
  ];
  int focusedViewId = 0;

  WindowManagerObserverOnFocusChangedParams() : super(kVersions.last.size);

  static WindowManagerObserverOnFocusChangedParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static WindowManagerObserverOnFocusChangedParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    WindowManagerObserverOnFocusChangedParams result = new WindowManagerObserverOnFocusChangedParams();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if (mainDataHeader.version <= kVersions.last.version) {
      // Scan in reverse order to optimize for more recent versions.
      for (int i = kVersions.length - 1; i >= 0; --i) {
        if (mainDataHeader.version >= kVersions[i].version) {
          if (mainDataHeader.size != kVersions[i].size)
            throw new bindings.MojoCodecError(
                'Header doesn\'t correspond to any known version.');
        }
      }
    } else if (mainDataHeader.size < kVersions.last.size) {
      throw new bindings.MojoCodecError(
        'Message newer than the last known version cannot be shorter than '
        'required by the last known version.');
    }
    if (mainDataHeader.version >= 0) {
      
      result.focusedViewId = decoder0.decodeUint32(8);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kVersions.last);
    
    encoder0.encodeUint32(focusedViewId, 8);
  }

  String toString() {
    return "WindowManagerObserverOnFocusChangedParams("
           "focusedViewId: $focusedViewId" ")";
  }
}

class WindowManagerObserverOnActiveWindowChangedParams extends bindings.Struct {
  static const List<bindings.StructDataHeader> kVersions = const [
    const bindings.StructDataHeader(16, 0)
  ];
  int focusedViewId = 0;

  WindowManagerObserverOnActiveWindowChangedParams() : super(kVersions.last.size);

  static WindowManagerObserverOnActiveWindowChangedParams deserialize(bindings.Message message) {
    return decode(new bindings.Decoder(message));
  }

  static WindowManagerObserverOnActiveWindowChangedParams decode(bindings.Decoder decoder0) {
    if (decoder0 == null) {
      return null;
    }
    WindowManagerObserverOnActiveWindowChangedParams result = new WindowManagerObserverOnActiveWindowChangedParams();

    var mainDataHeader = decoder0.decodeStructDataHeader();
    if (mainDataHeader.version <= kVersions.last.version) {
      // Scan in reverse order to optimize for more recent versions.
      for (int i = kVersions.length - 1; i >= 0; --i) {
        if (mainDataHeader.version >= kVersions[i].version) {
          if (mainDataHeader.size != kVersions[i].size)
            throw new bindings.MojoCodecError(
                'Header doesn\'t correspond to any known version.');
        }
      }
    } else if (mainDataHeader.size < kVersions.last.size) {
      throw new bindings.MojoCodecError(
        'Message newer than the last known version cannot be shorter than '
        'required by the last known version.');
    }
    if (mainDataHeader.version >= 0) {
      
      result.focusedViewId = decoder0.decodeUint32(8);
    }
    return result;
  }

  void encode(bindings.Encoder encoder) {
    var encoder0 = encoder.getStructEncoderAtOffset(kVersions.last);
    
    encoder0.encodeUint32(focusedViewId, 8);
  }

  String toString() {
    return "WindowManagerObserverOnActiveWindowChangedParams("
           "focusedViewId: $focusedViewId" ")";
  }
}
const int kWindowManager_embed_name = 0;
const int kWindowManager_setCapture_name = 1;
const int kWindowManager_focusWindow_name = 2;
const int kWindowManager_activateWindow_name = 3;
const int kWindowManager_getFocusedAndActiveViews_name = 4;

const String WindowManagerName =
      'mojo::WindowManager';

abstract class WindowManager {
  void embed(String url, Object services, Object exposedServices);
  Future<WindowManagerSetCaptureResponseParams> setCapture(int viewId,[Function responseFactory = null]);
  Future<WindowManagerFocusWindowResponseParams> focusWindow(int viewId,[Function responseFactory = null]);
  Future<WindowManagerActivateWindowResponseParams> activateWindow(int viewId,[Function responseFactory = null]);
  Future<WindowManagerGetFocusedAndActiveViewsResponseParams> getFocusedAndActiveViews(Object observer,[Function responseFactory = null]);

}


class WindowManagerProxyImpl extends bindings.Proxy {
  WindowManagerProxyImpl.fromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) : super.fromEndpoint(endpoint);

  WindowManagerProxyImpl.fromHandle(core.MojoHandle handle) :
      super.fromHandle(handle);

  WindowManagerProxyImpl.unbound() : super.unbound();

  static WindowManagerProxyImpl newFromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) =>
      new WindowManagerProxyImpl.fromEndpoint(endpoint);

  String get name => WindowManagerName;

  void handleResponse(bindings.ServiceMessage message) {
    switch (message.header.type) {
      case kWindowManager_setCapture_name:
        var r = WindowManagerSetCaptureResponseParams.deserialize(
            message.payload);
        if (!message.header.hasRequestId) {
          throw 'Expected a message with a valid request Id.';
        }
        Completer c = completerMap[message.header.requestId];
        if (c == null) {
          throw 'Message had unknown request Id: ${message.header.requestId}';
        }
        completerMap.remove(message.header.requestId);
        assert(!c.isCompleted);
        c.complete(r);
        break;
      case kWindowManager_focusWindow_name:
        var r = WindowManagerFocusWindowResponseParams.deserialize(
            message.payload);
        if (!message.header.hasRequestId) {
          throw 'Expected a message with a valid request Id.';
        }
        Completer c = completerMap[message.header.requestId];
        if (c == null) {
          throw 'Message had unknown request Id: ${message.header.requestId}';
        }
        completerMap.remove(message.header.requestId);
        assert(!c.isCompleted);
        c.complete(r);
        break;
      case kWindowManager_activateWindow_name:
        var r = WindowManagerActivateWindowResponseParams.deserialize(
            message.payload);
        if (!message.header.hasRequestId) {
          throw 'Expected a message with a valid request Id.';
        }
        Completer c = completerMap[message.header.requestId];
        if (c == null) {
          throw 'Message had unknown request Id: ${message.header.requestId}';
        }
        completerMap.remove(message.header.requestId);
        assert(!c.isCompleted);
        c.complete(r);
        break;
      case kWindowManager_getFocusedAndActiveViews_name:
        var r = WindowManagerGetFocusedAndActiveViewsResponseParams.deserialize(
            message.payload);
        if (!message.header.hasRequestId) {
          throw 'Expected a message with a valid request Id.';
        }
        Completer c = completerMap[message.header.requestId];
        if (c == null) {
          throw 'Message had unknown request Id: ${message.header.requestId}';
        }
        completerMap.remove(message.header.requestId);
        assert(!c.isCompleted);
        c.complete(r);
        break;
      default:
        throw new bindings.MojoCodecError("Unexpected message name");
        break;
    }
  }

  String toString() {
    var superString = super.toString();
    return "WindowManagerProxyImpl($superString)";
  }
}


class _WindowManagerProxyCalls implements WindowManager {
  WindowManagerProxyImpl _proxyImpl;

  _WindowManagerProxyCalls(this._proxyImpl);
    void embed(String url, Object services, Object exposedServices) {
      assert(_proxyImpl.isBound);
      var params = new WindowManagerEmbedParams();
      params.url = url;
      params.services = services;
      params.exposedServices = exposedServices;
      _proxyImpl.sendMessage(params, kWindowManager_embed_name);
    }
  
    Future<WindowManagerSetCaptureResponseParams> setCapture(int viewId,[Function responseFactory = null]) {
      assert(_proxyImpl.isBound);
      var params = new WindowManagerSetCaptureParams();
      params.viewId = viewId;
      return _proxyImpl.sendMessageWithRequestId(
          params,
          kWindowManager_setCapture_name,
          -1,
          bindings.MessageHeader.kMessageExpectsResponse);
    }
    Future<WindowManagerFocusWindowResponseParams> focusWindow(int viewId,[Function responseFactory = null]) {
      assert(_proxyImpl.isBound);
      var params = new WindowManagerFocusWindowParams();
      params.viewId = viewId;
      return _proxyImpl.sendMessageWithRequestId(
          params,
          kWindowManager_focusWindow_name,
          -1,
          bindings.MessageHeader.kMessageExpectsResponse);
    }
    Future<WindowManagerActivateWindowResponseParams> activateWindow(int viewId,[Function responseFactory = null]) {
      assert(_proxyImpl.isBound);
      var params = new WindowManagerActivateWindowParams();
      params.viewId = viewId;
      return _proxyImpl.sendMessageWithRequestId(
          params,
          kWindowManager_activateWindow_name,
          -1,
          bindings.MessageHeader.kMessageExpectsResponse);
    }
    Future<WindowManagerGetFocusedAndActiveViewsResponseParams> getFocusedAndActiveViews(Object observer,[Function responseFactory = null]) {
      assert(_proxyImpl.isBound);
      var params = new WindowManagerGetFocusedAndActiveViewsParams();
      params.observer = observer;
      return _proxyImpl.sendMessageWithRequestId(
          params,
          kWindowManager_getFocusedAndActiveViews_name,
          -1,
          bindings.MessageHeader.kMessageExpectsResponse);
    }
}


class WindowManagerProxy implements bindings.ProxyBase {
  final bindings.Proxy impl;
  WindowManager ptr;
  final String name = WindowManagerName;

  WindowManagerProxy(WindowManagerProxyImpl proxyImpl) :
      impl = proxyImpl,
      ptr = new _WindowManagerProxyCalls(proxyImpl);

  WindowManagerProxy.fromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) :
      impl = new WindowManagerProxyImpl.fromEndpoint(endpoint) {
    ptr = new _WindowManagerProxyCalls(impl);
  }

  WindowManagerProxy.fromHandle(core.MojoHandle handle) :
      impl = new WindowManagerProxyImpl.fromHandle(handle) {
    ptr = new _WindowManagerProxyCalls(impl);
  }

  WindowManagerProxy.unbound() :
      impl = new WindowManagerProxyImpl.unbound() {
    ptr = new _WindowManagerProxyCalls(impl);
  }

  static WindowManagerProxy newFromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) =>
      new WindowManagerProxy.fromEndpoint(endpoint);

  Future close({bool immediate: false}) => impl.close(immediate: immediate);

  String toString() {
    return "WindowManagerProxy($impl)";
  }
}


class WindowManagerStub extends bindings.Stub {
  WindowManager _impl = null;

  WindowManagerStub.fromEndpoint(
      core.MojoMessagePipeEndpoint endpoint, [this._impl])
      : super.fromEndpoint(endpoint);

  WindowManagerStub.fromHandle(core.MojoHandle handle, [this._impl])
      : super.fromHandle(handle);

  WindowManagerStub.unbound() : super.unbound();

  static WindowManagerStub newFromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) =>
      new WindowManagerStub.fromEndpoint(endpoint);

  static const String name = WindowManagerName;


  WindowManagerSetCaptureResponseParams _WindowManagerSetCaptureResponseParamsFactory(bool success) {
    var result = new WindowManagerSetCaptureResponseParams();
    result.success = success;
    return result;
  }
  WindowManagerFocusWindowResponseParams _WindowManagerFocusWindowResponseParamsFactory(bool success) {
    var result = new WindowManagerFocusWindowResponseParams();
    result.success = success;
    return result;
  }
  WindowManagerActivateWindowResponseParams _WindowManagerActivateWindowResponseParamsFactory(bool success) {
    var result = new WindowManagerActivateWindowResponseParams();
    result.success = success;
    return result;
  }
  WindowManagerGetFocusedAndActiveViewsResponseParams _WindowManagerGetFocusedAndActiveViewsResponseParamsFactory(int captureViewId, int focusedViewId, int activeViewId) {
    var result = new WindowManagerGetFocusedAndActiveViewsResponseParams();
    result.captureViewId = captureViewId;
    result.focusedViewId = focusedViewId;
    result.activeViewId = activeViewId;
    return result;
  }

  Future<bindings.Message> handleMessage(bindings.ServiceMessage message) {
    assert(_impl != null);
    switch (message.header.type) {
      case kWindowManager_embed_name:
        var params = WindowManagerEmbedParams.deserialize(
            message.payload);
        _impl.embed(params.url, params.services, params.exposedServices);
        break;
      case kWindowManager_setCapture_name:
        var params = WindowManagerSetCaptureParams.deserialize(
            message.payload);
        return _impl.setCapture(params.viewId,_WindowManagerSetCaptureResponseParamsFactory).then((response) {
          if (response != null) {
            return buildResponseWithId(
                response,
                kWindowManager_setCapture_name,
                message.header.requestId,
                bindings.MessageHeader.kMessageIsResponse);
          }
        });
        break;
      case kWindowManager_focusWindow_name:
        var params = WindowManagerFocusWindowParams.deserialize(
            message.payload);
        return _impl.focusWindow(params.viewId,_WindowManagerFocusWindowResponseParamsFactory).then((response) {
          if (response != null) {
            return buildResponseWithId(
                response,
                kWindowManager_focusWindow_name,
                message.header.requestId,
                bindings.MessageHeader.kMessageIsResponse);
          }
        });
        break;
      case kWindowManager_activateWindow_name:
        var params = WindowManagerActivateWindowParams.deserialize(
            message.payload);
        return _impl.activateWindow(params.viewId,_WindowManagerActivateWindowResponseParamsFactory).then((response) {
          if (response != null) {
            return buildResponseWithId(
                response,
                kWindowManager_activateWindow_name,
                message.header.requestId,
                bindings.MessageHeader.kMessageIsResponse);
          }
        });
        break;
      case kWindowManager_getFocusedAndActiveViews_name:
        var params = WindowManagerGetFocusedAndActiveViewsParams.deserialize(
            message.payload);
        return _impl.getFocusedAndActiveViews(params.observer,_WindowManagerGetFocusedAndActiveViewsResponseParamsFactory).then((response) {
          if (response != null) {
            return buildResponseWithId(
                response,
                kWindowManager_getFocusedAndActiveViews_name,
                message.header.requestId,
                bindings.MessageHeader.kMessageIsResponse);
          }
        });
        break;
      default:
        throw new bindings.MojoCodecError("Unexpected message name");
        break;
    }
    return null;
  }

  WindowManager get impl => _impl;
      set impl(WindowManager d) {
    assert(_impl == null);
    _impl = d;
  }

  String toString() {
    var superString = super.toString();
    return "WindowManagerStub($superString)";
  }
}

const int kWindowManagerObserver_onCaptureChanged_name = 0;
const int kWindowManagerObserver_onFocusChanged_name = 1;
const int kWindowManagerObserver_onActiveWindowChanged_name = 2;

const String WindowManagerObserverName =
      'mojo::WindowManagerObserver';

abstract class WindowManagerObserver {
  void onCaptureChanged(int captureViewId);
  void onFocusChanged(int focusedViewId);
  void onActiveWindowChanged(int focusedViewId);

}


class WindowManagerObserverProxyImpl extends bindings.Proxy {
  WindowManagerObserverProxyImpl.fromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) : super.fromEndpoint(endpoint);

  WindowManagerObserverProxyImpl.fromHandle(core.MojoHandle handle) :
      super.fromHandle(handle);

  WindowManagerObserverProxyImpl.unbound() : super.unbound();

  static WindowManagerObserverProxyImpl newFromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) =>
      new WindowManagerObserverProxyImpl.fromEndpoint(endpoint);

  String get name => WindowManagerObserverName;

  void handleResponse(bindings.ServiceMessage message) {
    switch (message.header.type) {
      default:
        throw new bindings.MojoCodecError("Unexpected message name");
        break;
    }
  }

  String toString() {
    var superString = super.toString();
    return "WindowManagerObserverProxyImpl($superString)";
  }
}


class _WindowManagerObserverProxyCalls implements WindowManagerObserver {
  WindowManagerObserverProxyImpl _proxyImpl;

  _WindowManagerObserverProxyCalls(this._proxyImpl);
    void onCaptureChanged(int captureViewId) {
      assert(_proxyImpl.isBound);
      var params = new WindowManagerObserverOnCaptureChangedParams();
      params.captureViewId = captureViewId;
      _proxyImpl.sendMessage(params, kWindowManagerObserver_onCaptureChanged_name);
    }
  
    void onFocusChanged(int focusedViewId) {
      assert(_proxyImpl.isBound);
      var params = new WindowManagerObserverOnFocusChangedParams();
      params.focusedViewId = focusedViewId;
      _proxyImpl.sendMessage(params, kWindowManagerObserver_onFocusChanged_name);
    }
  
    void onActiveWindowChanged(int focusedViewId) {
      assert(_proxyImpl.isBound);
      var params = new WindowManagerObserverOnActiveWindowChangedParams();
      params.focusedViewId = focusedViewId;
      _proxyImpl.sendMessage(params, kWindowManagerObserver_onActiveWindowChanged_name);
    }
  
}


class WindowManagerObserverProxy implements bindings.ProxyBase {
  final bindings.Proxy impl;
  WindowManagerObserver ptr;
  final String name = WindowManagerObserverName;

  WindowManagerObserverProxy(WindowManagerObserverProxyImpl proxyImpl) :
      impl = proxyImpl,
      ptr = new _WindowManagerObserverProxyCalls(proxyImpl);

  WindowManagerObserverProxy.fromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) :
      impl = new WindowManagerObserverProxyImpl.fromEndpoint(endpoint) {
    ptr = new _WindowManagerObserverProxyCalls(impl);
  }

  WindowManagerObserverProxy.fromHandle(core.MojoHandle handle) :
      impl = new WindowManagerObserverProxyImpl.fromHandle(handle) {
    ptr = new _WindowManagerObserverProxyCalls(impl);
  }

  WindowManagerObserverProxy.unbound() :
      impl = new WindowManagerObserverProxyImpl.unbound() {
    ptr = new _WindowManagerObserverProxyCalls(impl);
  }

  static WindowManagerObserverProxy newFromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) =>
      new WindowManagerObserverProxy.fromEndpoint(endpoint);

  Future close({bool immediate: false}) => impl.close(immediate: immediate);

  String toString() {
    return "WindowManagerObserverProxy($impl)";
  }
}


class WindowManagerObserverStub extends bindings.Stub {
  WindowManagerObserver _impl = null;

  WindowManagerObserverStub.fromEndpoint(
      core.MojoMessagePipeEndpoint endpoint, [this._impl])
      : super.fromEndpoint(endpoint);

  WindowManagerObserverStub.fromHandle(core.MojoHandle handle, [this._impl])
      : super.fromHandle(handle);

  WindowManagerObserverStub.unbound() : super.unbound();

  static WindowManagerObserverStub newFromEndpoint(
      core.MojoMessagePipeEndpoint endpoint) =>
      new WindowManagerObserverStub.fromEndpoint(endpoint);

  static const String name = WindowManagerObserverName;



  Future<bindings.Message> handleMessage(bindings.ServiceMessage message) {
    assert(_impl != null);
    switch (message.header.type) {
      case kWindowManagerObserver_onCaptureChanged_name:
        var params = WindowManagerObserverOnCaptureChangedParams.deserialize(
            message.payload);
        _impl.onCaptureChanged(params.captureViewId);
        break;
      case kWindowManagerObserver_onFocusChanged_name:
        var params = WindowManagerObserverOnFocusChangedParams.deserialize(
            message.payload);
        _impl.onFocusChanged(params.focusedViewId);
        break;
      case kWindowManagerObserver_onActiveWindowChanged_name:
        var params = WindowManagerObserverOnActiveWindowChangedParams.deserialize(
            message.payload);
        _impl.onActiveWindowChanged(params.focusedViewId);
        break;
      default:
        throw new bindings.MojoCodecError("Unexpected message name");
        break;
    }
    return null;
  }

  WindowManagerObserver get impl => _impl;
      set impl(WindowManagerObserver d) {
    assert(_impl == null);
    _impl = d;
  }

  String toString() {
    var superString = super.toString();
    return "WindowManagerObserverStub($superString)";
  }
}


