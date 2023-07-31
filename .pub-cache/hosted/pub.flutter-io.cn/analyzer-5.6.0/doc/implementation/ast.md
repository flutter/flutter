# Extending the AST

Supporting a new language feature often requires extending the AST. This
document describes what's involved in adding new fields to exiting nodes or
adding new nodes. This document does not describe the work that needs to be done
after the AST structure has been updated; those topics are covered in other
documents.

Note that not every new language feature requires updating the AST, and the AST
structure should only be updated when necessary. For example, if Dart were to
introduce a new binary operator, there likely wouldn't be any need for new nodes
because the existing nodes would probably cover the changes to the grammar. So,
the first step should always be to consider whether changes need to be made.

If it is necessary to change the AST, then you'll either be modifying an
existing node or adding new nodes. Those tasks are discussed separately.

## Extending or changing an existing node

If an existing syntactic construct is being changed, then you should probably
update the existing node representing that construct. If the change is
significant enough it's possible that it's better to add a new node, but that
should be uncommon.

If the change is to add some new tokens or child nodes, then doing so ought to
be a non-breaking change. For each of the children you'll need to add a new
getter and a new parameter to the constructor on the implementation class, but
the implementation classes aren't public API.

If the change requires a modification to an existing part of the public API,
then it needs to be handled by first adding the replacement for the modified
member, deprecating the old member, and then removing the old member as part of
a later breaking change release.

## Adding new nodes

If there are new syntactic constructs that can't cleanly be represented by an
existing class of node, then you'll need to add new classes. This section
describes what's involved in doing so.

### Design the node structure

The first step is to design the new node structure. We want the structure of the
AST to be self-consistent, so this section will discuss a few of the design
tradeoffs that you'll need to consider.

The node structure generally follows from the language grammar. That doesn't
mean that the structure follows the grammar exactly, but it _is_ representing
the syntax of the language, so, with one exception discussed below, it should be
equivalent to the original grammar, even if it's rewritten slightly.

If a grammar productions contain alternates (`|`), then you should create a
different node class for each branch of the production.

If a production has an optional group (`(a b c)?`), you should create a separate
node class for the group. It's generally better to have one nullable getter for
the whole group than to have separate nullable getters for each element of the
group when the getters either all return `null` or all return a non-`null`
value. 

If a production has a repeated element (`a*`), you should create a separate node
class for the repeated element and the AST will contain a list of such elements.

The one exception (to the rule that the AST should be equivalent to the language
grammar) is that it is sometimes better for the AST to represent a superset of
the grammar. We do this primarily to improve recovery in the face of invalid
code.

### Define the public API

The next step is to define the public API for the new AST nodes. We do that by
defining abstract classes in `analyzer/lib/dart/ast/ast.dart`. Every member of
the class should also be abstract because we're using the class as an interface.
That means that you can define getters and methods, but shouldn't define fields.
And because the AST is always read-only from a client's perspective, there also
shouldn't be any setters.

By convention, these classes use `implements` to represent the type hierarchy
rather than using `extends`. We do that to emphasize that we're defining an
interface, not a class. Every class (other than `AstNode`) should implement at
least one other class in this file, with `AstNode` being the root of the type
hierarchy.

The AST nodes typically have getters for all the tokens and child nodes in the
AST structure. The one exception is that we generally don't capture the commas
separating the elements in lists.

It's often useful to get a review of the node structure you've created before
going on to the next steps because it will save you a lot of work if the node
structure changes as a result of the code review.

### Define the implementation

After the public API is defined you'll need to implement the nodes. The
implementation should be defined in `analyzer/lib/src/dart/ast/ast.dart`.

There will typically be one concrete implementation class for each of the
abstract public classes defined above. The concrete class must implement the
public class and should extend one of the concrete classes corresponding to one
of the classes that the abstract class implements.

### Add the nodes to the visitor classes

A new `visit` method should be added to `AstVisitor` for a subset of the new
public interfaces that were added. In particular, there should be a `visit`
method for each of the interfaces for which there will be a node in the AST that
is an instance of that interface but not an instance of a subtype of that
interface.

Adding these `visit` methods will require you to add corresponding `visit`
methods to several utility visitors that implement `AstVisitor`. For the most
part you can replicate one of the existing methods in the utility visitors to
implement the new `visit` methods.

One exception is the class `GeneralizingAstVisitor`, where you might want to add
some additional `visit` methods for some supertypes of the interfaces being
visited.

Another exception is the class `ToSourceVisitor` where each visit method needs
to textually reproduce the node. The produced text should be as close to valid
Dart syntax as possible, but doesn't need to attempt to reproduce the original
text. In particular, the methods don't preserve things like comments or trailing
commas (unless those trailing commas are semantically meaningful).

### Add linter support

In order for lints to be able to visit the new node classes you also need to
update the classes in `analyzer/lib/src/lint/linter_visitor.dart`.

For each class of node that was added you need to add one field and one `add`
method in `NodeLintRegistry`. You then need to add visit methods to
`LinterVisitor`. All of this code can be modeled after the implementation of
existing methods.

### Add test support

Many of the tests use a utility class named `FindNode` to locate nodes of
interest within an AST structure. That class has a separate method for each
concrete subclass of `AstNode`, so you'll want to add methods to it for each of
the classes you've added. The class is in
`analyzer/lib/src/test_utilities/find_node.dart`.
