# Adding a new diagnostic

This document describes the process of adding a new (non-lint) diagnostic to the
analyzer.

## Define the diagnostic code

The first step is to define the code(s) associated with the diagnostic.

The codes are defined in the file `analyzer/messages.yaml`. There's a comment at
the top of the file describing the structure of the file.

Every diagnostic has at least one code associated with it. A code defines the
problem and correction messages that will be shown to users.

For most diagnostics, a single message (code) is sufficient. But sometimes it's
useful to tailor the message based on the context in which the problem occurs or
because the message can be made more clear.

For example, it's an error to declare two or more constructors with the same name.
That's true whether the name is explicit or implicit (the default constructor).
In order for the message to match the user's model of the language, we define
two messages for this one problem: one that refers to the constructors by their
name, and one that refers to the constructors as "unnamed". The way we define
two messages is by defining two codes.

Each code has a unique name (the key used in the map in `messages.yaml`) and can
optionally define a shared name that links all the codes for a single diagnostic
together. It is the shared name that is displayed to users. If a shared name
isn't explicitly provided, it will default to being the same as the unique name.

### Updating generated files

After every edit to the `messages.yaml` file, you will need to run the following
to update the generated files:
```bash
dart run analyzer/tool/messages/generate.dart
```

### Add code to `error_fix_status.yaml`

You also need to manually add the name of the code to the list of codes in the
file `analysis_server/lib/src/services/correction/error_fix_status.yaml`. The
code should have the line
```yaml
  status: needsEvaluation
```
nested under the name of the code.

At some point, we'll evaluate the diagnostics that are marked as `needsEvaluation`.
If we can think of a reasonable and useful fix, then we'll change it to `needsFix`
with a comment indicating what fix we thought of. If we can't think of one, then
we'll change it to `noFix`. The status is changed to `hasFix` when there's at least
one fix associated with the diagnostic, which is something we can (and do) verify
in a test.

## Write tests

We recommend writing the tests for a diagnostic before writing the code to
generate the diagnostic. Doing so helps you think about the specific cases that
the implementation code needs to handle, which can result in cleaner
implementation code and fewer bugs.

The tests for each diagnostic code (or set of codes that have the same shared
name) are in a separate file in the directory `analyzer/test/src/diagnostics`.

Looking at the implementation of tests in a few of the other files can help you
see the basic pattern, but all the tests essentially work by setting up the code
to be analyzed, then assert that either the expected diagnostic has been
produced in the expected locations or that there are no diagnostics being
generated. (It's often valuable to test that the diagnostic doesn't have any
false positives.)

## Report the diagnostic

The last step is to write the code to report the diagnostic. Where that code
lives depends on the kind of diagnostic you're adding.

If you're adding a diagnostic that's defined by the language specification
(with a severity of 'error'), then the best place to implement it will usually
be in one of the `<node class>Resolver` classes.

If you're adding a warning, then the class `BestPracticesVerifier` is usually
the best place for it.

## Document the diagnostic

After the diagnostic has been implemented and committed, documentation for the
diagnostic needs to be written.

__Note:__ We are in the process of defining a process for this task, so this
section is currently incomplete. Contact us for details if you want to write the
documentation yourself. If you don't want to write the documentation then we'll
write it for you.

Before you start writing documentation we recommend that you look at several of
the existing examples of documentation to get a feeling for the general writing
style and format of the docs. Some of this information is also found below. If
you have questions about style, we follow the general
[Google style guidelines](https://developers.google.com/style/).

The documentation for the diagnostics that are implemented in the analyzer is in
the file `analyzer/messages.yaml`. They are under the key `documentation:`, and
are mostly standard markdown. The differences are described below.

### Template

The good news is that the documentation is highly stylized, so writing it is
usually fairly easy.

To start writing the documentation, copy the following template. Each section is
discussed below.

    #### Description

    The analyzer produces this diagnostic when

    #### Example

    The following code produces this diagnostic because :

    ```dart
    ```

    #### Common fixes

    ```dart
    ```

### Description

The Description section should start by explaining _when_ the diagnostic will be
produced. Specifically, that means the conditions that cause the diagnostic to
be produced. The goal is to help the user understand why the diagnostic is
appearing in their code, so the explanation needs to cover all of the possible
reasons.

For example, the diagnostic `invalid_extension_argument_count` describes the
conditions that cause the diagnostic this way:

> The analyzer produces this diagnostic when an extension override doesn't
> have exactly one argument.

Unless it's fairly obvious, the description should also explain _why_ the
condition is being reported. In most cases the reason for the diagnostic will be
obvious from the description of when it's reported, but sometimes that isn't
enough.

For example, the user might not be familiar with extension overrides, so the
explanation above might not be sufficient. By explaining why an override must
have a single argument we can help the user learn about the feature, so the
documentation goes on to explain that:

> The argument is the expression used to compute the value of `this` within the
> extension method, so there must be one argument.

### Examples

The Examples section should show at least one example of code that will produce
the diagnostic. (If there's only one example, then the title should be singular
as in the template above, but if there are multiple examples the title should be
plural.)

The examples should be complete in the sense that the user should be able to
copy the example, paste it into an empty compilation unit, and see exactly the
one diagnostic being reported. (One technique we often use for this purpose is
to define local variables as parameters to a method or function so that the
`unused_local_variable` diagnostic isn't also reported.)

The examples should be minimal so that users aren't distracted by irrelevant
details. They should only include code that is required in order to generate
the diagnostic. They should use simple names, like `A`, `B`, and `C` for
classes, `M` for mixins, `f` and `g` for functions, and so on. It's better to
not use names with semantic value.

Each example must have the range of characters that are highlighted by the
diagnostic enclosed between `[!` and `!]` delimiters. These are used to
highlight the region on the web page and are also validated by tests.

Every code block must specify a file type, such as `dart` or `yaml`.

The examples occasionally need some additional support, which is provided by
"directives". The directives must be on the first lines of the code block, and
have the form `%directiveName=`. There are two directives defined.

The experiments directive (`%experiments=`) specifies a comma-separated list of
the names of language experiments that are to be enabled when analyzing the
example. This is necessary when writing documentation for experiments that
haven't yet shipped. These directives should be removed once the experiment is
enabled by default.

The uri directive (`%uri=`) specifies the URI for the file containing the code
block. Without a uri directive the standard uri will be used. This directive is
necessary for cases when an example needs an auxiliary file to be defined,
usually so that it can be imported in the example. Code blocks that have a uri
directive are considered to be auxiliary files, not examples, and aren't
analyzed or required to have highlight range markers. Auxiliary files exist
when either an example or a common fix is analyzed.

### Common fixes

The Common fixes section should show examples of the ways to fix the problem
that are most likely to be applicable. In some cases there's only one likely way
to fix the problem (like removing the null check operator when the expression
isn't nullable), but in other cases there might be multiple possible ways of
fixing the problem.

There should minimally be one fix shown for every action suggested by the
diagnostic's correction message.

Each fix should use one of the examples as the base and show how the invalid
code can be changed to apply the described fix. The same example can be used by
multiple fixes.

Each fix should be introduced by a sentence that explains what change the user
would make for the fix. Usually the description is written in the form "If
_these conditions hold_, then _make this change_:" so that users can tell when a
suggested fix can be applied.

Fixes can't have highlight markers, and are expected to not have any diagnostics
reported.
