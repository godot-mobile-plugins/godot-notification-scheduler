//
// © 2024-present https://github.com/cengiz-pz
//

tasks {
	register<Delete>("cleanIcons") {
		delete("${project.extra["outputDir"]}/assets/${project.extra["pluginName"]}")
	}

	register<Delete>("cleanDemoIcons") {
		delete("../demo/assets/${project.extra["pluginName"]}")
	}

	register<Copy>("copyIcons") {
		description = "Copies the notification icons to the plugin's assets directory"
		dependsOn("cleanIcons")

		from("../android/assets")
		into("${project.extra["outputDir"]}/assets/${project.extra["pluginName"]}")
	}

	register<Copy>("installIconsToDemo") {
		description = "Copies the notification icons to the plugin's assets directory"
		dependsOn("cleanIcons")

		from("${project.extra["outputDir"]}/assets/${project.extra["pluginName"]}")
		into("../demo/assets/${project.extra["pluginName"]}")
	}
}

afterEvaluate {
	tasks.named("cleanOutput").configure {
		finalizedBy("cleanIcons")
	}

	rootProject.tasks.named("cleanDemoAddons").configure {
		finalizedBy(":addon:cleanDemoIcons")
	}

	tasks.named("generateGDScript").configure {
		finalizedBy("copyIcons")
	}

	rootProject.tasks.named("installToDemo").configure {
		finalizedBy(":addon:installIconsToDemo")
	}

	listOf(
		rootProject.tasks.named("buildDebug"), 
		rootProject.tasks.named("buildRelease")
	).forEach { provider ->
		rootProject.tasks.named(provider.name).configure {
			mustRunAfter(":addon:copyIcons")
		}
	}
}
