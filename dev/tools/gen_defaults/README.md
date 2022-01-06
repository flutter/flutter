## Token Defaults Generator

Script that generates widget component theme data defaults
based on the Material Token database. These tokens were
extracted into a JSON file from an internal Google database.

## Usage
Run this program from the root of the git repository:
```
dart dev/tools/gen_defaults/bin/gen_defaults.dart
```

## Templates

There is a template file for every component that needs defaults from
the token database. These templates are implemented as subclasses of
`TokenTemplate`. This base class provides some utilities and a structure
for adding a new chunk of generated code to the bottom of a given file.

Templates need to override the `generate` method to provide the generated
code chunk as a string. The tokens are represented as a `Map<String, dynamic>`
that is loaded from `data/material-tokens.json`. Templates can look up
whatever properties are needed in this structure to provide the properties
needed for the component.

See `lib/fab_template.dart` for an example that generates defaults for the
Floating Action Button.
