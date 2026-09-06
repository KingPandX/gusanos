extends Resource
class_name TourStep

enum StepType { TEXT, ACTION }
enum ButtonAction { NONE, ADVANCE, SKIP }
enum PopupPosition { ABOVE, BELOW, LEFT, RIGHT, CENTER }
enum ActionType {
	NONE,
	COLLECT_WORM_DROP,
	DRAG_WORM_TO_COMBAT,
	DRAG_WORM_TO_SOCIAL,
	CLICK_NODE,
	CUSTOM_SIGNAL
}

@export var step_type: StepType = StepType.TEXT

@export_group("Identification")
@export var signal_string: String = ""

@export_group("Visual")
@export_multiline() var message: String = ""
@export var target_node_path: NodePath = NodePath("")
@export var target_node_paths: Array[NodePath] = []
@export var highlight_padding: Vector2 = Vector2(8, 8)
@export var follow_target: bool = false
@export var avoid_overlap: bool = true
@export var popup_position: PopupPosition = PopupPosition.BELOW

@export_group("Text Step Buttons")
@export var button_1_text: String = "Siguiente"
@export var button_1_action: ButtonAction = ButtonAction.ADVANCE
@export var button_2_text: String = ""
@export var button_2_action: ButtonAction = ButtonAction.NONE

@export_group("Action Step")
@export var action_type: ActionType = ActionType.NONE
@export var action_target_node: NodePath = NodePath("")
@export var action_signal_name: String = ""
@export var action_message_waiting: String = "Esperando..."
@export var action_count: int = 1
@export var dynamic_target_group: String = ""
