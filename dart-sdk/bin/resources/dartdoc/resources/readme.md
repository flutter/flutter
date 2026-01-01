# Dart documentation generator

This directory includes static sources used by the Dart documentation generator
through the `dart doc` command.

To learn more about generating and viewing the generated documentation,
check out the [`dart doc` documentation][].

[`dart doc` documentation]: https://dart.dev/tools/dart-doc

## Third-party resources

## highlight.js

**License:** https://github.com/highlightjs/highlight.js/blob/main/LICENSE

### Update

1. Visit https://highlightjs.org/download/
2. Open the developer console.
3. Copy the below code block and execute.
4. Verify that the listed language are selected.
5. Download and extract assets.

```javascript
var selected = [
  'bash',
  'c',
  'css',
  'dart',
  'diff',
  'java',
  'javascript',
  'json',
  'kotlin',
  'markdown',
  'objectivec',
  'plaintext',
  'shell',
  'swift',
  'xml', // also includes html
  'yaml',
];
document.querySelectorAll('input[type=checkbox]').forEach(function (elem) {elem.checked = selected.includes(elem.value);});
```
