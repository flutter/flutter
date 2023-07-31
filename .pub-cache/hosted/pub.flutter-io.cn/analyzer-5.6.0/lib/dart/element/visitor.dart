// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Defines element visitors that support useful patterns for visiting the
/// elements in an [element model](element.dart).
///
/// Dart is an evolving language, and the element model must evolved with it.
/// When the element model changes, the visitor interface will sometimes change
/// as well. If it is desirable to get a compilation error when the structure of
/// the element model has been modified, then you should consider implementing
/// the interface [ElementVisitor] directly. Doing so will ensure that changes
/// that introduce new classes of elements will be flagged. (Of course, not all
/// changes to the element model require the addition of a new class of element,
/// and hence cannot be caught this way.)
///
/// But if automatic detection of these kinds of changes is not necessary then
/// you will probably want to extend one of the classes in this library because
/// doing so will simplify the task of writing your visitor and guard against
/// future changes to the element model. For example, the
/// [RecursiveElementVisitor] automates the process of visiting all of the
/// descendants of an element.
import 'package:analyzer/dart/element/element.dart';

/// An element visitor that will recursively visit all of the elements in an
/// element model (like instances of the class [RecursiveElementVisitor]). In
/// addition, when an element of a specific type is visited not only will the
/// visit method for that specific type of element be invoked, but additional
/// methods for the supertypes of that element will also be invoked. For
/// example, using an instance of this class to visit a [MethodElement] will
/// cause the method [visitMethodElement] to be invoked but will also cause the
/// methods [visitExecutableElement] and [visitElement] to be subsequently
/// invoked. This allows visitors to be written that visit all executable
/// elements without needing to override the visit method for each of the
/// specific subclasses of [ExecutableElement].
///
/// Note, however, that unlike many visitors, element visitors visit objects
/// based on the interfaces implemented by those elements. Because interfaces
/// form a graph structure rather than a tree structure the way classes do, and
/// because it is generally undesirable for an object to be visited more than
/// once, this class flattens the interface graph into a pseudo-tree. In
/// particular, this class treats elements as if the element types were
/// structured in the following way:
///
/// <pre>
/// Element
///   ClassElement
///   CompilationUnitElement
///   ExecutableElement
///       ConstructorElement
///       LocalElement
///           FunctionElement
///       MethodElement
///       PropertyAccessorElement
///   ExportElement
///   HtmlElement
///   ImportElement
///   LabelElement
///   LibraryElement
///   MultiplyDefinedElement
///   PrefixElement
///   TypeAliasElement
///   TypeParameterElement
///   UndefinedElement
///   VariableElement
///       PropertyInducingElement
///           FieldElement
///           TopLevelVariableElement
///       LocalElement
///           LocalVariableElement
///           ParameterElement
///               FieldFormalParameterElement
/// </pre>
///
/// Subclasses that override a visit method must either invoke the overridden
/// visit method or explicitly invoke the more general visit method. Failure to
/// do so will cause the visit methods for superclasses of the element to not be
/// invoked and will cause the children of the visited node to not be visited.
///
/// Clients may extend this class.
class GeneralizingElementVisitor<R> implements ElementVisitor<R> {
  /// Initialize a newly created visitor.
  const GeneralizingElementVisitor();

  @override
  R? visitAugmentationImportElement(AugmentationImportElement element) =>
      visitElement(element);

  @override
  R? visitClassElement(ClassElement element) => visitElement(element);

  @override
  R? visitCompilationUnitElement(CompilationUnitElement element) =>
      visitElement(element);

  @override
  R? visitConstructorElement(ConstructorElement element) =>
      visitExecutableElement(element);

  R? visitElement(Element element) {
    element.visitChildren(this);
    return null;
  }

  @override
  R? visitEnumElement(EnumElement element) => visitElement(element);

  R? visitExecutableElement(ExecutableElement element) => visitElement(element);

  @override
  R? visitExtensionElement(ExtensionElement element) => visitElement(element);

  @override
  R? visitFieldElement(FieldElement element) =>
      visitPropertyInducingElement(element);

  @override
  R? visitFieldFormalParameterElement(FieldFormalParameterElement element) =>
      visitParameterElement(element);

  @override
  R? visitFunctionElement(FunctionElement element) =>
      visitLocalElement(element);

  @override
  R? visitGenericFunctionTypeElement(GenericFunctionTypeElement element) =>
      visitElement(element);

  @override
  R? visitLabelElement(LabelElement element) => visitElement(element);

  @override
  R? visitLibraryAugmentationElement(LibraryAugmentationElement element) =>
      visitElement(element);

  @override
  R? visitLibraryElement(LibraryElement element) => visitElement(element);

  @override
  R? visitLibraryExportElement(LibraryExportElement element) =>
      visitElement(element);

  @override
  R? visitLibraryImportElement(LibraryImportElement element) =>
      visitElement(element);

  R? visitLocalElement(LocalElement element) {
    if (element is LocalVariableElement) {
      return visitVariableElement(element);
    } else if (element is ParameterElement) {
      return visitVariableElement(element);
    } else if (element is FunctionElement) {
      return visitExecutableElement(element);
    }
    return null;
  }

  @override
  R? visitLocalVariableElement(LocalVariableElement element) =>
      visitLocalElement(element);

  @override
  R? visitMethodElement(MethodElement element) =>
      visitExecutableElement(element);

  @override
  R? visitMixinElement(MixinElement element) => visitElement(element);

  @override
  R? visitMultiplyDefinedElement(MultiplyDefinedElement element) =>
      visitElement(element);

  @override
  R? visitParameterElement(ParameterElement element) =>
      visitLocalElement(element);

  @override
  R? visitPartElement(PartElement element) => visitElement(element);

  @override
  R? visitPrefixElement(PrefixElement element) => visitElement(element);

  @override
  R? visitPropertyAccessorElement(PropertyAccessorElement element) =>
      visitExecutableElement(element);

  R? visitPropertyInducingElement(PropertyInducingElement element) =>
      visitVariableElement(element);

  @override
  R? visitSuperFormalParameterElement(SuperFormalParameterElement element) =>
      visitParameterElement(element);

  @override
  R? visitTopLevelVariableElement(TopLevelVariableElement element) =>
      visitPropertyInducingElement(element);

  @override
  R? visitTypeAliasElement(TypeAliasElement element) => visitElement(element);

  @override
  R? visitTypeParameterElement(TypeParameterElement element) =>
      visitElement(element);

  R? visitVariableElement(VariableElement element) => visitElement(element);
}

/// A visitor that will recursively visit all of the element in an element
/// model. For example, using an instance of this class to visit a
/// [CompilationUnitElement] will also cause all of the types in the compilation
/// unit to be visited.
///
/// Subclasses that override a visit method must either invoke the overridden
/// visit method or must explicitly ask the visited element to visit its
/// children. Failure to do so will cause the children of the visited element to
/// not be visited.
///
/// Clients may extend this class.
class RecursiveElementVisitor<R> implements ElementVisitor<R> {
  /// Initialize a newly created visitor.
  const RecursiveElementVisitor();

  @override
  R? visitAugmentationImportElement(AugmentationImportElement element) {
    element.visitChildren(this);
    return null;
  }

  @override
  R? visitClassElement(ClassElement element) {
    element.visitChildren(this);
    return null;
  }

  @override
  R? visitCompilationUnitElement(CompilationUnitElement element) {
    element.visitChildren(this);
    return null;
  }

  @override
  R? visitConstructorElement(ConstructorElement element) {
    element.visitChildren(this);
    return null;
  }

  @override
  R? visitEnumElement(EnumElement element) {
    element.visitChildren(this);
    return null;
  }

  @override
  R? visitExtensionElement(ExtensionElement element) {
    element.visitChildren(this);
    return null;
  }

  @override
  R? visitFieldElement(FieldElement element) {
    element.visitChildren(this);
    return null;
  }

  @override
  R? visitFieldFormalParameterElement(FieldFormalParameterElement element) {
    element.visitChildren(this);
    return null;
  }

  @override
  R? visitFunctionElement(FunctionElement element) {
    element.visitChildren(this);
    return null;
  }

  @override
  R? visitGenericFunctionTypeElement(GenericFunctionTypeElement element) {
    element.visitChildren(this);
    return null;
  }

  @override
  R? visitLabelElement(LabelElement element) {
    element.visitChildren(this);
    return null;
  }

  @override
  R? visitLibraryAugmentationElement(LibraryAugmentationElement element) {
    element.visitChildren(this);
    return null;
  }

  @override
  R? visitLibraryElement(LibraryElement element) {
    element.visitChildren(this);
    return null;
  }

  @override
  R? visitLibraryExportElement(LibraryExportElement element) {
    element.visitChildren(this);
    return null;
  }

  @override
  R? visitLibraryImportElement(LibraryImportElement element) {
    element.visitChildren(this);
    return null;
  }

  @override
  R? visitLocalVariableElement(LocalVariableElement element) {
    element.visitChildren(this);
    return null;
  }

  @override
  R? visitMethodElement(MethodElement element) {
    element.visitChildren(this);
    return null;
  }

  @override
  R? visitMixinElement(MixinElement element) {
    element.visitChildren(this);
    return null;
  }

  @override
  R? visitMultiplyDefinedElement(MultiplyDefinedElement element) {
    element.visitChildren(this);
    return null;
  }

  @override
  R? visitParameterElement(ParameterElement element) {
    element.visitChildren(this);
    return null;
  }

  @override
  R? visitPartElement(PartElement element) {
    element.visitChildren(this);
    return null;
  }

  @override
  R? visitPrefixElement(PrefixElement element) {
    element.visitChildren(this);
    return null;
  }

  @override
  R? visitPropertyAccessorElement(PropertyAccessorElement element) {
    element.visitChildren(this);
    return null;
  }

  @override
  R? visitSuperFormalParameterElement(SuperFormalParameterElement element) {
    element.visitChildren(this);
    return null;
  }

  @override
  R? visitTopLevelVariableElement(TopLevelVariableElement element) {
    element.visitChildren(this);
    return null;
  }

  @override
  R? visitTypeAliasElement(TypeAliasElement element) {
    element.visitChildren(this);
    return null;
  }

  @override
  R? visitTypeParameterElement(TypeParameterElement element) {
    element.visitChildren(this);
    return null;
  }
}

/// A visitor that will do nothing when visiting an element. It is intended to
/// be a superclass for classes that use the visitor pattern primarily as a
/// dispatch mechanism (and hence don't need to recursively visit a whole
/// structure) and that only need to visit a small number of element types.
///
/// Clients may extend this class.
class SimpleElementVisitor<R> implements ElementVisitor<R> {
  /// Initialize a newly created visitor.
  const SimpleElementVisitor();

  @override
  R? visitAugmentationImportElement(AugmentationImportElement element) => null;

  @override
  R? visitClassElement(ClassElement element) => null;

  @override
  R? visitCompilationUnitElement(CompilationUnitElement element) => null;

  @override
  R? visitConstructorElement(ConstructorElement element) => null;

  @override
  R? visitEnumElement(EnumElement element) => null;

  @override
  R? visitExtensionElement(ExtensionElement element) => null;

  @override
  R? visitFieldElement(FieldElement element) => null;

  @override
  R? visitFieldFormalParameterElement(FieldFormalParameterElement element) =>
      null;

  @override
  R? visitFunctionElement(FunctionElement element) => null;

  @override
  R? visitGenericFunctionTypeElement(GenericFunctionTypeElement element) =>
      null;

  @override
  R? visitLabelElement(LabelElement element) => null;

  @override
  R? visitLibraryAugmentationElement(LibraryAugmentationElement element) =>
      null;

  @override
  R? visitLibraryElement(LibraryElement element) => null;

  @override
  R? visitLibraryExportElement(LibraryExportElement element) => null;

  @override
  R? visitLibraryImportElement(LibraryImportElement element) => null;

  @override
  R? visitLocalVariableElement(LocalVariableElement element) => null;

  @override
  R? visitMethodElement(MethodElement element) => null;

  @override
  R? visitMixinElement(MixinElement element) => null;

  @override
  R? visitMultiplyDefinedElement(MultiplyDefinedElement element) => null;

  @override
  R? visitParameterElement(ParameterElement element) => null;

  @override
  R? visitPartElement(PartElement element) => null;

  @override
  R? visitPrefixElement(PrefixElement element) => null;

  @override
  R? visitPropertyAccessorElement(PropertyAccessorElement element) => null;

  @override
  R? visitSuperFormalParameterElement(SuperFormalParameterElement element) =>
      null;

  @override
  R? visitTopLevelVariableElement(TopLevelVariableElement element) => null;

  @override
  R? visitTypeAliasElement(TypeAliasElement element) => null;

  @override
  R? visitTypeParameterElement(TypeParameterElement element) => null;
}

/// An AST visitor that will throw an exception if any of the visit methods that
/// are invoked have not been overridden. It is intended to be a superclass for
/// classes that implement the visitor pattern and need to (a) override all of
/// the visit methods or (b) need to override a subset of the visit method and
/// want to catch when any other visit methods have been invoked.
///
/// Clients may extend this class.
class ThrowingElementVisitor<R> implements ElementVisitor<R> {
  /// Initialize a newly created visitor.
  const ThrowingElementVisitor();

  @override
  R? visitAugmentationImportElement(AugmentationImportElement element) =>
      _throw(element);

  @override
  R? visitClassElement(ClassElement element) => _throw(element);

  @override
  R? visitCompilationUnitElement(CompilationUnitElement element) =>
      _throw(element);

  @override
  R? visitConstructorElement(ConstructorElement element) => _throw(element);

  @override
  R? visitEnumElement(EnumElement element) => _throw(element);

  @override
  R? visitExtensionElement(ExtensionElement element) => _throw(element);

  @override
  R? visitFieldElement(FieldElement element) => _throw(element);

  @override
  R? visitFieldFormalParameterElement(FieldFormalParameterElement element) =>
      _throw(element);

  @override
  R? visitFunctionElement(FunctionElement element) => _throw(element);

  @override
  R? visitGenericFunctionTypeElement(GenericFunctionTypeElement element) =>
      _throw(element);

  @override
  R? visitLabelElement(LabelElement element) => _throw(element);

  @override
  R? visitLibraryAugmentationElement(LibraryAugmentationElement element) =>
      _throw(element);

  @override
  R? visitLibraryElement(LibraryElement element) => _throw(element);

  @override
  R? visitLibraryExportElement(LibraryExportElement element) => _throw(element);

  @override
  R? visitLibraryImportElement(LibraryImportElement element) => _throw(element);

  @override
  R? visitLocalVariableElement(LocalVariableElement element) => _throw(element);

  @override
  R? visitMethodElement(MethodElement element) => _throw(element);

  @override
  R? visitMixinElement(MixinElement element) => _throw(element);

  @override
  R? visitMultiplyDefinedElement(MultiplyDefinedElement element) =>
      _throw(element);

  @override
  R? visitParameterElement(ParameterElement element) => _throw(element);

  @override
  R? visitPartElement(PartElement element) => _throw(element);

  @override
  R? visitPrefixElement(PrefixElement element) => _throw(element);

  @override
  R? visitPropertyAccessorElement(PropertyAccessorElement element) =>
      _throw(element);

  @override
  R? visitSuperFormalParameterElement(SuperFormalParameterElement element) =>
      _throw(element);

  @override
  R? visitTopLevelVariableElement(TopLevelVariableElement element) =>
      _throw(element);

  @override
  R? visitTypeAliasElement(TypeAliasElement element) => _throw(element);

  @override
  R? visitTypeParameterElement(TypeParameterElement element) => _throw(element);

  R _throw(Element element) {
    throw Exception('Missing implementation of visit${element.runtimeType}');
  }
}
