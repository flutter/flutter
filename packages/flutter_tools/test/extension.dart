
import 'package:flutter_tool_api/extension.dart';
import 'package:flutter_tools/src/base/extension_host.dart';

import 'src/common.dart';

void main() {
  group('ExtensionShim', () {
    ToolExtensionManager toolExtensionManager;
    TestExtension testExtension;

    setUp(() {
      testExtension = TestExtension();
      toolExtensionManager = ToolExtensionManager(<ToolExtension>[
        testExtension,
      ], <CrossIsolateShim>[]);
    });

    test('handles nonsense method', () async {
      final Response response = await toolExtensionManager.sendRequest('test', 'foobar');

      expect(response.hasError, true);
    });

    test('handles nonsense extensionName', () async {
      final Response response = await toolExtensionManager.sendRequest('not defined', 'foobar');

      expect(response.hasError, true);
    });

    test('can send response to extension', () async {
      final TestDomain testDoctorDomain = testExtension.testDomain;
      expect(testDoctorDomain.received, false);

      final Response response = await toolExtensionManager.sendRequest('test', 'example.bar');

      expect(response.hasError, false);
      expect(testDoctorDomain.received, true);
    });

    test('can handle error from extension', () async {
      final TestDomain testDoctorDomain = testExtension.testDomain;
      expect(testDoctorDomain.received, false);

      testDoctorDomain.domainHandler = (Map<String, Object> arguments) async {
        throw Exception('Something went wrong');
      };

      final Response response = await toolExtensionManager.sendRequest('test', 'example.bar');

      expect(response.hasError, true);
      expect(testDoctorDomain.received, true);
    });

    test('can receive data from extension', () async {
      final TestDomain testDoctorDomain = testExtension.testDomain;
      expect(testDoctorDomain.received, false);

      testDoctorDomain.domainHandler = (Map<String, Object> arguments) async {
        return FakeSerializable(<String, Object>{'foo': 'bar'});
      };

      final Response response = await toolExtensionManager.sendRequest('test', 'example.bar');

      expect(response.hasError, false);
      expect(response.body, <String, Object>{'foo': 'bar'});
      expect(testDoctorDomain.received, true);
    });
  });
}

class FakeSerializable extends Serializable {
  FakeSerializable(this.value);

  final Map<String, Object> value;

  @override
  Object toJson() => value;
}


class TestExtension extends ToolExtension {
  TestExtension() {
    registerMethod('example.bar', testDomain.example);
  }

  final TestDomain testDomain = TestDomain();

  @override
  String get name => 'test';
}


class TestDomain extends Domain {
  bool received = false;
  DomainHandler domainHandler = (Map<String, Object> arguments) async => FakeSerializable(<String, Object>{});

  Future<FakeSerializable> example(Map<String, Object> arguments) async {
    received = true;
    return domainHandler(arguments);
  }
}
