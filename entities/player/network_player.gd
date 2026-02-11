extends Player
class_name NetworkPlayer

func configure(new_player_id: int, is_local: bool) -> void:
	set_player_id(new_player_id)
	set_network_input_enabled(not is_local)
	if not is_local:
		set_remote_mode(true)
