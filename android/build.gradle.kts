// Top-level build file — configuration in settings.gradle.kts

subprojects {
    afterEvaluate {
        val android = extensions.findByName("android")
        if (android is com.android.build.gradle.LibraryExtension) {
            android.compileSdk = 36
        }
    }
}
