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

gradle.projectsEvaluated {
    tasks.named("cleanOutput").configure {
        finalizedBy("cleanIcons")
    }

    project(":android").tasks.named("uninstallAndroid").configure {
        finalizedBy(":addon:cleanDemoIcons")
    }

    project(":addon").tasks.named("generateGDScript").configure {
        finalizedBy(":addon:copyIcons")
    }

    project(":android").tasks.named("installToDemoAndroid").configure {
        finalizedBy(":addon:installIconsToDemo")
    }

    listOf(
        project(":android").tasks.named("buildAndroidDebug"),
        project(":android").tasks.named("buildAndroidRelease"),
    ).forEach { provider ->
        provider.configure {
            mustRunAfter(":addon:copyIcons")
        }
    }
}
