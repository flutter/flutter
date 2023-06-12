// Copyright (c) 2012, the Dart project authors.
// Copyright (c) 2006, Kirill Simonov.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file or at
// https://opensource.org/licenses/MIT.

import 'src/error_listener.dart';
import 'src/loader.dart';
import 'src/style.dart';
import 'src/yaml_document.dart';
import 'src/yaml_exception.dart';
import 'src/yaml_node.dart';

export 'src/style.dart';
export 'src/utils.dart' show YamlWarningCallback, yamlWarningCallback;
export 'src/yaml_document.dart';
export 'src/yaml_exception.dart';
export 'src/yaml_node.dart' hide setSpan;

/// Loads a single document from a YAML string.
///
/// If the string contains more than one document, this throws a
/// [YamlException]. In future releases, this will become an [ArgumentError].
///
/// The return value is mostly normal Dart objects. However, since YAML mappings
/// support some key types that the default Dart map implementation doesn't
/// (NaN, lists, and maps), all maps in the returned document are [YamlMap]s.
/// These have a few small behavioral differences from the default Map
/// implementation; for details, see the [YamlMap] class.
///
/// In future versions, maps will instead be [HashMap]s with a custom equality
/// operation.
///
/// If [sourceUrl] is passed, it's used as the URL from which the YAML
/// originated for error reporting.
///
/// If [recover] is true, will attempt to recover from parse errors and may
/// return invalid or synthetic nodes. If [errorListener] is also supplied, its
/// onError method will be called for each error recovered from. It is not valid
/// to provide [errorListener] if [recover] is false.
dynamic loadYaml(String yaml,
        {Uri? sourceUrl, bool recover = false, ErrorListener? errorListener}) =>
    loadYamlNode(yaml,
            sourceUrl: sourceUrl,
            recover: recover,
            errorListener: errorListener)
        .value;

/// Loads a single document from a YAML string as a [YamlNode].
///
/// This is just like [loadYaml], except that where [loadYaml] would return a
/// normal Dart value this returns a [YamlNode] instead. This allows the caller
/// to be confident that the return value will always be a [YamlNode].
YamlNode loadYamlNode(String yaml,
        {Uri? sourceUrl, bool recover = false, ErrorListener? errorListener}) =>
    loadYamlDocument(yaml,
            sourceUrl: sourceUrl,
            recover: recover,
            errorListener: errorListener)
        .contents;

/// Loads a single document from a YAML string as a [YamlDocument].
///
/// This is just like [loadYaml], except that where [loadYaml] would return a
/// normal Dart value this returns a [YamlDocument] instead. This allows the
/// caller to access document metadata.
YamlDocument loadYamlDocument(String yaml,
    {Uri? sourceUrl, bool recover = false, ErrorListener? errorListener}) {
  var loader = Loader(yaml,
      sourceUrl: sourceUrl, recover: recover, errorListener: errorListener);
  var document = loader.load();
  if (document == null) {
    return YamlDocument.internal(YamlScalar.internalWithSpan(null, loader.span),
        loader.span, null, const []);
  }

  var nextDocument = loader.load();
  if (nextDocument != null) {
    throw YamlException('Only expected one document.', nextDocument.span);
  }

  return document;
}

/// Loads a stream of documents from a YAML string.
///
/// The return value is mostly normal Dart objects. However, since YAML mappings
/// support some key types that the default Dart map implementation doesn't
/// (NaN, lists, and maps), all maps in the returned document are [YamlMap]s.
/// These have a few small behavioral differences from the default Map
/// implementation; for details, see the [YamlMap] class.
///
/// In future versions, maps will instead be [HashMap]s with a custom equality
/// operation.
///
/// If [sourceUrl] is passed, it's used as the URL from which the YAML
/// originated for error reporting.
YamlList loadYamlStream(String yaml, {Uri? sourceUrl}) {
  var loader = Loader(yaml, sourceUrl: sourceUrl);

  var documents = <YamlDocument>[];
  var document = loader.load();
  while (document != null) {
    documents.add(document);
    document = loader.load();
  }

  // TODO(jmesserly): the type on the `document` parameter is a workaround for:
  // https://github.com/dart-lang/dev_compiler/issues/203
  return YamlList.internal(
      documents.map((YamlDocument document) => document.contents).toList(),
      loader.span,
      CollectionStyle.ANY);
}

/// Loads a stream of documents from a YAML string.
///
/// This is like [loadYamlStream], except that it returns [YamlDocument]s with
/// metadata wrapping the document contents.
List<YamlDocument> loadYamlDocuments(String yaml, {Uri? sourceUrl}) {
  var loader = Loader(yaml, sourceUrl: sourceUrl);

  var documents = <YamlDocument>[];
  var document = loader.load();
  while (document != null) {
    documents.add(document);
    document = loader.load();
  }

  return documents;
}
