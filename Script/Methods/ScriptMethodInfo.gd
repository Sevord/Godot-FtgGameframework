extends Reference
class_name ScriptMethodInfo
#脚本函数，类似于Funcref类型。保存一个id函数字段指向一个函数。
#不过不一样的是，也保存参数


#函数名
var method:String

#参数，使用string[]得策划自己在脚本（Methods）翻译其用意
var param:Array

#初始化函数
func _init(method:String,param:Array):
	self.method = method
	self.param = param

