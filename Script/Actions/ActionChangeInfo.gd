extends Reference
class_name ActionChangeInfo

#动作变化方式"枚举 Auto.ChangType
var changeType

 #"变化方式的参数，如果是ToActionId则是要指向的Action的id；如果是ByCatalog则指向Action的Catalog属性")]
var param:String
	
#"优先级，因为有多个变化信息会要求角色变化动作，但是角色最后只能变到一个，所以得冒泡"
var priority:int

#从百分之多少开始这个动作")
var fromNormalized:float

#融合长度"
var transNormalized:float

func _init(changeType,param:String,priority:int,fromNormalized:float,transNormalized:float):
	self.changeType = changeType
	self.param = param;
	self.priority = priority
	self.fromNormalized = fromNormalized
	self.transNormalized = transNormalized;
