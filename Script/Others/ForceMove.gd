extends Reference
class_name ForceMove
# 强制位移信息

var Data:MoveInfo
var TimeElapsed:float = 0
var WasElapsed:float = 0
var MoveTween:FuncRef #移动函数


func _init(data:MoveInfo,TimeElapsed:float = 0,WasElapsed:float = 0):
	self.Data = data
	self.TimeElapsed = 0
	self.WasElapsed = 0
	self.MoveTween = ForceMoveMethod.Methods[data.tweenMethod] # 根据字符获取强制移动函数


#置空函数
static func NoForceMove() -> ForceMove:
	return load("res://Script/Others/ForceMove.gd").new(MoveInfo.new())
	

func Update(delta):
	WasElapsed = TimeElapsed
	TimeElapsed += delta
