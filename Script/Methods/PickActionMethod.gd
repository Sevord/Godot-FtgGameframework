extends Node
# 根据Catalog选择技能的函数
# key是Catalog
# value是(List of ActionInfo, ForceDirection)=>ActionInfo
# 执行value获得一个结果
#catalog是一个 Action的标识，通过标识来 标记Action。但一个Catalog可能有多个Action。这个类就是用于挑选的（pick比如受击动画）

# 奇怪的action 回调函数表  string->Funref
var Methods:Dictionary = {
	"Hurt":funcref(self,"HurtPickAction"),
	"Beaten":funcref(self,"BeatenPickAction"),
	"":funcref(self,"NoPickAction")}
	

#受伤1
#从受伤动作根据面向挑选出正确的 [0]动作组 [1]受击方向枚举
static func HurtPickAction(candidates:Array,dir:int)->ActionInfo:
	for info in candidates:
		 if( (info.id == "HurtFromForward" && dir == AutoSomething.ForceDirection.Forward) ||
			(info.id == "HurtFromBackward" && dir == AutoSomething.ForceDirection.Backward)):
				return info;
	return ActionInfo.new()

#另一种类型？
#从受到重击的动作类型重挑选出正确的
static func BeatenPickAction(candidates:Array,dir:int):
	for info in candidates:
		if ((info.id == "BeatenFromForward" && dir == AutoSomething.ForceDirection.Forward) ||
			(info.id == "BeatenFromBackward" && dir == AutoSomething.ForceDirection.Backward)):
				return info
	
	return ActionInfo.new() #否则返回一个空的

static func NoPickAction():
	return ActionInfo.new()
