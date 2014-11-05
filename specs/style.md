Sky Style Language
==================

For now, the Sky style language is CSS with the following restrictions:

- No combinators
- Only = and ~= attribute selectors
- Lots of other selectors removed // TODO(ianh): list them
- Floats removed
- Lots of other layout models removed // TODO(ianh): list them


Planed changes
--------------

Add //-to-end-of-line comments to be consistent with the script
language.

Add a way to add new values, e.g. by default only support #RRGGBB
colours (or maybe only rgba() colours), but provide a way to enable
CSS4-like "color(red rgb(+ #004400))" stuff.
