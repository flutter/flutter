import 'package:flutter/semantics.dart';

class MockSemanticsService implements SemanticsService {
  bool mockIsAnnounceSupported = false;

  @override
  bool isAnnounceSupported() {
    return mockIsAnnounceSupported;
  }
}