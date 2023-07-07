/// Proxy which will be used to fetch page sources in the [SourceType.urlBypass] mode.
abstract class BypassProxy {
  /// Builds the proxied url
  String buildProxyUrl(String pageUrl);

  /// Returns the page source from the response body
  String extractPageSource(String responseBody);

  /// A default list of public proxies
  static const publicProxies = <BypassProxy>[
    BridgedBypassProxy(),
    CodeTabsBypassProxy(),
    WeCorsAnyWhereProxy(),
  ];
}

/// cors.bridged.cc proxy
class BridgedBypassProxy implements BypassProxy {
  const BridgedBypassProxy();

  @override
  String buildProxyUrl(String pageUrl) {
    return 'https://cors.bridged.cc/$pageUrl';
  }

  @override
  String extractPageSource(String responseBody) {
    return responseBody;
  }
}

/// api.codetabs.com proxy
class CodeTabsBypassProxy implements BypassProxy {
  const CodeTabsBypassProxy();

  @override
  String buildProxyUrl(String pageUrl) {
    return 'https://api.codetabs.com/v1/proxy/?quest=$pageUrl';
  }

  @override
  String extractPageSource(String responseBody) {
    return responseBody;
  }
}

/// we-cors-anywhere.herokuapp.com proxy
class WeCorsAnyWhereProxy implements BypassProxy {
  const WeCorsAnyWhereProxy();

  @override
  String buildProxyUrl(String pageUrl) {
    return 'https://we-cors-anywhere.herokuapp.com/$pageUrl';
  }

  @override
  String extractPageSource(String responseBody) {
    return responseBody;
  }
}

/* 
Example for when the proxy's response is not the page source directly,
but instead it's a JSON object.

Such as this: {"response": "<html><head>......."}



class ExampleExtractPageSourceBypassProxy implements BypassProxy {
  @override
  String buildRequestUrl(String pageUrl) {
    return 'https://example-extract-page-source/$pageUrl';
  }

  @override
  String extractPageSource(String responseBody) {
    final jsonResponse = jsonDecode(responseBody) as Map<String, dynamic>;
    return jsonResponse['response'] as String;
  }
}
*/
