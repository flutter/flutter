// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// These file contents were derived from the META-INF/plugin.xml from an Intellij Flutter
/// plugin installation.
///
/// The file is loacted in a plugin JAR, which can be located by looking at the plugin
/// path for the Intellij and Android Studio validators.
///
/// If more XML contents are needed, prefer modifying these contents over checking
/// in another JAR.
const String kIntellijFlutterPluginXml = r'''
<idea-plugin version="2">
  <id>io.flutter</id>
  <name>Flutter</name>
  <description>Support for developing Flutter applications. Flutter gives developers an easy and productive way to build and deploy cross-platform, high-performance mobile apps on both Android and iOS.</description>
  <vendor url="https://github.com/flutter/flutter-intellij">flutter.io</vendor>

  <category>Custom Languages</category>

  <version>0.1.3</version>

  <idea-version since-build="162.1" until-build="163.*"/>

<change-notes>
<![CDATA[
0.1.3:
<ul>
  <li>notifications for projects that look like Flutter apps but do not have Flutter enabled</li>
  <li>improved Flutter preference UI and SDK configuration</li>
  <li>IDEA version constraints to ensure that the plugin cannot be installed in incompatible IDEA versions</li>
</ul>

0.1.2:
<ul>
  <li>fixed device selector filtering</li>
</ul>

0.1.1:
<ul>
  <li>removed second (redundant) "open observatory" button</li>
  <li>filtering to ensure the Flutter device selector only appears for Flutter projects</li>
  <li>fixed hangs on app re-runs</li>
</ul>

0.1.0:
<ul>
  <li>initial alpha release</li>
</ul>
 ]]>
 </change-notes>

  <depends>Dart</depends>

  <!-- Contributes IDEA-specific features and implementations. -->
  <depends optional="true" config-file="idea-contribs.xml">com.intellij.modules.java</depends>

  <!-- Everything following should be SmallIDE-friendly.-->
  <!-- See: http://www.jetbrains.org/intellij/sdk/docs/basics/getting_started/plugin_compatibility.html -->

  <actions>
    <action id="Flutter.HotReloadFlutterAppKey" class="io.flutter.actions.HotReloadFlutterAppKeyAction" text="Flutter Hot Reload">
      <keyboard-shortcut first-keystroke="ctrl F5" keymap="$default"/>
    </action>
    <action id="Flutter.RestartFlutterAppKey" class="io.flutter.actions.RestartFlutterAppKeyAction" text="Flutter Restart Application">
      <keyboard-shortcut first-keystroke="ctrl shift F5" keymap="$default"/>
    </action>
    <group id="Flutter.MainToolbarActions">
      <separator/>

      <action id="Flutter.DeviceSelector" class="io.flutter.actions.DeviceSelectorAction"
              description="Flutter Device Selection"
              icon="FlutterIcons.Phone"/>
    <separator/>
      <add-to-group anchor="before" group-id="RunContextGroup" relative-to-action="RunConfiguration"/>
      <add-to-group anchor="before" group-id="ToolbarRunGroup" relative-to-action="RunConfiguration"/>
    </group>
  </actions>

  <extensions defaultExtensionNs="com.intellij">

    <consoleInputFilterProvider implementation="io.flutter.run.daemon.DaemonJsonInputFilterProvider" />?
    <postStartupActivity implementation="io.flutter.FlutterInitializer"/>
    <applicationService serviceInterface="io.flutter.run.daemon.FlutterDaemonService"
                        serviceImplementation="io.flutter.run.daemon.FlutterDaemonService"/>

    <configurationType implementation="io.flutter.run.FlutterRunConfigurationType"/>
    <runConfigurationProducer implementation="io.flutter.run.FlutterRunConfigurationProducer"/>
    <programRunner implementation="io.flutter.run.FlutterRunner"/>

    <moduleType id="FLUTTER_MODULE_TYPE" implementationClass="io.flutter.module.FlutterModuleType"/>

    <projectService serviceInterface="io.flutter.settings.FlutterSettings" serviceImplementation="io.flutter.settings.FlutterSettings"/>

    <!-- Plugin service with SmallIDE default, optionally overridden by product-specific implementations -->
    <projectService serviceInterface="io.flutter.sdk.FlutterSdkService" serviceImplementation="io.flutter.sdk.FlutterSmallIDESdkService"
                    overrides="false"/>

    <console.folding implementation="io.flutter.console.FlutterConsoleFolding"/>

    <applicationConfigurable groupId="language" instance="io.flutter.sdk.FlutterSettingsConfigurable"
                             id="flutter.settings" key="flutter.title" bundle="io.flutter.FlutterBundle" nonDefaultProject="true"/>
  </extensions>

</idea-plugin>

<idea-plugin version="2">
  <name>Dart</name>
  <version>162.2485</version>
  <idea-version since-build="162.1121" until-build="162.*"/>

  <description>Support for Dart programming language</description>
  <vendor>JetBrains</vendor>
  <depends>com.intellij.modules.xml</depends>
  <depends optional="true" config-file="dartium-debugger-support.xml">JavaScriptDebugger</depends>
  <depends optional="true" config-file="dart-yaml.xml">org.jetbrains.plugins.yaml</depends>
  <depends optional="true" config-file="dart-copyright.xml">com.intellij.copyright</depends>
  <depends optional="true" config-file="dart-coverage.xml">com.intellij.modules.coverage</depends>

  <change-notes>
    <![CDATA[
        <ul>
          <li>Improvements and bug fixes</li>
        </ul>
      ]]>
  </change-notes>

  <application-components/>

  <project-components>
    <component>
      <implementation-class>com.jetbrains.lang.dart.DartProjectComponent</implementation-class>
      <skipForDefaultProject/>
    </component>
  </project-components>

  <extensions defaultExtensionNs="com.intellij">
    <fileTypeFactory implementation="com.jetbrains.lang.dart.DartFileTypeFactory"/>
    <psi.treeChangePreprocessor implementation="com.jetbrains.lang.dart.DartPsiTreeChangePreprocessor"/>
    <lang.syntaxHighlighterFactory language="Dart" implementationClass="com.jetbrains.lang.dart.highlight.DartSyntaxHighlighterFactory"/>

    <lang.braceMatcher language="Dart" implementationClass="com.jetbrains.lang.dart.ide.DartBraceMatcher"/>
    <typedHandler implementation="com.jetbrains.lang.dart.ide.editor.DartTypeHandler" id="Dart"/>
    <quoteHandler fileType="Dart" className="com.jetbrains.lang.dart.ide.editor.DartQuoteHandler"/>

    <lang.commenter language="Dart" implementationClass="com.jetbrains.lang.dart.ide.DartCommenter"/>
    <lang.parserDefinition language="Dart" implementationClass="com.jetbrains.lang.dart.DartParserDefinition"/>

    <enterHandlerDelegate implementation="com.jetbrains.lang.dart.ide.editor.DartEnterInDocLineCommentHandler"/>
    <enterHandlerDelegate implementation="com.jetbrains.lang.dart.ide.editor.DartEnterInStringHandler" order="first"/>
    <lang.lineWrapStrategy language="Dart" implementationClass="com.jetbrains.lang.dart.ide.editor.DartLineWrapPositionStrategy"/>

    <languageInjector implementation="com.jetbrains.lang.dart.psi.DartLanguageInjector"/>
    <multiHostInjector implementation="com.jetbrains.lang.dart.injection.DartMultiHostInjector"/>

    <colorSettingsPage implementation="com.jetbrains.lang.dart.highlight.DartColorsAndFontsPage"/>
    <lang.foldingBuilder language="Dart" implementationClass="com.jetbrains.lang.dart.folding.DartFoldingBuilder"/>
    <extendWordSelectionHandler implementation="com.jetbrains.lang.dart.ide.editor.DartWordSelectionHandler"/>
    <basicWordSelectionFilter implementation="com.jetbrains.lang.dart.ide.editor.DartSelectionFilter"/>

    <html.scriptContentProvider language="Dart" implementationClass="com.jetbrains.lang.dart.DartScriptContentProvider"/>
    <nonProjectFileWritingAccessExtension implementation="com.jetbrains.lang.dart.ide.DartWritingAccessProvider"/>
    <spellchecker.support language="Dart" implementationClass="com.jetbrains.lang.dart.DartSpellcheckingStrategy"/>
    <lang.documentationProvider language="Dart" implementationClass="com.jetbrains.lang.dart.ide.documentation.DartDocumentationProvider"/>
    <lang.implementationTextSelectioner language="Dart"
                                        implementationClass="com.jetbrains.lang.dart.ide.DartImplementationTextSelectioner"/>
    <lang.formatter language="Dart" implementationClass="com.jetbrains.lang.dart.ide.formatter.DartFormattingModelBuilder"/>
    <lang.psiStructureViewFactory language="Dart" implementationClass="com.jetbrains.lang.dart.ide.structure.DartStructureViewFactory"/>
    <lang.structureViewExtension implementation="com.jetbrains.lang.dart.ide.structure.DartStructureViewExtension"/>
    <psi.referenceContributor language="HTML" implementation="com.jetbrains.lang.dart.psi.DartPackagePathReferenceContributor"
                              order="last"/>
    <include.provider implementation="com.jetbrains.lang.dart.psi.DartPackageAwareFileIncludeProvider" order="first"/>
    <typeHierarchyProvider language="Dart" implementationClass="com.jetbrains.lang.dart.ide.hierarchy.type.DartTypeHierarchyProvider"/>
    <callHierarchyProvider language="Dart" implementationClass="com.jetbrains.lang.dart.ide.hierarchy.call.DartCallHierarchyProvider"/>
    <methodHierarchyProvider language="Dart" implementationClass="com.jetbrains.lang.dart.ide.hierarchy.method.DartMethodHierarchyProvider"/>
    <lang.elementManipulator forClass="com.jetbrains.lang.dart.psi.DartUriElement"
                             implementationClass="com.jetbrains.lang.dart.psi.impl.DartUriElementBase$DartUriElementManipulator"/>
    <lang.elementManipulator forClass="com.jetbrains.lang.dart.psi.DartStringLiteralExpression"
                             implementationClass="com.jetbrains.lang.dart.psi.impl.DartStringLiteralExpressionBase$DartStringManipulator"/>
    <lang.refactoringSupport language="Dart"
                             implementationClass="com.jetbrains.lang.dart.ide.refactoring.DartRefactoringSupportProvider"/>

    <codeInsight.parameterInfo language="Dart"
                               implementationClass="com.jetbrains.lang.dart.ide.info.DartParameterInfoHandler"/>

    <codeStyleSettingsProvider implementation="com.jetbrains.lang.dart.ide.formatter.settings.DartCodeStyleSettingsProvider"/>
    <codeStyleSettingsProvider implementation="com.jetbrains.lang.dart.ide.application.options.DartGenerationSettingsProvider"/>

    <langCodeStyleSettingsProvider implementation="com.jetbrains.lang.dart.ide.formatter.settings.DartLanguageCodeStyleSettingsProvider"/>
    <lang.importOptimizer language="Dart" implementationClass="com.jetbrains.lang.dart.ide.imports.DartImportOptimizer"/>

    <renamePsiElementProcessor implementation="com.jetbrains.lang.dart.ide.DartRenamePsiElementProcessor"/>
    <renameHandler implementation="com.jetbrains.lang.dart.ide.refactoring.DartServerRenameHandler"/>
    <inlineActionHandler implementation="com.jetbrains.lang.dart.ide.refactoring.DartInlineHandler"/>

    <codeInsight.lineMarkerProvider language="Dart" implementationClass="com.jetbrains.lang.dart.ide.marker.DartMethodLineMarkerProvider"/>
    <!--<codeInsight.lineMarkerProvider language="Dart"-->
                                    <!--implementationClass="com.jetbrains.lang.dart.ide.marker.DartImplementationsMarkerProvider"/>-->
    <codeInsight.lineMarkerProvider language="Dart"
                                    implementationClass="com.jetbrains.lang.dart.ide.marker.DartServerImplementationsMarkerProvider"/>
    <!--<codeInsight.lineMarkerProvider language="Dart"-->
                                    <!--implementationClass="com.jetbrains.lang.dart.ide.marker.DartMethodOverrideMarkerProvider"/>-->
    <codeInsight.lineMarkerProvider language="Dart"
                                    implementationClass="com.jetbrains.lang.dart.ide.marker.DartServerOverrideMarkerProvider"/>

    <!--<codeInsight.gotoSuper language="Dart" implementationClass="com.jetbrains.lang.dart.ide.actions.DartGotoSuperHandler"/>-->
    <!--<definitionsSearch implementation="com.jetbrains.lang.dart.ide.index.DartInheritanceIndex$DefinitionsSearchExecutor"/>-->
    <codeInsight.gotoSuper language="Dart" implementationClass="com.jetbrains.lang.dart.ide.actions.DartServerGotoSuperHandler"/>
    <definitionsScopedSearch implementation="com.jetbrains.lang.dart.ide.actions.DartInheritorsSearcher"/>

    <codeInsight.overrideMethod language="Dart"
                                implementationClass="com.jetbrains.lang.dart.ide.generation.DartOverrideMethodHandler"/>
    <codeInsight.implementMethod language="Dart"
                                 implementationClass="com.jetbrains.lang.dart.ide.generation.DartImplementMethodHandler"/>

    <fileBasedIndex implementation="com.jetbrains.lang.dart.ide.index.DartImportAndExportIndex"/>
    <fileBasedIndex implementation="com.jetbrains.lang.dart.ide.index.DartPartUriIndex"/>
    <!--<fileBasedIndex implementation="com.jetbrains.lang.dart.ide.index.DartSourceIndex"/>-->
    <fileBasedIndex implementation="com.jetbrains.lang.dart.ide.index.DartClassIndex"/>
    <fileBasedIndex implementation="com.jetbrains.lang.dart.ide.index.DartLibraryIndex"/>
    <fileBasedIndex implementation="com.jetbrains.lang.dart.ide.index.DartComponentIndex"/>
    <fileBasedIndex implementation="com.jetbrains.lang.dart.ide.index.DartSymbolIndex"/>
    <fileBasedIndex implementation="com.jetbrains.lang.dart.ide.index.DartInheritanceIndex"/>

    <!-- moduleBuilder works in IntelliJ IDEA only -->
    <moduleBuilder builderClass="com.jetbrains.lang.dart.projectWizard.DartModuleBuilder"/>
    <!-- directoryProjectGenerator works in WebStorm and other small IDEs -->
    <directoryProjectGenerator implementation="com.jetbrains.lang.dart.projectWizard.DartProjectGenerator"/>

    <projectConfigurable groupId="language" instance="com.jetbrains.lang.dart.sdk.DartConfigurable"
                         id="dart.settings" key="dart.title" bundle="com.jetbrains.lang.dart.DartBundle" nonDefaultProject="true"/>
    <library.presentationProvider implementation="com.jetbrains.lang.dart.sdk.DartSdkLibraryPresentationProvider"/>
    <library.type implementation="com.jetbrains.lang.dart.sdk.DartPackagesLibraryType"/>

    <treeStructureProvider implementation="com.jetbrains.lang.dart.projectView.DartTreeStructureProvider"/>
    <iconProvider implementation="com.jetbrains.lang.dart.projectView.DartIconProvider" order="first"/>
    <projectViewNodeDecorator implementation="com.jetbrains.lang.dart.projectView.DartNodeDecorator"/>

    <internalFileTemplate name="Dart File"/>

    <liveTemplateMacro implementation="com.jetbrains.lang.dart.ide.template.macro.DartClassNameMacro"/>
    <liveTemplateMacro implementation="com.jetbrains.lang.dart.ide.template.macro.DartMethodNameMacro"/>
    <liveTemplateMacro implementation="com.jetbrains.lang.dart.ide.template.macro.DartClassNameMethodNameMacro"/>
    <liveTemplateMacro implementation="com.jetbrains.lang.dart.ide.template.macro.DartMethodParametersMacro"/>
    <liveTemplateMacro implementation="com.jetbrains.lang.dart.ide.template.macro.DartMethodReturnTypeMacro"/>
    <liveTemplateMacro implementation="com.jetbrains.lang.dart.ide.template.macro.DartListVariableMacro"/>
    <liveTemplateMacro implementation="com.jetbrains.lang.dart.ide.template.macro.DartIterableVariableMacro"/>
    <liveTemplateMacro implementation="com.jetbrains.lang.dart.ide.template.macro.DartSuggestIndexNameMacro"/>
    <liveTemplateMacro implementation="com.jetbrains.lang.dart.ide.template.macro.DartSuggestVariableNameMacro"/>

    <liveTemplateContext implementation="com.jetbrains.lang.dart.ide.template.DartTemplateContextType$Generic"/>
    <liveTemplateContext implementation="com.jetbrains.lang.dart.ide.template.DartTemplateContextType$Statement"/>
    <defaultLiveTemplatesProvider implementation="com.jetbrains.lang.dart.ide.template.DartLiveTemplatesProvider"/>

    <lang.surroundDescriptor language="Dart"
                             implementationClass="com.jetbrains.lang.dart.ide.surroundWith.DartExpressionSurroundDescriptor"/>
    <lang.surroundDescriptor language="Dart"
                             implementationClass="com.jetbrains.lang.dart.ide.surroundWith.DartStatementsSurroundDescriptor"/>

    <gotoClassContributor implementation="com.jetbrains.lang.dart.ide.DartClassContributor"/>
    <gotoSymbolContributor implementation="com.jetbrains.lang.dart.ide.DartSymbolContributor"/>

    <completion.contributor language="Dart" implementationClass="com.jetbrains.lang.dart.ide.completion.DartServerCompletionContributor"/>
    <weigher key="completion" id="DartServerCompletionWeigher" order="after prefix"
             implementationClass="com.jetbrains.lang.dart.ide.completion.DartServerCompletionWeigher"/>

    <resolveScopeProvider implementation="com.jetbrains.lang.dart.resolve.DartResolveScopeProvider"/>

    <annotator language="Dart" implementationClass="com.jetbrains.lang.dart.ide.annotator.DartAnnotator"/>
    <!--<annotator language="Dart" implementationClass="com.jetbrains.lang.dart.ide.annotator.DartUnresolvedReferenceVisitor"/>-->

    <lang.findUsagesProvider language="Dart" implementationClass="com.jetbrains.lang.dart.ide.findUsages.DartFindUsagesProvider"/>
    <usageTypeProvider implementation="com.jetbrains.lang.dart.ide.findUsages.DartUsageTypeProvider"/>
    <findUsagesHandlerFactory implementation="com.jetbrains.lang.dart.ide.findUsages.DartServerFindUsagesHandlerFactory"/>
    <fileStructureGroupRuleProvider implementation="com.jetbrains.lang.dart.ide.findUsages.DartUnitMemberGroupRuleProvider"/>
    <fileStructureGroupRuleProvider implementation="com.jetbrains.lang.dart.ide.findUsages.DartClassMemberGroupRuleProvider"/>

    <intentionAction>
      <className>com.jetbrains.lang.dart.assists.DartQuickAssistIntention</className>
      <category>Dart</category>
    </intentionAction>

    <applicationService serviceInterface="com.jetbrains.lang.dart.analyzer.DartAnalysisServerService"
                        serviceImplementation="com.jetbrains.lang.dart.analyzer.DartAnalysisServerService"/>
    <projectService serviceInterface="com.jetbrains.lang.dart.psi.DartClassResolveCache"
                    serviceImplementation="com.jetbrains.lang.dart.psi.DartClassResolveCache"/>
    <projectService serviceInterface="com.jetbrains.lang.dart.pubServer.PubServerManager"
                    serviceImplementation="com.jetbrains.lang.dart.pubServer.PubServerManager"/>
    <projectService serviceInterface="com.jetbrains.lang.dart.ide.errorTreeView.DartProblemsView"
                    serviceImplementation="com.jetbrains.lang.dart.ide.errorTreeView.DartProblemsView"/>

    <applicationService serviceInterface="com.jetbrains.lang.dart.folding.DartCodeFoldingSettings"
                        serviceImplementation="com.jetbrains.lang.dart.folding.DartCodeFoldingSettings"/>
    <exportable serviceInterface="com.jetbrains.lang.dart.folding.DartCodeFoldingSettings"/>
    <codeFoldingOptionsProvider instance="com.jetbrains.lang.dart.folding.DartCodeFoldingOptionsProvider"/>
    <editorNotificationProvider implementation="com.jetbrains.lang.dart.ide.actions.DartEditorNotificationsProvider"/>
    <consoleFilterProvider implementation="com.jetbrains.lang.dart.ide.runner.DartConsoleFilterProvider" order="first"/>

    <xdebugger.breakpointType implementation="com.jetbrains.lang.dart.ide.runner.DartLineBreakpointType"/>

    <configurationType implementation="com.jetbrains.lang.dart.ide.runner.server.DartCommandLineRunConfigurationType"/>
    <runConfigurationProducer implementation="com.jetbrains.lang.dart.ide.runner.server.DartCommandLineRuntimeConfigurationProducer"/>
    <configurationType implementation="com.jetbrains.lang.dart.ide.runner.server.DartRemoteDebugConfigurationType"/>
    <configurationType implementation="com.jetbrains.lang.dart.ide.runner.test.DartTestRunConfigurationType"/>
    <runConfigurationProducer implementation="com.jetbrains.lang.dart.ide.runner.test.DartTestRunConfigurationProducer"/>

    <programRunner implementation="com.jetbrains.lang.dart.ide.runner.DartRunner"/>

    <localInspection bundle="com.jetbrains.lang.dart.DartBundle" key="outdated.dependencies.inspection.name"
                     groupName="Dart" enabledByDefault="true" level="WARNING" language="Dart"
                     implementationClass="com.jetbrains.lang.dart.ide.inspections.DartOutdatedDependenciesInspection"/>
  </extensions>

  <extensions defaultExtensionNs="org.jetbrains">
    <webServerPathHandler implementation="com.jetbrains.lang.dart.pubServer.PubServerPathHandler"/>
  </extensions>

  <actions>
    <action id="Dart.stop.pub.server" class="com.jetbrains.lang.dart.pubServer.StopPubServerAction" text="Stop Pub Serve"/>

    <action id="Dart.NewDartFile" class="com.jetbrains.lang.dart.ide.actions.CreateDartFileAction"
            text="Dart File" description="Create new Dart file">
      <add-to-group group-id="NewGroup" anchor="before" relative-to-action="NewFromTemplate"/>
    </action>
    <action id="Dart.Reanalyze" class="com.jetbrains.lang.dart.ide.errorTreeView.ReanalyzeDartSourcesAction"
            text="Reanalyze Dart Sources" description="Reanalyze all Dart source files">
    </action>
    <action id="Dart.Restart.Analysis.Server" class="com.jetbrains.lang.dart.ide.errorTreeView.RestartDartAnalysisServerAction"
            text="Restart Dart Analysis Server" description="Restart Dart Analysis Server">
    </action>
    <action id="Dart.DartStyle" class="com.jetbrains.lang.dart.ide.actions.DartStyleAction"
            text="Reformat with Dart Style" description="Format your Dart code using the dart_style formatter">
      <add-to-group group-id="CodeFormatGroup" anchor="last"/>
      <add-to-group group-id="EditorPopupMenu" relative-to-action="EditorPopupMenu1" anchor="after"/>
      <add-to-group group-id="ProjectViewPopupMenuModifyGroup" anchor="before" relative-to-action="$Delete"/>
    </action>
    <action id="Dart.DartSortMembers" class="com.jetbrains.lang.dart.ide.actions.DartSortMembersAction"
            text="Sort members in Dart File" description="Sort members in your Dart code">
      <add-to-group group-id="CodeFormatGroup" anchor="after" relative-to-action="Dart.DartStyle"/>
    </action>
    <action id="Generate.Constructor.Dart" class="com.jetbrains.lang.dart.ide.generation.DartGenerateConstructorAction"
            text="Constructor">
      <add-to-group anchor="first" group-id="GenerateGroup"/>
    </action>
    <action id="Generate.Named.Constructor.Dart" class="com.jetbrains.lang.dart.ide.generation.DartGenerateNamedConstructorAction"
            text="Named Constructor">
      <add-to-group anchor="after" relative-to-action="Generate.Constructor.Dart"  group-id="GenerateGroup"/>
    </action>
    <action id="Generate.GetAccessor.Dart" class="com.jetbrains.lang.dart.ide.generation.DartGenerateGetterAction"
            text="Getter">
      <add-to-group anchor="after" relative-to-action="Generate.Named.Constructor.Dart" group-id="GenerateGroup"/>
    </action>
    <action id="Generate.SetAccessor.Dart" class="com.jetbrains.lang.dart.ide.generation.DartGenerateSetterAction"
            text="Setter">
      <add-to-group anchor="after" relative-to-action="Generate.GetAccessor.Dart" group-id="GenerateGroup"/>
    </action>
    <action id="Generate.GetSetAccessor.Dart" class="com.jetbrains.lang.dart.ide.generation.DartGenerateGetterSetterAction"
            text="Getter and Setter">
      <add-to-group anchor="after" relative-to-action="Generate.SetAccessor.Dart" group-id="GenerateGroup"/>
    </action>
    <action id="Generate.ToString.Dart" class="com.jetbrains.lang.dart.ide.generation.DartGenerateToStringAction"
            text="toString()">
      <add-to-group anchor="after" relative-to-action="Generate.GetSetAccessor.Dart" group-id="GenerateGroup"/>
    </action>
    <action id="Generate.EqualsAndHashcode.Dart" class="com.jetbrains.lang.dart.ide.generation.DartGenerateEqualsAndHashcodeAction"
            text="==() and hashCode">
      <add-to-group anchor="after" relative-to-action="Generate.ToString.Dart" group-id="GenerateGroup"/>
    </action>

    <group>
      <action id="Dart.pub.get" class="com.jetbrains.lang.dart.ide.actions.DartPubGetAction" text="Pub: Get Dependencies"
              description="Run 'pub get'"/>
      <action id="Dart.pub.upgrade" class="com.jetbrains.lang.dart.ide.actions.DartPubUpgradeAction" text="Pub: Upgrade Dependencies"
              description="Run 'pub upgrade'"/>
      <action id="Dart.pub.build" class="com.jetbrains.lang.dart.ide.actions.DartPubBuildAction" text="Pub: Build..."
              description="Run 'pub build'"/>
      <separator/>
      <add-to-group group-id="EditorPopupMenu" anchor="first"/>
      <add-to-group group-id="ProjectViewPopupMenu" relative-to-action="CutCopyPasteGroup" anchor="before"/>
    </group>
    <action id="Dart.pub.cache.repair" class="com.jetbrains.lang.dart.ide.actions.DartPubCacheRepairAction" text="Pub: Repair Cache..."
            description="Run 'pub cache repair'"/>

    <action id="DartTypeHierarchy.BaseOnThisType" text="Base on this Type"
            class="com.jetbrains.lang.dart.ide.hierarchy.type.DartTypeHierarchyBrowser$BaseOnThisTypeAction"
            use-shortcut-of="TypeHierarchy"/>
    <group id="DartClassHierarchyPopupMenu">
      <reference ref="DartTypeHierarchy.BaseOnThisType"/>
      <reference ref="TypeHierarchy.Class"/>
      <reference ref="TypeHierarchy.Subtypes"/>
      <reference ref="TypeHierarchy.Supertypes"/>
      <separator/>
      <reference ref="EditSource"/>
      <separator/>
      <reference ref="FindUsages"/>
      <reference ref="RefactoringMenu"/>
      <separator/>
      <reference ref="AddToFavorites"/>
      <separator/>
      <reference ref="VersionControlsGroup"/>
      <separator/>
    </group>

    <action id="DartCallHierarchy.BaseOnThisFunction" text="Base on this Component"
            class="com.intellij.ide.hierarchy.CallHierarchyBrowserBase$BaseOnThisMethodAction"
            use-shortcut-of="CallHierarchy"/>
    <group id="DartCallHierarchyPopupMenu">
      <reference ref="DartCallHierarchy.BaseOnThisFunction"/>
      <separator/>
      <reference ref="EditSource"/>
      <separator/>
      <reference ref="FindUsages"/>
      <reference ref="RefactoringMenu"/>
      <separator/>
      <reference ref="AddToFavorites"/>
      <separator/>
      <reference ref="VersionControlsGroup"/>
      <separator/>
    </group>

    <group id="DartMethodHierarchyPopupMenu">
      <reference ref="EditSource"/>
      <separator/>
      <reference ref="FindUsages"/>
      <reference ref="RefactoringMenu"/>
      <separator/>
      <reference ref="AddToFavorites"/>
      <separator/>
      <reference ref="VersionControlsGroup"/>
      <separator/>
    </group>

  </actions>
</idea-plugin>
''';

/// These file contents were derived from the META-INF/plugin.xml from an Intellij Dart
/// plugin installation.
///
/// The file is loacted in a plugin JAR, which can be located by looking at the plugin
/// path for the Intellij and Android Studio validators.
///
/// If more XML contents are needed, prefer modifying these contents over checking
/// in another JAR.
const String kIntellijDartPluginXml = r'''
<idea-plugin version="2">
  <name>Dart</name>
  <version>162.2485</version>
  <idea-version since-build="162.1121" until-build="162.*"/>

  <description>Support for Dart programming language</description>
  <vendor>JetBrains</vendor>
  <depends>com.intellij.modules.xml</depends>
  <depends optional="true" config-file="dartium-debugger-support.xml">JavaScriptDebugger</depends>
  <depends optional="true" config-file="dart-yaml.xml">org.jetbrains.plugins.yaml</depends>
  <depends optional="true" config-file="dart-copyright.xml">com.intellij.copyright</depends>
  <depends optional="true" config-file="dart-coverage.xml">com.intellij.modules.coverage</depends>

  <change-notes>
    <![CDATA[
        <ul>
          <li>Improvements and bug fixes</li>
        </ul>
      ]]>
  </change-notes>

  <application-components/>

  <project-components>
    <component>
      <implementation-class>com.jetbrains.lang.dart.DartProjectComponent</implementation-class>
      <skipForDefaultProject/>
    </component>
  </project-components>

  <extensions defaultExtensionNs="com.intellij">
    <fileTypeFactory implementation="com.jetbrains.lang.dart.DartFileTypeFactory"/>
    <psi.treeChangePreprocessor implementation="com.jetbrains.lang.dart.DartPsiTreeChangePreprocessor"/>
    <lang.syntaxHighlighterFactory language="Dart" implementationClass="com.jetbrains.lang.dart.highlight.DartSyntaxHighlighterFactory"/>

    <lang.braceMatcher language="Dart" implementationClass="com.jetbrains.lang.dart.ide.DartBraceMatcher"/>
    <typedHandler implementation="com.jetbrains.lang.dart.ide.editor.DartTypeHandler" id="Dart"/>
    <quoteHandler fileType="Dart" className="com.jetbrains.lang.dart.ide.editor.DartQuoteHandler"/>

    <lang.commenter language="Dart" implementationClass="com.jetbrains.lang.dart.ide.DartCommenter"/>
    <lang.parserDefinition language="Dart" implementationClass="com.jetbrains.lang.dart.DartParserDefinition"/>

    <enterHandlerDelegate implementation="com.jetbrains.lang.dart.ide.editor.DartEnterInDocLineCommentHandler"/>
    <enterHandlerDelegate implementation="com.jetbrains.lang.dart.ide.editor.DartEnterInStringHandler" order="first"/>
    <lang.lineWrapStrategy language="Dart" implementationClass="com.jetbrains.lang.dart.ide.editor.DartLineWrapPositionStrategy"/>

    <languageInjector implementation="com.jetbrains.lang.dart.psi.DartLanguageInjector"/>
    <multiHostInjector implementation="com.jetbrains.lang.dart.injection.DartMultiHostInjector"/>

    <colorSettingsPage implementation="com.jetbrains.lang.dart.highlight.DartColorsAndFontsPage"/>
    <lang.foldingBuilder language="Dart" implementationClass="com.jetbrains.lang.dart.folding.DartFoldingBuilder"/>
    <extendWordSelectionHandler implementation="com.jetbrains.lang.dart.ide.editor.DartWordSelectionHandler"/>
    <basicWordSelectionFilter implementation="com.jetbrains.lang.dart.ide.editor.DartSelectionFilter"/>

    <html.scriptContentProvider language="Dart" implementationClass="com.jetbrains.lang.dart.DartScriptContentProvider"/>
    <nonProjectFileWritingAccessExtension implementation="com.jetbrains.lang.dart.ide.DartWritingAccessProvider"/>
    <spellchecker.support language="Dart" implementationClass="com.jetbrains.lang.dart.DartSpellcheckingStrategy"/>
    <lang.documentationProvider language="Dart" implementationClass="com.jetbrains.lang.dart.ide.documentation.DartDocumentationProvider"/>
    <lang.implementationTextSelectioner language="Dart"
                                        implementationClass="com.jetbrains.lang.dart.ide.DartImplementationTextSelectioner"/>
    <lang.formatter language="Dart" implementationClass="com.jetbrains.lang.dart.ide.formatter.DartFormattingModelBuilder"/>
    <lang.psiStructureViewFactory language="Dart" implementationClass="com.jetbrains.lang.dart.ide.structure.DartStructureViewFactory"/>
    <lang.structureViewExtension implementation="com.jetbrains.lang.dart.ide.structure.DartStructureViewExtension"/>
    <psi.referenceContributor language="HTML" implementation="com.jetbrains.lang.dart.psi.DartPackagePathReferenceContributor"
                              order="last"/>
    <include.provider implementation="com.jetbrains.lang.dart.psi.DartPackageAwareFileIncludeProvider" order="first"/>
    <typeHierarchyProvider language="Dart" implementationClass="com.jetbrains.lang.dart.ide.hierarchy.type.DartTypeHierarchyProvider"/>
    <callHierarchyProvider language="Dart" implementationClass="com.jetbrains.lang.dart.ide.hierarchy.call.DartCallHierarchyProvider"/>
    <methodHierarchyProvider language="Dart" implementationClass="com.jetbrains.lang.dart.ide.hierarchy.method.DartMethodHierarchyProvider"/>
    <lang.elementManipulator forClass="com.jetbrains.lang.dart.psi.DartUriElement"
                             implementationClass="com.jetbrains.lang.dart.psi.impl.DartUriElementBase$DartUriElementManipulator"/>
    <lang.elementManipulator forClass="com.jetbrains.lang.dart.psi.DartStringLiteralExpression"
                             implementationClass="com.jetbrains.lang.dart.psi.impl.DartStringLiteralExpressionBase$DartStringManipulator"/>
    <lang.refactoringSupport language="Dart"
                             implementationClass="com.jetbrains.lang.dart.ide.refactoring.DartRefactoringSupportProvider"/>

    <codeInsight.parameterInfo language="Dart"
                               implementationClass="com.jetbrains.lang.dart.ide.info.DartParameterInfoHandler"/>

    <codeStyleSettingsProvider implementation="com.jetbrains.lang.dart.ide.formatter.settings.DartCodeStyleSettingsProvider"/>
    <codeStyleSettingsProvider implementation="com.jetbrains.lang.dart.ide.application.options.DartGenerationSettingsProvider"/>

    <langCodeStyleSettingsProvider implementation="com.jetbrains.lang.dart.ide.formatter.settings.DartLanguageCodeStyleSettingsProvider"/>
    <lang.importOptimizer language="Dart" implementationClass="com.jetbrains.lang.dart.ide.imports.DartImportOptimizer"/>

    <renamePsiElementProcessor implementation="com.jetbrains.lang.dart.ide.DartRenamePsiElementProcessor"/>
    <renameHandler implementation="com.jetbrains.lang.dart.ide.refactoring.DartServerRenameHandler"/>
    <inlineActionHandler implementation="com.jetbrains.lang.dart.ide.refactoring.DartInlineHandler"/>

    <codeInsight.lineMarkerProvider language="Dart" implementationClass="com.jetbrains.lang.dart.ide.marker.DartMethodLineMarkerProvider"/>
    <!--<codeInsight.lineMarkerProvider language="Dart"-->
                                    <!--implementationClass="com.jetbrains.lang.dart.ide.marker.DartImplementationsMarkerProvider"/>-->
    <codeInsight.lineMarkerProvider language="Dart"
                                    implementationClass="com.jetbrains.lang.dart.ide.marker.DartServerImplementationsMarkerProvider"/>
    <!--<codeInsight.lineMarkerProvider language="Dart"-->
                                    <!--implementationClass="com.jetbrains.lang.dart.ide.marker.DartMethodOverrideMarkerProvider"/>-->
    <codeInsight.lineMarkerProvider language="Dart"
                                    implementationClass="com.jetbrains.lang.dart.ide.marker.DartServerOverrideMarkerProvider"/>

    <!--<codeInsight.gotoSuper language="Dart" implementationClass="com.jetbrains.lang.dart.ide.actions.DartGotoSuperHandler"/>-->
    <!--<definitionsSearch implementation="com.jetbrains.lang.dart.ide.index.DartInheritanceIndex$DefinitionsSearchExecutor"/>-->
    <codeInsight.gotoSuper language="Dart" implementationClass="com.jetbrains.lang.dart.ide.actions.DartServerGotoSuperHandler"/>
    <definitionsScopedSearch implementation="com.jetbrains.lang.dart.ide.actions.DartInheritorsSearcher"/>

    <codeInsight.overrideMethod language="Dart"
                                implementationClass="com.jetbrains.lang.dart.ide.generation.DartOverrideMethodHandler"/>
    <codeInsight.implementMethod language="Dart"
                                 implementationClass="com.jetbrains.lang.dart.ide.generation.DartImplementMethodHandler"/>

    <fileBasedIndex implementation="com.jetbrains.lang.dart.ide.index.DartImportAndExportIndex"/>
    <fileBasedIndex implementation="com.jetbrains.lang.dart.ide.index.DartPartUriIndex"/>
    <!--<fileBasedIndex implementation="com.jetbrains.lang.dart.ide.index.DartSourceIndex"/>-->
    <fileBasedIndex implementation="com.jetbrains.lang.dart.ide.index.DartClassIndex"/>
    <fileBasedIndex implementation="com.jetbrains.lang.dart.ide.index.DartLibraryIndex"/>
    <fileBasedIndex implementation="com.jetbrains.lang.dart.ide.index.DartComponentIndex"/>
    <fileBasedIndex implementation="com.jetbrains.lang.dart.ide.index.DartSymbolIndex"/>
    <fileBasedIndex implementation="com.jetbrains.lang.dart.ide.index.DartInheritanceIndex"/>

    <!-- moduleBuilder works in IntelliJ IDEA only -->
    <moduleBuilder builderClass="com.jetbrains.lang.dart.projectWizard.DartModuleBuilder"/>
    <!-- directoryProjectGenerator works in WebStorm and other small IDEs -->
    <directoryProjectGenerator implementation="com.jetbrains.lang.dart.projectWizard.DartProjectGenerator"/>

    <projectConfigurable groupId="language" instance="com.jetbrains.lang.dart.sdk.DartConfigurable"
                         id="dart.settings" key="dart.title" bundle="com.jetbrains.lang.dart.DartBundle" nonDefaultProject="true"/>
    <library.presentationProvider implementation="com.jetbrains.lang.dart.sdk.DartSdkLibraryPresentationProvider"/>
    <library.type implementation="com.jetbrains.lang.dart.sdk.DartPackagesLibraryType"/>

    <treeStructureProvider implementation="com.jetbrains.lang.dart.projectView.DartTreeStructureProvider"/>
    <iconProvider implementation="com.jetbrains.lang.dart.projectView.DartIconProvider" order="first"/>
    <projectViewNodeDecorator implementation="com.jetbrains.lang.dart.projectView.DartNodeDecorator"/>

    <internalFileTemplate name="Dart File"/>

    <liveTemplateMacro implementation="com.jetbrains.lang.dart.ide.template.macro.DartClassNameMacro"/>
    <liveTemplateMacro implementation="com.jetbrains.lang.dart.ide.template.macro.DartMethodNameMacro"/>
    <liveTemplateMacro implementation="com.jetbrains.lang.dart.ide.template.macro.DartClassNameMethodNameMacro"/>
    <liveTemplateMacro implementation="com.jetbrains.lang.dart.ide.template.macro.DartMethodParametersMacro"/>
    <liveTemplateMacro implementation="com.jetbrains.lang.dart.ide.template.macro.DartMethodReturnTypeMacro"/>
    <liveTemplateMacro implementation="com.jetbrains.lang.dart.ide.template.macro.DartListVariableMacro"/>
    <liveTemplateMacro implementation="com.jetbrains.lang.dart.ide.template.macro.DartIterableVariableMacro"/>
    <liveTemplateMacro implementation="com.jetbrains.lang.dart.ide.template.macro.DartSuggestIndexNameMacro"/>
    <liveTemplateMacro implementation="com.jetbrains.lang.dart.ide.template.macro.DartSuggestVariableNameMacro"/>

    <liveTemplateContext implementation="com.jetbrains.lang.dart.ide.template.DartTemplateContextType$Generic"/>
    <liveTemplateContext implementation="com.jetbrains.lang.dart.ide.template.DartTemplateContextType$Statement"/>
    <defaultLiveTemplatesProvider implementation="com.jetbrains.lang.dart.ide.template.DartLiveTemplatesProvider"/>

    <lang.surroundDescriptor language="Dart"
                             implementationClass="com.jetbrains.lang.dart.ide.surroundWith.DartExpressionSurroundDescriptor"/>
    <lang.surroundDescriptor language="Dart"
                             implementationClass="com.jetbrains.lang.dart.ide.surroundWith.DartStatementsSurroundDescriptor"/>

    <gotoClassContributor implementation="com.jetbrains.lang.dart.ide.DartClassContributor"/>
    <gotoSymbolContributor implementation="com.jetbrains.lang.dart.ide.DartSymbolContributor"/>

    <completion.contributor language="Dart" implementationClass="com.jetbrains.lang.dart.ide.completion.DartServerCompletionContributor"/>
    <weigher key="completion" id="DartServerCompletionWeigher" order="after prefix"
             implementationClass="com.jetbrains.lang.dart.ide.completion.DartServerCompletionWeigher"/>

    <resolveScopeProvider implementation="com.jetbrains.lang.dart.resolve.DartResolveScopeProvider"/>

    <annotator language="Dart" implementationClass="com.jetbrains.lang.dart.ide.annotator.DartAnnotator"/>
    <!--<annotator language="Dart" implementationClass="com.jetbrains.lang.dart.ide.annotator.DartUnresolvedReferenceVisitor"/>-->

    <lang.findUsagesProvider language="Dart" implementationClass="com.jetbrains.lang.dart.ide.findUsages.DartFindUsagesProvider"/>
    <usageTypeProvider implementation="com.jetbrains.lang.dart.ide.findUsages.DartUsageTypeProvider"/>
    <findUsagesHandlerFactory implementation="com.jetbrains.lang.dart.ide.findUsages.DartServerFindUsagesHandlerFactory"/>
    <fileStructureGroupRuleProvider implementation="com.jetbrains.lang.dart.ide.findUsages.DartUnitMemberGroupRuleProvider"/>
    <fileStructureGroupRuleProvider implementation="com.jetbrains.lang.dart.ide.findUsages.DartClassMemberGroupRuleProvider"/>

    <intentionAction>
      <className>com.jetbrains.lang.dart.assists.DartQuickAssistIntention</className>
      <category>Dart</category>
    </intentionAction>

    <applicationService serviceInterface="com.jetbrains.lang.dart.analyzer.DartAnalysisServerService"
                        serviceImplementation="com.jetbrains.lang.dart.analyzer.DartAnalysisServerService"/>
    <projectService serviceInterface="com.jetbrains.lang.dart.psi.DartClassResolveCache"
                    serviceImplementation="com.jetbrains.lang.dart.psi.DartClassResolveCache"/>
    <projectService serviceInterface="com.jetbrains.lang.dart.pubServer.PubServerManager"
                    serviceImplementation="com.jetbrains.lang.dart.pubServer.PubServerManager"/>
    <projectService serviceInterface="com.jetbrains.lang.dart.ide.errorTreeView.DartProblemsView"
                    serviceImplementation="com.jetbrains.lang.dart.ide.errorTreeView.DartProblemsView"/>

    <applicationService serviceInterface="com.jetbrains.lang.dart.folding.DartCodeFoldingSettings"
                        serviceImplementation="com.jetbrains.lang.dart.folding.DartCodeFoldingSettings"/>
    <exportable serviceInterface="com.jetbrains.lang.dart.folding.DartCodeFoldingSettings"/>
    <codeFoldingOptionsProvider instance="com.jetbrains.lang.dart.folding.DartCodeFoldingOptionsProvider"/>
    <editorNotificationProvider implementation="com.jetbrains.lang.dart.ide.actions.DartEditorNotificationsProvider"/>
    <consoleFilterProvider implementation="com.jetbrains.lang.dart.ide.runner.DartConsoleFilterProvider" order="first"/>

    <xdebugger.breakpointType implementation="com.jetbrains.lang.dart.ide.runner.DartLineBreakpointType"/>

    <configurationType implementation="com.jetbrains.lang.dart.ide.runner.server.DartCommandLineRunConfigurationType"/>
    <runConfigurationProducer implementation="com.jetbrains.lang.dart.ide.runner.server.DartCommandLineRuntimeConfigurationProducer"/>
    <configurationType implementation="com.jetbrains.lang.dart.ide.runner.server.DartRemoteDebugConfigurationType"/>
    <configurationType implementation="com.jetbrains.lang.dart.ide.runner.test.DartTestRunConfigurationType"/>
    <runConfigurationProducer implementation="com.jetbrains.lang.dart.ide.runner.test.DartTestRunConfigurationProducer"/>

    <programRunner implementation="com.jetbrains.lang.dart.ide.runner.DartRunner"/>

    <localInspection bundle="com.jetbrains.lang.dart.DartBundle" key="outdated.dependencies.inspection.name"
                     groupName="Dart" enabledByDefault="true" level="WARNING" language="Dart"
                     implementationClass="com.jetbrains.lang.dart.ide.inspections.DartOutdatedDependenciesInspection"/>
  </extensions>

  <extensions defaultExtensionNs="org.jetbrains">
    <webServerPathHandler implementation="com.jetbrains.lang.dart.pubServer.PubServerPathHandler"/>
  </extensions>

  <actions>
    <action id="Dart.stop.pub.server" class="com.jetbrains.lang.dart.pubServer.StopPubServerAction" text="Stop Pub Serve"/>

    <action id="Dart.NewDartFile" class="com.jetbrains.lang.dart.ide.actions.CreateDartFileAction"
            text="Dart File" description="Create new Dart file">
      <add-to-group group-id="NewGroup" anchor="before" relative-to-action="NewFromTemplate"/>
    </action>
    <action id="Dart.Reanalyze" class="com.jetbrains.lang.dart.ide.errorTreeView.ReanalyzeDartSourcesAction"
            text="Reanalyze Dart Sources" description="Reanalyze all Dart source files">
    </action>
    <action id="Dart.Restart.Analysis.Server" class="com.jetbrains.lang.dart.ide.errorTreeView.RestartDartAnalysisServerAction"
            text="Restart Dart Analysis Server" description="Restart Dart Analysis Server">
    </action>
    <action id="Dart.DartStyle" class="com.jetbrains.lang.dart.ide.actions.DartStyleAction"
            text="Reformat with Dart Style" description="Format your Dart code using the dart_style formatter">
      <add-to-group group-id="CodeFormatGroup" anchor="last"/>
      <add-to-group group-id="EditorPopupMenu" relative-to-action="EditorPopupMenu1" anchor="after"/>
      <add-to-group group-id="ProjectViewPopupMenuModifyGroup" anchor="before" relative-to-action="$Delete"/>
    </action>
    <action id="Dart.DartSortMembers" class="com.jetbrains.lang.dart.ide.actions.DartSortMembersAction"
            text="Sort members in Dart File" description="Sort members in your Dart code">
      <add-to-group group-id="CodeFormatGroup" anchor="after" relative-to-action="Dart.DartStyle"/>
    </action>
    <action id="Generate.Constructor.Dart" class="com.jetbrains.lang.dart.ide.generation.DartGenerateConstructorAction"
            text="Constructor">
      <add-to-group anchor="first" group-id="GenerateGroup"/>
    </action>
    <action id="Generate.Named.Constructor.Dart" class="com.jetbrains.lang.dart.ide.generation.DartGenerateNamedConstructorAction"
            text="Named Constructor">
      <add-to-group anchor="after" relative-to-action="Generate.Constructor.Dart"  group-id="GenerateGroup"/>
    </action>
    <action id="Generate.GetAccessor.Dart" class="com.jetbrains.lang.dart.ide.generation.DartGenerateGetterAction"
            text="Getter">
      <add-to-group anchor="after" relative-to-action="Generate.Named.Constructor.Dart" group-id="GenerateGroup"/>
    </action>
    <action id="Generate.SetAccessor.Dart" class="com.jetbrains.lang.dart.ide.generation.DartGenerateSetterAction"
            text="Setter">
      <add-to-group anchor="after" relative-to-action="Generate.GetAccessor.Dart" group-id="GenerateGroup"/>
    </action>
    <action id="Generate.GetSetAccessor.Dart" class="com.jetbrains.lang.dart.ide.generation.DartGenerateGetterSetterAction"
            text="Getter and Setter">
      <add-to-group anchor="after" relative-to-action="Generate.SetAccessor.Dart" group-id="GenerateGroup"/>
    </action>
    <action id="Generate.ToString.Dart" class="com.jetbrains.lang.dart.ide.generation.DartGenerateToStringAction"
            text="toString()">
      <add-to-group anchor="after" relative-to-action="Generate.GetSetAccessor.Dart" group-id="GenerateGroup"/>
    </action>
    <action id="Generate.EqualsAndHashcode.Dart" class="com.jetbrains.lang.dart.ide.generation.DartGenerateEqualsAndHashcodeAction"
            text="==() and hashCode">
      <add-to-group anchor="after" relative-to-action="Generate.ToString.Dart" group-id="GenerateGroup"/>
    </action>

    <group>
      <action id="Dart.pub.get" class="com.jetbrains.lang.dart.ide.actions.DartPubGetAction" text="Pub: Get Dependencies"
              description="Run 'pub get'"/>
      <action id="Dart.pub.upgrade" class="com.jetbrains.lang.dart.ide.actions.DartPubUpgradeAction" text="Pub: Upgrade Dependencies"
              description="Run 'pub upgrade'"/>
      <action id="Dart.pub.build" class="com.jetbrains.lang.dart.ide.actions.DartPubBuildAction" text="Pub: Build..."
              description="Run 'pub build'"/>
      <separator/>
      <add-to-group group-id="EditorPopupMenu" anchor="first"/>
      <add-to-group group-id="ProjectViewPopupMenu" relative-to-action="CutCopyPasteGroup" anchor="before"/>
    </group>
    <action id="Dart.pub.cache.repair" class="com.jetbrains.lang.dart.ide.actions.DartPubCacheRepairAction" text="Pub: Repair Cache..."
            description="Run 'pub cache repair'"/>

    <action id="DartTypeHierarchy.BaseOnThisType" text="Base on this Type"
            class="com.jetbrains.lang.dart.ide.hierarchy.type.DartTypeHierarchyBrowser$BaseOnThisTypeAction"
            use-shortcut-of="TypeHierarchy"/>
    <group id="DartClassHierarchyPopupMenu">
      <reference ref="DartTypeHierarchy.BaseOnThisType"/>
      <reference ref="TypeHierarchy.Class"/>
      <reference ref="TypeHierarchy.Subtypes"/>
      <reference ref="TypeHierarchy.Supertypes"/>
      <separator/>
      <reference ref="EditSource"/>
      <separator/>
      <reference ref="FindUsages"/>
      <reference ref="RefactoringMenu"/>
      <separator/>
      <reference ref="AddToFavorites"/>
      <separator/>
      <reference ref="VersionControlsGroup"/>
      <separator/>
    </group>

    <action id="DartCallHierarchy.BaseOnThisFunction" text="Base on this Component"
            class="com.intellij.ide.hierarchy.CallHierarchyBrowserBase$BaseOnThisMethodAction"
            use-shortcut-of="CallHierarchy"/>
    <group id="DartCallHierarchyPopupMenu">
      <reference ref="DartCallHierarchy.BaseOnThisFunction"/>
      <separator/>
      <reference ref="EditSource"/>
      <separator/>
      <reference ref="FindUsages"/>
      <reference ref="RefactoringMenu"/>
      <separator/>
      <reference ref="AddToFavorites"/>
      <separator/>
      <reference ref="VersionControlsGroup"/>
      <separator/>
    </group>

    <group id="DartMethodHierarchyPopupMenu">
      <reference ref="EditSource"/>
      <separator/>
      <reference ref="FindUsages"/>
      <reference ref="RefactoringMenu"/>
      <separator/>
      <reference ref="AddToFavorites"/>
      <separator/>
      <reference ref="VersionControlsGroup"/>
      <separator/>
    </group>

  </actions>
</idea-plugin>
''';
