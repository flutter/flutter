Common issues Flutter developers might run into and recipes how to fix or work around.

= Flutter Recipes

== Flutter installation

=== Flutter installation corrupted

The Flutter install directory is in an inconsistent state and that causes all kinds of troubles.

==== Symptoms

// TODO

==== Causes

Unclear

==== Ways to fix

- Run the following commands in the Flutter install directory:
[source,sh]
----
git clean -xfd
git stash save --keep-index
git stash drop
git pull
flutter doctor
----

[CAUTION]
====
The `git stash drop` command drops customizations you might have made to the Flutter installation.
====

==== Related information
- https://github.com/flutter/flutter/issues/25220
- https://github.com/flutter/flutter/issues/1963

== Flutter project files

=== Generated project files outdated

==== Symptoms
// TODO

==== Causes

When a project is created with `flutter create foo` several files in the `ios/` and `android/` sub-directories are created.

Newer Flutter versions might generate these files a bit differently and projects created with older Flutter versions might cause issues.

==== Ways to fix

- Delete the `ios/` and `android/` directories and run `flutter create .` to re-generate these directories.

[CAUTION]
====
Custom changes will be lost and need to be re-applied.
This is easiest if the project is committed to a version control system like Git.
====


==== Related information
- https://github.com/flutter/flutter/issues/14974
- https://github.com/flutter/flutter/issues/12573
- https://github.com/flutter/flutter/issues/12983
- https://github.com/flutter/flutter/issues/9827


== Pub dependencies

=== Corrupted cache

Especially with plugin packages it was seen several times that the package in the pub cache was corrupted.

==== Symptoms
Usually syntax errors at build time about code in dependencies.

==== Causes

Unknown.
IDEs or editors used by developers might not prevent editing plugin files and when they navigate into plugin code they might accidentally modify the code.

==== Ways to fix

- Run `pub cache repair`
This might take quite some time and re-downloads every package in the cache, even outdated versions that might not be used anymore by any project on disk.

- Delete `~/.pub-cache/hosted` and/or `~/.pub-cache/git` (for Git dependencies).
This requires to run `flutter packages get` in all active projects on your machine afterwards.

- Delete a specific package or package version.
Look up the exact path in cache for a specific package in the `.packages` file of your project.
For example for `firebase_auth`
```
firebase_auth:file:///Users/someuser/.pub-cache/hosted/pub.dartlang.org/firebase_auth-0.6.6/lib/
```
To fix this package delete `///Users/someuser/.pub-cache/hosted/pub.dartlang.org/firebase_auth-0.6.6/` (`lib/` removed) and run `flutter packages get`.

==== Related information
- https://www.dartlang.org/tools/pub/cmd/pub-cache
- https://www.dartlang.org/tools/pub/environment-variables

== Proxy

=== Flutter commands can not access the Internet

In a network where the Internet can only be reached through a proxy and Flutter commands fail.

==== Symtoms

// TODO

==== Causes

Proxy setting incomplete or invalid.

==== Related information
(none yet)

=== Hot-reload not working

When a proxy is configured hot-reload does often not work.

==== Symptoms

// TODO

==== Causes

Proxy setting incomplete or invalid.
Localhost is redirected to the proxy.

==== Ways to fix

- Set environment variable `NO_PROXY=127.0.0.1`

==== Related information

- https://github.com/flutter/flutter/issues/24854
- https://github.com/flutter/flutter/issues/16875#issuecomment-384758566
- https://stackoverflow.com/questions/9546324/adding-directory-to-path-environment-variable-in-windows[Adding directory to PATH Environment Variable in Windows]
- https://stackoverflow.com/questions/19287379/how-do-i-add-to-the-windows-path-variable-using-setx-having-weird-problems[How do I add to the Windows PATH variable using setx? Having weird problems]


= Empty Template for new recipes

Copy from the following line down

== Topic name

=== Issue title

Issue description

==== Symptoms
Explain seen symptoms

==== Causes

Explain what causes this issue

==== Ways to fix

- Do this, do that as well

==== Related information
- https://example.com/some_link.html


= AsciiDoc Recipes

==== AsciiDoc Syntax Quick Reference

- https://asciidoctor.org/docs/asciidoc-syntax-quick-reference/

==== GitHub Flavored AsciiDoc

Some workarounds for common issues with AsciiDoc on GitHub

- https://gist.github.com/dcode/0cfbf2699a1fe9b46ff04c41721dda74