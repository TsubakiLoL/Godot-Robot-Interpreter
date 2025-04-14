#----------------------
#版权所有：
#	李志鹏
#	新疆大学 计算机科学与技术学院 
#	计算机科学与技术 21-3班
#	毕业设计
#	学号：20211401239
#----------------------


extends Node

#mod加载数据
var mod_origin_db:Dictionary={}
#mod自动加载集
var mod_autoload_db:Dictionary={}
#mod节点类集
var mod_nodeclass_db:Dictionary={}


#mod加载的触发器类型
var mod_triger_type_name_db:Dictionary={
}

#mod加载的在主界面的面板的数据
var mod_panel_db:Dictionary={}

#加载mod的路径
var load_path:String="user://mod"



##当系统装载的插件更改时发出
signal mod_changed()


#从指定的路径加载模块数据
func load_mod_from_path(path:String):
	var file_name := ""
	var files := []
	var dir := DirAccess.open(path)
	if dir==null:
		return
	if dir:
		dir.list_dir_begin()
		file_name = dir.get_next()
		while file_name != "":
			if dir.current_is_dir():
				#获取当前的路径
				var sub_path:String = path + "/" + file_name
				var now_file:DirAccess=DirAccess.open(sub_path)
				var json_path:String=sub_path+"/"+"config.json"
				var dic=load_dictionary_from_json(json_path)
				if dic==null:
					file_name = dir.get_next()
					continue
				if not dic.has("name"):
					file_name = dir.get_next()
					continue
				#if not dic.has("depend"):
					#continue
				var mod_name:String=dic["name"]
				dic["mod_path"]=sub_path
				install_mod(mod_name,dic)
			file_name = dir.get_next()
		dir.list_dir_end()
#从json路径中读取字典
func load_dictionary_from_json(json_path:String):
	var f=FileAccess.open(json_path,FileAccess.READ)
	if f!=null:
		var str=f.get_as_text()
		var json_parse=JSON.parse_string(str)
		if json_parse is Dictionary:
			return json_parse
	return null

#获取autoload单例
func get_autoload(autoload_name:String):
	if mod_autoload_db.has(autoload_name):
		return mod_autoload_db[autoload_name]
	return  null
#使用指定的mod数据加载数据
func install_mod(mod_name:String,mod_data:Dictionary):
	var name_view:String=mod_name
	if mod_data.has("name_view"):
		name_view+=("("+mod_data["name_view"]+")")
	print("安装模块:"+name_view)
	if mod_origin_db.has(mod_name):
		return
	if not mod_data.has("mod_path"):
		return 
	var mod_path:String=mod_data["mod_path"]
	#开辟mod空间
	mod_origin_db[mod_name]=mod_data
	#加载单例
	if mod_data.has("autoload"):
		var auto_load_dic:Dictionary=mod_data["autoload"]
		for i in auto_load_dic.keys():
			print("\t加载全局项:"+i)
			var new_script=ResourceLoader.load(mod_path+auto_load_dic[i],"",ResourceLoader.CACHE_MODE_IGNORE_DEEP)
			if not new_script is GDScript:
				continue
			var tscn=new_script.new()
			tscn.name=i
			add_child(tscn)
			mod_autoload_db[mod_name+"/"+i]=tscn
	#加载节点类文件
	if mod_data.has("node"):
		mod_nodeclass_db[mod_name]={}
		var node_dic:Dictionary=mod_data["node"]
		#加载类数据库
		for i in node_dic.keys():
			print("\t加载类:"+mod_name+"/"+i)
			var new_script=ResourceLoader.load(mod_path+"/"+node_dic[i],"",ResourceLoader.CACHE_MODE_IGNORE_DEEP)
			if not new_script is GDScript:
				print("\t加载失败")
				continue
			mod_nodeclass_db[mod_name][i]=new_script
	if mod_data.has("triger"):
		var mod_triger_data=mod_data["triger"]
		if mod_triger_data is Dictionary:
			for i in mod_triger_data.keys():
				mod_triger_type_name_db[i]=mod_triger_data[i]
				print("\t加载触发器类型:"+mod_triger_data[i]+"("+i+")")
	if mod_data.has("panel"):
		var mod_panel_data=mod_data["panel"]
		if mod_panel_data is Dictionary:
			mod_panel_db[mod_name]=[]
			for i in mod_panel_data.keys():
				var single_panel_data=mod_panel_data[i]
				var tscn=null
				var tscn_script=null
				if single_panel_data.has("tscn"):
					tscn=ResourceLoader.load(mod_path+single_panel_data["tscn"],"",ResourceLoader.CACHE_MODE_IGNORE_DEEP)
					if not tscn is PackedScene:
						continue
				if single_panel_data.has("script"):
					tscn_script=ResourceLoader.load(mod_path+single_panel_data["script"],"",ResourceLoader.CACHE_MODE_IGNORE_DEEP)
					if not tscn_script is GDScript:
						tscn_script=null
				mod_panel_db[mod_name].append([i,tscn,tscn_script])
#依据mod名称卸载mod
func uninstall_mod(mod_name:String):
	print("卸载模块:"+mod_name)
	if not mod_origin_db.has(mod_name):
		return
	var mod_data=mod_origin_db[mod_name]
	#卸载autoload单例
	if mod_data.has("autoload"):
		var auto_load_dic:Dictionary=mod_data["autoload"]
		for i in auto_load_dic.keys():
			if mod_autoload_db.has(i):
				print("\t卸载单例:"+i)
				var node=mod_autoload_db[i]
				if node is Node:
					node.queue_free()
				mod_autoload_db.erase(i)
	
	if mod_nodeclass_db.has(mod_name):
		#卸载类数据库
		mod_nodeclass_db.erase(mod_name)
	#卸载触发器类型
	if mod_data.has("triger"):
		var mod_triger_data=mod_data["triger"]
		if mod_triger_data is Dictionary:
			for i in mod_triger_data.keys():
				mod_triger_type_name_db.erase(i)
				print("\t卸载触发器类型:"+mod_triger_data[i]+"("+i+")")
	#卸载面板
	if mod_panel_db.has(mod_name):
		mod_panel_db.erase(mod_name)
#获取全部节点的队列
func get_all_node_class():
	var res:Array=[]
	for i in mod_nodeclass_db.keys():
		
		
		var class_db=mod_nodeclass_db[i]
		for j in class_db.keys():
			res.append([i,j])
	return res

#获取节点的class
func get_node_class(mod_name:String,node_name:String):
	if not mod_nodeclass_db.has(mod_name):
		print("缺少模块:"+mod_name)
		return null
	var mode_class:Dictionary=mod_nodeclass_db[mod_name]
	if not mode_class.has(node_name):
		print("未在模块中找到指定节点:"+mod_name+"/"+node_name)
		return null
	return mode_class[node_name]

#获取当前加载的全部触发器类型
func get_all_triger()->Array:
	return mod_triger_type_name_db.keys()
#获取trigertype对应的触发器名字
func get_triger_name(triger_type:String)->String:
	if mod_triger_type_name_db.has(triger_type):
		return mod_triger_type_name_db[triger_type]
	else:
		return "未知触发器类型"

#获取全部需要加载的面板
func get_all_panel():
	var res=[]
	for i in mod_panel_db.values():
		res.append_array(i)
	return res

#获取全部mod的加载数据
func get_all_mod_origin_data():
	return mod_origin_db
	
	pass
#获取mod的路径，如果路径不存在则返回空字符串
func get_mod_path(mod_name:String)->String:
	if not mod_origin_db.has(mod_name):
		return ""
	var mod_data:Dictionary=mod_origin_db[mod_name]
	if not mod_data.has("mod_path"):
		return ""
	return mod_data["mod_path"]
func reload():
	#清空数据
	for i in get_children():
		i.queue_free()
	#mod加载数据
	mod_origin_db={}
	#mod自动加载集
	mod_autoload_db={}
	#mod节点类集
	mod_nodeclass_db={}


	#mod加载的触发器类型
	mod_triger_type_name_db={}

	#mod加载的在主界面的面板的数据
	mod_panel_db={}
	load_mod_from_path(load_path)
	mod_changed.emit()
	
	
	pass
#监测当前是否具有此名字的mod
func has_mod(mod_name:String)->bool:
	return mod_origin_db.has(mod_name)


#获取mod加载的根节点
func get_load_path():
	var path:String=load_path
	if not path.ends_with("/"):
		path+="/"
	return path

#删除mod
func delete_mod(mod_name:String):
	var path=get_mod_path(mod_name)
	if path=="":
		return
	#删除文件夹
	OS.move_to_trash(ProjectSettings.globalize_path(path))
	reload()
