buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        // Firebase — google-services plugin
        classpath("com.google.gms:google-services:4.4.2")
    }
}

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

    // Certains plugins Flutter (image_picker, flutter_local_notifications, …)
    // compilent encore avec source/target Java 8 et le compilateur JDK
    // récent émet un warning "obsolete". Les plugins ne sont pas sous notre
    // contrôle → on masque le bruit au niveau JavaCompile pour tous les
    // sous-projets. Le code de l'app reste en Java 17 (voir app/build.gradle.kts).
    tasks.withType<JavaCompile>().configureEach {
        options.compilerArgs.add("-Xlint:-options")
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
