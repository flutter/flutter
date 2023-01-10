import 'common.dart';

abstract class Extension {
  const Extension();

  /// Must run synchronously.
  void registerHandlers(Map<Type, List<RequestHandler>> registeredHandlers);
}

class TemplateExtension extends Extension {
  void registerHandlers(Map<Type, List<RequestHandler>> registeredHandlers) {
    // TODO make this a field;
    final List<RequestHandler> handlers = registeredHandlers[ListTemplatesRequest] ?? <RequestHandler>[];
    handlers.add(_handleListTemplatesRequest);
  }

  void _handleListTemplatesRequest(Object? _) {

  }
}

class ListTemplatesRequest implements Request {
  const ListTemplatesRequest();
}

class ListTemplatesResponse extends Response {
  ListTemplatesResponse({required super.id});

  final List<String> templates = <String>[];

  @override
  String toString() => 'Installed templates: [${templates.join(', ')}]';
}
