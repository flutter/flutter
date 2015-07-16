Sky Style Guide
===============

In general, follow our [Design Principles](design.md) for all code.

The primary goal of this style guide is to improve code readability so
that everyone, whether reading the code for the first time or
maintaining it for years, can quickly determine what the code does. A
secondary goal is avoiding arguments when there are disagreements.

Dart
----

In general, follow the [Dart style
guide](https://www.dartlang.org/articles/style-guide/) for Dart code,
except where that would contradict this page.

Always use the Dart Analyzer. Do not check in code that increases the
output of the analyzer unless you've filed a bug with the Dart team.

Use assert()s liberally.


Types (i.e. classes, typedefs (function signature definitions) and
enums) are named UpperCamelCase. Everything else (methods, fields,
variables, constants, enum values, etc) is lowerCamelCase. Constant
doubles and strings are prefixed with k. Prefer using a local const
or a static const in a relevant class than using a global constant.

Don't name your libraries (no ```library``` keyword). Name the files
in ```lower_under_score.dart``` format.


Class constructors and methods should be ordered in the order that
their members will be used in an instance's typical lifecycle. In
particular, this means constructors all come first in class
declarations.

The default (unnamed) constructor should come first, then the named
constructors.

Fields should come before the methods that manipulate them, if they
are specific to a particular group of methods.

> For example, RenderObject groups all the layout methods and layout
> fields together, then all the paint methods and paint fields.

Fields that aren't specific to a particular group of methods should
come immediately after the constructors.

Be consistent in the order of members. If a constructor lists a bunch
of fields, then those fields should declared be in the same order, and
any code that operates on all of them should operate on them in the
same order (unless the order matters).


All variables and arguments are typed; don't use "var", "dynamic", or
"Object" in any case where you could figure out the actual type.
Always specialise generic types where possible.

Aim for a line length of 80 characters, but go over if breaking the
line would make it less readable.

Only use => when the result fits on a single line.

When using ```{ }``` braces, put a space or a newline after the open
brace and before the closing brace. (If the black is empty, the same
space will suffice for both.)

When breaking an argument list into multiple lines, indent the
arguments two characters from the previous line.

> Example:
> ```dart
> Foo f = new Foo(
>   bar: 1.0,
>   quux: 2.0
> );
> ```

When breaking a parameter list into multiple lines, do the same.

Use // and ///, not /* */ and /** */.

Don't put the statement part of an "if" statement on the same line as
the expression, even if it is short. (Doing so makes it unobvious that
there is relevant code there. This is especially important for early
returns.)

If a flow control structure's statement is one line long, then don't
use braces around it. (Keeping the code free of boilerplate or
redundant punctuation keeps it concise and readable.)

> For example,
> ```dart
>   if (children != null) {
>     for (RenderBox child in children)
>       add(child);
>   }
> ```
> ...rather than:
> ```dart
>   if (children != null) {
>     for (RenderBox child in children) {
>       add(child);
>     }
>   }
> ```


Use the most relevant constructor or method, when there are multiple
options.

> For example,
> ```dart
>    new EdgeDims.symmetric(horizontal: 8.0);
> ```
> ...rather than:
> ```dart
>    new EdgeDims(0.0, 8.0, 0.0, 8.0);
> ```


Use for-in loops rather than forEach() where possible, since that
saves a stack frame per iteration.


C++
---

Put spaces around operators in expressions.


Java
----

