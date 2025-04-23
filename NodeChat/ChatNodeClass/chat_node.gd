
#----------------------
#版权所有：
#	李志鹏
#	新疆大学 计算机科学与技术学院 
#	计算机科学与技术 21-3班
#	毕业设计
#	学号：20211401239
#----------------------


extends Object
##基础用于可视化编辑的行为节点
class_name ChatNode
enum variable_type{
	TYPE_STRING=0,
	TYPE_SELECT=1,
	TYPE_BOOL=2,
	TYPE_COLOR=3
}
##用于记录节点位置的变量
var position_x:float=0
var position_y:float=0
##节点的ID，用于标识不同节点之间的链接
var id:String="0"
##节点的类型
var type:int=0

##来自的mod组件
var mod_from:String
##来自组件的mod类名
var mod_node:String


##输入节点类型数组
var input_port_array:Array[String]=[]
##输入端口的名字（用于可视化编辑）
var input_port_name:Array[String]=[]
##输出节点类型数组
var output_port_array:Array[String]=[]
##输出端口的名字（用于可视化编辑）
var output_port_name:Array[String]=[]

##需要从外部输入的变量
var variable_name_array:Array[String]=[]
##标注外部输入变量的类型
var variable_type_array:Array[variable_type]=[]
##外部输入变量补充
var variable_type_more:Array=[]
##外部输入变量的显示标识
var variable_name_view:Array[String]=[]

##触发器名字
static var triger_type_name:Dictionary={
	0:"弹幕消息",
	1:"房间消息",
	2:"私聊消息",
	3:"进入状态消息",
	4:"退出状态消息"
}


##链接的下级节点
var next_node_array:Array[Array]=[]
##链接的上级节点
var from_node_array:Array[Array]=[]
##状态机根节点引用
var root:NodeRoot
func _init(root:NodeRoot) -> void:
	self.root=root

#初始化输入堆
func init_input_dic(input_data_dic:Dictionary,input_ready_dic:Dictionary):
	input_data_dic[self]=[]
	input_ready_dic[self]=[]
	for i in input_port_array:
		input_data_dic[self].append(false)
		input_ready_dic[self].append(false)
	
func init_ready_dic(input_ready_dic:Dictionary):
	input_ready_dic[self]=[]
	for i in input_port_array:
		input_ready_dic[self].append(false)
#初始化输出堆
func init_output_dic(dic:Dictionary):
	dic[self]=[]
	for i in output_port_array:
		dic[self].append(false)

#当前输入标记堆是否就绪
func is_input_dic_ready(ready_dic:Dictionary):
	if not ready_dic.has(self):
		return false
	var arr=ready_dic[self]
	var res:bool=true
	for i in arr:
		res=res and i
	return res



func process_input(id:String,input_port_data:Array,output_port_data:Array):
	
	
	pass
#执行输入，返回输出是否就绪,就绪结果输出写入output dic
func act(id:String,input,to_port:int,input_dic:Dictionary,input_ready_dic:Dictionary,output_dic:Dictionary):
	if to_port<input_port_array.size():
		input_dic[self][to_port]=input
		input_ready_dic[self][to_port]=true
		#如果输入准备好
		if is_input_dic_ready(input_ready_dic):
			var res:bool=await process_input(id,input_dic[self],output_dic[self])
			init_ready_dic(input_ready_dic)
			return res
	return false




##从data字典中加载数据
func load_from_data(data:Dictionary):
	if data.has("position_x") and data.has("position_y"):
		var new_position_x=data["position_x"] 
		var new_position_y=data["position_y"]
		if new_position_x is float and new_position_y is float:
			position_x=new_position_x
			position_y=new_position_y
	pass
##将自己的数据输出到data字典
func export_data(data:Dictionary):
	data["type"]=type
	data["mod_from"]=mod_from
	data["mod_node"]=mod_node
	data["position_x"]=position_x
	data["position_y"]=position_y
	var next_array:Array=[]
	for i in next_node_array:
		var new_array=[i[0].id,i[1],i[2]]
		next_array.append(new_array)
	data["next_node_array"]=next_array
	var from_array:Array=[]
	for i in from_node_array:
		var new_array=[i[0].id,i[1],i[2]]
		from_array.append(new_array)
	data["from_node_array"]=from_array
##链接到下级节点	
func connect_with_next_node(to_node:ChatNode,from_port:int,to_port:int)->bool:
	if from_port<output_port_array.size() and to_port<to_node.input_port_array.size():
		if output_port_array[from_port]==to_node.input_port_array[to_port]:
			for i in next_node_array:
				if i[0]==to_node and i[1]==from_port and i[2]==to_port:
					#print("已经存在链接")
					return false
			var new_connect_message=[to_node,from_port,to_port]
			next_node_array.append(new_connect_message)
			to_node.connect_with_from_node(self,from_port,to_port)
			return true
		else:
			#print("类型不兼容")
			#print("当前节点类型：",ChatNodeGraph.node_name[type],"输出类型:",output_port_array[from_port])
			#print("下级节点类型： ",ChatNodeGraph.node_name[to_node.type]," 输入类型：",to_node.input_port_array[to_port])
			return false
	else:
		#print("超出端口数量")
		return false
		
	pass
##被链接到上级节点（由上级节点调用）
func connect_with_from_node(from_node:ChatNode,from_port:int,to_port:int):
	from_node_array.append([from_node,from_port,to_port])
	pass
##与下级节点断开链接
func disconnect_with_next_node(to_node:ChatNode,from_port:int,to_port:int)->bool:
	if from_port<output_port_array.size() and to_port<to_node.input_port_array.size():
		var ind:int=-1
		for i in range(next_node_array.size()):
			if next_node_array[i][0]==to_node and next_node_array[i][1]==from_port and next_node_array[i][2]==to_port:
				ind=i
		if ind!=-1:
			#print("断开成功")
			to_node.disconnect_with_from_node(self,from_port,to_port)
			next_node_array.pop_at(ind)
			return true
			pass
		else:
			#print("不存在链接")
			to_node.disconnect_with_from_node(self,from_port,to_port)
			return false
	else:
		#print("不在端口范围内")
		return false
##与上级节点断开链接		
func disconnect_with_from_node(from_node:ChatNode,from_port:int,to_port:int)->bool:
	if from_port<from_node.output_port_array.size() and to_port<input_port_array.size():
		var ind:int=-1
		for i in range(from_node_array.size()):
			if from_node_array[i][0]==from_node and from_node_array[i][1]==from_port and from_node_array[i][2]==to_port:
				ind=i
		if ind!=-1:
			from_node_array.pop_at(ind)
			return true
		else:
			return false
	else:
		return false
##删除自己，并解除链接
func delete():
	while from_node_array.size()!=0:
		var from_real:ChatNode=from_node_array[0][0]
		from_real.disconnect_with_next_node(self,from_node_array[0][1],from_node_array[0][2])
	while next_node_array.size()!=0:
		var to_real:ChatNode=next_node_array[0][0]
		disconnect_with_next_node(to_real,next_node_array[0][1],next_node_array[0][2])
	call_deferred("free")
