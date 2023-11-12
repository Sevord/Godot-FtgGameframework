extends Reference
class_name MoveInfo
#角色移动的信息



#最终移动这么多距离
var moveDistance:Vector2


#在这么多秒内完成移动
var inSec:float

# 移动函数，会从Methods/MoveTween中找到对应的函数，如果没有这个函数，就会按照匀速的来
# 空字符串时直接视为没有这个函数指向回调函数的字符
var tweenMethod:String

func _init(moveDistance:Vector2 = Vector2.ZERO,inSec:float = 0,tweenMethod:String = "" ):
	self.moveDistance = moveDistance
	self.inSec = inSec
	self.tweenMethod = tweenMethod

