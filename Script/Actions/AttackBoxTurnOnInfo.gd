extends Reference
class_name AttackBoxTurnOnInfo


#开启的时间段 Array(vector2)
var inPercentage:Array


#要开启的攻击盒的tag
var tag:Array

#这段攻击的逻辑数据是ActionInfo中的哪个AttackInfo
var attackPhase:int
	

# 这样开启的盒子，优先级会发生怎样的临时变化
var priority:int

func _init(inPercentage:Array,tag:Array,attackPhase:int, priority:int):
	self.inPercentage = inPercentage
	self.tag = tag;
	self.attackPhase = attackPhase;
	self.priority = priority;
