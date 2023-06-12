import 'package:provider/src/provider.dart';
import 'package:test/test.dart';

Matcher isPostEventCall(Object kind, Object? event) {
  var matcher =
      isA<PostEventCall>().having((e) => e.eventKind, 'eventKind', kind);

  if (event != null) {
    matcher = matcher.having((e) => e.event, 'event', event);
  }

  return matcher;
}
