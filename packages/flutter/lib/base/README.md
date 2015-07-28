Sky Base
========

AbstractNode
------------

The [node.dart](node.dart) file defines a class, `AbstractNode`, which
can be used to build mutable trees.

* When a subclass is changing the parent of a child, it should
  call either parent.adoptChild(child) or parent.dropChild(child)
  as appropriate. Subclasses should expose an API for
  manipulating the tree if you want to (e.g. a setter for a
  'child' property, or an 'add()' method to manipulate a list).

* You can see the current parent by querying 'parent'.

* You can see the current attachment state by querying
  'attached'. The root of any tree that is to be considered
  attached should be manually attached by calling 'attach()'.
  Other than that, don't call 'attach()' or 'detach()'. This is
  all managed automatically assuming you call the 'adoptChild()'
  and 'dropChild()' methods appropriately.

* Subclasses that have children must override 'attach()' and
  'detach()' as described below.

* Nodes always have a 'depth' greater than their ancestors'.
  There's no guarantee regarding depth between siblings. The
  depth of a node is used to ensure that nodes are processed in
  depth order. The 'depth' of a child can be more than one
  greater than the 'depth' of the parent, because the 'depth'
  values are never decreased: all that matters is that it's
  greater than the parent. Consider a tree with a root node A, a
  child B, and a grandchild C. Initially, A will have 'depth' 0,
  B 'depth' 1, and C 'depth' 2. If C is moved to be a child of A,
  sibling of B, then the numbers won't change. C's 'depth' will
  still be 2. This is all managed automatically assuming you call
  'adoptChild()' and 'dropChild()' appropriately.


Dependencies
------------

No dependencies except for `dart:sky` and Dart's core libraries.
