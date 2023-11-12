extends Reference
class_name CancleTag


#这个tag的字符串，可以理解为id
var tag:String

#这个动作会从normalized多少的地方开始播放
var startFromPercentage:float


#动画融合进来的百分比时间长度
var fadeInPercentage:float
	

#当从这里Cancel动作时，优先级变化
var priority:int

func _init(tag:String = "",startFromPercentage:float = 0,fadeInPercentage:float=0,priority:int = 0):
	self.tag = tag
	self.startFromPercentage = startFromPercentage
	self.fadeInPercentage = fadeInPercentage
	self.priority = priority

