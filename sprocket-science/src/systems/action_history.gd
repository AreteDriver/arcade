class_name ActionHistory
extends RefCounted

## Undo/redo stack using the Command pattern.
## Each action stores enough data to undo and redo itself.

var _undo_stack: Array[Dictionary] = []
var _redo_stack: Array[Dictionary] = []
const MAX_HISTORY: int = 50


## Record an action. Clears redo stack.
func record(action: Dictionary) -> void:
	_undo_stack.append(action)
	_redo_stack.clear()
	if _undo_stack.size() > MAX_HISTORY:
		_undo_stack.pop_front()


## Whether undo is available
func can_undo() -> bool:
	return _undo_stack.size() > 0


## Whether redo is available
func can_redo() -> bool:
	return _redo_stack.size() > 0


## Pop the last action for undoing. Returns empty dict if nothing to undo.
func pop_undo() -> Dictionary:
	if _undo_stack.is_empty():
		return {}
	var action: Dictionary = _undo_stack.pop_back()
	_redo_stack.append(action)
	return action


## Pop the last undone action for redoing. Returns empty dict if nothing to redo.
func pop_redo() -> Dictionary:
	if _redo_stack.is_empty():
		return {}
	var action: Dictionary = _redo_stack.pop_back()
	_undo_stack.append(action)
	return action


## Clear all history
func clear() -> void:
	_undo_stack.clear()
	_redo_stack.clear()
