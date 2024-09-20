// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart._debugger;

import 'dart:_foreign_helper' show JS;
import 'dart:_interceptors' show JSArray;
import 'dart:_js_helper' show InternalMap, jsObjectGetPrototypeOf;
import 'dart:_foreign_helper' show JS_GET_FLAG, JS_GET_NAME;
import 'dart:_js_shared_embedded_names' show JsGetName;
import 'dart:_runtime' as dart;
import 'dart:core';
import 'dart:collection';
import 'dart:math';

part 'profile.dart';

/// JsonMLConfig object to pass to devtools to specify how an Object should
/// be displayed. skipDart signals that an object should not be formatted
/// by the Dart formatter. This is used to specify that an Object
/// should just be displayed using the regular JavaScript view instead of a
/// custom Dart view. For example, this is used to display the JavaScript view
/// of a Dart Function as a child of the regular Function object. keyToString
/// signals that a map key object should have its toString() displayed by
/// the Dart formatter.
///
/// We'd like this to be an enum, but we can't because it's a dev_compiler bug.
class JsonMLConfig {
  const JsonMLConfig(this.name);

  final String name;
  static const none = JsonMLConfig("none");
  static const skipDart = JsonMLConfig("skipDart");
  static const keyToString = JsonMLConfig("keyToString");
  static const asClass = JsonMLConfig("asClass");
  static const asObject = JsonMLConfig("asObject");
  static const asMap = JsonMLConfig("asMap");
  toString() => "JsonMLConfig($name)";
}

int _maxSpanLength = 100;
var _devtoolsFormatter = JsonMLFormatter(DartFormatter());

/// We truncate a toString() longer than [maxStringLength].
int maxFormatterStringLength = 100;

String _typeof(object) => JS<String>('!', 'typeof #', object);

List<String> getOwnPropertyNames(Object object) =>
    JSArray<String>.of(dart.getOwnPropertyNames(object));

List getOwnPropertySymbols(object) =>
    JS('List', 'Object.getOwnPropertySymbols(#)', object);

// TODO(jacobr): move this to dart:js and fully implement.
class JSNative {
  // Name may be a String or a Symbol.
  static getProperty(object, name) => JS('', '#[#]', object, name);
  // Name may be a String or a Symbol.
  static setProperty(object, name, value) =>
      JS('', '#[#]=#', object, name, value);
}

void addMetadataChildren(object, Set<NameValuePair> ret) {
  ret.add(NameValuePair(
      name: "[[class]]",
      value: dart.getClass(object),
      config: JsonMLConfig.asClass));
}

/// Add properties from a signature definition [sig] for [object].
/// Walk the prototype chain if [walkProtypeChain] is set.
/// Tag types on function typed properties of [object] if [tagTypes] is set.
///
void addPropertiesFromSignature(
    sig, Set<NameValuePair> properties, object, bool walkPrototypeChain,
    {tagTypes = false}) {
  // Including these property names doesn't add any value and just clutters
  // the debugger output.
  // TODO(jacobr): consider adding runtimeType to this list.
  var skippedNames = Set()..add('hashCode');
  var objectPrototype = JS('', 'Object.prototype');
  while (sig != null && !identical(sig, objectPrototype)) {
    for (var symbol in getOwnPropertySymbols(sig)) {
      var dartName = symbolName(symbol);
      String dartXPrefix = 'dartx.';
      if (dartName.startsWith(dartXPrefix)) {
        dartName = dartName.substring(dartXPrefix.length);
      }
      if (skippedNames.contains(dartName)) continue;
      var value = safeGetProperty(object, symbol);
      // Tag the function with its runtime type.
      if (tagTypes && _typeof(value) == 'function') {
        dart.fn(value, JS('', '#[#]', sig, symbol));
      }
      properties.add(NameValuePair(name: dartName, value: value));
    }

    for (var name in getOwnPropertyNames(sig)) {
      var value = safeGetProperty(object, name);
      if (skippedNames.contains(name)) continue;
      // Tag the function with its runtime type.
      if (tagTypes && _typeof(value) == 'function') {
        dart.fn(value, JS('', '#[#]', sig, name));
      }
      properties.add(NameValuePair(name: name, value: value));
    }

    if (!walkPrototypeChain) break;

    sig = dart.getPrototypeOf(sig);
  }
}

/// Sort properties sorting public names before private names.
List<NameValuePair> sortProperties(Iterable<NameValuePair> properties) {
  var sortedProperties = properties.toList();

  sortedProperties.sort((a, b) {
    var aPrivate = a.name.startsWith('_');
    var bPrivate = b.name.startsWith('_');
    if (aPrivate != bPrivate) return aPrivate ? 1 : -1;
    return a.name.compareTo(b.name);
  });
  return sortedProperties;
}

String getObjectTypeName(object) {
  var reifiedType = dart.getReifiedType(object);
  if (reifiedType == null) {
    if (_typeof(object) == 'function') {
      return '[[Raw JavaScript Function]]';
    }
    return '<Error getting type name>';
  }
  return getTypeName(reifiedType);
}

/// Replaces names of Dart classes/types with a more user friendly version.
///
/// Strictly a string replacement so we display a more helpful string in the
/// formatter output.
String _hideInternalNames(String name) {
// Replace all 'JSArray' with 'List' to make it appear more "Dart friendly"
  final jsArrayClassName = RegExp(r'\bJSArray\b');
  return name.replaceAll(jsArrayClassName, 'List');
}

String getTypeName(type) {
  // TODO(jacobr): it would be nice if there was a way we could distinguish
  // between a List<dynamic> created from Dart and an Array passed in from
  // JavaScript.
  return _hideInternalNames(dart.typeName(type));
}

String safePreview(object, config) {
  try {
    var preview = _devtoolsFormatter._simpleFormatter.preview(object, config);
    if (preview != null) return preview;
    return object.toString();
  } catch (e) {
    return '<Exception thrown> $e';
  }
}

String symbolName(symbol) {
  var name = symbol.toString();
  assert(name.startsWith('Symbol('));
  return name.substring('Symbol('.length, name.length - 1);
}

bool hasMethod(object, String name) {
  try {
    return dart.hasMethod(object, name);
  } catch (e) {
    return false;
  }
}

/// [JsonMLFormatter] consumes [NameValuePair] objects and
class NameValuePair {
  NameValuePair(
      {this.name = '',
      this.value,
      this.config = JsonMLConfig.none,
      this.hideName = false});

  // Define equality and hashCode so that NameValuePair can be used
  // in a Set to dedupe entries with duplicate names.
  bool operator ==(other) {
    if (other is! NameValuePair) return false;
    if (this.hideName || other.hideName) return identical(this, other);
    return other.name == name;
  }

  int get hashCode => name.hashCode;

  final String name;
  final Object? value;
  final JsonMLConfig config;
  final bool hideName;

  String get displayName => hideName ? '' : name;
}

class MapEntry {
  MapEntry({this.key, this.value});

  final Object? key;
  final Object? value;
}

class IterableSpan {
  IterableSpan(this.start, this.end, this.iterable);

  final int start;
  final int end;
  final Iterable iterable;
  int get length => end - start;

  /// Using length - .5, a list of length 10000 results in a
  /// maxPowerOfSubsetSize of 1, so the list will be broken up into 100,
  /// 100-length subsets. A list of length 10001 results in a
  /// maxPowerOfSubsetSize of 2, so the list will be broken up into 1
  /// 10000-length subset and 1 1-length subset.
  int get maxPowerOfSubsetSize =>
      (log(length - .5) / log(_maxSpanLength)).truncate();
  int get subsetSize => pow(_maxSpanLength, maxPowerOfSubsetSize).toInt();

  Map<int, dynamic> asMap() =>
      iterable.skip(start).take(length).toList().asMap();

  List<NameValuePair> children() {
    var children = <NameValuePair>[];
    if (length <= _maxSpanLength) {
      asMap().forEach((i, element) {
        children
            .add(NameValuePair(name: (i + start).toString(), value: element));
      });
    } else {
      for (var i = start; i < end; i += subsetSize) {
        var subSpan = IterableSpan(i, min(end, subsetSize + i), iterable);
        if (subSpan.length == 1) {
          children.add(
              NameValuePair(name: i.toString(), value: iterable.elementAt(i)));
        } else {
          children.add(NameValuePair(
              name: '[${i}...${subSpan.end - 1}]',
              value: subSpan,
              hideName: true));
        }
      }
    }
    return children;
  }
}

class Library {
  Library(this.name, this.object);

  final String name;
  final Object object;
}

class NamedConstructor {
  NamedConstructor(this.object);

  final Object object;
}

class HeritageClause {
  HeritageClause(this.name, this.types);

  final String name;
  final List types;
}

Object? safeGetProperty(Object protoChain, Object name) {
  try {
    return JSNative.getProperty(protoChain, name);
  } catch (e) {
    return '<Exception thrown> $e';
  }
}

safeProperties(object) => Map.fromIterable(
    getOwnPropertyNames(object)
        .where((each) => safeGetProperty(object, each) != null),
    key: (name) => name,
    value: (name) => safeGetProperty(object, name));

/// Class to simplify building the JsonML objects expected by the
/// Devtools Formatter API.
class JsonMLElement {
  dynamic _attributes;
  late List _jsonML;

  JsonMLElement(tagName) {
    _attributes = JS('', '{}');
    _jsonML = [tagName, _attributes];
  }

  appendChild(element) {
    _jsonML.add(element.toJsonML());
  }

  JsonMLElement createChild(String tagName) {
    var c = JsonMLElement(tagName);
    _jsonML.add(c.toJsonML());
    return c;
  }

  JsonMLElement createObjectTag(object) =>
      createChild('object')..addAttribute('object', object);

  void setStyle(String style) {
    _attributes.style = style;
  }

  addStyle(String style) {
    if (_attributes.style == null) {
      _attributes.style = style;
    } else {
      _attributes.style += style;
    }
  }

  addAttribute(key, value) {
    JSNative.setProperty(_attributes, key, value);
  }

  createTextChild(String text) {
    _jsonML.add(text);
  }

  toJsonML() => _jsonML;
}

/// Returns `true` when [object] should display the JavaScript view of the
/// object instead of the custom Dart specific render of properties.
bool _useNativeJSFormatter(object) {
  var type = _typeof(object);
  if (type != 'object' && type != 'function') return true;
  if (dart.isDartClass(object) || dart.isDartFunction(object)) return false;

  // Consider all regular JS objects that do not represent Dart modules native
  // JavaScript objects.
  if (dart.isJsInterop(object) && dart.getModuleName(object) == null) {
    return true;
  }

  // Treat Node objects as a native JavaScript type as the regular DOM render
  // in devtools is superior to the dart specific view.
  return JS<bool>('!', '# instanceof Node', object);
}

/// Class implementing the Devtools Formatter API described by:
/// https://docs.google.com/document/d/1FTascZXT9cxfetuPRT2eXPQKXui4nWFivUnS_335T3U
/// Specifically, a formatter implements a header, hasBody, and body method.
/// This class renders the simple structured format objects [_simpleFormatter]
/// provides as JsonML.
class JsonMLFormatter {
  // TODO(jacobr): define a SimpleFormatter base class that DartFormatter
  // implements if we decide to use this class elsewhere. We specify that the
  // type is DartFormatter here purely to get type checking benefits not because
  // this class is really intended to only support instances of type
  // DartFormatter.
  DartFormatter _simpleFormatter;

  bool customFormattersOn = false;

  JsonMLFormatter(this._simpleFormatter);

  void setMaxSpanLengthForTestingOnly(int spanLength) {
    _maxSpanLength = spanLength;
  }

  header(object, config) {
    customFormattersOn = true;
    if (config == JsonMLConfig.skipDart || _useNativeJSFormatter(object)) {
      return null;
    }
    var c = _simpleFormatter.preview(object, config);
    if (c == null) return null;

    if (config == JsonMLConfig.keyToString) {
      c = object.toString();
    }

    // Indicate this is a Dart Object by using a Dart background color.
    // This is stylistically a bit ugly but it eases distinguishing Dart and
    // JS objects.
    var element = JsonMLElement('span')
      ..setStyle('background-color: #d9edf7;color: black')
      ..createTextChild(c);
    return element.toJsonML();
  }

  bool hasBody(object, config) => _simpleFormatter.hasChildren(object, config);

  body(object, config) {
    var body = JsonMLElement('ol')
      ..setStyle('list-style-type: none;'
          'padding-left: 0px;'
          'margin-top: 0px;'
          'margin-bottom: 0px;'
          'margin-left: 12px;');
    if (object is StackTrace) {
      body.addStyle('background-color: thistle;color: rgb(196, 26, 22);');
    }
    var children = _simpleFormatter.children(object, config);
    if (children == null) return body.toJsonML();
    for (NameValuePair child in children) {
      var li = body.createChild('li');
      li.setStyle("padding-left: 13px;");

      // The value is indented when it is on a different line from the name
      // by setting right padding of the name to -13px and the padding of the
      // value to 13px.
      JsonMLElement? nameSpan;
      var valueStyle = '';
      if (!child.hideName) {
        nameSpan = JsonMLElement('span')
          ..createTextChild(
              child.displayName.isNotEmpty ? '${child.displayName}: ' : '')
          ..setStyle(
              'background-color: thistle; color: rgb(136, 19, 145); margin-right: -13px');
        valueStyle = 'margin-left: 13px';
      }

      if (_typeof(child.value) == 'object' ||
          _typeof(child.value) == 'function') {
        var valueSpan = JsonMLElement('span')..setStyle(valueStyle);
        valueSpan
            .createObjectTag(child.value)
            .addAttribute('config', child.config);
        if (nameSpan != null) {
          li.appendChild(nameSpan);
        }
        li.appendChild(valueSpan);
      } else {
        var line = li.createChild('span');
        if (nameSpan != null) {
          line.appendChild(nameSpan);
        }
        line.appendChild(JsonMLElement('span')
          ..createTextChild(safePreview(child.value, child.config))
          ..setStyle(valueStyle));
      }
    }
    return body.toJsonML();
  }
}

abstract class Formatter {
  bool accept(object, config);
  String? preview(object);
  bool hasChildren(object);
  List<NameValuePair>? children(object);
}

class DartFormatter {
  final List<Formatter> _formatters;

  DartFormatter()
      : _formatters = [
          // Formatters earlier in the list take precedence.
          ObjectInternalsFormatter(),
          ClassFormatter(),
          TypeFormatter(),
          NamedConstructorFormatter(),
          MapFormatter(),
          MapOverviewFormatter(),
          IterableFormatter(),
          IterableSpanFormatter(),
          MapEntryFormatter(),
          StackTraceFormatter(),
          ErrorAndExceptionFormatter(),
          FunctionFormatter(),
          HeritageClauseFormatter(),
          LibraryModuleFormatter(),
          LibraryFormatter(),
          ObjectFormatter(),
        ];

  String? preview(object, config) {
    try {
      if (object == null ||
          object is num ||
          object is String ||
          _useNativeJSFormatter(object)) {
        return object.toString();
      }
      for (var formatter in _formatters) {
        if (formatter.accept(object, config)) return formatter.preview(object);
      }
    } catch (e, trace) {
      // Log formatter internal errors as unfortunately the devtools cannot
      // be used to debug formatter errors.
      _printConsoleError("Caught exception $e\n trace:\n$trace");
    }

    return null;
  }

  bool hasChildren(object, config) {
    if (object == null) return false;
    try {
      for (var formatter in _formatters) {
        if (formatter.accept(object, config))
          return formatter.hasChildren(object);
      }
    } catch (e, trace) {
      // See comment for preview.
      _printConsoleError("[hasChildren] Caught exception $e\n trace:\n$trace");
    }
    return false;
  }

  List<NameValuePair>? children(object, config) {
    try {
      if (object != null) {
        for (var formatter in _formatters) {
          if (formatter.accept(object, config))
            return formatter.children(object);
        }
      }
    } catch (e, trace) {
      // See comment for preview.
      _printConsoleError("Caught exception $e\n trace:\n$trace");
    }
    return <NameValuePair>[];
  }

  void _printConsoleError(String message) =>
      JS('', 'window.console.error(#)', message);
}

/// Default formatter for Dart Objects.
class ObjectFormatter extends Formatter {
  bool accept(object, config) => !_useNativeJSFormatter(object);

  String preview(object) {
    var typeName = getObjectTypeName(object);
    try {
      // An explicit toString() call might not actually be a string. This way
      // we're sure.
      var toString = "$object";
      if (toString.length > maxFormatterStringLength) {
        toString = toString.substring(0, maxFormatterStringLength - 3) + "...";
      }
      // The default toString() will be "Instance of 'Foo'", in which case we
      // don't need any further indication of the class.
      if (toString.contains(typeName)) {
        return toString;
      } else {
        // If there's no class indication, e.g. an Int64 that just prints as a
        // number, then add the class name.
        return "$toString ($typeName)";
      }
    } catch (e) {}
    // We will only get here if there was an error getting the toString, in
    // which case we just use the type name.
    return typeName;
  }

  bool hasChildren(object) => true;

  children(object) {
    var type = dart.getType(object);
    var ret = LinkedHashSet<NameValuePair>();
    // We use a Set rather than a List to avoid duplicates.
    var fields = Set<NameValuePair>();
    addPropertiesFromSignature(dart.getFields(type), fields, object, true);
    var getters = Set<NameValuePair>();
    addPropertiesFromSignature(dart.getGetters(type), getters, object, true);
    ret.addAll(sortProperties(fields));
    ret.addAll(sortProperties(getters));
    addMetadataChildren(object, ret);
    return ret.toList();
  }
}

/// Show the object instance members and a reduced preview.
///
/// Used as a sub-entry to show the internals of objects that have a different
/// primary format. For example, a Map shows the key-value pairs, but this makes
/// the internals of the map visible for debugging.
class ObjectInternalsFormatter extends ObjectFormatter {
  bool accept(object, config) =>
      super.accept(object, config) && config == JsonMLConfig.asObject;

  // A minimal preview because we expect a full preview is already shown in a
  // parent formatter.
  String preview(object) {
    return getObjectTypeName(object);
  }
}

/// Formatter for module Dart Library objects.
class LibraryModuleFormatter implements Formatter {
  bool accept(object, config) => dart.getModuleName(object) != null;

  bool hasChildren(object) => true;

  String preview(object) {
    var libraryNames = dart.getModuleName(object)!.split('/');
    // Library names are received with a repeat directory name, so strip the
    // last directory entry here to make the path cleaner. For example, the
    // library "third_party/dart/utf/utf" should display as
    // "third_party/dart/utf/".
    if (libraryNames.length > 1 &&
        libraryNames.last == libraryNames[libraryNames.length - 2]) {
      libraryNames[libraryNames.length - 1] = '';
    }
    return 'Library Module: ${libraryNames.join('/')}';
  }

  List<NameValuePair> children(object) {
    var children = LinkedHashSet<NameValuePair>();
    for (var name in getOwnPropertyNames(object)) {
      var value = safeGetProperty(object, name);
      children.add(NameValuePair(
          name: name, value: Library(name, value!), hideName: true));
    }
    return children.toList();
  }
}

class LibraryFormatter implements Formatter {
  var genericParameters = HashMap<String, String>();

  bool accept(object, config) => object is Library;

  bool hasChildren(object) => true;

  String preview(object) => object.name;

  List<NameValuePair> children(object) {
    // Maintain library member order rather than sorting members as is the
    // case for class members.
    var children = LinkedHashSet<NameValuePair>();
    var objectProperties = safeProperties(object.object);
    objectProperties.forEach((name, value) {
      // Skip the generic constructors for each class as users are only
      // interested in seeing the actual classes.
      if (dart.getGenericTypeCtor(value) != null) return;

      children.add(dart.isDartClass(value)
          ? classChild(name, value)
          : NameValuePair(name: name, value: value));
    });
    return children.toList();
  }

  classChild(String name, Object child) {
    var className = _hideInternalNames(dart.getClassName(child));
    return NameValuePair(
        name: className, value: child, config: JsonMLConfig.asClass);
  }
}

/// Formatter for Dart Function objects.
/// Dart functions happen to be regular JavaScript Function objects but
/// we can distinguish them based on whether they have been tagged with
/// runtime type information.
class FunctionFormatter implements Formatter {
  bool accept(object, config) => dart.isDartFunction(object);

  bool hasChildren(object) => true;

  String preview(object) {
    // The debugger can create a preview of a FunctionType while it's being
    // constructed (before argument types exist), so we need to catch errors.
    try {
      return getTypeName(dart.getReifiedType(object));
    } catch (e) {
      return safePreview(object, JsonMLConfig.none);
    }
  }

  List<NameValuePair> children(object) => <NameValuePair>[
        NameValuePair(name: 'signature', value: preview(object)),
        NameValuePair(
            name: 'JavaScript Function',
            value: object,
            config: JsonMLConfig.skipDart)
      ];
}

/// Formatter for Objects that implement Map but are not system Maps.
///
/// This shows two sub-views, one for instance fields and one for
/// Map key/value pairs.
class MapOverviewFormatter implements Formatter {
  // Because this comes after MapFormatter in the list, internal
  // maps will be picked up by that formatter.
  bool accept(object, config) => object is Map;

  bool hasChildren(object) => true;

  String preview(object) {
    Map map = object;
    try {
      return '${getObjectTypeName(map)}';
    } catch (e) {
      return safePreview(object, JsonMLConfig.none);
    }
  }

  List<NameValuePair> children(object) => [
        NameValuePair(
            name: "[[instance view]]",
            value: object,
            config: JsonMLConfig.asObject),
        NameValuePair(
            name: "[[entries]]", value: object, config: JsonMLConfig.asMap)
      ];
}

/// Formatter for Dart Map objects.
///
/// This is only used for internal maps, or when shown as [[entries]]
/// from MapOverViewFormatter.
class MapFormatter implements Formatter {
  bool accept(object, config) =>
      object is InternalMap || config == JsonMLConfig.asMap;

  bool hasChildren(object) => true;

  String preview(object) {
    Map map = object;
    try {
      return '${getObjectTypeName(map)} length ${map.length}';
    } catch (e) {
      return safePreview(object, JsonMLConfig.none);
    }
  }

  List<NameValuePair> children(object) {
    // TODO(jacobr): be lazier about enumerating contents of Maps that are not
    // the build in LinkedHashMap class.
    // TODO(jacobr): handle large Maps better.
    Map map = object;
    var entries = LinkedHashSet<NameValuePair>();
    map.forEach((key, value) {
      var entryWrapper = MapEntry(key: key, value: value);
      entries.add(
          NameValuePair(name: entries.length.toString(), value: entryWrapper));
    });
    addMetadataChildren(object, entries);
    return entries.toList();
  }
}

/// Formatter for Dart Iterable objects including List and Set.
class IterableFormatter implements Formatter {
  bool accept(object, config) => object is Iterable;

  String preview(object) {
    Iterable iterable = object;
    try {
      var length = iterable.length;
      return '${getObjectTypeName(iterable)} length $length';
    } catch (_) {
      return '${getObjectTypeName(iterable)}';
    }
  }

  bool hasChildren(object) => true;

  List<NameValuePair> children(object) {
    // TODO(jacobr): be lazier about enumerating contents of Iterables that
    // are not the built in Set or List types.
    // TODO(jacobr): handle large Iterables better.
    // TODO(jacobr): consider only using numeric indices
    var children = LinkedHashSet<NameValuePair>();
    children.addAll(IterableSpan(0, object.length, object).children());
    // TODO(jacobr): provide a link to show regular class properties here.
    // required for subclasses of iterable, etc.
    addMetadataChildren(object, children);
    return children.toList();
  }
}

class NamedConstructorFormatter implements Formatter {
  bool accept(object, config) => object is NamedConstructor;

  // TODO(bmilligan): Display the signature of the named constructor as the
  // preview.
  String preview(object) => 'Named Constructor';

  bool hasChildren(object) => true;

  List<NameValuePair> children(object) => <NameValuePair>[
        NameValuePair(
            name: 'JavaScript Function',
            value: object,
            config: JsonMLConfig.skipDart)
      ];
}

/// Formatter for synthetic MapEntry objects used to display contents of a Map
/// cleanly.
class MapEntryFormatter implements Formatter {
  bool accept(object, config) => object is MapEntry;

  String preview(object) {
    MapEntry entry = object;
    return '${safePreview(entry.key, JsonMLConfig.none)} => ${safePreview(entry.value, JsonMLConfig.none)}';
  }

  bool hasChildren(object) => true;

  List<NameValuePair> children(object) => <NameValuePair>[
        NameValuePair(
            name: 'key', value: object.key, config: JsonMLConfig.keyToString),
        NameValuePair(name: 'value', value: object.value)
      ];
}

/// Formatter for Dart Iterable objects including List and Set.
class HeritageClauseFormatter implements Formatter {
  bool accept(object, config) => object is HeritageClause;

  String preview(object) {
    HeritageClause clause = object;
    var typeNames = clause.types.map(getTypeName);
    return '${clause.name} ${typeNames.join(", ")}';
  }

  bool hasChildren(object) => true;

  List<NameValuePair> children(object) {
    HeritageClause clause = object;
    var children = <NameValuePair>[];
    for (var type in clause.types) {
      children.add(NameValuePair(value: type, config: JsonMLConfig.asClass));
    }
    return children;
  }
}

/// Formatter for synthetic IterableSpan objects used to display contents of
/// an Iterable cleanly.
class IterableSpanFormatter implements Formatter {
  bool accept(object, config) => object is IterableSpan;

  String preview(object) {
    return '[${object.start}...${object.end - 1}]';
  }

  bool hasChildren(object) => true;

  List<NameValuePair> children(object) => object.children();
}

/// Formatter for Dart Errors and Exceptions.
class ErrorAndExceptionFormatter extends ObjectFormatter {
  static final RegExp _pattern = RegExp(r'\d+\:\d+');

  bool accept(object, config) => object is Error || object is Exception;

  bool hasChildren(object) => true;

  String preview(object) {
    var trace = dart.stackTrace(object);
    // TODO(vsm): Pull our stack mapping logic here.  We should aim to
    // provide the first meaningful stack frame.
    var line = '$trace'.split('\n').firstWhere(
        (l) =>
            l.contains(_pattern) &&
            !l.contains('dart:sdk') &&
            !l.contains('dart_sdk'),
        orElse: () => '');
    return line != '' ? '${object} at ${line}' : '${object}';
  }

  List<NameValuePair> children(object) {
    var trace = dart.stackTrace(object);
    var entries = LinkedHashSet<NameValuePair>();
    entries.add(NameValuePair(name: 'stackTrace', value: trace));
    addInstanceMembers(object, entries);
    addMetadataChildren(object, entries);
    return entries.toList();
  }

  // Add an ObjectFormatter view underneath.
  void addInstanceMembers(object, Set<NameValuePair> ret) {
    ret.add(NameValuePair(
        name: "[[instance members]]",
        value: object,
        config: JsonMLConfig.asObject));
  }
}

class StackTraceFormatter implements Formatter {
  bool accept(object, config) => object is StackTrace;

  String preview(object) => 'StackTrace';

  bool hasChildren(object) => true;

  // Using the stack_trace formatting would be ideal, but adding the
  // dependency or re-writing the code is too messy, so each line of the
  // StackTrace will be added as its own child.
  List<NameValuePair> children(object) => object
      .toString()
      .split('\n')
      .map((line) => NameValuePair(
          value: line.replaceFirst(RegExp(r'^\s+at\s'), ''), hideName: true))
      .toList();
}

class ClassFormatter implements Formatter {
  bool accept(object, config) => dart.isDartClass(object);

  String preview(cls) {
    return _hideInternalNames(dart.getClassName(cls));
  }

  bool hasChildren(object) => true;

  List<NameValuePair> children(type) {
    // TODO(jacobr): add other entries describing the class such as
    // implemented interfaces, and methods.
    var ret = LinkedHashSet<NameValuePair>();

    // Static fields, getters, setters, and methods signatures were removed
    // from the runtime representation because they are not needed. At this
    // time there is no intention to support them in this custom formatter.

    // instance methods.
    var instanceMethods = Set<NameValuePair>();
    // Instance methods are defined on the prototype not the constructor object.
    addPropertiesFromSignature(dart.getMethods(type), instanceMethods,
        JS('', '#.prototype', type), false,
        tagTypes: true);
    if (instanceMethods.isNotEmpty) {
      ret
        ..add(NameValuePair(value: '[[Instance Methods]]', hideName: true))
        ..addAll(sortProperties(instanceMethods));
    }

    var mixin = dart.getMixin(type);
    if (mixin != null) {
      // TODO(jmesserly): this can only be one value.
      ret.add(NameValuePair(
          name: '[[Mixins]]', value: HeritageClause('mixins', [mixin])));
    }

    var baseProto = jsObjectGetPrototypeOf(type);
    if (baseProto != null && !_useNativeJSFormatter(baseProto)) {
      ret.add(NameValuePair(
          name: "[[base class]]",
          value: baseProto,
          config: JsonMLConfig.asClass));
    }

    // TODO(jacobr): add back fields for named constructors.
    return ret.toList();
  }
}

class TypeFormatter implements Formatter {
  bool accept(object, config) => object is Type;

  String preview(object) => object.toString();

  bool hasChildren(object) => false;

  List<NameValuePair> children(object) => [];
}

typedef StackTraceMapper = String Function(String stackTrace);

/// Hook for other parts of the SDK To use to map JS stack traces to Dart
/// stack traces.
///
/// Raw JS stack traces are used if $dartStackTraceUtility has not been
/// specified.
StackTraceMapper? get stackTraceMapper {
  var _util = JS('', r'#.$dartStackTraceUtility', dart.global_);
  return _util != null ? JS('!', '#.mapper', _util) : null;
}

/// This entry point is automatically invoked by the code generated by
/// Dart Dev Compiler
registerDevtoolsFormatter() {
  JS('', '#.devtoolsFormatters = [#]', dart.global_, _devtoolsFormatter);
}

// These methods are exposed here for debugger tests.
//
// TODO(jmesserly): these are not exports because there is existing code that
// calls into them from JS. Currently `dartdevc` always resolves exports at
// compile time, so there is no need to make exports available at runtime by
// copying properties. For that reason we cannot use re-export.
//
// If these methods are only for tests, we should move them here, or change the
// tests to call the methods directly on dart:_runtime.
List<String> getModuleNames() => dart.getModuleNames();
getModuleLibraries(String name) => dart.getModuleLibraries(name);
