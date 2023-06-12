// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import '../api.dart';
import '../executor/augmentation_library.dart';
import '../executor/introspection_impls.dart';
import '../executor.dart';

/// A [MacroExecutor] implementation which delegates most work to other
/// executors which are spawned through a provided callback.
class MultiMacroExecutor extends MacroExecutor with AugmentationLibraryBuilder {
  /// Executors by [MacroInstanceIdentifier].
  ///
  /// Using an expando means we don't have to worry about cleaning  up instances
  /// for executors that were shut down.
  final Expando<ExecutorFactoryToken> _instanceExecutors = new Expando();

  /// Registered factories for starting up a new macro executor for a library.
  final Map<Uri, ExecutorFactoryToken> _libraryExecutorFactories = {};

  /// All known registered executor factories.
  final Set<ExecutorFactoryToken> _executorFactoryTokens = {};

  /// Whether or not an executor factory for [library] is currently registered.
  bool libraryIsRegistered(Uri library) =>
      _libraryExecutorFactories.containsKey(library);

  /// Registers a [factory] which can produce a [MacroExecutor] that can be
  /// used to run any macro defined in [libraries].
  ///
  /// Throws an [ArgumentError] if a library in [libraries] already has a
  /// factory registered.
  ///
  /// Returns a token which can be used to shut down any executors spawned in
  /// this way via [unregisterExecutorFactory].
  ExecutorFactoryToken registerExecutorFactory(
      FutureOr<MacroExecutor> Function() factory, Set<Uri> libraries) {
    ExecutorFactoryToken token = new ExecutorFactoryToken._(factory, libraries);
    _executorFactoryTokens.add(token);
    for (Uri library in libraries) {
      if (_libraryExecutorFactories.containsKey(library)) {
        throw new ArgumentError(
            'Attempted to register a macro executor factory for library '
            '$library which already has one assigned.');
      }
      _libraryExecutorFactories[library] = token;
    }
    return token;
  }

  /// Unregisters [token] for all [libraries].
  ///
  /// If [libraries] is not passed (or `null`), then the token is unregistered
  /// for all libraries.
  ///
  /// If no libraries are registered for [token] after this call, then the
  /// executor mapped to [token] will be shut down and the token will be freed.
  ///
  /// This should be called whenever the executors might be stale, or as an
  /// optimization to shut them down when they are known to be not used any
  /// longer.
  Future<void> unregisterExecutorFactory(ExecutorFactoryToken token,
      {Set<Uri>? libraries}) async {
    bool shouldClose;
    if (libraries == null) {
      libraries = token._libraries;
      shouldClose = true;
    } else {
      token._libraries.removeAll(libraries);
      shouldClose = token._libraries.isEmpty;
    }

    for (Uri library in libraries) {
      _libraryExecutorFactories.remove(library);
    }

    if (shouldClose) {
      _executorFactoryTokens.remove(token);
      token._libraries.clear();
      await token._close();
    }
  }

  /// Shuts down all executors, but does not clear [_libraryExecutorFactories]
  /// or [_executorFactoryTokens].
  @override
  Future<void> close() {
    Future done = Future.wait([
      for (ExecutorFactoryToken token in _executorFactoryTokens) token._close(),
    ]);
    return done;
  }

  @override
  Future<MacroExecutionResult> executeDeclarationsPhase(
          MacroInstanceIdentifier macro,
          DeclarationImpl declaration,
          IdentifierResolver identifierResolver,
          TypeDeclarationResolver typeDeclarationResolver,
          TypeResolver typeResolver,
          TypeIntrospector typeIntrospector) =>
      _instanceExecutors[macro]!._withInstance((executor) =>
          executor.executeDeclarationsPhase(
              macro,
              declaration,
              identifierResolver,
              typeDeclarationResolver,
              typeResolver,
              typeIntrospector));

  @override
  Future<MacroExecutionResult> executeDefinitionsPhase(
          MacroInstanceIdentifier macro,
          DeclarationImpl declaration,
          IdentifierResolver identifierResolver,
          TypeDeclarationResolver typeDeclarationResolver,
          TypeResolver typeResolver,
          TypeIntrospector typeIntrospector,
          TypeInferrer typeInferrer) =>
      _instanceExecutors[macro]!._withInstance((executor) =>
          executor.executeDefinitionsPhase(
              macro,
              declaration,
              identifierResolver,
              typeDeclarationResolver,
              typeResolver,
              typeIntrospector,
              typeInferrer));

  @override
  Future<MacroExecutionResult> executeTypesPhase(MacroInstanceIdentifier macro,
          DeclarationImpl declaration, IdentifierResolver identifierResolver) =>
      _instanceExecutors[macro]!._withInstance((executor) =>
          executor.executeTypesPhase(macro, declaration, identifierResolver));

  @override
  Future<MacroInstanceIdentifier> instantiateMacro(
      Uri library, String name, String constructor, Arguments arguments) {
    ExecutorFactoryToken? token = _libraryExecutorFactories[library];
    if (token == null) {
      throw new ArgumentError(
          'No executor registered to run macros from $library');
    }
    return token._withInstance((executor) async {
      MacroInstanceIdentifier instance = await executor.instantiateMacro(
          library, name, constructor, arguments);
      _instanceExecutors[instance] = token;
      return instance;
    });
  }
}

/// A token to track registered [MacroExecutor] factories.
///
/// Used to unregister them later on, and also handles bookkeeping for the
/// factory and actual instances.
class ExecutorFactoryToken {
  final FutureOr<MacroExecutor> Function() _factory;
  FutureOr<MacroExecutor>? _instance;
  final Set<Uri> _libraries;

  ExecutorFactoryToken._(this._factory, this._libraries);

  /// Runs [callback] with an actual instance once available.
  ///
  /// This will spin up an instance if one is not currently running.
  Future<T> _withInstance<T>(Future<T> Function(MacroExecutor) callback) {
    FutureOr<MacroExecutor>? instance = _instance;
    if (instance == null) {
      instance = _instance = _factory();
    }
    if (instance is Future<MacroExecutor>) {
      return instance.then(callback);
    } else {
      return callback(instance);
    }
  }

  /// Closes [_instance] if non-null, and sets it to `null`.
  Future<void> _close() async {
    FutureOr<MacroExecutor>? instance = _instance;
    _instance = null;
    if (instance != null) {
      if (instance is Future<MacroExecutor>) {
        await (await instance).close();
      } else {
        await instance.close();
      }
    }
  }
}
