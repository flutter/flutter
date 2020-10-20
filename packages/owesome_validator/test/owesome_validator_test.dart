import 'package:flutter_test/flutter_test.dart';

import 'package:owesome_validator/owesome_validator.dart';

void main() {
  test('adds one to input values', () {
    expect(
        OwesomeValidator.name(
            "Osama Asif", OwesomeValidator.patternNameOnlyChar),
        true);
    expect(
        OwesomeValidator.email(
            "osama.asif20@gmail.com", OwesomeValidator.patternEmail),
        true);
    expect(
        OwesomeValidator.password("Osama12@1",
            OwesomeValidator.passwordMinLen8withCamelAndSpecialChar),
        true);
    expect(
        OwesomeValidator.phone("+923090052512", OwesomeValidator.patternPhone),
        true);
  });
}
