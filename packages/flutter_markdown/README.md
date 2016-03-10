# Flutter Markdown

A markdown renderer for Flutter. It supports the
[original format](https://daringfireball.net/projects/markdown/), but no inline
html.

## Getting Started

Using the Markdown widget is simple, just pass in the source markdown as a
string:

    new Markdown(data: markdownSource);

If you do not want the padding or scrolling behavior, use the MarkdownBody
instead:

    new MarkdownBody(data: markdownSource);

By default, Markdown uses the formatting from the current material design theme,
but it's possible to create your own custom styling. Use the MarkdownStyle class
to pass in your own style. If you don't want to use Markdown outside of material
design, use the MarkdownRaw class.
