#
# © 2024-present https://github.com/cengiz-pz
#

@tool
extends EditorPlugin

const PLUGIN_NAME: String = "@pluginName@"
const RESULT_ACTIVITY_CLASS_PATH: String = "@resultClass@"
const NOTIFICATION_RECEIVER_CLASS_PATH: String = "@notificationReceiverClass@"
const CANCEL_RECEIVER_CLASS_PATH: String = "@cancelReceiverClass@"
const BOOT_RECEIVER_CLASS_PATH: String = "@bootReceiverClass@"
const ANDROID_DEPENDENCIES: Array = [ @androidDependencies@ ]
const IOS_FRAMEWORKS: Array = [ @iosFrameworks@ ]
const IOS_EMBEDDED_FRAMEWORKS: Array = [ @iosEmbeddedFrameworks@ ]
const IOS_LINKER_FLAGS: Array = [ @iosLinkerFlags@ ]

var android_export_plugin: AndroidExportPlugin
var ios_export_plugin: IosExportPlugin


func _enter_tree() -> void:
	android_export_plugin = AndroidExportPlugin.new()
	add_export_plugin(android_export_plugin)
	ios_export_plugin = IosExportPlugin.new()
	add_export_plugin(ios_export_plugin)


func _exit_tree() -> void:
	remove_export_plugin(android_export_plugin)
	android_export_plugin = null
	remove_export_plugin(ios_export_plugin)
	ios_export_plugin = null


class AndroidExportPlugin extends EditorExportPlugin:
	const PLUGIN_ASSETS_DIRECTORY = "res://assets/%s" % PLUGIN_NAME
	const ANDROID_RES_DIRECTORY = "res://android/build/res"


	func _supports_platform(platform: EditorExportPlatform) -> bool:
		if platform is EditorExportPlatformAndroid:
			return true
		return false


	func _get_android_libraries(platform: EditorExportPlatform, debug: bool) -> PackedStringArray:
		if debug:
			return PackedStringArray(["%s/bin/debug/%s-debug.aar" % [PLUGIN_NAME, PLUGIN_NAME]])
		else:
			return PackedStringArray(["%s/bin/release/%s-release.aar" % [PLUGIN_NAME, PLUGIN_NAME]])


	func _get_name() -> String:
		return PLUGIN_NAME


	func _export_begin(_features: PackedStringArray, _is_debug: bool, path: String, _flags: int) -> void:
		if not DirAccess.dir_exists_absolute(PLUGIN_ASSETS_DIRECTORY):
			NotificationScheduler.log_error("Error: %s's assets directory not found! \"%s\""
					% [PLUGIN_NAME, PLUGIN_ASSETS_DIRECTORY])
		else:
			# copy notification assets
			_copy(PLUGIN_ASSETS_DIRECTORY, ANDROID_RES_DIRECTORY)


	func _get_android_dependencies(platform: EditorExportPlatform, debug: bool) -> PackedStringArray:
		return PackedStringArray(ANDROID_DEPENDENCIES)


	func _get_android_manifest_application_element_contents(platform: EditorExportPlatform, debug: bool) -> String:
		var __contents: String = ""

		__contents += """
			<activity
				android:name="%s"
				android:theme="@style/Theme.AppCompat.NoActionBar"
				android:excludeFromRecents="true"
				android:launchMode="singleTask"
				android:noHistory="true"
				android:taskAffinity="" />
			""" % RESULT_ACTIVITY_CLASS_PATH

		__contents += """
			<receiver
				android:name="%s"
				android:enabled="true"
				android:exported="true"
				android:process=":godot_notification_receiver" />
			""" % NOTIFICATION_RECEIVER_CLASS_PATH

		__contents += """
			<receiver
				android:name="%s"
				android:enabled="true"
				android:exported="true" />
			""" % CANCEL_RECEIVER_CLASS_PATH

		__contents += """
			<receiver
				android:name="%s"
				android:enabled="true"
				android:exported="false">
				<intent-filter>
					<action android:name="android.intent.action.BOOT_COMPLETED" />
					<action android:name="android.intent.action.QUICKBOOT_POWERON" />
				</intent-filter>
			</receiver>
			""" % BOOT_RECEIVER_CLASS_PATH

		return __contents


	func _copy(a_source_path: String, a_dest_path: String) -> void:
		NotificationScheduler.log_info("Copying \"%s\" to \"%s\"" % [a_source_path, a_dest_path])

		var __base_path: String = a_dest_path.get_base_dir()

		if not DirAccess.dir_exists_absolute(__base_path):
			var __result: int = DirAccess.make_dir_recursive_absolute(__base_path)
			if __result != OK:
				NotificationScheduler.log_error("Error %d when creating destination path \"%s\". Skipping."
						% [__result, __base_path])
				return

		if DirAccess.dir_exists_absolute(a_source_path):
			var sub_paths: PackedStringArray = DirAccess.get_files_at(a_source_path)
			sub_paths.append_array(DirAccess.get_directories_at(a_source_path))

			for sub_path in sub_paths:
				if not sub_path.ends_with(".import") and not sub_path.ends_with(".uid"):
					var __full_source_path = a_source_path.path_join(sub_path)
					if DirAccess.dir_exists_absolute(__full_source_path) or \
							FileAccess.file_exists(__full_source_path):
						_copy(__full_source_path, a_dest_path.path_join(sub_path))
					else:
						NotificationScheduler.log_error("Asset path not found: %s" % __full_source_path)
			return

		var __source_data: PackedByteArray = FileAccess.get_file_as_bytes(a_source_path)
		if not len(__source_data):
			NotificationScheduler.log_error("Failed reading \"%s\" or file is empty! Skipping." % a_source_path)
			return

		var __dest_file: FileAccess = FileAccess.open(a_dest_path, FileAccess.WRITE)
		if not __dest_file:
			NotificationScheduler.log_error("Error %d opening destination \"%s\" for writing! Skipping." %
					[FileAccess.get_open_error(), a_dest_path])
			return

		__dest_file.store_buffer(__source_data)
		__dest_file.close()


class IosExportPlugin extends EditorExportPlugin:

	var _plugin_name = PLUGIN_NAME


	func _supports_platform(platform: EditorExportPlatform) -> bool:
		if platform is EditorExportPlatformIOS:
			return true
		return false


	func _get_name() -> String:
		return _plugin_name


	func _export_begin(features: PackedStringArray, is_debug: bool, path: String, flags: int) -> void:
		for __framework in IOS_FRAMEWORKS:
			add_apple_embedded_platform_framework(__framework)

		for __framework in IOS_EMBEDDED_FRAMEWORKS:
			add_apple_embedded_platform_embedded_framework(__framework)

		for __flag in IOS_LINKER_FLAGS:
			add_apple_embedded_platform_linker_flags(__flag)
