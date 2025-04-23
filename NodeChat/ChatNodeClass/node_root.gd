extends Object
##NodeChat的根节点，用于管理节点交互及对整个节点图进行操作
class_name NodeRoot
##当前根节点拥有的节点列表
var node_list:Array[ChatNode]
##用户实例的字典
var user_instance_array:Dictionary={} #UID:[now_state,time_last_move,data_dic:Dictionary{}]      
##用户数据字典
var user_data_dic:Dictionary={}
##默认状态的进入状态引用
var init_state
##当用户长时间没进行交互时，删除用户实例需要经过的时间（s）
var time_to_delete_instance:float=30
##每次遍历字典判定过期的间隔时间，用于节省性能
var judge_time:float=2
##节点命名计数器
var ind=0
##是否启动
var is_start:bool=false
##data存储路径
var data_path:String
##添加节点
func add_node(n:ChatNode):
	n.id=str(ind)
	ind+=1
	node_list.append(n)
##通过id查找节点
func find_node_by_id(id:String):
	for i in node_list:
		if i.id==id:
			return i
##从文件中读取数据
func read_data_from_file():
	if data_path!=null:
		var f=FileAccess.open(data_path,FileAccess.READ)
		if f!=null:
			var str=f.get_as_text()
			var data=JSON.parse_string(str)
			if data!=null and data is Dictionary:
				user_data_dic=data
##新建新的用户实例
func add_user_instance(id:String):
	if not user_instance_array.has(id):
		if init_state!=null:
			var new_user_instance_data=[init_state,Time.get_ticks_msec()]
			user_instance_array[id]=new_user_instance_data
		else:
			print("进入节点为空！")
##删除用户实例
func delete_user_instance(id:String):
	user_instance_array.erase(id)
##改变状态到指定的状态，如果当前用户实例不存在，则新建实例
func change_state(id:String,state)->void:
	if not user_instance_array.has(id):
		add_user_instance(id)
	if not user_data_dic.has(id):
		user_data_dic[id]={}
	user_instance_array[id][0]=state
	user_instance_array[id][1]=Time.get_ticks_msec()
	pass
##获取字典内对应的data数据，如果数据不存在则创建新的数据，并返回0
func get_data(id:String,data_name:String)->float:
	if not user_data_dic.has(id):
		user_data_dic[id]={}
		user_data_dic[id][data_name]=float(0)
		return 0
	elif not user_data_dic[id].has(data_name):
		user_data_dic[id][data_name]=float(0)
		return 0
	else:
		var data=user_data_dic[id][data_name]
		if data is float:
			return data
		else:
			user_data_dic[id][data_name]=float(0)
			return 0
##从数据中获取String类型的变量，用户ID和数据名称
func get_string(id:String,data_name:String)->Array:
	var res=[false,""]
	if not user_data_dic.has(id):
		user_data_dic[id]={}
	elif  user_data_dic[id].has(data_name):
		var data=user_data_dic[id][data_name]
		if data is Array and data.size()>0:
			var ind=randi()%data.size()
			res[0]=true
			res[1]=data[ind]
	return res
##向数据中添加String类型的持久型数据，用户ID和数据名称和设置的值
func add_string(id:String,data_name:String,value:String):
	if not user_data_dic.has(id):
		user_data_dic[id]={}
	if not user_data_dic[id].has(data_name):
		user_data_dic[id][data_name]=[value]
	else:
		var data=user_data_dic[id][data_name]
		if not data is Array:
			data=[value]
		else:
			data.append(value)
		user_data_dic[id][data_name]=data
##清除持久性数据的String类型变量，用户ID和数据名称
func clear_string(id:String,data_name:String):
	if not user_data_dic.has(id):
		user_data_dic[id]={}
	user_data_dic[id][data_name]=[]
##设置字典内对应用户的data数据，如果数据不存在则创建新的用户数据
func set_data(id:String,data_name:String,new_value:float)->void:
	if not user_data_dic.has(id):
		user_data_dic[id]={}
		user_data_dic[id][data_name]=new_value
	else:
		user_data_dic[id][data_name]=new_value
##设置进入状态
func set_init_state(state):
	if init_state!=null:
		init_state.is_init=false
	init_state=state
	

	
##判定字典时间，擦除已经过期的用户状态实例（建议定期执行）
func judge()->void:
	for i in user_instance_array.keys():
		var data=user_instance_array[i]
		var now_time=Time.get_ticks_msec()
		var before_time=data[1]
		if before_time is int and now_time-before_time>=time_to_delete_instance*1000:
			delete_user_instance(i)
			pass
	if data_path!=null:
		var f=FileAccess.open(data_path,FileAccess.WRITE)
		if f !=null:
			var str:String=JSON.stringify(user_data_dic)
			f.store_string(str)
			f.close()
##向字典中写入自身数据
func export_data(data:Dictionary):
	data["time_to_delete_instance"]=time_to_delete_instance
	data["judge_time"]=judge_time
	if init_state!=null:
		data["init_state"]=init_state.id
	else:
		data["init_state"]=null
##从字典中读取数据
func load_from_data(data:Dictionary):
	if data.has("time_to_delete_instance") and data.has("judge_time"):
		time_to_delete_instance=data["time_to_delete_instance"]
		judge_time=data["judge_time"]
##删除自身
func delete():
	if PromptMessageControler.is_linked(prompt_message):
		PromptMessageControler.dislink(prompt_message)
	for i in node_list:
		i.delete()
	call_deferred("free")
###收到消息
#func prompt_message(id:String,triger_type:ChatNodeTriger.triger_type,mes:Dictionary):
	#sent_data_to_out([triger_type,mes],0,id)
	#VLR(id)
var prompt_list:Array=[]
#当前是否在debug中
var is_in_debug:bool=false
		
##收到消息
func prompt_message(id:String,triger_type:String,mes:Dictionary):
	if not id in user_instance_array:
		add_user_instance(id)
	var now_state=user_instance_array[id][0]
	if is_in_debug:
		debug_cache.append({
		"id":id,
		"triger_type":triger_type,
		"mes":mes,
		"frame":[]
		})
		await VLR_debug(id,now_state,[[triger_type,mes]])
		debug_cache_update.emit()
	else:
		await VLR(id,now_state,[[triger_type,mes]])
	
signal debug_cache_update

var debug_cache:Array=[]
var message_list:Array=[]


##循环代替递归调用
func VLR(id:String,from_node:ChatNode,from_data:Array):
	var stack:Array[ChatNode]=[]
	var stack_index:Array[int]
	var stack_data:Array=[]
	stack.append(from_node)
	stack_index.append(0)
	stack_data.append(from_data)
	
	#输入数据缓存
	var input_data_dic:Dictionary={}
	#就绪数据缓存
	var input_ready_dic:Dictionary={}
	#输出数据缓存
	var output_data_dic:Dictionary={}
	#初始化缓存
	for i in node_list:
		i.init_input_dic(input_data_dic,input_ready_dic)
		i.init_output_dic(output_data_dic)
	output_data_dic[from_node]=from_data
	while stack.size()!=0:
		while stack_index.back()<stack.back().next_node_array.size():
			var now_next=stack.back().next_node_array[stack_index.back()]
			var now_node:ChatNode=now_next[0]
			var parent_node:ChatNode=stack.back()
			var parent_index:int=stack_index.back()
			var parent_data=stack_data.back()
			var is_out_r=await now_node.act(id,
				parent_data[parent_node.next_node_array[parent_index][1]],
				parent_node.next_node_array[parent_index][2],
				input_data_dic,input_ready_dic,
				output_data_dic
				)
			stack_index[stack_index.size()-1]+=1
			if now_node.next_node_array.size()!=0 and is_out_r:
				stack.append(now_next[0])
				stack_index.append(0)
				stack_data.append(output_data_dic[now_node])
		stack.pop_back()
		stack_index.pop_back()
		stack_data.pop_back()
func VLR_debug(id:String,from_node:ChatNode,from_data:Array):
	
	var stack:Array[ChatNode]=[]
	var stack_index:Array[int]
	var stack_data:Array=[]
	stack.append(from_node)
	stack_index.append(0)
	stack_data.append(from_data)
	var frame_data:Dictionary={
		"id":from_node.id,
		"type":from_node.mod_node,
		"input_data_type":[],
		"input_data_arr":[],
		"output_data_type":from_node.output_port_array.duplicate(),
		"output_data_arr":from_data.duplicate()
	}
	
	debug_cache[debug_cache.size()-1]["frame"].append(frame_data)
	#输入数据缓存
	var input_data_dic:Dictionary={}
	#就绪数据缓存
	var input_ready_dic:Dictionary={}
	#输出数据缓存
	var output_data_dic:Dictionary={}
	#初始化缓存
	for i in node_list:
		i.init_input_dic(input_data_dic,input_ready_dic)
		i.init_output_dic(output_data_dic)
	while stack.size()!=0:
		while stack_index.back()<stack.back().next_node_array.size():
			var now_next=stack.back().next_node_array[stack_index.back()]
			var now_node:ChatNode=now_next[0]
			var parent_node:ChatNode=stack.back()
			var parent_index:int=stack_index.back()
			var parent_data=stack_data.back()
			var is_out_r=await now_node.act(id,
				parent_data[parent_node.next_node_array[parent_index][1]],
				parent_node.next_node_array[parent_index][2],
				input_data_dic,input_ready_dic,
				output_data_dic
				)
			stack_index[stack_index.size()-1]+=1
			print("执行结果"+str(is_out_r))
			if now_node.next_node_array.size()!=0 and is_out_r:
				stack.append(now_next[0])
				stack_index.append(0)
				stack_data.append(output_data_dic[now_node])
				var frame_data_n:Dictionary={
					"id":now_node.id,
					"type":now_node.mod_node,
					"input_data_type":now_node.input_port_array.duplicate(),
					"input_data_arr":input_data_dic[now_node].duplicate(),
					"output_data_type":now_node.output_port_array.duplicate(),
					"output_data_arr":output_data_dic[now_node].duplicate()
				}
				debug_cache[debug_cache.size()-1]["frame"].append(frame_data_n)
		stack.pop_back()
		stack_index.pop_back()
		stack_data.pop_back()






##启动此根节点
func start():
	PromptMessageControler.link(prompt_message)
	read_data_from_file()
	is_start=true
##结束此根节点
func end():
	if is_start:
		if PromptMessageControler.is_linked(prompt_message):
			PromptMessageControler.dislink(prompt_message)
		is_start=false
##重载此根节点ID队列，将命名计数器自动转换为当前节点队列的上限+1
func reload_id():
	for i in node_list:
		if i.id.is_valid_int():
			var nid=i.id.to_int()
			if nid>ind:
				ind=nid
	ind+=1
			
