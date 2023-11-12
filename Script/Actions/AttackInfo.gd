extends Reference
class_name AttackInfo
# 造成的伤害信息


#一个伤害信息都会有一个phase，也就是证明他是第几段的
var phase:int
	

# 伤害值，这不一定是一个最终值，他可以是一个倍率，看AttackInfo用在哪儿
# 比如用在动作游戏中，就相当于mh的伤害倍率，很好理解，动作游戏都有这个
# 精致一些的话会做在每一帧，但既然用了Unity和UE要尊重他们的框架就只能………
# 按动作问题也不大，毕竟“玩家好理解”。
var attack:float


#这段攻击的方向算是哪儿（会被角色的方向修正得出最终攻击方向） AutoSomething.ForceDirection
var forceDir


#推动力，目标会收到这个力的影响
#这是一个ForceMove，不受标准移动力影响
var pushPower:MoveInfo


#目标的硬直时间（秒）
var hitStun:float


#攻击者自身的卡帧（秒）
var freeze:float


#这个攻击在动作变换之前可以命中同一个目标多少次
var canHitSameTarget:int

#如果超过1次，那么每2次之间的间隔时间是多少秒
var hitSameTargetDelay:float
	
# 当命中的时候，自身会发生的变化
#这里值得注意的是，这未必是动作的属性，我在这里只是做的“粗糙”了
# 精细一点的应该是不同帧不同的攻击框都有不同的值
var selfActionChange:ActionChangeInfo

#命中时候对手的动作变化
var targetActionChange:ActionChangeInfo
	
#
# 如果攻击命中了，就会临时开启一些tempBeCancelledTag，这里用id去索引,是个字符数组
var tempBeCancelledTagTurnOn:Array

func _init(phase:int = 0,attack:float =0,forceDir= null,
pushPower:MoveInfo = null,hitStun:float=0,freeze:float=0,canHitSameTarget:int =0,
hitSameTargetDelay:float =0,selfActionChange:ActionChangeInfo = null,targetActionChange:ActionChangeInfo = null,
tempBeCancelledTagTurnOn:Array = []):
	self.phase = phase
	self.attack = attack
	self.forceDir = forceDir
	self.pushPower = pushPower
	self.hitStun = hitStun
	self.freeze = freeze
	self.canHitSameTarget = canHitSameTarget
	self.hitSameTargetDelay = hitSameTargetDelay
	self.selfActionChange = selfActionChange
	self.targetActionChange = targetActionChange
	self.tempBeCancelledTagTurnOn = tempBeCancelledTagTurnOn
	
