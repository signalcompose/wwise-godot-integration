#pragma once

#include "core/utils.h"
#include "core/wwise_gdextension.h"
#include "scene/ak_environment.h"
#include <godot_cpp/classes/node.hpp>
#include <godot_cpp/core/object_id.hpp>
#include <godot_cpp/templates/vector.hpp>
#include <godot_cpp/variant/array.hpp>

using namespace godot;

class AkEnvironment;

struct AkAuxArrayData
{
	Array data{};
	void set_values(Node* event_node);

	AkAuxArrayData() { data.clear(); }
};

class AkEnvironmentData : public Object
{
	GDCLASS(AkEnvironmentData, Object);

protected:
	static void _bind_methods();

private:
	// Environments are tracked by ObjectID rather than by Object* (or a Variant boxing
	// one): an AkEnvironment can be freed without remove_environment() running first
	// (e.g. area_exited never fires on abrupt teardown), and resolving a stale raw
	// pointer is unsafe. ObjectDB::get_instance() is the only way to check "is this
	// still alive" without touching freed memory.
	Vector<ObjectID> active_environment_ids{};
	AkAuxArrayData aux_array_data{};
	Vector3 last_position{};
	bool have_environments_changed{};

	static bool compare_by_priority(const AkEnvironment* a, const AkEnvironment* b);
	void purge_freed_environments();

public:
	void add_environment(const AkEnvironment* env);
	void remove_environment(const AkEnvironment* env);
	void add_highest_priority_environments();
	void update_aux_send(Node* event, const Vector3& position);
};
