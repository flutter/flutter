[![ci](https://github.com/google/uri.dart/workflows/ci/badge.svg?branch=master)](https://github.com/google/uri.dart/actions?query=branch%3Amaster)

Utilities for working with [URI][uri]s in Dart, mostly parsing and generating URIs.

[uri]: https://api.dart.dev/stable/dart-core/Uri-class.html

## UriPattern

UriPattern is an interface for classes that match and parse URIs, much like the [Pattern][pattern] is for Strings. It defines the methods `bool matches(Uri uri)` and `UriMatch match(Uri uri)`.

[pattern]: https://api.dart.dev/stable/dart-core/Pattern-class.html

## UriMatch

UriMatch is the result of `UriPattern.match()`. It contains the parameters parsed out of a URI and the "rest" of the URI left over after parsing, which is useful for parsing a single URI with multiple relative URI patterns that form a hierarchy.

## UriTemplate

UriTemplate is an implementation of [RFC 6570 URI Templates][rfc6570]. URI Templates are useful for generating URIs from data. UriTemplates are created from a template string, and then expanded with data to generate a URI:

```dart
var template = UriTemplate("http://example.com/~{user}/");
String fredUri = template.expand({'user': 'fred'});
print(fredUri); // prints: http://example.com/~fred/
```

### Syntax

URI templates are strings made up of fixed and variable parts. The variable parts are described with _expressions_, which are places within single curly-braces: `{` and `}`.

Expressions consist of an optional _operator_ and a comma-separated list of _variable_ specifications_. Variable specifications consist of a variable name and an optional _modifier_. The operator applies to the whole expression and controls how reserved characters are expanded, the prefix and separator, if any, applied to the expansion, and whether to expand the variable as a key/value pair. Modifiers apply to each variable in the expression and allow truncating the value, or "exploding" list and maps into multiple key/value pairs.

#### Examples

  * `http://example.com/~{username}/`
  * `http://example.com/dictionary/{term:1}/{term}`
  * `http://example.com/search{?q,lang}`

#### Operators

URI template expansions does more than simple variable replacement, it has facilities for generating paths, fragments, query strings and more. To control the expansion, expressions can use one of the supported operators:

| Operator | Description                               |
|----------|-------------------------------------------|
| _none_   | Simple string expansion                   |
| +        | Reserved string expansion                 |
| #        | Fragment expansion                        |
| .        | Label expansion, dot-prefixed             |
| /        | Path segments, slash-prefixed             |
| ;        | Path-style parameters, semicolon-prefixed |
| ?        | Form-style query, ampersand-separated     |
| &        | Form-style query continuation             |


#### Modifiers

Modifiers control 

| Modifier | Description                                           |
|----------|-------------------------------------------------------|
| _none_   | Default expansion                                     |
| :_n_     | Prefix: use only the first _n_ characters of the value|
| *        | "Explode" the lists and maps into key/value pairs     |


[rfc6570]: http://tools.ietf.org/html/rfc6570

## UriParser

UriParser parses URIs according to a UriTemplate, extracting parameters based on the variables defined in the template.

Since URI Templates are not designed to be parsable, only a restricted subset of templates can be used for parsing.

Parsable templates have the following restrictions over expandable templates:

   * URI components must come in order: scheme, host, path, query, fragment.
     There can only be one of each component.
   * Path expressions can only contain one variable.
   * Multiple expressions must be separated by a literal.
   * Only the following operators are supported: none, +, #, ?, &
   * Default and + operators are not allowed in query or fragment components.
   * Queries can only use the ? or & operator.
   * The ? operator can only be used once.
   * Fragments can only use the # operator
 
## UriBuilder

UriBuilder is mutable container of URI components for incrementally building Uris.
