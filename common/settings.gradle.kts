//
// © 2024-present https://github.com/cengiz-pz
//

pluginManagement {
	repositories {
		gradlePluginPortal()
		google()
		mavenCentral()
	}
}

dependencyResolutionManagement {
	repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
	repositories {
		google()
		mavenCentral()
		flatDir {
			dirs("${rootDir}/../android/libs")
		}
	}
}

rootProject.name = "godot-notification-scheduler-plugin"
include(":android")
include(":addon")

project(":android").projectDir = file("../android")
project(":addon").projectDir = file("../addon")
