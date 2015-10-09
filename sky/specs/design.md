Design Principles
=================

Flutter is written based on some core principles that were mostly
intuited from past experiences with other platforms such as the Web
and Android, some of which are summarised below.

Lazy programming
----------------

Write what you need and no more, but when you write it, do it right.

Avoid implementing features you don't need. You can't design a feature
without knowing what the constraints are. Implementing features "for
completeness" results in unused code that is expensive to maintain,
learn about, document, test, etc.

When you do implement a feature, implement it the right way. Avoid
workarounds. Workarounds merely kick the problem further down the
road, but at a higher cost: someone will have to relearn the problem,
figure out the workaround and how to dismantle it (and all the places
that now use it), _and_ implement the feature.

Tests
-----

When you fix a bug, first write a test that fails, then fix the bug
and verify the test passes.

When you implement a new feature, write tests for it.

Run the tests before checking code in. (Travis does this for you, so
wait for Travis to give the green light before merging a PR.)

API design
----------

* There should be no objects that represent live state that reflects
  some other state, since they are expensive to maintain. e.g. no
  HTMLCollection.

* Property getters should be efficient (e.g. just returning a cached
  value, or an O(1) table lookup). If an operation is inefficient it
  should be a method instead. e.g. document.getForms(), not
  document.forms.

* There should be no APIs that require synchronously completing an
  expensive operation (e.g. computing a full app layout outside of the
  layout phase).

* We use a layered framework design, where each layer addresses a
  narrowly scoped problem and is then used by the next layer to solve
  a bigger problem. This is true both at a high level (widgets relies
  on rendering relies on painting) and at the level of individual
  classes and methods (e.g. in the rendering library, having one class
  for clipping and one class for opacity rather than one class that
  does both at the same time).

 - Convenience APIs belong at the layer above the one they are
   simplifying.

 - Having dedicated APIs for performance reasons is fine. If one
   specific operation, say clipping a rounded rectangle, is expensive
   using the generic API but could be implemented more efficiently
   using a dedicated API, then a dedicated API is fine.

* APIs that encourage bad practices should not exist. e.g., no
  document.write(), innerHTML, insertAdjacentHTML(), etc.

 - String manipulation to generate data or code that will subsequently
   be interpreted or parsed is a bad practice as it leads to code
   injection vulnerabilities.

* If we expose some aspect of a mojo service, we should expose/wrap
  all of it, so that there's no cognitive cliff when interacting with
  that service (where you are fine using the exposed API up to a
  point, but beyond that have to learn all about the underlying
  service).

Bugs
----

"Don't lick the cookie": Only assign a bug to yourself when you are
actively working on it. If you're not working on it, leave it
unassigned. Don't assign bugs to people unless you know they are going
to work on it.

File bugs for anything that you come across that needs doing. When you
implement something but know it's not complete, file bugs for what you
haven't done. That way, we can keep track of what still needs doing.

Regressions
-----------

If a check-in has caused a regression on the trunk, roll back the
check-in (even if it isn't yours) unless doing so would take longer
than fixing the bug. When the trunk is broken, it slows down everyone
else on the project.

There is no shame in making mistakes.

Questions
---------

It's always ok to ask questions. Our systems are large, nobody will be
an expert in all the systems.
