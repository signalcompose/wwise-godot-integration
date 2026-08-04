#pragma once

#include "core/wwise_object_type.h"
#include <godot_cpp/classes/display_server.hpp>
#include <godot_cpp/classes/object.hpp>
#include <godot_cpp/classes/resource_loader.hpp>
#include <godot_cpp/classes/texture2d.hpp>

using namespace godot;

class AkEditorUtils : public Object
{
	GDCLASS(AkEditorUtils, Object);

protected:
	static void _bind_methods() {};

private:
	static Ref<Texture2D> icon_cache[2][(int)WwiseObjectType::Max];

public:
	static Ref<Texture2D> get_editor_icon(const WwiseObjectType p_type);
	static String get_icon_name(const WwiseObjectType p_type);
	static String get_theme_folder(bool dark_mode);

	// Must be called from unregister_wwise_types() while the engine is still alive. icon_cache holds
	// Ref<Texture2D>, and releasing it via the implicit static destructor at process exit calls back
	// into an already-shut-down engine, causing a crash.
	static void clear_icon_cache();
};