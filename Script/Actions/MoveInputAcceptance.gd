extends Reference
class_name MoveInputAcceptance
#一个小巧的用于显示移速倍率的类

# 在百分比多少的阶段

var PercentageRange:Vector2

# 允许百分比
var rate:float

func _init(PercentageRange:Vector2,rate:float):
	self.PercentageRange = Vector2(clamp(PercentageRange.x,0,1),clamp(PercentageRange.y,0,1))
	self.rate= rate
