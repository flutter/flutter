import 'package:flutter/foundation.dart';
import 'package:webviewx/src/utils/source_type.dart';

/// Model class for webview's content
///
/// This is the result of calling [await webViewXController.getContent()]
class WebViewContent {
  /// Source
  final String source;

  /// Source type
  final SourceType sourceType;

  /// Headers
  final Map<String, String>? headers;

  /// POST request body, on WEB only
  final Object? webPostRequestBody;

  /// Constructor
  const WebViewContent({
    required this.source,
    required this.sourceType,
    this.headers,
    this.webPostRequestBody,
  });

  WebViewContent copyWith({
    String? source,
    SourceType? sourceType,
    Map<String, String>? headers,
    Object? webPostRequestBody,
  }) =>
      WebViewContent(
        source: source ?? this.source,
        sourceType: sourceType ?? this.sourceType,
        headers: headers ?? this.headers,
        webPostRequestBody: webPostRequestBody ?? this.webPostRequestBody,
      );

  @override
  String toString() {
    return 'WebViewContent:\n'
        'Source: $source\n'
        'SourceType: ${describeEnum(sourceType)}\n'
        'Last request Headers: ${headers ?? 'none'}\n'
        'Last request Body: ${webPostRequestBody ?? 'none'}\n';
  }

  @override
  bool operator ==(Object other) =>
      identical(other, this) ||
      (other is WebViewContent &&
          other.source == source &&
          other.sourceType == sourceType &&
          other.headers == headers &&
          other.webPostRequestBody == webPostRequestBody);

  @override
  int get hashCode =>
      source.hashCode ^
      sourceType.hashCode ^
      headers.hashCode ^
      webPostRequestBody.hashCode;
}
