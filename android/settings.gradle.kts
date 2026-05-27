pluginManagement {
    val flutterSdkPath =
        run {
            val properties = java.util.Properties()
            val localPropertiesFile = file("local.properties")
            localPropertiesFile.inputStream().use { properties.load(it) }
            var flutterSdkPath = properties.getProperty("flutter.sdk")
            require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
            // Windows workaround: dart compile kernel fails when the SDK path contains
            // spaces. If Flutter regenerated local.properties with a spaced path, rewrite
            // it immediately so every subsequent Gradle task (including flutter.gradle's
            // own flutter.bat invocation) picks up the space-free junction instead.
            if (flutterSdkPath.contains(" ")) {
                flutterSdkPath = "C:\\flutter"
                properties.setProperty("flutter.sdk", flutterSdkPath)
                localPropertiesFile.outputStream().use { properties.store(it, null) }
            }
            flutterSdkPath
        }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "8.11.1" apply false
    // START: FlutterFire Configuration
    id("com.google.gms.google-services") version("4.3.15") apply false
    // END: FlutterFire Configuration
    id("org.jetbrains.kotlin.android") version "2.2.20" apply false
}

include(":app")
