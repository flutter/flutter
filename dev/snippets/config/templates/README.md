## Creating Code Snippets

In general, creating application snippets can be accomplished with the following
syntax inside of the dartdoc comment for a Flutter class/variable/enum/etc.:

```dart
/// {@tool snippet --template=stateful_widget}
/// Any text outside of the code blocks will be accumulated and placed at the
/// top of the snippet box as a description. Don't try and say "see the code
/// above" or "see the code below", since the location of the description may
/// change in the future. You can use dartdoc [Linking] in the description, and
/// __Markdown__ too.
/// ```dart preamble
/// class Foo extends StatelessWidget {
///   const Foo({this.value = ''});
/// 
///   String value; 
/// 
///   @override
///   Widget build(BuildContext context) {
///     return Text(value);
///   }
/// }
/// ```
/// This will get tacked on to the end of the description above, and shown above
/// the snippet.  These two code blocks will be separated by `///...` in the
/// short version of the snippet code sample.
/// ```dart
/// String myValue = 'Foo';
/// 
/// @override
/// Widget build(BuildContext) {
///   return const Foo(myValue);
/// }
/// ```
/// {@end-tool}
```

This will result in the template having the section that's inside "```dart"
interpolated into the template's stateful widget's state object body.

All code within a code block in a snippet needs to be able to be run through
dartfmt without errors, so it needs to be valid code (This shouldn't be an
additional burden, since all code will also be compiled to be sure it compiles).

## Available Templates

The templates available for using as an argument to the snippets tool are as
follows:

- __`stateful_widget`__ : Takes a `preamble` in addition to the default code
  block, which will be placed at the top level of the Dart file, so bare
  function calls are not allowed in the preamble.  The default code block is
  placed as the body of a stateful widget, so you will need to implement the
  build() function, and any state variables.
  
