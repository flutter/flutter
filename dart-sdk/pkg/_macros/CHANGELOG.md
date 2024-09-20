## 0.3.2

- Fix bug where augmenting classes with type parameters didn't work.

## 0.3.1

- Make it an error for macros to complete with pending async work scheduled.

## 0.3.0

- Remove type parameter on internal `StaticType` implementation.

## 0.2.0

- Add identifiers to `NamedStaticType`.
- Add `StaticType.asInstanceOf`.

## 0.1.7

- Fix for generating code after extendsType

## 0.1.6

- Add extendsType API for adding an extends clause.
- Refactor builder implementations, fixes some bugs around nested builders.

## 0.1.5

- Handle ParallelWaitError with DiagnosticException errors nicely.
- Fix a bug where we weren't reporting diagnostics for nested builders.

## 0.1.4

- Improve formatting of constructor initializer augmentations.

## 0.1.3

- Validate parts in `Code.fromParts()`.

## 0.1.2

- Add caching for `typeDeclarationOf` results.

## 0.1.1

- Add caching for `TypeDeclaration` related introspection results.

## 0.1.0

Initial release, copied from `_fe_analyzer_shared/lib/src/macros`.
