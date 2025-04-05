import 'package:flutter/semantics.dart';

/// Util service to mock methods in the service.
class MockSemanticsService implements SemanticsService {
  bool mockIsAnnounceSupported = false;

  @override
  bool isAnnounceSupported() {
    return mockIsAnnounceSupported;
  }
}
