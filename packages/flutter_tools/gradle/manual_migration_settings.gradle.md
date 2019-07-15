To manually update `settings.gradle`, follow these steps:

    1. Copy `settings.gradle` as `settings_aar.gradle`
    2. Remove the following code from `settings_aar.gradle`:

            def flutterProjectRoot = rootProject.projectDir.parentFile.toPath()

            def plugins = new Properties()
            def pluginsFile = new File(flutterProjectRoot.toFile(), '.flutter-plugins')
            if (pluginsFile.exists()) {
                pluginsFile.withReader('UTF-8') { reader -> plugins.load(reader) }
            }

            plugins.each { name, path ->
                def pluginDirectory = flutterProjectRoot.resolve(path).resolve('android').toFile()
                include ":$name"
                project(":$name").projectDir = pluginDirectory
            }

