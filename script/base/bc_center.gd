extends Node

class Message extends RefCounted:## 消息类
	var title : String = ""
	var value : Array = []
	var priority : int = 2
	
	func _init(ttl : String, vl : Variant, prt : int = 2) -> void:
		title = ttl
		value = vl if vl is Array else [vl]
		priority = prt

class Subscription extends RefCounted:## 订阅类
	var title : String = ""
	var receiver : Object = null
	var method : Callable
	var disposable : bool = false
	
	func _init(ttl : String, rcv : Object, mthd : Callable, dsp : bool = false) -> void:
		
		title = ttl
		receiver = rcv
		method = mthd
		disposable = dsp

enum EVENT_MODE{
	PROCESS,
	PHYSICS
}

var message_mode : EVENT_MODE = EVENT_MODE.PROCESS

var list : Array[Message] = []
var list_lock : Mutex = Mutex.new()
var list_size_max : int = 1000
var subs : Dictionary = {}
var subs_lock : Mutex = Mutex.new()

func _physics_process(_delta: float) -> void:
	if message_mode == EVENT_MODE.PHYSICS:
		process_message()
		

func _process(_delta: float) -> void:
	if message_mode == EVENT_MODE.PROCESS:
		process_message()

func process_message() -> void:
	if list.is_empty() || subs.is_empty(): return
	list_lock.lock()
	subs_lock.lock()
	unsub_null()
	var processing_list : Array[Message] = list.duplicate()
	var local_subs : Dictionary = subs.duplicate(true)
	list.clear()
	list_lock.unlock()
	subs_lock.unlock()
	for _message in processing_list:
		if local_subs.has(_message.title):
			var tmp_idx : int = 0
			while tmp_idx < local_subs[_message.title].size():
				var sub : Subscription = local_subs[_message.title][tmp_idx]
				if is_instance_valid(sub.receiver) && sub.method.is_valid():
					sub.method.call(_message.value)
					if sub.disposable:
						sub = null
						local_subs[_message.title].remove_at(tmp_idx)
						tmp_idx -= 1
				elif !is_instance_valid(sub.receiver):
					push_warning("错误，订阅者%s失效，本次广播已丢弃。" %str(sub.receiver))
				elif !sub.method.is_valid():
					push_warning("错误，方法%s失效，本次广播已丢弃。" %str(sub.method))
				tmp_idx += 1

func subscribe(_title : String, _recevier : Object, _method : Callable, _disposable : bool = false) -> void:
	if !is_instance_valid(_recevier):
		push_warning("错误，订阅者%s已失效，取消订阅。" %str(_recevier))
		return
	
	subs_lock.lock()
	var tmp_subscription : Subscription = Subscription.new(_title, _recevier, _method, _disposable)
	
	if !subs.has(_title):
		subs[_title] = []
	
	subs[_title].append(tmp_subscription)
	subs_lock.unlock()

func subs_clear() -> void:
	if !subs.is_empty():
		subs.clear()
	push_warning("已清空所有订阅信息。")
	return

func is_empty() -> bool:
	if subs.is_empty() :
		push_warning("错误，订阅信息集为空。")
		return true
	return false
	

func unsub_by_title(_title) -> void:
	if is_empty(): return
	subs_lock.lock()
	if subs.erase(_title):
		push_warning("已清空订阅了标题为%s的消息的订阅信息" %_title)
	else:
		push_warning("错误，不存在订阅了标题为%s的消息的订阅信息，本次操作无效。" %_title)
	subs_lock.unlock()
	return

func unsub_by_recevier(_recevier : Object) -> void:
	var judge : Callable = func(sub : Subscription) -> bool:
		if sub.receiver == _recevier:
			return true
		return false
	unsub_traverse(judge)
	return

func unsub_by_method(_method : Callable) -> void:
	var judge : Callable = func(sub : Subscription) -> bool:
		if sub.method == _method:
			return true
		return false
	unsub_traverse(judge)
	return

func unsub_null() -> void:
	var judge : Callable = func(sub : Subscription) -> bool:
		if !is_instance_valid(sub.receiver) || !sub.method.is_valid():
			return true
		return false
	unsub_traverse(judge)
	return

func unsub_traverse(call_judge : Callable) -> bool:
	if is_empty():
		push_warning("订阅信息集为空。")
		return false
	subs_lock.lock()
	
	var found : bool = false
	
	for _title in subs:
		var tmp_idx : int = subs[_title].size() - 1
		while tmp_idx >= 0:
			var tmp_sub : Subscription = subs[_title][tmp_idx]
			if !is_instance_valid(tmp_sub.receiver):
				subs[_title].remove_at(tmp_idx)
				tmp_sub.receiver = null
				continue
			if call_judge.call(tmp_sub):
				subs[_title].remove_at(tmp_idx)
				found = true
			tmp_idx -= 1
	for _title in subs.keys():
		if subs[_title].is_empty():
			subs.erase(_title)
	subs_lock.unlock()
	
	return found

func publish(_title : String, _value : Variant, _priority : int = 2) -> void:
	if list.size() > list_size_max:
		push_warning("待广播信息数量超出最大值，该信息已丢弃")
		return
	list_lock.lock()
	var tmp_message : Message = Message.new(_title, _value, _priority)
	var low : int = 0
	var high : int = list.size() - 1
	while low <= high:
		var mid : int = floor((low + high) / 2.)
		if list[mid].priority <= _priority:
			low = mid + 1
		else:
			high = mid - 1
	list.insert(low, tmp_message)
	list_lock.unlock()
	return
		
