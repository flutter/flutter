// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:path/path.dart' as path;
import 'package:vm_service/vm_service.dart' as vm;

import 'adapters/dart.dart';
import 'isolate_manager.dart';
import 'protocol_generated.dart' as dap;

/// A helper that handlers converting to/from DAP and VM Service types and to
/// user-friendly display strings.
///
/// This class may call back to the VM Service to fetch additional information
/// when converting classes - for example when converting a stack frame it may
/// fetch scripts from the VM Service in order to map token positions back to
/// line/columns as required by DAP.
class ProtocolConverter {
  /// The parent debug adapter, used to access arguments and the VM Service for
  /// the debug session.
  final DartDebugAdapter _adapter;

  ProtocolConverter(this._adapter);

  /// Converts an absolute path to one relative to the cwd used to launch the
  /// application.
  ///
  /// If [sourcePath] is outside of the cwd used for launching the application
  /// then the full absolute path will be returned.
  String convertToRelativePath(String sourcePath) {
    final cwd = _adapter.args.cwd;
    if (cwd == null) {
      return sourcePath;
    }
    final rel = path.relative(sourcePath, from: cwd);
    return !rel.startsWith('..') ? rel : sourcePath;
  }

  /// Converts a [vm.InstanceRef] into a user-friendly display string.
  ///
  /// This may be shown in the collapsed view of a complex type.
  ///
  /// If [allowCallingToString] is true, the toString() method may be called on
  /// the object for a display string.
  ///
  /// Strings are usually wrapped in quotes to indicate their type. This can be
  /// controlled with [includeQuotesAroundString] (for example to suppress them
  /// if the context indicates the user is copying the value to the clipboard).
  Future<String> convertVmInstanceRefToDisplayString(
    ThreadInfo thread,
    vm.InstanceRef ref, {
    required bool allowCallingToString,
    bool allowTruncatedValue = true,
    bool includeQuotesAroundString = true,
  }) async {
    final isTruncated = ref.valueAsStringIsTruncated ?? false;
    if (ref.kind == vm.InstanceKind.kString && isTruncated) {
      // Call toString() if allowed (and we don't already have a value),
      // otherwise (or if it returns null) fall back to the truncated value
      // with "…" suffix.
      var stringValue = allowCallingToString &&
              (ref.valueAsString == null || !allowTruncatedValue)
          ? await _callToString(
              thread,
              ref,
              // Quotes are handled below, so they can be wrapped around the
              // elipsis.
              includeQuotesAroundString: false,
            )
          : null;
      stringValue ??= '${ref.valueAsString}…';

      return includeQuotesAroundString ? '"$stringValue"' : stringValue;
    } else if (ref.kind == vm.InstanceKind.kString) {
      // Untruncated strings.
      return includeQuotesAroundString
          ? '"${ref.valueAsString}"'
          : ref.valueAsString.toString();
    } else if (ref.valueAsString != null) {
      return isTruncated
          ? '${ref.valueAsString}…'
          : ref.valueAsString.toString();
    } else if (ref.kind == 'PlainInstance') {
      var stringValue = ref.classRef?.name ?? '<unknown instance>';
      if (allowCallingToString) {
        final toStringValue = await _callToString(
          thread,
          ref,
          includeQuotesAroundString: false,
        );
        // Include the toString() result only if it's not the default (which
        // duplicates the type name we're already showing).
        if (toStringValue != "Instance of '${ref.classRef?.name}'") {
          stringValue += ' ($toStringValue)';
        }
      }
      return stringValue;
    } else if (ref.kind == 'List') {
      return 'List (${ref.length} ${ref.length == 1 ? "item" : "items"})';
    } else if (ref.kind == 'Map') {
      return 'Map (${ref.length} ${ref.length == 1 ? "item" : "items"})';
    } else if (ref.kind == 'Type') {
      return 'Type (${ref.name})';
    } else {
      return ref.kind ?? '<unknown result>';
    }
  }

  /// Converts a [vm.Instace] to a list of [dap.Variable]s, one for each
  /// field/member/element/association.
  ///
  /// If [startItem] and/or [numItems] are supplied, only a slice of the
  /// items will be returned to allow the client to page.
  Future<List<dap.Variable>> convertVmInstanceToVariablesList(
    ThreadInfo thread,
    vm.Instance instance, {
    required String? evaluateName,
    required bool allowCallingToString,
    int? startItem = 0,
    int? numItems,
  }) async {
    final elements = instance.elements;
    final associations = instance.associations;
    final fields = instance.fields;

    if (isSimpleKind(instance.kind)) {
      // For simple kinds, just return a single variable with their value.
      return [
        await convertVmResponseToVariable(
          thread,
          instance,
          name: null,
          evaluateName: evaluateName,
          allowCallingToString: allowCallingToString,
        )
      ];
    } else if (elements != null) {
      // For lists, map each item (in the requested subset) to a variable.
      final start = startItem ?? 0;
      return Future.wait(elements
          .cast<vm.Response>()
          .sublist(start, numItems != null ? start + numItems : null)
          .mapIndexed(
            (index, response) => convertVmResponseToVariable(
              thread,
              response,
              name: '[${start + index}]',
              evaluateName: _adapter.combineEvaluateName(
                  evaluateName, '[${start + index}]'),
              allowCallingToString:
                  allowCallingToString && index <= maxToStringsPerEvaluation,
            ),
          ));
    } else if (associations != null) {
      // For maps, create a variable for each entry (in the requested subset).
      // Use the keys and values to create a display string in the form
      // "Key -> Value".
      // Both the key and value will be expandable (handled by variablesRequest
      // detecting the MapAssociation type).
      final start = startItem ?? 0;
      return Future.wait(associations
          .sublist(start, numItems != null ? start + numItems : null)
          .mapIndexed((index, mapEntry) async {
        final key = mapEntry.key;
        final value = mapEntry.value;
        final callToString =
            allowCallingToString && index <= maxToStringsPerEvaluation;

        final keyDisplay = await convertVmResponseToDisplayString(thread, key,
            allowCallingToString: callToString);
        final valueDisplay = await convertVmResponseToDisplayString(
            thread, value,
            allowCallingToString: callToString);

        // We only provide an evaluateName for the value, and only if the
        // key is a simple value.
        if (key is vm.InstanceRef &&
            value is vm.InstanceRef &&
            evaluateName != null &&
            isSimpleKind(key.kind)) {
          _adapter.storeEvaluateName(value, '$evaluateName[$keyDisplay]');
        }

        return dap.Variable(
          name: '${start + index}',
          value: '$keyDisplay -> $valueDisplay',
          variablesReference: thread.storeData(mapEntry),
        );
      }));
    } else if (fields != null) {
      // Otherwise, show the fields from the instance.
      final variables = await Future.wait(fields.mapIndexed(
        (index, field) async {
          final name = field.decl?.name;
          return convertVmResponseToVariable(thread, field.value,
              name: name ?? '<unnamed field>',
              evaluateName: name != null
                  ? _adapter.combineEvaluateName(evaluateName, '.$name')
                  : null,
              allowCallingToString:
                  allowCallingToString && index <= maxToStringsPerEvaluation);
        },
      ));

      // Also evaluate the getters if evaluateGettersInDebugViews=true enabled.
      final service = _adapter.vmService;
      if (service != null &&
          (_adapter.args.evaluateGettersInDebugViews ?? false)) {
        // Collect getter names for this instances class and its supers.
        final getterNames =
            await _getterNamesForClassHierarchy(thread, instance.classRef);

        /// Helper to evaluate each getter and convert the response to a
        /// variable.
        Future<dap.Variable> evaluate(int index, String getterName) async {
          try {
            final response = await service.evaluate(
              thread.isolate.id!,
              instance.id!,
              getterName,
            );
            // Convert results to variables.
            return convertVmResponseToVariable(
              thread,
              response,
              name: getterName,
              evaluateName:
                  _adapter.combineEvaluateName(evaluateName, '.$getterName'),
              allowCallingToString:
                  allowCallingToString && index <= maxToStringsPerEvaluation,
            );
          } catch (e) {
            return dap.Variable(
              name: getterName,
              value: _adapter.extractEvaluationErrorMessage('$e'),
              variablesReference: 0,
            );
          }
        }

        variables.addAll(await Future.wait(getterNames.mapIndexed(evaluate)));
      }

      // Sort the fields/getters by name.
      variables.sortBy((v) => v.name);

      return variables;
    } else {
      // For any other type that we don't produce variables for, return an empty
      // list.
      return [];
    }
  }

  /// Converts a [vm.Response] into a user-friendly display string.
  ///
  /// This may be shown in the collapsed view of a complex type.
  ///
  /// If [allowCallingToString] is true, the toString() method may be called on
  /// the object for a display string.
  Future<String> convertVmResponseToDisplayString(
    ThreadInfo thread,
    vm.Response response, {
    required bool allowCallingToString,
    bool includeQuotesAroundString = true,
  }) async {
    if (response is vm.InstanceRef) {
      return convertVmInstanceRefToDisplayString(
        thread,
        response,
        allowCallingToString: allowCallingToString,
        includeQuotesAroundString: includeQuotesAroundString,
      );
    } else if (response is vm.Sentinel) {
      return '<sentinel>';
    } else {
      return '<unknown: ${response.type}>';
    }
  }

  /// Converts a [vm.Response] into to a [dap.Variable].
  ///
  /// If provided, [name] is used as the variables name (for example the field
  /// name holding this variable).
  ///
  /// If [allowCallingToString] is true, the toString() method may be called on
  /// the object for a display string.
  Future<dap.Variable> convertVmResponseToVariable(
    ThreadInfo thread,
    vm.Response response, {
    required String? name,
    required String? evaluateName,
    required bool allowCallingToString,
  }) async {
    if (response is vm.InstanceRef) {
      // For non-simple variables, store them and produce a new reference that
      // can be used to access their fields/items/associations.
      final variablesReference =
          isSimpleKind(response.kind) ? 0 : thread.storeData(response);

      return dap.Variable(
        name: name ?? response.kind.toString(),
        evaluateName: evaluateName,
        value: await convertVmResponseToDisplayString(
          thread,
          response,
          allowCallingToString: allowCallingToString,
        ),
        variablesReference: variablesReference,
      );
    } else if (response is vm.Sentinel) {
      return dap.Variable(
        name: name ?? '<sentinel>',
        value: response.valueAsString.toString(),
        variablesReference: 0,
      );
    } else if (response is vm.ErrorRef) {
      final errorMessage = _adapter
          .extractUnhandledExceptionMessage(response.message ?? '<error>');
      return dap.Variable(
        name: name ?? '<error>',
        value: '<$errorMessage>',
        variablesReference: 0,
      );
    } else {
      return dap.Variable(
        name: name ?? '<error>',
        value: response.runtimeType.toString(),
        variablesReference: 0,
      );
    }
  }

  /// Converts a VM Service stack frame to a DAP stack frame.
  Future<dap.StackFrame> convertVmToDapStackFrame(
    ThreadInfo thread,
    vm.Frame frame, {
    required bool isTopFrame,
    int? firstAsyncMarkerIndex,
  }) async {
    final frameId = thread.storeData(frame);

    if (frame.kind == vm.FrameKind.kAsyncSuspensionMarker) {
      return dap.StackFrame(
        id: frameId,
        name: '<asynchronous gap>',
        presentationHint: 'label',
        line: 0,
        column: 0,
      );
    }

    // The VM may supply frames with a prefix that we don't want to include in
    // the frame for the user.
    const unoptimizedPrefix = '[Unoptimized] ';
    final codeName = frame.code?.name;
    final frameName = codeName != null
        ? (codeName.startsWith(unoptimizedPrefix)
            ? codeName.substring(unoptimizedPrefix.length)
            : codeName)
        : '<unknown>';

    // If there's no location, this isn't source a user can debug so use a
    // subtle hint (which the editor may use to render the frame faded).
    final location = frame.location;
    if (location == null) {
      return dap.StackFrame(
        id: frameId,
        name: frameName,
        presentationHint: 'subtle',
        line: 0,
        column: 0,
      );
    }

    final scriptRef = location.script;
    final tokenPos = location.tokenPos;
    final scriptRefUri = scriptRef?.uri;
    final uri = scriptRefUri != null ? Uri.parse(scriptRefUri) : null;
    final uriIsDart = uri?.isScheme('dart') ?? false;
    final uriIsPackage = uri?.isScheme('package') ?? false;
    final sourcePath = uri != null ? await thread.resolveUriToPath(uri) : null;
    var canShowSource = sourcePath != null && File(sourcePath).existsSync();

    // Download the source if from a "dart:" uri.
    int? sourceReference;
    if (!canShowSource &&
        uri != null &&
        (uri.isScheme('dart') || uri.isScheme('org-dartlang-app')) &&
        scriptRef != null) {
      sourceReference = thread.storeData(scriptRef);
      canShowSource = true;
    }

    var line = 0, col = 0;
    if (scriptRef != null && tokenPos != null) {
      try {
        final script = await thread.getScript(scriptRef);
        line = script.getLineNumberFromTokenPos(tokenPos) ?? 0;
        col = script.getColumnNumberFromTokenPos(tokenPos) ?? 0;
      } catch (e) {
        _adapter.logger?.call('Failed to map frame location to line/col: $e');
      }
    }

    // If a source would be considered not-debuggable (for example it's in the
    // SDK and debugSdkLibraries=false) then we should also mark it as
    // deemphasized so that the editor can jump up the stack to the first frame
    // of debuggable code.
    final isDebuggable =
        uri != null && await _adapter.libraryIsDebuggable(thread, uri);
    final presentationHint = isDebuggable ? null : 'deemphasize';
    final origin = uri != null && _adapter.isSdkLibrary(uri)
        ? 'from the SDK'
        : uri != null && await _adapter.isExternalPackageLibrary(thread, uri)
            ? 'from external packages'
            : null;

    final source = canShowSource
        ? dap.Source(
            name: uriIsPackage || uriIsDart
                ? uri!.toString()
                : sourcePath != null
                    ? convertToRelativePath(sourcePath)
                    : uri?.toString() ?? '<unknown source>',
            path: sourcePath,
            sourceReference: sourceReference,
            origin: origin,
            adapterData: location.script,
            presentationHint: presentationHint,
          )
        : null;

    // The VM only allows us to restart from frames that are not the top frame,
    // but since we're also showing asyncCausalFrames any indexes past the first
    // async boundary will not line up so we cap it there.
    final canRestart = !isTopFrame &&
        (firstAsyncMarkerIndex == null || frame.index! < firstAsyncMarkerIndex);

    return dap.StackFrame(
      id: frameId,
      name: frameName,
      source: source,
      line: line,
      column: col,
      canRestart: canRestart,
    );
  }

  /// Whether [kind] is a simple kind, and does not need to be mapped to a variable.
  bool isSimpleKind(String? kind) {
    return kind == 'String' ||
        kind == 'Bool' ||
        kind == 'Int' ||
        kind == 'Num' ||
        kind == 'Double' ||
        kind == 'Null' ||
        kind == 'Closure';
  }

  /// Invokes the toString() method on a [vm.InstanceRef] and converts the
  /// response to a user-friendly display string.
  ///
  /// Strings are usually wrapped in quotes to indicate their type. This can be
  /// controlled with [includeQuotesAroundString] (for example to suppress them
  /// if the context indicates the user is copying the value to the clipboard).
  Future<String?> _callToString(
    ThreadInfo thread,
    vm.InstanceRef ref, {
    bool includeQuotesAroundString = true,
  }) async {
    final service = _adapter.vmService;
    if (service == null) {
      return null;
    }
    var result = await service.invoke(
      thread.isolate.id!,
      ref.id!,
      'toString',
      [],
      disableBreakpoints: true,
    );

    // If the response is a string and is truncated, use getObject() to get the
    // full value.
    if (result is vm.InstanceRef &&
        result.kind == 'String' &&
        (result.valueAsStringIsTruncated ?? false)) {
      result = await service.getObject(thread.isolate.id!, result.id!);
    }

    return convertVmResponseToDisplayString(
      thread,
      result,
      allowCallingToString: false, // Don't allow recursing.
      includeQuotesAroundString: includeQuotesAroundString,
    );
  }

  /// Collect a list of all getter names for [classRef] and its super classes.
  ///
  /// This is used to show/evaluate getters in debug views like hovers and
  /// variables/watch panes.
  Future<Set<String>> _getterNamesForClassHierarchy(
    ThreadInfo thread,
    vm.ClassRef? classRef,
  ) async {
    final getterNames = <String>{};
    final service = _adapter.vmService;
    while (service != null && classRef != null) {
      final classResponse =
          await service.getObject(thread.isolate.id!, classRef.id!);
      if (classResponse is! vm.Class) {
        break;
      }
      final functions = classResponse.functions;
      if (functions != null) {
        final instanceFields = functions.where((f) =>
            // TODO(dantup): Update this to use something better that bkonyi is
            // adding to the protocol.
            f.json?['_kind'] == 'GetterFunction' &&
            !(f.isStatic ?? false) &&
            !(f.isConst ?? false));
        getterNames.addAll(instanceFields.map((f) => f.name!));
      }

      classRef = classResponse.superClass;
    }

    return getterNames;
  }
}
