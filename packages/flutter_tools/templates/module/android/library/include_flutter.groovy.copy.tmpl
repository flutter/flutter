// Generated file. Do not edit.

def scriptFile = getClass().protectionDomain.codeSource.location.path
def flutterProjectRoot = new File(scriptFile).parentFile.parentFile

gradle.include ':flutter'
gradle.project(':flutter').projectDir = new File(flutterProjectRoot, '.android/Flutter')

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

gradle.getGradle().projectsLoaded { g ->
    g.rootProject.afterEvaluate { p ->
        p.subprojects { sp ->
            if (sp.name != 'flutter') {
                sp.evaluationDependsOn(':flutter')
            }
        }
    }
}
