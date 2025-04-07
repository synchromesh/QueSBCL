/* settings.gradle.kts 11 Mar 25 JDP QueSBCL */

pluginManagement {
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}
dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
    repositories {
        google()
        mavenCentral()
        maven("https://plugins.gradle.org/m2/")
        maven("https://s01.oss.sonatype.org/content/repositories/snapshots/")
    }
}

// 11 Mar 25 JDP
rootProject.name = "QueSBCL"
include(":plugin")

/*** End of settings.gradle.kts ***/