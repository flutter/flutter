// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_tools_core/flutter_tools_core.dart';
import 'package:json_rpc_2/json_rpc_2.dart';
import 'protocol_base/service.dart';

/// The service responsible for adding custom platform support to
/// `flutter create`.
abstract base class TemplateService extends ToolExtensionService {
  /// Service namespace identifier for templates.
  static const String serviceNamespace = 'template';

  /// RPC method identifier to retrieve app templates.
  static const String getAppTemplatesMethod = 'template.getAppTemplates';

  /// RPC method identifier to retrieve plugin templates.
  static const String getPluginTemplatesMethod = 'template.getPluginTemplates';

  /// RPC method identifier to retrieve project templates.
  static const String getProjectTemplatesMethod = 'template.getProjectTemplates';

  /// RPC method identifier to generate template parameters.
  static const String generateTemplateParametersMethod = 'template.generateTemplateParameters';

  @override
  String get namespace => serviceNamespace;

  /// The set of additional template files to be initialized when using
  /// the `app` template.
  Set<String> get appPlatformTemplates;

  /// The set of platform templates for `plugin` template.
  Set<String> get pluginPlatformTemplates;

  /// The set of full project templates provided by the extension.
  Set<ProjectTemplate> get projectTemplates;

  /// Initializes the service by registering RPC methods with the extension provider.
  @override
  Future<Map<String, ExtensionRpcHandler>> initialize() async {
    return <String, ExtensionRpcHandler>{
      'getAppTemplates': _getAppTemplatesRpc,
      'getPluginTemplates': _getPluginTemplatesRpc,
      'getProjectTemplates': _getProjectTemplatesRpc,
      'generateTemplateParameters': _generateTemplateParametersRpc,
    };
  }

  /// Shuts down the service and cleans up any resources.
  @override
  Future<void> shutdown() async {}

  Future<Object?> _getAppTemplatesRpc(Map<String, Object?> params) async {
    return appPlatformTemplates.toList();
  }

  Future<Object?> _getPluginTemplatesRpc(Map<String, Object?> params) async {
    return pluginPlatformTemplates.toList();
  }

  Future<Object?> _getProjectTemplatesRpc(Map<String, Object?> params) async {
    return projectTemplates.map((ProjectTemplate template) => template.toMap()).toList();
  }

  Future<Object?> _generateTemplateParametersRpc(Map<String, Object?> params) async {
    if (params case {
      'templateName': final String templateName,
      'toolParameters': final Map<Object?, Object?> toolParams,
    }) {
      final Map<String, Object?> toolParameters = toolParams.cast<String, Object?>();
      for (final ProjectTemplate template in projectTemplates) {
        if (template.name == templateName) {
          return template.generateTemplateParameters(toolParameters);
        }
      }
      throw RpcException.invalidParams('Unknown project template: $templateName');
    }
    if (params['templateName'] is! String) {
      throw RpcException.invalidParams('Missing "templateName" parameter.');
    }
    throw RpcException.invalidParams('Missing "toolParameters" parameter.');
  }
}
