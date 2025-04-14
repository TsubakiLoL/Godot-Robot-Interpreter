#----------------------
#版权所有：
#	李志鹏
#	新疆大学 计算机科学与技术学院 
#	计算机科学与技术 21-3班
#	毕业设计
#	学号：20211401239
#----------------------



class_name Serializater


static func stringfy_state_root(s:NodeRoot)->String:
	var res:Array=[]
	var node_dic={}
	for i in s.node_list:
		var data={}
		i.export_data(data)
		node_dic[i.id]=data
	res.append(node_dic)
	var root_dic={}
	s.export_data(root_dic)
	print(node_dic)
	res.append(root_dic)

	return JSON.stringify(res)
	
static func parse_string(str:String):
	var new_root:NodeRoot=NodeRoot.new()
	var arr=JSON.parse_string(str)
	
	if arr==null:
		#print("解析失败，不可识别的文本")
		return null
	if (not arr is Array) or (not arr.size()==2):
		return null
			#print("数组长度检测通过！")
	var node_dic:Dictionary=arr[0]
			#print("节点字典构建成功！")
	var root_dic:Dictionary=arr[1]
			#print("根节点字典构建成功！")
	if (not node_dic is Dictionary) or (not root_dic is Dictionary):
		return null
	for i in node_dic.keys():
		var data=node_dic[i]
		if (not data is Dictionary) or (not data.has("mod_from")) or(not data.has("mod_node")):
			return null
		var type=int(data["type"])
		var mod_from:String=str(data["mod_from"])
		var mod_node:String=str(data["mod_node"])
		var node_class=ModLoader.get_node_class(mod_from,mod_node)
		if node_class==null:
			return null
		#print("识别到节点类型：",ChatNodeGraph.node_name[type]," ID:",i)
		var new_chat_node=node_class.new(new_root) as ChatNode
		#print("	实例化成功！")
		new_chat_node.mod_from=mod_from
		new_chat_node.mod_node=mod_node
		new_chat_node.id=i
		new_chat_node.load_from_data(data)
		#print("	加载节点成员变量成功！")
		new_root.node_list.append(new_chat_node)
		#print("	成功添加到节点树！")


	for i in node_dic.keys():
		var from_node:ChatNode=new_root.find_node_by_id(i)	
		var data=node_dic[i]
		if not data.has("next_node_array"):
			#print("未找到链接信息")
			return null
		var connections=data["next_node_array"]	
		if not connections is Array:
			#print("解析链接时发生错误")
			return null
		for j in connections:
			if not (j is Array and j.size()==3):
				#print("解析链接时发生错误")
				return null
			var to_node=new_root.find_node_by_id(j[0])
			if to_node==null:
				#print("错误，未找到节点")
				return null
			from_node.connect_with_next_node(to_node,j[1],j[2])
	if not root_dic.has("init_state"):
		#print("解析根节点时遇到错误")
		return null
	if root_dic["init_state"]!=null:
					
		var init_state=new_root.find_node_by_id(root_dic["init_state"])
		if init_state==null:
			#print("解析进入状态时遇到错误")
			pass
		new_root.set_init_state(init_state)
	else:
		#print("存入了空的状态")
		pass
	new_root.reload_id()
	return new_root
