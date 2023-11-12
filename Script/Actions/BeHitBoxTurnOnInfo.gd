extends Reference
class_name  BeHitBoxTurnOnInfo

# 开启的时间区域，可以分为多段时间开启
# Array(Vector2) 内部vector2 表示 范围值
var inPercentage:Array
	
# 要开启的盒子的tag
var tag:Array

# 这样开启的盒子，优先级会发生怎样的临时变化

var priority:int
	

# 如果命中了这里的受击框，就会临时开启一些tempBeCancelledTag，这里用id去索引
var tempBeCancelledTagTurnOn:Array
	
#与攻击框不同（是因为这个demo的游戏设计精度所决定的），受击框本身会决定这次受到攻击的时候双方的动作。
#因为我们完全可以开启一个受击框代表盾牌的同时，还有一个受击框代表屁股，屁股挨揍和盾牌挨揍效果完全不同
var attackerActionChange:ActionChangeInfo
	

#与攻击框不同（是因为这个demo的游戏设计精度所决定的），受击框本身会决定这次受到攻击的时候双方的动作。
# 因为我们完全可以开启一个受击框代表盾牌的同时，还有一个受击框代表屁股，屁股挨揍和盾牌挨揍效果完全不同
var selfActionChange:ActionChangeInfo


func _init(inPercentage:Array = [],tag:Array = [], priority:int = 0 ,tempBeCancelledTagTurnOn:Array = [],attackerActionChange:ActionChangeInfo = null, selfActionChange:ActionChangeInfo = null):
	self.inPercentage = inPercentage
	self.tag = tag
	self.priority = priority
	self.tempBeCancelledTagTurnOn = tempBeCancelledTagTurnOn
	self.attackerActionChange = attackerActionChange
	self.selfActionChange = selfActionChange
