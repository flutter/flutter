Design Principles
=================

* There should be no objects that represent live state that reflects
  some other state, since they are expensive to maintain. e.g. no
  HTMLCollection.

* Property getters should be efficient. If an operation is inefficient
  it should be a method instead. e.g. document.getForms(), not
  document.forms.

* There should be no APIs that require synchronously computing layout
  (or other expensive operations).

* Any API that can be implemented in terms of another is a convenience
  API and should be implemented in a framework, not as part of the
  core. e.g., no document.forms.

 - having APIs for performance reasons is fine (e.g. querySelector()
   could be implemented by crawling but it would be so much faster if
   it could use the runtime's ID hashtables that it's ok to support
   natively)

* APIs that encourage bad practices should not exist. e.g., no
  document.write(), innerHTML, insertAdjacentHTML(), etc.

* If we expose some aspect of a mojo service (e.g. touch events) we
  should expose/wrap all of it (e.g. mousewheel) so that there's no
  cognitive cliff when interacting with that service

* APIs should always spell acronyms like words (findId, not findID;
  XmlHttpRequest, not XMLHttpRequest)
