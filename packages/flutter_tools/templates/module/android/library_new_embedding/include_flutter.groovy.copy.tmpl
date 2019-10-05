// Generated file. Do not edit.

def scriptFile = getClass().protectionDomain.codeSource.location.toURI()
def flutterProjectRoot = new File(scriptFile).parentFile.parentFile

gradle.include ':flutter'
gradle.project(':flutter').projectDir = new File(flutterProjectRoot, '.android/Flutter')

if (System.getProperty('build-plugins-as-aars') != 'true') {
    def plugins = new Properties()
    def pluginsFile = new File(flutterProjectRoot, '.flutter-plugins')
    if (pluginsFile.exists()) {
        pluginsFile.withReader('UTF-8') { reader -> plugins.load(reader) }
    }

    plugins.each { name, path ->
        def pluginDirectory = flutterProjectRoot.toPath().resolve(path).resolve('android').toFile()
        gradle.include ":$name"
        gradle.project(":$name").projectDir = pluginDirectory
    }
}
gradle.getGradle().projectsLoaded { g ->
    g.rootProject.beforeEvaluate { p ->
        _mainModuleName = binding.variables['mainModuleName']
        if (_mainModuleName != null && !_mainModuleName.empty) {
            p.ext.mainModuleName = _mainModuleName
        }
        def subprojects = []
        def flutterProject
        p.subprojects { sp ->
            if (sp.name == 'flutter') {
                flutterProject = sp
            } else {
                subprojects.add(sp)
            }
        }
        assert flutterProject != null
        flutterProject.ext.hostProjects = subprojects
        flutterProject.ext.pluginBuildDir = new File(flutterProjectRoot, 'build/host')
    }
    g.rootProject.afterEvaluate { p ->
        p.subprojects { sp ->
            if (sp.name != 'flutter') {
                sp.evaluationDependsOn(':flutter')
            }
        }
    }
}
