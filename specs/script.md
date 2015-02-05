Sky Script Language
===================

The Sky script language is based on Dart.

It has the following differences from Dart:

- the 'library', 'part', 'import', 'export', and 'part of' directives
  are not supported in sky (sky has its own module system)

- ``<script>`` elements parse ``topLevelDefinition``s (there is no
  ``libraryDefinition`` construct in the Sky Script Language).

The way that Sky integrates the module system with its script language
  is described in (modules.md)[modules.md].
