allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

subprojects {
    val configureProject = {
        val android = extensions.findByName("android")
        if (android != null) {
            try {
                val getNamespaceMethod = android.javaClass.getMethod("getNamespace")
                val namespace = getNamespaceMethod.invoke(android) as String?
                if (namespace.isNullOrEmpty()) {
                    val manifestFile = file("src/main/AndroidManifest.xml")
                    if (manifestFile.exists()) {
                        val manifestXml = manifestFile.readText()
                        val packageRegex = Regex("package=\"([^\"]+)\"")
                        val match = packageRegex.find(manifestXml)
                        if (match != null) {
                            val packageName = match.groupValues[1]
                            val setNamespaceMethod = android.javaClass.getMethod("setNamespace", String::class.java)
                            setNamespaceMethod.invoke(android, packageName)
                        }
                    }
                }
            } catch (e: Exception) {
                // Ignore missing method or errors during reflection
            }
        }
    }

    if (state.executed) {
        configureProject()
    } else {
        afterEvaluate {
            configureProject()
        }
    }
}
