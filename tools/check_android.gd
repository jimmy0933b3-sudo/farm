@tool
extends SceneTree
func _initialize() -> void:
	var s = EditorInterface.get_editor_settings()
	print("DIAG sdk="+str(s.get_setting("export/android/android_sdk_path")))
	print("DIAG java="+str(s.get_setting("export/android/java_sdk_path")))
	print("DIAG real sdk="+OS.get_environment("ANDROID_HOME"))
	print("DIAG real java="+OS.get_environment("JAVA_HOME"))
	quit(0)
