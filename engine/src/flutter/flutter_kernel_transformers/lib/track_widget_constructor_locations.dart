// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

library track_widget_constructor_locations;

// The kernel/src import below that requires lint `ignore_for_file`
// is a temporary state of things until kernel team builds better api that would
// replace api used below. This api was made private in an effort to discourage
// further use.
// ignore_for_file: implementation_imports
import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart';
import 'package:meta/meta.dart';
import 'package:vm/frontend_server.dart' show ProgramTransformer;

// Parameter name used to track were widget constructor calls were made from.
//
// The parameter name contains a randomly generate hex string to avoid collision
// with user generated parameters.
const String _creationLocationParameterName =
    r'$creationLocationd_0dea112b090073317d4';

/// Name of private field added to the Widget class and any other classes that
/// implement Widget.
///
/// Regardless of what library a class implementing Widget is defined in, the
/// private field will always be defined in the context of the widget_inspector
/// library ensuring no name conflicts with regular fields.
const String _locationFieldName = r'_location';

bool _hasNamedParameter(FunctionNode function, String name) {
  return function.namedParameters
      .any((VariableDeclaration parameter) => parameter.name == name);
}

bool _hasNamedArgument(Arguments arguments, String argumentName) {
  return arguments.named
      .any((NamedExpression argument) => argument.name == argumentName);
}

VariableDeclaration _getNamedParameter(
  FunctionNode function,
  String parameterName,
) {
  for (VariableDeclaration parameter in function.namedParameters) {
    if (parameter.name == parameterName) {
      return parameter;
    }
  }
  return null;
}

// TODO(jacobr): find a solution that supports optional positional parameters.
/// Add the creation location to the arguments list if possible.
///
/// Returns whether the creation location argument could be added. We cannot
/// currently add the named argument for functions with optional positional
/// parameters as the current scheme requires adding the creation location as a
/// named parameter. Fortunately that is not a significant issue in practice as
/// no Widget classes in package:flutter have optional positional parameters.
/// This code degrades gracefully for constructors with optional positional
/// parameters by skipping adding the creation location argument rather than
/// failing.
void _maybeAddCreationLocationArgument(
  Arguments arguments,
  FunctionNode function,
  Expression creationLocation,
  Class locationClass,
) {
  if (_hasNamedArgument(arguments, _creationLocationParameterName)) {
    return;
  }
  if (!_hasNamedParameter(function, _creationLocationParameterName)) {
    return;
  }

  final NamedExpression namedArgument =
      new NamedExpression(_creationLocationParameterName, creationLocation);
  namedArgument.parent = arguments;
  arguments.named.add(namedArgument);
}

/// Adds a named parameter to a function if the function does not already have
/// a named parameter with the name or optional positional parameters.
bool _maybeAddNamedParameter(
  FunctionNode function,
  VariableDeclaration variable,
) {
  if (_hasNamedParameter(function, _creationLocationParameterName)) {
    // Gracefully handle if this method is called on a function that has already
    // been transformed.
    return false;
  }
  // Function has optional positional parameters so cannot have optional named
  // parameters.
  if (function.requiredParameterCount != function.positionalParameters.length) {
    return false;
  }
  variable.parent = function;
  function.namedParameters.add(variable);
  return true;
}

/// Transformer that modifies all calls to Widget constructors to include
/// a [DebugLocation] parameter specifying the location where the constructor
/// call was made.
///
/// This transformer requires that all Widget constructors have already been
/// transformed to have a named parameter with the name specified by
/// `_locationParameterName`.
class _WidgetCallSiteTransformer extends Transformer {
  final ClassHierarchy _hierarchy;

  /// The [Widget] class defined in the `package:flutter` library.
  ///
  /// Used to perform instanceof checks to determine whether Dart constructor
  /// calls are creating [Widget] objects.
  Class _widgetClass;

  /// The [DebugLocation] class defined in the `package:flutter` library.
  Class _locationClass;

  /// Current factory constructor that node being transformed is inside.
  ///
  /// Used to flow the location passed in as an argument to the factory to the
  /// actual constructor call within the factory.
  Procedure _currentFactory;

  _WidgetCallSiteTransformer(
    this._hierarchy, {
    @required Class widgetClass,
    @required Class locationClass,
  })
      : _widgetClass = widgetClass,
        _locationClass = locationClass;

  /// Builds a call to the const constructor of the [DebugLocation]
  /// object specifying the location where a constructor call was made and
  /// optionally the locations for all parameters passed in.
  ///
  /// Specifying the parameters passed in is an experimental feature. With
  /// access to the source code of an application you could determine the
  /// locations of the parameters passed in from the source location of the
  /// constructor call but it is convenient to bundle the location and names
  /// of the parameters passed in so that tools can show parameter locations
  /// without reparsing the source code.
  ConstructorInvocation _constructLocation(
    Location location, {
    String name,
    ListLiteral parameterLocations,
    bool showFile: true,
  }) {
    final List<NamedExpression> arguments = <NamedExpression>[
      new NamedExpression('line', new IntLiteral(location.line)),
      new NamedExpression('column', new IntLiteral(location.column)),
    ];
    if (showFile) {
      arguments.add(new NamedExpression(
          'file', new StringLiteral(location.file.toString())));
    }
    if (name != null) {
      arguments.add(new NamedExpression('name', new StringLiteral(name)));
    }
    if (parameterLocations != null) {
      arguments
          .add(new NamedExpression('parameterLocations', parameterLocations));
    }
    return new ConstructorInvocation(
      _locationClass.constructors.first,
      new Arguments(<Expression>[], named: arguments),
      isConst: true,
    );
  }

  @override
  Procedure visitProcedure(Procedure node) {
    if (node.isFactory) {
      _currentFactory = node;
      node.transformChildren(this);
      _currentFactory = null;
      return node;
    }
    return defaultTreeNode(node);
  }

  bool _isSubclassOfWidget(Class clazz) {
    // TODO(jacobr): use hierarchy.isSubclassOf once we are using the
    // non-deprecated ClassHierarchy constructor.
    return _hierarchy.isSubclassOf(clazz, _widgetClass);
  }

  @override
  StaticInvocation visitStaticInvocation(StaticInvocation node) {
    node.transformChildren(this);
    final Procedure target = node.target;
    if (!target.isFactory) {
      return node;
    }
    final Class constructedClass = target.enclosingClass;
    if (!_isSubclassOfWidget(constructedClass)) {
      return node;
    }

    _addLocationArgument(node, target.function, constructedClass);
    return node;
  }

  void _addLocationArgument(InvocationExpression node, FunctionNode function,
      Class constructedClass) {
    _maybeAddCreationLocationArgument(
      node.arguments,
      function,
      _computeLocation(node, function, constructedClass),
      _locationClass,
    );
  }

  @override
  ConstructorInvocation visitConstructorInvocation(ConstructorInvocation node) {
    node.transformChildren(this);

    final Constructor constructor = node.target;
    final Class constructedClass = constructor.enclosingClass;
    if (!_isSubclassOfWidget(constructedClass)) {
      return node;
    }

    _addLocationArgument(node, constructor.function, constructedClass);
    return node;
  }

  Expression _computeLocation(InvocationExpression node, FunctionNode function,
      Class constructedClass) {
    // For factory constructors we need to use the location specified as an
    // argument to the factory constructor rather than the location
    // TODO(jacobr): use hierarchy.isSubclassOf once we are using the
    // non-deprecated ClassHierarchy constructor.
    if (_currentFactory != null &&
        _hierarchy.isSubclassOf(constructedClass, _currentFactory.enclosingClass)) {
      final VariableDeclaration creationLocationParameter = _getNamedParameter(
        _currentFactory.function,
        _creationLocationParameterName,
      );
      if (creationLocationParameter != null) {
        return new VariableGet(creationLocationParameter);
      }
    }

    final Arguments arguments = node.arguments;
    final Location location = node.location;
    final List<ConstructorInvocation> parameterLocations =
        <ConstructorInvocation>[];
    final List<VariableDeclaration> parameters = function.positionalParameters;
    for (int i = 0; i < arguments.positional.length; ++i) {
      final Expression expression = arguments.positional[i];
      final VariableDeclaration parameter = parameters[i];
      parameterLocations.add(_constructLocation(
        expression.location,
        name: parameter.name,
        showFile: false,
      ));
    }
    for (NamedExpression expression in arguments.named) {
      parameterLocations.add(_constructLocation(
        expression.location,
        name: expression.name,
        showFile: false,
      ));
    }
    return _constructLocation(
      location,
      parameterLocations: new ListLiteral(
        parameterLocations,
        typeArgument: _locationClass.thisType,
        isConst: true,
      ),
    );
  }
}


/// Rewrites all widget constructors and constructor invocations to add a
/// parameter specifying the location the constructor was called from.
///
/// The creation location is stored as a private field named `_location`
/// on the base widget class and flowed through the constructors using a named
/// parameter.
class WidgetCreatorTracker implements ProgramTransformer {
  Class _widgetClass;
  Class _locationClass;

  /// Marker interface indicating that a private _location field is
  /// available.
  Class _hasCreationLocationClass;

  /// The [ClassHierarchy] that should be used after applying this transformer.
  /// If any class was updated, in general we need to create a new
  /// [ClassHierarchy] instance, with new dispatch targets; or at least let
  /// the existing instance know that some of its dispatch tables are not
  /// valid anymore.
  ClassHierarchy hierarchy;

  void _resolveFlutterClasses(Iterable<Library> libraries) {
    // If the Widget or Debug location classes have been updated we need to get
    // the latest version
    for (Library library in libraries) {
      final Uri importUri = library.importUri;
      if (!library.isExternal &&
          importUri != null &&
          importUri.scheme == 'package') {
        if (importUri.path == 'flutter/src/widgets/framework.dart') {
          for (Class class_ in library.classes) {
            if (class_.name == 'Widget') {
              _widgetClass = class_;
            }
          }
        } else {
          if (importUri.path == 'flutter/src/widgets/widget_inspector.dart') {
            for (Class class_ in library.classes) {
              if (class_.name == '_HasCreationLocation') {
                _hasCreationLocationClass = class_;
              } else if (class_.name == '_Location') {
                _locationClass = class_;
              }
            }
          }
        }
      }
    }
  }

  /// Modify [clazz] to add a field named [_locationFieldName] that is the
  /// first parameter of all constructors of the class.
  ///
  /// This method should only be called for classes that implement but do not
  /// extend [Widget].
  void _transformClassImplementingWidget(Class clazz) {
    if (clazz.fields
        .any((Field field) => field.name.name == _locationFieldName)) {
      // This class has already been transformed. Skip
      return;
    }
    clazz.implementedTypes
        .add(new Supertype(_hasCreationLocationClass, <DartType>[]));
    // We intentionally use the library context of the _HasCreationLocation
    // class for the private field even if [clazz] is in a different library
    // so that all classes implementing Widget behave consistently.
    final Field locationField = new Field(
      new Name(
        _locationFieldName,
        _hasCreationLocationClass.enclosingLibrary,
      ),
      isFinal: true,
    );
    clazz.addMember(locationField);

    final Set<Constructor> _handledConstructors =
        new Set<Constructor>.identity();

    void handleConstructor(Constructor constructor) {
      if (!_handledConstructors.add(constructor)) {
        return;
      }
      assert(!_hasNamedParameter(
        constructor.function,
        _creationLocationParameterName,
      ));
      final VariableDeclaration variable = new VariableDeclaration(
        _creationLocationParameterName,
        type: _locationClass.thisType,
      );
      if (!_maybeAddNamedParameter(constructor.function, variable)) {
        return;
      }

      bool hasRedirectingInitializer = false;
      for (Initializer initializer in constructor.initializers) {
        if (initializer is RedirectingInitializer) {
          if (initializer.target.enclosingClass == clazz) {
            // We need to handle this constructor first or the call to
            // addDebugLocationArgument bellow will fail due to the named
            // parameter not yet existing on the constructor.
            handleConstructor(initializer.target);
          }
          _maybeAddCreationLocationArgument(
            initializer.arguments,
            initializer.target.function,
            new VariableGet(variable),
            _locationClass,
          );
          hasRedirectingInitializer = true;
          break;
        }
      }
      if (!hasRedirectingInitializer) {
        constructor.initializers.add(new FieldInitializer(
          locationField,
          new VariableGet(variable),
        ));
        // TODO(jacobr): add an assert verifying the locationField is not
        // null. Curently we cannot safely add this assert because we do not
        // handle Widget classes with optional positional arguments. There are
        // no Widget classes in the flutter repo with optional positional
        // arguments but it is possible users could add classes with optional
        // positional arguments.
        //
        // constructor.initializers.add(new AssertInitializer(new AssertStatement(
        //   new IsExpression(
        //       new VariableGet(variable), _locationClass.thisType),
        //   conditionStartOffset: constructor.fileOffset,
        //   conditionEndOffset: constructor.fileOffset,
        // )));
      }
    }

    // Add named parameters to all constructors.
    clazz.constructors.forEach(handleConstructor);
  }

  Component _computeFullProgram(Component deltaProgram) {
    final Set<Library> libraries = new Set<Library>();
    final List<Library> workList = <Library>[];
    for (Library library in deltaProgram.libraries) {
      if (libraries.add(library)) {
        workList.add(library);
      }
    }
    while (workList.isNotEmpty) {
      final Library library = workList.removeLast();
      for (LibraryDependency dependency in library.dependencies) {
        if (libraries.add(dependency.targetLibrary)) {
          workList.add(dependency.targetLibrary);
        }
      }
    }
    return new Component()..libraries.addAll(libraries);
  }

  /// Transform the given [program].
  ///
  /// It is safe to call this method on a delta program generated as part of
  /// performing a hot reload.
  @override
  void transform(Component program) {
    final List<Library> libraries = program.libraries;

    if (libraries.isEmpty) {
      return;
    }

    _resolveFlutterClasses(libraries);

    if (_widgetClass == null) {
      // This application doesn't actually use the package:flutter library.
      return;
    }

    // TODO(jacobr): once there is a working incremental ClassHierarchy
    // constructor switch to using it instead of building a ClassHierarchy off
    // the full program.
    hierarchy = new ClassHierarchy(
      _computeFullProgram(program),
      onAmbiguousSupertypes: (Class cls, Supertype a, Supertype b) { },
    );

    final Set<Class> transformedClasses = new Set<Class>.identity();
    final Set<Library> librariesToTransform = new Set<Library>.identity()
      ..addAll(libraries);

    for (Library library in libraries) {
      if (library.isExternal) {
        continue;
      }
      for (Class class_ in library.classes) {
        _transformWidgetConstructors(
          librariesToTransform,
          transformedClasses,
          class_,
        );
      }
    }

    // Transform call sites to pass the location parameter.
    final _WidgetCallSiteTransformer callsiteTransformer =
        new _WidgetCallSiteTransformer(
      hierarchy,
      widgetClass: _widgetClass,
      locationClass: _locationClass,
    );

    for (Library library in libraries) {
      if (library.isExternal) {
        continue;
      }
      library.transformChildren(callsiteTransformer);
    }
  }

  bool _isSubclassOfWidget(Class clazz) {
    if (clazz == null) {
      return false;
    }
    // TODO(jacobr): use hierarchy.isSubclassOf once we are using the
    // non-deprecated ClassHierarchy constructor.
    return hierarchy.isSubclassOf(clazz, _widgetClass);
  }

  void _transformWidgetConstructors(Set<Library> librariesToBeTransformed,
      Set<Class> transformedClasses, Class clazz) {
    if (!_isSubclassOfWidget(clazz) ||
        !librariesToBeTransformed.contains(clazz.enclosingLibrary) ||
        !transformedClasses.add(clazz)) {
      return;
    }

    // Ensure super classes have been transformed before this class.
    if (clazz.superclass != null &&
        !transformedClasses.contains(clazz.superclass)) {
      _transformWidgetConstructors(
        librariesToBeTransformed,
        transformedClasses,
        clazz.superclass,
      );
    }

    for (Procedure procedure in clazz.procedures) {
      if (procedure.isFactory) {
        _maybeAddNamedParameter(
          procedure.function,
          new VariableDeclaration(
            _creationLocationParameterName,
            type: _locationClass.thisType,
          ),
        );
      }
    }

    // Handle the widget class and classes that implement but do not extend the
    // widget class.
    if (!_isSubclassOfWidget(clazz.superclass)) {
      _transformClassImplementingWidget(clazz);
      return;
    }

    final Set<Constructor> _handledConstructors =
        new Set<Constructor>.identity();

    void handleConstructor(Constructor constructor) {
      if (!_handledConstructors.add(constructor)) {
        return;
      }

      final VariableDeclaration variable = new VariableDeclaration(
        _creationLocationParameterName,
        type: _locationClass.thisType,
      );
      if (_hasNamedParameter(
          constructor.function, _creationLocationParameterName)) {
        // Constructor was already rewritten. TODO(jacobr): is this case actually hit?
        return;
      }
      if (!_maybeAddNamedParameter(constructor.function, variable)) {
        return;
      }
      for (Initializer initializer in constructor.initializers) {
        if (initializer is RedirectingInitializer) {
          if (initializer.target.enclosingClass == clazz) {
            // We need to handle this constructor first or the call to
            // addDebugLocationArgument could fail due to the named parameter
            // not existing.
            handleConstructor(initializer.target);
          }

          _maybeAddCreationLocationArgument(
            initializer.arguments,
            initializer.target.function,
            new VariableGet(variable),
            _locationClass,
          );
        } else if (initializer is SuperInitializer &&
            _isSubclassOfWidget(initializer.target.enclosingClass)) {
          _maybeAddCreationLocationArgument(
            initializer.arguments,
            initializer.target.function,
            new VariableGet(variable),
            _locationClass,
          );
        }
      }
    }

    clazz.constructors.forEach(handleConstructor);
  }
}
