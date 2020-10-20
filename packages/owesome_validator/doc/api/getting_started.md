# How to use this package

<!-- Don't worry it's very simple.. -->

 <!-- ****This is the base class for your understanding that what is going on inside this package. -->

## TEST CASE

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
        OwesomeValidator.phone("+923093254877", OwesomeValidator.patternPhone),
        true);
  });
}

<!-- Yeah the usuage is mentioned above just call the class function and utilize it,
here's the one more if you want to add your custom regex so just pass your regex string
to the function and rest leave on it.

String myCustomRegexString = r'^[A-Za-z ]+(?:[ _-][A-Za-z ]+)*$';

OwesomeValidator.name("Osama12@1",myCustomRegexString); -->