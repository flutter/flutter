Sky module system
=================

This document describes the Sky module system.

Overview
--------

The Sky module system is based on the ```import``` element. In its
most basic form, you import a module as follows:

```html
<import src="path/to/module.sky" />
```

As these ```import``` elements are inserted into a document, the
document's list of outstanding dependencies grows. When an imported
module completes, it is removed from the document's list of
outstanding dependencies.

Before executing any ```script``` elements, the parser waits until the
list of outstanding dependencies is empty. After the parser has
finished parsing, the document waits until its list of outstanding
dependencies is empty before the module it represents is marked
complete.

Module API
----------

Within a script in a module, the ```module``` identifier is bound to
the ```Module``` object that represents the module:

```javascript
interface Module : EventTarget {
  constructor (Application application, Document document); // O(1)
  attribute any exports; // O(1) // defaults to the module's document
  readonly attribute Document document; // O(1) // the module's document
  readonly attribute Application application; // O(1)
}
```

### Exporting values ###

A module can export a value by assigning the ```exports``` property of
its ```Module``` object. By default, the ```exports``` property of a
```Module``` is its ```Document``` object, so that a script-less
import is still useful (it exposes its contents, e.g. templates that
the import might have been written to provide).

Naming modules
--------------

The ```as``` attribute on the ```import``` element binds a name to the
imported module:

```html
<import src="path/to/chocolate.sky" as="chocolate" />
```

The parser executes the contents of script elements inside a module as
if they were executed as follow:

```javascript
(new Function(name_1, ..., name_n, module, source_code)).call(
  value_1, ..., value_n, source_module);
```

Where ```name_1``` through ```name_n``` are the names bound to the
various named imports in the script element's document,
```source_code``` is the text content of the script element,
```source_module`` is the ```Module``` object of the script element's
module, and ```value_1``` through ```value_n``` are the values
exported by the various named imports in the script element's
document.

When an import fails to load, the ```as``` name for the import gets
bound to ```undefined```.
