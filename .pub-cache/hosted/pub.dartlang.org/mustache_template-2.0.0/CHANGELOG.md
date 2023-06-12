# CHANGELOG

## 2.0.0

* Support for null safe dart added.

## 1.0.0+1

* Fixed regression where lookups from list did not work. Removed failing tests
  that depend on reflection.

## 1.0.0

 * Forked from original repo. Support for mirrors removed.

## Fork

## 1.1.1

 * Fixed error "boolean expression must not be null". Thanks Nico.

## 1.1.0

 * Better support for class members in sections. Thanks to Janice Collins.
 * Set the SDK constraint to Dart 2+.

## 1.0.2
  Set the max SDK constraint to <3.0.0.

## 0.2.5

* Remove MustacheFormatException
* Allow templates to specify default delimiters. Thanks to Joris Hermans.
* Fix #24: renderString shrinks multiple newlines to just one (Thanks to John Ryan for the repro).

## 0.2.4

* Fix #23 failure if tag or comment contains "="

## 0.2.3

* Change handling of lenient sections to match python mustache implementation.

## 0.2.2

* Fix MirrorsUsed tag for using mirrors on dart2js.
* Clean up dead code.

## 0.2.1

* Added new methods to LambdaContext.

## 0.2

* Deprecated parse() function - please update your code to use new Template(source).
* Deprecated MustacheFormatException - please update your code to use TemplateException.
* Breaking change: Template.render and Template.renderString methods no longer
  take the optional lenient and htmlEscapeValues. These should now be passed to
  the Template constructor.
* Fully passing all mustache spec tests.
* Added support for MirrorsUsed.
* Implemented partials. #11
* Implemented lambdas. #4
* Implemented change delimiter tag.
* Add template name parameter, and show this in error messages.
* Allow whitespace at begining of tags. #10

