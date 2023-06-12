# Summaries in Dart analyzer

The purpose of this document is to provide a high-level overview of the summaries linking, storage format, and reading
in Dart analyzer.

## Design Considerations

There are a couple of considerations to keep in mind when discussing the design.

**We want the linking to be done using AST.** Default values, constructor initializers, and field initializers should be
stored in their resolved state, with elements and type, because we need them to perform constant evaluation.

**We want separation between AST and resolution.** Files change rarely, usually the user changes just one file, and this
affects resolution of this file and a multiple other files. But only the resolution, not AST. So, we want to keep pieces
that are not affected by the change.

**We want to read only as much as necessary to do resolution.** Libraries often have many classes, but when we resolve a
file, we don’t need all these classes, only those that are actually referenced. So, we want the format to support
loading individual classes, functions, etc.

## High level view

When the analyzer needs to resolve a file, it works in the following way:

1. Find the library cycle that contains this file, and library cycles of its dependencies, down to SDK.

2. Link these library cycles from SDK up to the target cycle.

3. Add linked bundles to `LinkedElementFactory`.

4. When we need a specific element, we call `LinkedElementFactory.elementOfReference`. It will request parent elements,
   and eventually load the containing library, the containing class, method, etc.

## Lazy loading

We try to load only libraries that are necessary. When a `PackageBundleReader` is created, it decodes only the header of
the bundle - with the list of library URIs contained in the bundle, and creates `LibraryReader`s.

When `LinkedElementFactory.createLibraryElementForReading` is invoked, the corresponding `LibraryReader` is asked to
load units, which are `UnitReader`s. Each `UnitReader` keeps track of the location of its AST and resolution portions
in `astReader` and `resolutionReader`. When `UnitReader` is created, it reads the index of top-level declarations, and
fills `Reference` subtree. For each `Reference` we set its `nodeAccessor`, a pointer to the `_UnitMemberReader`, which
can be used to load the corresponding AST node. This is a way to present the index of the unit to `LinkedElementFactory`
.

To support lazy loading the package bundle has the index of libraries, the library has the index of units, the unit has
the index of top-level declarations, the class / extension / mixin has the index of members.

Any time when we need the element for a `Reference`, we call `elementOfReference` of `LinkedElementFactory`, which
asks `Reference.nodeAccessor` for the AST node, and then creates the corresponding `Element` wrapper around it, and
stores into `Reference.element`. For example for `ClassDeclaration` it will create `ClassElement`. No resolution is
required yet.

When `Reference.element` is already set, we just return it, we have already done loading AST node and creating the
element for this `Reference`.

When we link libraries, we don’t use `LinkedElementFactory` to read nodes and create elements, because we already have
full ASTs, and we can create elements for all nodes in advance, and put them into corresponding `Reference` children.

We say that we need the element for a `Reference` because resolution stores elements as such references - a pair of the
name, and the parent reference. So, we may have an empty `Reference` first, without `element` and `nodeAccessor`, then
when `elementOfReference` is invoked, it will fill both for a `Reference`. But its siblings will stay unfilled.

When we ask an `Element` anything that requires resolution, we apply resolution to the whole AST node of the element.
For example, when we ask `ClassElement` for `supertype`, we apply resolution to the `ClassDeclaration` header (but not
to any member of the `ClassDeclaration`) - supertype, mixins, interfaces. We do this by calling `applyResolution`
of `AstLinkedContext`. We get `AstLinkedContext` from the node, which implements `HasAstLinkedContext`.

`AstBinaryWriter` writes two streams of information at once - the AST itself, and resolution. In the future we might
split writing AST and resolution into separate writers.

Resolution information is just a sequence of elements and types, which is stored when we visit the resolved AST
in `AstBinaryWriter`. We use the helper `_ResolutionSink` to encode elements and types into bytes.

Resolution is applied to unresolved AST using `ApplyResolutionVisitor`, which visits AST nodes in the same sequence
as `AstBinaryWriter`, and takes either elements or types from the same (untyped, unmarked in any way) stream of
resolution bytes. `LinkedResolutionReader` corresponds to `_ResolutionSink` - it decodes elements and types from bytes.

Each raw element is represented by an integer, an index in the reference table. This table is collected during writing
in `_BundleWriterReferences`, and stored by `BundleWriterResolution` during `BundleWriter.finish()`. During
loading `BundleReader` creates `_ReferenceReader`, which lazily converts names and parent references into `Reference`
instances in the given `LinkedElementFactory` (from which we just take `rootReference`, not actually any elements). Once
we have `Reference` for the element that we need to decode, we actually ask `LinkedResolutionReader` for the element,
see above.

In addition to raw elements, there are “members” (which is not the best name) - which might be `Element`s which we want
to convert to legacy because they are declared in a null safe library, but we want their legacy types; or actually
members of a class with type parameters and with some `Substitution` applied to them; or both.

Strings are encoded as integers, during writing using `StringIndexer`, and during loading using `_StringTable`. We
use `SummaryDataReader` to load primitive types, and also strings.

## Known limitations

Currently `LibraryScope` and its basis `_LibraryImportScope` and `PrefixScope` - they all work by asking all elements
from the imported libraries. Which means that we load all top-level nodes of these libraries (and all libraries that
they export). Fortunately we don’t apply resolution to these elements until we try to access some property of these
elements, e.g. the return type of a getter. But still, we probably don’t actually use all the imported elements, and we
potentially could avoid loading all these AST nodes. A solution could be to work with `Reference`s instead.

Similarly `InheritanceManager3` builds the whole interface of a class, and loads all members of the class and all
members of all its superinterfaces. But again, we might only call a few methods, and might not need any superinterfaces.
A solution might be to fill class interfaces on demand.
