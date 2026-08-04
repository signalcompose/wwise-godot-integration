#include "ak_environment_data.h"

void AkAuxArrayData::set_values(Node* event_node)
{
	Wwise::get_singleton()->set_game_object_aux_send_values(event_node, data, data.size());
}

void AkEnvironmentData::_bind_methods() {}

bool AkEnvironmentData::compare_by_priority(const AkEnvironment* a, const AkEnvironment* b)
{
	return a->get_priority() < b->get_priority();
}

void AkEnvironmentData::purge_freed_environments()
{
	for (int i = active_environment_ids.size() - 1; i >= 0; i--)
	{
		if (!Object::cast_to<AkEnvironment>(ObjectDB::get_instance(active_environment_ids[i])))
		{
			active_environment_ids.remove_at(i);
			have_environments_changed = true;
		}
	}
}

void AkEnvironmentData::add_environment(const AkEnvironment* env)
{
	if (!env)
	{
		return;
	}

	// Freed entries must be purged before searching: the binary search below assumes
	// every element resolves to a live AkEnvironment*, otherwise the priority ordering
	// it relies on is no longer monotonic and can insert at the wrong position.
	purge_freed_environments();

	// Manual lower_bound insert, matching the previous Array::bsearch_custom(value, func)
	// semantics (func returns true if the existing element belongs before value).
	int lo = 0;
	int hi = active_environment_ids.size();
	while (lo < hi)
	{
		int mid = (lo + hi) / 2;
		const AkEnvironment* mid_env =
				Object::cast_to<AkEnvironment>(ObjectDB::get_instance(active_environment_ids[mid]));

		if (compare_by_priority(mid_env, env))
		{
			lo = mid + 1;
		}
		else
		{
			hi = mid;
		}
	}

	active_environment_ids.insert(lo, ObjectID(env->get_instance_id()));
	have_environments_changed = true;
}

void AkEnvironmentData::remove_environment(const AkEnvironment* env)
{
	if (!env)
	{
		return;
	}

	ObjectID id(env->get_instance_id());
	for (int i = 0; i < active_environment_ids.size(); i++)
	{
		if (active_environment_ids[i] == id)
		{
			active_environment_ids.remove_at(i);
			have_environments_changed = true;
			break;
		}
	}
}

void AkEnvironmentData::add_highest_priority_environments()
{
	purge_freed_environments();

	if (aux_array_data.data.size() < active_environment_ids.size())
	{
		const AkEnvironment* env = Object::cast_to<AkEnvironment>(ObjectDB::get_instance(active_environment_ids[0]));

		if (env)
		{
			Ref<WwiseAuxBus> aux_bus = env->get_aux_bus();
			if (aux_bus.is_valid())
			{
				bool exists = false;
				for (int j = 0; j < aux_array_data.data.size(); j++)
				{
					Dictionary current_aux_data = aux_array_data.data[j];
					if (current_aux_data.has("aux_bus_id") &&
							(uint32_t)current_aux_data["aux_bus_id"] == aux_bus->get_id())
					{
						exists = true;
						break;
					}
				}

				if (!exists)
				{
					Dictionary aux_data;
					aux_data["control_value"] = 1.0f;
					aux_data["aux_bus_id"] = aux_bus->get_id();
					aux_array_data.data.append(aux_data);
				}
			}
		}
	}
}

void AkEnvironmentData::update_aux_send(Node* event, const Vector3& position)
{
	if (!have_environments_changed && position == last_position)
	{
		return;
	}

	aux_array_data.data.clear();
	add_highest_priority_environments();
	aux_array_data.set_values(event);
	last_position = position;
	have_environments_changed = false;
}
