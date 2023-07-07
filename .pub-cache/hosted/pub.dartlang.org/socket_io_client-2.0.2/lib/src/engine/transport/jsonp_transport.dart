import 'dart:async';
import 'dart:html';
import 'dart:js' hide JsArray;
import 'package:js/js_util.dart';
import 'package:socket_io_client/src/engine/transport/polling_transport.dart';

import 'js_array.dart';

/// jsonp_transport.dart
///
/// Purpose:
///
/// Description:
///
/// History:
///   26/04/2017, Created by jumperchen
///
/// Copyright (C) 2017 Potix Corporation. All Rights Reserved.

///
/// Cached regular expressions.
final RegExp rNewline = RegExp(r'\n');
final RegExp rEscapedNewline = RegExp(r'\\n');

///
/// Global JSONP callbacks.
var callbacks;

class JSONPTransport extends PollingTransport {
//  static var empty = (_) => '';
  late int index;
  ScriptElement? script;
  FormElement? form;
  IFrameElement? iframe;
  TextAreaElement? area;
  String? iframeId;

  ///
  /// JSONP Polling constructor.
  ///
  /// @param {Object} opts.
  /// @api public
  JSONPTransport(Map opts) : super(opts) {
    query ??= {};

    // define global callbacks array if not present
    // we do this here (lazily) to avoid unneeded global pollution
    if (callbacks == null) {
      // we need to consider multiple engines in the same page
      if (getProperty(self, '___eio') == null) {
        setProperty(self, '___eio', JsArray());
      }
      callbacks = getProperty(self, '___eio');
    }

    // callback identifier
    index = callbacks.length;

    // add callback to jsonp global
    callMethod(callbacks, 'push', [
      allowInterop((msg) {
        onData(msg);
      })
    ]);

    // append to query string
    query!['j'] = index;

    // prevent spurious errors from being emitted when the window is unloaded
//    if (window.document != null && window.addEventListener != null) {
//      window.addEventListener('beforeunload', (_) {
////      if (script != null) script.onError.listen(empty);
//      }, false);
//    }
  }

  /// JSONP only supports binary as base64 encoded strings
  @override
  bool? supportsBinary = false;

  ///
  /// Closes the socket.
  ///
  /// @api private
  @override
  void doClose() {
    if (script != null) {
      script!.remove();
      script = null;
    }

    if (form != null) {
      form!.remove();
      form = null;
      iframe = null;
    }
    super.doClose();
  }

  ///
  /// Starts a poll cycle.
  ///
  /// @api private
  @override
  void doPoll() {
    var script = document.createElement('script') as ScriptElement;

    this.script?.remove();
    this.script = null;

    script.async = true;
    script.src = uri();
    script.onError.listen((e) {
      onError('jsonp poll error');
    });

    var scripts = document.getElementsByTagName('script');
    var insertAt = scripts.isNotEmpty ? scripts.first as ScriptElement : null;
    if (insertAt != null) {
      insertAt.parentNode!.insertBefore(script, insertAt);
    } else {
      (document.head ?? document.body!).append(script);
    }
    this.script = script;

    var isUAgecko = window.navigator.userAgent.contains('gecko');

    if (isUAgecko) {
      Timer(Duration(milliseconds: 100), () {
        var iframe = document.createElement('iframe');
        document.body!.append(iframe);
        iframe.remove();
      });
    }
  }

  ///
  /// Writes with a hidden iframe.
  ///
  /// @param {String} data to send
  /// @param {Function} called upon flush.
  /// @api private
  @override
  void doWrite(data, fn) {
    if (form == null) {
      var form = document.createElement('form') as FormElement;
      var area = document.createElement('textarea') as TextAreaElement;
      var id = iframeId = 'eio_iframe_$index';

      form.className = 'socketio';
      form.style.position = 'absolute';
      form.style.top = '-1000px';
      form.style.left = '-1000px';
      form.target = id;
      form.method = 'POST';
      form.setAttribute('accept-charset', 'utf-8');
      area.name = 'd';
      form.append(area);
      document.body!.append(form);

      this.form = form;
      this.area = area;
    }

    form!.action = uri();

    var initIframe = () {
      if (iframe != null) {
        try {
          iframe!.remove();
        } catch (e) {
          onError('jsonp polling iframe removal error', e);
        }
      }

      iframe = document.createElement('iframe') as IFrameElement;
      iframe!.name = iframeId;
      iframe!.src = 'javascript:0';

      iframe!.id = iframeId!;

      form!.append(iframe!);
      iframe = iframe;
    };

    initIframe();

    // escape \n to prevent it from being converted into \r\n by some UAs
    // double escaping is required for escaped new lines because unescaping of new lines can be done safely on server-side
    data = data.replaceAll(rEscapedNewline, '\\\n');
    area!.value = data.replaceAll(rNewline, '\\n');

    try {
      form!.submit();
    } catch (e) {
      //ignore
    }

    iframe!.onLoad.listen((_) {
      initIframe();
      fn(_);
    });
  }
}
