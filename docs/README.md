<p align="center">
	<img width="128" height="128" src="https://raw.githubusercontent.com/godot-mobile-plugins/godot-notification-scheduler/main/demo/assets/notification-scheduler-android.png">
	&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
	<img width="128" height="128" src="https://raw.githubusercontent.com/godot-mobile-plugins/godot-notification-scheduler/main/demo/assets/notification-scheduler-ios.png">
</p>

<div align="center">
	<a href="https://github.com/godot-mobile-plugins/godot-notification-scheduler"><img src="https://img.shields.io/github/stars/godot-mobile-plugins/godot-notification-scheduler?style=social&style=plastic" height="32"/></a>
	<img src="https://img.shields.io/github/v/release/godot-mobile-plugins/godot-notification-scheduler?label=Latest%20Release&style=plastic" height="32"/>
	<img src="https://img.shields.io/github/downloads/godot-mobile-plugins/godot-notification-scheduler/latest/total?label=Downloads&style=plastic" height="32" />
	<img src="https://img.shields.io/github/downloads/godot-mobile-plugins/godot-notification-scheduler/total?label=Total%20Downloads&style=plastic" height="32" />
</div>

<br>

# <img src="https://raw.githubusercontent.com/godot-mobile-plugins/godot-notification-scheduler/main/addon/src/icon.png" width="24"> Godot Notification Scheduler Plugin

A unified GDScript interface for scheduling **local notifications** on **Android** and **iOS**.

**Features:**
- Schedule local notifications with customizable titles, content, and delays.
- Schedule repeating notifications with intervals.
- Manage notification channels and badges.
- Handle permissions and user interactions via signals.
- Plugin handles system restart allowing scheduled notifications to survive device reboots

## <img src="https://raw.githubusercontent.com/godot-mobile-plugins/godot-notification-scheduler/main/addon/src/icon.png" width="20"> Table of Contents

- [Demo](#demo)
- [Installation](#installation)
- [Usage](#usage)
- [Signals](#signals)
- [Methods](#methods)
- [Error Codes](#error-codes)
- [Classes](#classes)
- [Classes](#classes)
- [Platform-Specific Notes](#platform-specific-notes)
- [Video Tutorials](#video-tutorials)
- [Links](#links)
- [All Plugins](#all-plugins)
- [Credits](#credits)
- [Contributing](#contributing)

---

<a name="demo"></a>

## <img src="https://raw.githubusercontent.com/godot-mobile-plugins/godot-notification-scheduler/main/addon/src/icon.png" width="20"> Demo

Try the **demo app** located in the `demo` directory.

<p align="center">
	<img src="https://raw.githubusercontent.com/godot-mobile-plugins/godot-notification-scheduler/main/docs/assets/demo_screenshot_android_521.png" width="243">
</p>

<a name="installation"></a>

## <img src="https://raw.githubusercontent.com/godot-mobile-plugins/godot-notification-scheduler/main/addon/src/icon.png" width="20"> Installation

**Uninstall previous versions** before installing.
If using both Android & iOS, ensure **same addon interface version**.

**Options:**
1. **AssetLib**
	- Search for `Notification Scheduler`
	- Click `Download` → `Install`
	- Install to project root, `Ignore asset root` checked
	- Enable via **Project → Project Settings → Plugins**
	- Ignore file conflict warnings when installing both versions
2. **Manual**
	- Download release from GitHub
	- Unzip to project root
	- Enable via **Plugins** tab

<a name="usage"></a>

## <img src="https://raw.githubusercontent.com/godot-mobile-plugins/godot-notification-scheduler/main/addon/src/icon.png" width="20"> Usage

1. Add a **NotificationScheduler** node to your scene.
2. Connect [signals](#signals):
	- `initialization_completed`
	- `notification_opened`
	- `notification_dismissed`
	- `permission_granted`
	- `permission_denied`
3. Check permission:
	```gdscript
	if not $NotificationScheduler.has_post_notifications_permission():
		$NotificationScheduler.request_post_notifications_permission()
	```
4. To send user to App Info (manual enable):
	```gdscript
	$NotificationScheduler.open_app_info_settings()
	```
5. Create a notification channel:
	```gdscript
	var res = $NotificationScheduler.create_notification_channel(
		 NotificationChannel.new()
			  .set_id("my_channel_id")
			  .set_name("My Channel Name")
			  .set_description("My channel description")
			  .set_importance(NotificationChannel.Importance.DEFAULT))
	```
6. Build & schedule notification:
	```gdscript
	var data = NotificationData.new()
		 .set_id(1)
		 .set_channel_id("my_channel_id")
		 .set_title("My Title")
		 .set_content("My content")
		 .set_small_icon_name("ic_custom_icon")
		 .set_delay(10)

	var res = $NotificationScheduler.schedule(data)
	```

<a name="signals"></a>

## <img src="https://raw.githubusercontent.com/godot-mobile-plugins/godot-notification-scheduler/main/addon/src/icon.png" width="20"> Signals
- `initialization_completed()`: Emitted when the plugin is initialized.
- `post_notifications_permission_granted(permission_name: String)`: Emitted when notification permission is granted to app.
- `post_notifications_permission_denied(permission_name: String)`: Emitted when notification permission is denied to app.
- `notification_opened(notification_data: NotificationData)`: Emitted when user taps notification.
- `notification_dismissed(notification_data: NotificationData)`: Emitted when user dismisses notification.

### <img src="https://raw.githubusercontent.com/godot-mobile-plugins/godot-notification-scheduler/main/addon/src/icon.png" width="16"> Android-only Signals
- `battery_optimizations_permission_granted(permission_name: String)`: Emitted when battery optimization exemption permission is granted to app.
- `battery_optimizations_permission_granted(permission_name: String)`: Emitted when battery optimization exemption is denied to app.
- `schedule_exact_alarm_permission_granted(permission_name: String)`: Emitted when permission to schedule exact alarms is granted to app.
- `schedule_exact_alarm_permission_denied(permission_name: String)`: Emitted when permission to schedule exact alarms is denied to app.

<a name="methods"></a>

## <img src="https://raw.githubusercontent.com/godot-mobile-plugins/godot-notification-scheduler/main/addon/src/icon.png" width="20"> Methods
- `initialize()` - initialize plugin
- `create_notification_channel(NotificationChannel)` - create a new notification channel with given data
- `schedule(NotificationData)` - schedule a new notification with given data
- `cancel(id)` – cancel notification with given Id before opened/dismissed
- `get_notification_id()` – get ID of last opened notification
- `has_post_notifications_permission()` – returns true if app has already been granted permissions to post notifications
- `request_post_notifications_permission()` – request permissions to post notifications from user
- `open_app_info_settings()` - open the system settings screen for app

### <img src="https://raw.githubusercontent.com/godot-mobile-plugins/godot-notification-scheduler/main/addon/src/icon.png" width="16"> Android-only Methods
- `has_battery_optimizations_permission()` – returns true if app has already been granted permissions to ignore battery optimizations
- `request_battery_optimizations_permission()` – request permissions to ignore battery optimizations from user
- `has_schedule_exact_alarm_permission()` – returns true if app has already been granted permission to schedule exact alarms
- `request_schedule_exact_alarm_permission()` – request permission to schedule exact alarms rom user

### <img src="https://raw.githubusercontent.com/godot-mobile-plugins/godot-notification-scheduler/main/addon/src/icon.png" width="16"> iOS-only Methods
- `set_badge_count(count)` – show/hide app icon badge with count (on Android, use `NotificationData`'s `set_badge_count()` method)

<a name="error-codes"></a>

## <img src="https://raw.githubusercontent.com/godot-mobile-plugins/godot-notification-scheduler/main/addon/src/icon.png" width="20"> Error Codes

| Constant              | Value | Description                             |
|-----------------------|-------|-----------------------------------------|
| `ERR_ALREADY_EXISTS`  | `32`  | Channel ID already exists               |
| `ERR_INVALID_DATA`    | `30`  | Invalid notification/channel data       |
| `ERR_UNAVAILABLE`     | `2`   | Not supported on current platform       |
| `ERR_UNCONFIGURED`    | `3`   | Plugin not initialized                  |
| `OK`                  | `0`   | Success                                 |

<a name="classes"></a>

## <img src="https://raw.githubusercontent.com/godot-mobile-plugins/godot-notification-scheduler/main/addon/src/icon.png" width="20"> Classes

### <img src="https://raw.githubusercontent.com/godot-mobile-plugins/godot-notification-scheduler/main/addon/src/icon.png" width="16"> NotificationChannel
- Encapsulates data that defines the notification channel.
- Properties: `id`, `name`, `description`, `importance`, `badge_enabled`

### <img src="https://raw.githubusercontent.com/godot-mobile-plugins/godot-notification-scheduler/main/addon/src/icon.png" width="16"> NotificationData
- Encapsulates data that defines the notification.
- Properties: `notification_id`, `channel_id`, `title`, `content`, `small_icon_name`, `large_icon_name`, `delay`, `deeplink`, `interval`, `badge_count`, `custom_data`
- Note: `small_icon_name` and `large_icon_name` are only used on Android.

### <img src="https://raw.githubusercontent.com/godot-mobile-plugins/godot-notification-scheduler/main/addon/src/icon.png" width="16"> CustomData
- Encapsulates extra data to be sent and received along with other notification data.
- Allows setting of any number of `bool`, `int`, `float`, or `String` properties.

<a name="platform-specific-notes"></a>

## <img src="https://raw.githubusercontent.com/godot-mobile-plugins/godot-notification-scheduler/main/addon/src/icon.png" width="20"> Platform-Specific Notes

### <img src="https://raw.githubusercontent.com/godot-mobile-plugins/godot-notification-scheduler/main/addon/src/icon.png" width="16"> Android
- **Default icon:** `ic_default_notification` in `res://assets/NotificationSchedulerPlugin`
- **Custom icon:**
	1. Generate via Android Studio → **Image Asset Studio** → **Notification Icons**
	2. Copy generated drawables into `res://assets/NotificationSchedulerPlugin`
	3. Use `set_small_icon_name("icon_name")`
- **App Optimization:**
	- Check app optimization settings
	- If app settings are set to `Optimized` or `Restricted`, notifications may not be delivered when app is not running
- **MIUI:**
	- `request_post_notifications_permission()` may not work reliably on Xiaomi devices to fully exempt an app from **MIUI**'s custom battery management features.
- **App Optimization and Exact Alarm:**
	- The plugin will schedule an exact alarm to deliver the notification if the `SCHEDULE_EXACT_ALARM` permission has been granted, else the plugin will fall back to non-exact scheduling.
	- Obtaining the `IGNORE_BATTERY_OPTIMIZATIONS` permission will also allow scheduling of exact alarms - additionally requesting `SCHEDULE_EXACT_ALARM` permission is not necessary.
- **Troubleshooting:**
	- Logs: `adb logcat | grep 'godot'` (Linux), `adb.exe logcat | select-string "godot"` (Windows)
	- No small icon error: ensure icons exist in assets directory.
	- Battery restrictions: check **Settings → Apps → Your App → Battery**.

### <img src="https://raw.githubusercontent.com/godot-mobile-plugins/godot-notification-scheduler/main/addon/src/icon.png" width="16"> iOS
- Set notification icons in **Project → Export → iOS**.
- System limits:
	- Max repeating notifications: 64
	- Min interval: 60 seconds
- View XCode logs while running the game for troubleshooting.
- See [Godot iOS Export Troubleshooting](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_ios.html#troubleshooting).

<a name="video-tutorials"></a>

# <img src="https://raw.githubusercontent.com/godot-mobile-plugins/godot-notification-scheduler/main/addon/src/icon.png" width="24"> Video Tutorials

## **Notification Scheduler Plugin on Android** -- _by [Code Artist](https://www.youtube.com/@codeartist1687)_
[![Notification Scheduler Plugin on Android](https://img.youtube.com/vi/QKN5enW2640/0.jpg)](https://youtu.be/QKN5enW2640)

<br>

<a name="links"></a>

# <img src="https://raw.githubusercontent.com/godot-mobile-plugins/godot-notification-scheduler/main/addon/src/icon.png" width="20"> Links

- [AssetLib Entry Android](https://godotengine.org/asset-library/asset/2547)
- [AssetLib Entry iOS](https://godotengine.org/asset-library/asset/3186)

<br>

<a name="all-plugins"></a>

# <img src="https://raw.githubusercontent.com/godot-mobile-plugins/godot-notification-scheduler/main/addon/src/icon.png" width="24"> All Plugins

| ✦ | Plugin | Android | iOS | Latest Release | Downloads | Stars |
| :--- | :--- | :---: | :---: | :---: | :---: | :---: |
| <img src="https://raw.githubusercontent.com/godot-sdk-integrations/godot-admob/main/addon/src/icon.png" width="20"> | [Admob](https://github.com/godot-sdk-integrations/godot-admob) | ✅ | ✅ | <a href="https://github.com/godot-sdk-integrations/godot-admob/releases"><img src="https://img.shields.io/github/release-date/godot-sdk-integrations/godot-admob?label=%20" /> <img src="https://img.shields.io/github/v/release/godot-sdk-integrations/godot-admob?label=%20" /></a> | <img src="https://img.shields.io/github/downloads/godot-sdk-integrations/godot-admob/latest/total?label=latest" /> <img src="https://img.shields.io/github/downloads/godot-sdk-integrations/godot-admob/total?label=total" /> | <img src="https://img.shields.io/github/stars/godot-sdk-integrations/godot-admob?style=plastic&label=%20" /> |
| <img src="https://raw.githubusercontent.com/godot-mobile-plugins/godot-connection-state/main/addon/src/icon.png" width="20"> | [Connection State](https://github.com/godot-mobile-plugins/godot-connection-state) | ✅ | ✅ | <a href="https://github.com/godot-mobile-plugins/godot-connection-state/releases"><img src="https://img.shields.io/github/release-date/godot-mobile-plugins/godot-connection-state?label=%20" /> <img src="https://img.shields.io/github/v/release/godot-mobile-plugins/godot-connection-state?label=%20" /></a> | <img src="https://img.shields.io/github/downloads/godot-mobile-plugins/godot-connection-state/latest/total?label=latest" /> <img src="https://img.shields.io/github/downloads/godot-mobile-plugins/godot-connection-state/total?label=total" /> | <img src="https://img.shields.io/github/stars/godot-mobile-plugins/godot-connection-state?style=plastic&label=%20" /> |
| <img src="https://raw.githubusercontent.com/godot-mobile-plugins/godot-deeplink/main/addon/src/icon.png" width="20"> | [Deeplink](https://github.com/godot-mobile-plugins/godot-deeplink) | ✅ | ✅ | <a href="https://github.com/godot-mobile-plugins/godot-deeplink/releases"><img src="https://img.shields.io/github/release-date/godot-mobile-plugins/godot-deeplink?label=%20" /> <img src="https://img.shields.io/github/v/release/godot-mobile-plugins/godot-deeplink?label=%20" /></a> | <img src="https://img.shields.io/github/downloads/godot-mobile-plugins/godot-deeplink/latest/total?label=latest" /> <img src="https://img.shields.io/github/downloads/godot-mobile-plugins/godot-deeplink/total?label=total" /> | <img src="https://img.shields.io/github/stars/godot-mobile-plugins/godot-deeplink?style=plastic&label=%20" /> |
| <img src="https://raw.githubusercontent.com/godot-mobile-plugins/godot-firebase/main/addon/src/icon.png" width="20"> | [Firebase](https://github.com/godot-mobile-plugins/godot-firebase) | ✅ | ✅ | - <!-- <a href="https://github.com/godot-mobile-plugins/godot-firebase/releases"><img src="https://img.shields.io/github/release-date/godot-mobile-plugins/godot-firebase?label=%20" /> <img src="https://img.shields.io/github/v/release/godot-mobile-plugins/godot-firebase?label=%20" /></a> --> | - <!-- <img src="https://img.shields.io/github/downloads/godot-mobile-plugins/godot-firebase/latest/total?label=latest" /> <img src="https://img.shields.io/github/downloads/godot-mobile-plugins/godot-firebase/total?label=%20" /> --> | <img src="https://img.shields.io/github/stars/godot-mobile-plugins/godot-firebase?style=plastic&label=%20" /> |
| <img src="https://raw.githubusercontent.com/godot-mobile-plugins/godot-inapp-review/main/addon/src/icon.png" width="20"> | [In-App Review](https://github.com/godot-mobile-plugins/godot-inapp-review) | ✅ | ✅ | <a href="https://github.com/godot-mobile-plugins/godot-inapp-review/releases"><img src="https://img.shields.io/github/release-date/godot-mobile-plugins/godot-inapp-review?label=%20" /> <img src="https://img.shields.io/github/v/release/godot-mobile-plugins/godot-inapp-review?label=%20" /></a> | <img src="https://img.shields.io/github/downloads/godot-mobile-plugins/godot-inapp-review/latest/total?label=latest" /> <img src="https://img.shields.io/github/downloads/godot-mobile-plugins/godot-inapp-review/total?label=total" /> | <img src="https://img.shields.io/github/stars/godot-mobile-plugins/godot-inapp-review?style=plastic&label=%20" /> |
| <img src="https://raw.githubusercontent.com/godot-mobile-plugins/godot-native-camera/main/addon/src/icon.png" width="20"> | [Native Camera](https://github.com/godot-mobile-plugins/godot-native-camera) | ✅ | ✅ | <a href="https://github.com/godot-mobile-plugins/godot-native-camera/releases"><img src="https://img.shields.io/github/release-date/godot-mobile-plugins/godot-native-camera?label=%20" /> <img src="https://img.shields.io/github/v/release/godot-mobile-plugins/godot-native-camera?label=%20" /></a> | <img src="https://img.shields.io/github/downloads/godot-mobile-plugins/godot-native-camera/latest/total?label=latest" /> <img src="https://img.shields.io/github/downloads/godot-mobile-plugins/godot-native-camera/total?label=total" /> | <img src="https://img.shields.io/github/stars/godot-mobile-plugins/godot-native-camera?style=plastic&label=%20" /> |
| <img src="https://raw.githubusercontent.com/godot-mobile-plugins/godot-notification-scheduler/main/addon/src/icon.png" width="20"> | [Notification Scheduler](https://github.com/godot-mobile-plugins/godot-notification-scheduler) | ✅ | ✅ | <a href="https://github.com/godot-mobile-plugins/godot-notification-scheduler/releases"><img src="https://img.shields.io/github/release-date/godot-mobile-plugins/godot-notification-scheduler?label=%20" /> <img src="https://img.shields.io/github/v/release/godot-mobile-plugins/godot-notification-scheduler?label=%20" /></a> | <img src="https://img.shields.io/github/downloads/godot-mobile-plugins/godot-notification-scheduler/latest/total?label=latest" /> <img src="https://img.shields.io/github/downloads/godot-mobile-plugins/godot-notification-scheduler/total?label=total" /> | <img src="https://img.shields.io/github/stars/godot-mobile-plugins/godot-notification-scheduler?style=plastic&label=%20" /> |
| <img src="https://raw.githubusercontent.com/godot-mobile-plugins/godot-oauth2/main/addon/src/icon.png" width="20"> | [OAuth 2.0](https://github.com/godot-mobile-plugins/godot-oauth2) | ✅ | ✅ | <a href="https://github.com/godot-mobile-plugins/godot-oauth2/releases"><img src="https://img.shields.io/github/release-date/godot-mobile-plugins/godot-oauth2?label=%20" /> <img src="https://img.shields.io/github/v/release/godot-mobile-plugins/godot-oauth2?label=%20" /></a> | <img src="https://img.shields.io/github/downloads/godot-mobile-plugins/godot-oauth2/latest/total?label=latest" /> <img src="https://img.shields.io/github/downloads/godot-mobile-plugins/godot-oauth2/total?label=total" /> | <img src="https://img.shields.io/github/stars/godot-mobile-plugins/godot-oauth2?style=plastic&label=%20" /> |
| <img src="https://raw.githubusercontent.com/godot-mobile-plugins/godot-qr/main/addon/src/icon.png" width="20"> | [QR](https://github.com/godot-mobile-plugins/godot-qr) | ✅ | ✅ | <a href="https://github.com/godot-mobile-plugins/godot-qr/releases"><img src="https://img.shields.io/github/release-date/godot-mobile-plugins/godot-qr?label=%20" /> <img src="https://img.shields.io/github/v/release/godot-mobile-plugins/godot-qr?label=%20" /></a> | <img src="https://img.shields.io/github/downloads/godot-mobile-plugins/godot-qr/latest/total?label=latest" /> <img src="https://img.shields.io/github/downloads/godot-mobile-plugins/godot-qr/total?label=total" /> | <img src="https://img.shields.io/github/stars/godot-mobile-plugins/godot-qr?style=plastic&label=%20" /> |
| <img src="https://raw.githubusercontent.com/godot-mobile-plugins/godot-share/main/addon/src/icon.png" width="20"> | [Share](https://github.com/godot-mobile-plugins/godot-share) | ✅ | ✅ | <a href="https://github.com/godot-mobile-plugins/godot-share/releases"><img src="https://img.shields.io/github/release-date/godot-mobile-plugins/godot-share?label=%20" /> <img src="https://img.shields.io/github/v/release/godot-mobile-plugins/godot-share?label=%20" /></a> | <img src="https://img.shields.io/github/downloads/godot-mobile-plugins/godot-share/latest/total?label=latest" /> <img src="https://img.shields.io/github/downloads/godot-mobile-plugins/godot-share/total?label=total" /> | <img src="https://img.shields.io/github/stars/godot-mobile-plugins/godot-share?style=plastic&label=%20" /> |

<br>

<a name="credits"></a>

# <img src="https://raw.githubusercontent.com/godot-mobile-plugins/godot-notification-scheduler/main/addon/src/icon.png" width="24"> Credits

Developed by [Cengiz](https://github.com/cengiz-pz)

Based on [Godot Mobile Plugin Template v5](https://github.com/godot-mobile-plugins/godot-plugin-template/tree/v5)

Original repository: [Godot Notification Scheduler](https://github.com/godot-mobile-plugins/godot-notification-scheduler)

<br>

<a name="contributing"></a>

# <img src="https://raw.githubusercontent.com/godot-mobile-plugins/godot-notification-scheduler/main/addon/src/icon.png" width="24"> Contributing

See [our guide](https://github.com/godot-mobile-plugins/godot-notification-scheduler?tab=contributing-ov-file) if you would like to contribute to this project.

<br>

# 💖 Support the Project

If this plugin has helped you, consider supporting its development! Every bit of support helps keep the plugin updated and bug-free.

| ✦ | Ways to Help | How to do it |
| :--- | :--- | :--- |
|✨⭐| **Spread the Word** | [Star this repo](https://github.com/godot-mobile-plugins/godot-notification-scheduler/stargazers) to help others find it. |
|💡✨| **Give Feedback** | [Open an issue](https://github.com/godot-mobile-plugins/godot-notification-scheduler/issues) or [suggest a feature](https://github.com/godot-mobile-plugins/godot-notification-scheduler/issues/new). |
|🧩| **Contribute** | [Submit a PR](https://github.com/godot-mobile-plugins/godot-notification-scheduler?tab=contributing-ov-file) to help improve the codebase. |
|❤️| **Buy a Coffee** | Support the maintainers on GitHub Sponsors or other platforms. |

<br>

## ⭐ Star History
[![Star History Chart](https://api.star-history.com/svg?repos=godot-mobile-plugins/godot-notification-scheduler&type=Date)](https://star-history.com/#godot-mobile-plugins/godot-notification-scheduler&Date)
