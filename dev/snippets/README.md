## Snippet Tool

This is a dartdoc extension tool that takes code snippets and expands how they
are presented so that Flutter can have more interactive and useful code
snippets.

This takes code in dartdocs, like this:

```dart
/// The following is a skeleton of a stateless widget subclass called `GreenFrog`:
/// {@tool snippet --template="stateless_widget"}
/// class GreenFrog extends StatelessWidget {
///   const GreenFrog({ Key key }) : super(key: key);
///
///   @override
///   Widget build(BuildContext context) {
///     return Container(color: const Color(0xFF2DBD3A));
///   }
/// }
/// {@end-tool}
```

And converts it into something which has a nice visual presentation, and 
a button to automatically copy the sample to the clipboard.

It does this by processing the source input and emitting HTML for output,
which dartdoc places back into the documentation. Any options given to the
 `{@tool ...}` directive are passed on verbatim to the tool.

To render the above, the snippets tool needs to render the code in a combination
of markdown and HTML, using the `{@inject-html}` dartdoc directive.

## Templates

In order to support showing an entire app when you click on the right tab of
the code snippet UI, we have to be able to insert the snippet into the template
and instantiate the right parts.

To do this, there is a [config/templates](config/templates) directory that
contains a list of templates. These templates represent an entire app that the
snippet can be placed into, basically a replacement for `lib/main.dart` in a
flutter app package.

## Skeletons

A skeleton (in relation to this tool, in the [config/skeletons](config/skeletons)
directory) is an HTML template into which the snippet Dart code and description
are interpolated, in order to display it nicely.

There is currently one skeleton for
[application](config/skeletons/application.html) snippets and one for
[sample](config/skeletons/sample.html)
snippets, but there could be more. It uses moustache notation (e.g. `{{code}}`)
to mark where the components to be interpolated into the template should go.

(It doesn't actually use the moustache package, since the only things that need
substituting are simple strings, but it uses the same syntax). 