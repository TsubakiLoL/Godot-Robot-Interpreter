extends Node


var node_array:Array[NodeRoot]=[]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var mod_load_path:String=""
	var nodeset_execute_array:Array[String]=[]
	var cmd_line_args:PackedStringArray=OS.get_cmdline_user_args()
	var args:Dictionary[String,String]=get_cmd_args(cmd_line_args)
	if (not args.has("Mod") ) or (not args.has("Nodeset") ):
		print("缺失启动参数")
		print(cmd_line_args)
		print(args)
		get_tree().quit()
		return
	var mod_path:String=args["Mod"]
	var nodeset_path:String=args["Nodeset"]
	print("插件加载目录："+mod_path)
	print("节点集加载目录："+nodeset_path)
	ModLoader.load_mod_from_path(mod_path)
	execute_nodeset(nodeset_path)
	

func get_cmd_args(input:PackedStringArray)->Dictionary[String,String]:
	var res:Dictionary[String,String]={}
	var regex:RegEx=RegEx.create_from_string("^--(?<argname>[^=]+)=(?<argvalue>[^=]+)$")
	for i in input:
		var result:RegExMatch=regex.search(i)
		if result==null:
			continue
		var exe_res:Dictionary={}
		for j in result.names.keys():
			exe_res[j]=result.strings[result.names[j]]	
		if (not exe_res.has("argname")) or (not exe_res.has("argvalue")):
			continue
		var argname:String=exe_res["argname"]
		var argvalue:String=exe_res["argvalue"]
		res[argname]=argvalue
	return res

#实例化特定目录下的nodeset
func execute_nodeset(load_path:String)->Array[NodeRoot]:
	var res:Array[NodeRoot]=[]
	var file_name := ""
	var files := []
	var dir := DirAccess.open(load_path)
	if dir==null:
		return []
	if dir:
		dir.list_dir_begin()
		file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir() and file_name.ends_with(".nodeset"):
				#获取当前的路径
				var sub_path:String = load_path + "/" + file_name
				var now_file=FileAccess.open(sub_path,FileAccess.READ)
				if now_file!=null:
					var data:String=now_file.get_as_text()
					var node_root=Serializater.parse_string(data)
					if node_root!=null:
						node_root.start()
						res.append(node_root)
						print("运行节点集："+file_name)
			file_name = dir.get_next()
		dir.list_dir_end()
		
	return res
