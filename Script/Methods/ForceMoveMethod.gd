extends Node
#强制位移的方法
#参数1: ForceMove这条数据是什么
# 返回值：当前移动量

#储存强制位置方式 的 字典。 string->funcref
var Methods:Dictionary = {
	"Slowly": funcref(self,"SlowlyForceMove"),
	"":funcref(self,"NoForceMove")
}


static func SlowlyForceMove(forceMove) -> Vector2:
	if (forceMove.Data.inSec <= 0):return Vector2.ZERO
	
	var wasPec:float = clamp(forceMove.WasElapsed / forceMove.Data.inSec,0,1);
	var curPec:float = clamp(forceMove.TimeElapsed / forceMove.Data.inSec,0,1);
	#因为愚蠢的unity坐标系和正常游戏坐标系是反过来的，所以y负数向上，但是游戏开发的宇宙标准是y正向上
	#所以我们得为策划填表做个翻译，就是给他的y反个向
	var wasRate:float = 1.00 - pow(1.00 - wasPec, 3)
	var curRate:float  = 1.00 - pow(1.00 - curPec, 3)
	
	var was:Vector2 = forceMove.Data.moveDistance * wasPec
	var cur:Vector2 = forceMove.Data.moveDistance * curPec
	
	var cal:Vector2= cur - was
	return cal

static func NoForceMove()->Vector2:
	return Vector2.ZERO

