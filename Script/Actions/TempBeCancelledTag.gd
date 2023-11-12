extends Reference
class_name TempBeCancelledTag

#临时的BeCanceledTag类型，往往用于达成条件时修正 当前动作的 BecancelTag，从而使得另一个动作可以取消的掉当前的这个action，从而达成连段。
#因为需要被索引，所以需要一个id
var id:String
	

# 在当前动作中，有百分之多少的时间是开启的
#从开启的时间往后算

var percentage:float
	

#可以Cancel的CancelTag,字符串数组
var cancelTag:Array


#动画融合出去的时间
# Unity推荐用normalized作为一个标尺，因为用second对于做动画本身有点要求
# 当然也可能是我对CrossFadeInFixedTime理解有误
var fadeOutPercentage:float
	

#当从这里被Cancel，动作会增加多少优先级
var priority:int

func _init(id:String,percentage:float,cancelTag:Array,fadeOutPercentage:float,priority:int):
	self.id = id
	self.percentage = percentage
	self.cancelTag = cancelTag
	self.fadeOutPercentage = fadeOutPercentage
	self.priority = priority
