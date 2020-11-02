import 'package:flutter_test/flutter_test.dart';

import 'package:integration_test/common.dart';

void main() {
  test('Serialize and deserialize Failure', () {
    Failure fail = Failure('what a name', 'no detail');
    Failure restored = Failure.fromJsonString(fail.toString());
    expect(restored.methodName, fail.methodName);
    expect(restored.details, fail.details);
  });

  test('Serialize and deserialize Response', () {
    Response response, restored;
    String jsonString;

    response = Response.allTestsPassed();
    jsonString = response.toJson();
    expect(jsonString, '{"result":"true","failureDetails":[]}');
    restored = Response.fromJson(jsonString);
    expect(restored.allTestsPassed, response.allTestsPassed);
    expect(restored.data, null);
    expect(restored.formattedFailureDetails, '');

    final Failure fail = Failure('what a name', 'no detail');
    final Failure fail2 = Failure('what a name2', 'no detail2');
    response = Response.someTestsFailed([fail, fail2]);
    jsonString = response.toJson();
    restored = Response.fromJson(jsonString);
    expect(restored.allTestsPassed, response.allTestsPassed);
    expect(restored.data, null);
    expect(restored.formattedFailureDetails, response.formattedFailureDetails);

    Map<String, dynamic> data = <String, dynamic>{'aaa': 'bbb'};
    response = Response.allTestsPassed(data: data);
    jsonString = response.toJson();
    restored = Response.fromJson(jsonString);
    expect(restored.data.keys, ['aaa']);
    expect(restored.data.values, ['bbb']);

    response = Response.someTestsFailed([fail, fail2], data: data);
    jsonString = response.toJson();
    restored = Response.fromJson(jsonString);
    expect(restored.data.keys, ['aaa']);
    expect(restored.data.values, ['bbb']);
  });
}
