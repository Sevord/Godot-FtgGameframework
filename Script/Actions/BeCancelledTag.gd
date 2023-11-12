extends Reference
class_name BeCancelledTag


#时间段 . 带两个值，最大和最小值都在 0-1之间
var percentageRange:Vector2

#可以Cancel的CancelTag,字符串数组
var cancelTag:Array


#动画融合出去的时间
# Unity推荐用normalized作为一个标尺，因为用second对于做动画本身有点要求
# 当然也可能是我对CrossFadeInFixedTime理解有误
var fadeOutPercentage:float
	

#当从这里被Cancel，动作会增加多少优先级
var priority:int

func _init(percentageRange:Vector2 = Vector2.ZERO,cancelTag:Array=[],fadeOutPercentage:float=0,priority:int = 0):
	self.percentageRange = Vector2(clamp(percentageRange.x,0,1),clamp(percentageRange.y,0,1))
	self.cancelTag = cancelTag
	self.fadeOutPercentage = fadeOutPercentage
	self.priority = priority


#根据TempBeCancelledTag和产生这个Tag的百分比时间点，算出一个新的BeCancelledTag
#其实就是内部改值
func FromTemp(tempTag:TempBeCancelledTag,fromPercentage:float):
	self.percentageRange.x = clamp(fromPercentage,0,1)
	self.percentageRange.y = clamp(tempTag.percentage+fromPercentage,0,1)
	
	self.cancelTag = tempTag.cancelTag
	self.fadeOutPercentage = tempTag.fadeOutPercentage
	self.priority = tempTag.priority
