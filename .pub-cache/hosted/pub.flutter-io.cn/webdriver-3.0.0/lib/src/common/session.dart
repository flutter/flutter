import 'spec.dart';

class SessionInfo {
  /// Id of the session.
  final String id;

  /// Spec of the session.
  ///
  /// This shouldn't be [WebDriverSpec.Auto].
  final WebDriverSpec spec;

  /// Capabilities of the session.
  final Map<String, dynamic>? capabilities;

  SessionInfo(this.id, this.spec, this.capabilities);
}
