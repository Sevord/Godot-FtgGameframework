extends Node2D
class_name CharacterObj


# 动作管理
export(NodePath) var _action
var action:ActionController
#action: ActionController

# 输入系统，通过这个可以获得一部分移动信息
export(NodePath) var _input
var input:InputToCommand
#input:InputToCommand 

export(NodePath) var _anim

# 重量，影响到下落速度，第一秒的时候下降weight，第1-2秒的时候下降就是2*weight了，以此类推
# 实际上动作游戏中是每帧增加一个重量，但是我们用的是Update，帧的概念是电影行业的，不是做游戏的
# 所以我们不得不拟合一个，按照每秒作为单位来用deltaTime做拟合
export(float) var weight:float = 3.5


# 是否正在下落
var _falling:bool = false;
# 下落的重量
var _curWeight:float = 0;

# 当前是否下降这个东西，并不是由角色自己说了算的，这是绝大多数游戏教程，也包括UE的游戏框架在内，完全做错的地方
# 因为是否下落取决于地形等游戏中的其他元素，不仅仅取决于角色自身，甚至几乎不取决于角色自己
# 而角色不应该依赖于其他这么多的元素，所以应该由“最小弟”的GameMain这一层来告诉我，我该不该下落
var Falling:bool setget setFalling,getFalling
func setFalling(value):
	if (value && !_falling):
		#得初始化一下当前重量         
		_curWeight = 0;
	_falling = value
func getFalling():
	return _falling


# 碰撞盒的碰撞信息，现在这里缓存一下  AttackHitBox -> Array(BeHitBox)
var _boxTouches:Dictionary


# 当前动作的命中记录，更换动作就清空了这个列表了 类型：Array(HitRecord)
var HitRecords:Array


# 被强制移动，最多只有一个被强制移动
var _forceMove:ForceMove = ForceMove.NoForceMove()

var UnderForceMove:bool setget setUnderForceMove,getUnderForceMove
func setUnderForceMove(value):
	pass
func getUnderForceMove():
	var flag:bool = (self._forceMove.TimeElapsed <= self._forceMove.Data.inSec)
	return flag

#var Inversed:bool setget setInversed,getInversed
#func setInversed(value):
#	input.Inversed = value
#func getInversed():
#	if (input.Inversed):
#		return true
#	return false



#移动速度（米/秒）
#这原本应该是角色属性中的一个，但是这个demo并不打算做数值部分，所以就暴露在外
export(float) var moveSpeed:float

#是否期望向前action？
#var WishToMoveForward:bool setget setWishToMoveForward,getWishToMoveForward
#func setWishToMoveForward(value):
#	pass
#func getWishToMoveForward():
#	if (input.ActionOccur(ActionCommand.new([AutoSomething.KeyMap.Forward]))): 
#		return true
#	return false
#
#
#var WishToMoveBackward:bool setget setWishToMoveBackward,getWishToMoveBackward
#func setWishToMoveBackward(value):
#	pass
#func getWishToMoveBackward():
#	var result:bool = input.ActionOccur(ActionCommand.new(AutoSomething.KeyMap.Backward))
#	return result

#获取到是否向前？
func GetWishToMoveForward()->bool:
	return input.ActionOccur(ActionCommand.new([AutoSomething.KeyMap.Forward]))
#是否向后
func GetWishToMoveBackward()->bool:
	return input.ActionOccur(ActionCommand.new([AutoSomething.KeyMap.Backward]))


# 自然的移动，而非ForceMoved
func NatureMove(delta:float)->Vector2:
	var x_movement = 0
	var y_movement = 0 
	
	if (GetWishToMoveForward()):
		x_movement = moveSpeed * action.moveInputAcceptance * delta
	elif (GetWishToMoveBackward()): x_movement = -moveSpeed * action.moveInputAcceptance * delta
	
	
	#来自Action的两个偏移值
	x_movement += action.RootMotionMove.x
	#Godot坐标里 y正轴向下
	#加重力和  减去动作本身带来的偏移量
	y_movement = y_movement + _curWeight - action.RootMotionMove.y
	
	#转向的问题
	if (input.inversed): x_movement = -x_movement

	return Vector2(x_movement,y_movement)



#根据预先导出的节点路径获取到节点
func initRefer():
	action = get_node(_action)
	input = get_node(_input)
	action.anim = get_node(_anim) #设置动画播放器

func _ready():
	#set一下components
	initRefer()
	
	
	#设置回调
	action.Set(funcref(self,"onActionChangedCallBack"))
	
	#开始的时候初始化一下必要的Components 给攻击盒和受击的赋值拥有者
	var ahb:AttackHitBox = self.find_node("AttackHitBox")
	if (ahb):ahb.Master = self
	
	var bhb:BeHitBox = self.find_node("BeHitBox")
	if (bhb):bhb.Master = self


#Action变化的时的回调
#【0】当前的Actioninfo 【1】目标ActionInfo
func onActionChangedCallBack(wasAction:ActionInfo, toAction:ActionInfo):
	#更换动作时去掉所有命中记录
	HitRecords.clear();

func _process(delta):
	#以下内容只有不在硬直才会执行
	if (!action.Freezing):
		#HitRecords，处理受击信息
		for record in HitRecords:
			record.Update(delta)


# 攻击盒子当前是否激活？
#<param name="tags">攻击盒的tag,字符数组</param>
func ShouldAttackBoxActive(tags:Array)->bool:
	for s in tags:
		if (action.ActiveAttackBoxTag.has(s)):
			return true
	return false



# 挨打盒子当前是否激活？
# <param name="tags">受击盒的tag</param>
func ShouldBeHitBoxActive(tags:Array)->bool:
	for s in tags:
		if (action.ActiveBeHitBoxTag.has(s)):
			return true
	return false


# 追加一条攻击框命中受击框的信息
# 这里可不管框active与否
#<param name="attackHitBox">攻击框</param>
# <param name="targetBox">受击框</param>
func OnAttackBoxHit(attackHitBox:AttackHitBox,targetBox:BeHitBox)->void:
	
	#如果box 没有 攻击盒，添加攻击盒
	if (!_boxTouches.has(attackHitBox)):
		_boxTouches[attackHitBox] = []
	#如果对应攻击盒没有目标受击盒 添加
	if (!_boxTouches[attackHitBox].has(targetBox)):
		_boxTouches[attackHitBox].append(targetBox)



# 当攻击框脱离了受击框
# <param name="attackHitBox"></param>
# <param name="beHitBox"></param>
func OnAttackBoxExit(attackHitBox:AttackHitBox,beHitBox:BeHitBox):
	if (!_boxTouches.has(attackHitBox)):return
	_boxTouches[attackHitBox].erase(beHitBox) #从指定数组移除 指定bHitBox


#通过HitBox 获取到 帧信息
func GetDefensePhaseByBeHitBox(box:BeHitBox)->BeHitBoxTurnOnInfo:
	for boxTag in box.tags: #每个盒子
		for info in action.ActiveBeHitBoxInfo: #每个激活的盒子信息
			for infoTag in info.tag: #每个盒子信息的tag
				if (infoTag == boxTag):#tag一致
					return info
			
	return BeHitBoxTurnOnInfo.new()



# 现在是否能殴打某个人，这里不判断HitRecord
# <param name="target">谁挨打？</param>
#<param name="attackPhase">这是攻击阶段信息</param>
# <param name="defensePhase">受击的时候的阶段信息</param>
#<param name="attackBox">命中的是哪个攻击框</param>
# <param name="targetBox">目标的那个受击框被命中</param>
# 多返回值 [0] bool  [1] AttackInfo [2] BeHitBoxTurnOnInfo [3] AttackHitBox[4] BeHitBox
#CharacterObj target, out AttackInfo attackPhase, out BeHitBoxTurnOnInfo defensePhase,
# out AttackHitBox attackBox, out BeHitBox targetBox)
func CanAttackTargetNow(target:CharacterObj)->Array:
	
	#结果的装箱和一些初始化
	var result:Array = [false,false,false,false,false]
	var attackBox:AttackHitBox = null
	var targetBox:BeHitBox = null
	var attackPhase:AttackInfo = null
	
	var defensePhase:BeHitBoxTurnOnInfo =  null
	if (!target):
		result[0] = false
		return result
	
	#获取目标已开启的受击盒
	var activeBoxTag:Array
	for info in target.action.ActiveBeHitBoxInfo:
		for t in info.tag:
			if (!activeBoxTag.has(t)):
				activeBoxTag.append(t)
		
	
	#获取 命中对方的所有攻击框
	for boxInfo in action.ActiveAttackBoxInfo:
		for touch in _boxTouches:  # 角色 所有 的 攻击盒与 受击盒 信息
			#没有启动的攻击框不会判断命中
			if (!touch.Active):continue
			
			#命中的最有价值的受击框才行
			var best:BeHitBox = null
			var bestPriority:int = 0
			for hitBox in _boxTouches[touch]:  #字典默认情况下遍历的 key 。真坑阿...
				if (!hitBox.Active || hitBox.Master != target || !hitBox.TagHit(activeBoxTag)):continue;
				var info:BeHitBoxTurnOnInfo = GetDefensePhaseByBeHitBox(hitBox)
				var thisPriority:int = hitBox.Priority + info.priority;
				if (!best || thisPriority > bestPriority):
					best = hitBox
					bestPriority = thisPriority
					result[2] = info
					#defensePhase = info
				
			#一个没找到，当然就……
			if (!best):continue
			
			#就不管攻击框了，本来应该先判断攻击框的，其实也无所谓的
			result[3] = touch
			result[4] = best
			#attackBox = touch.Key;
			#targetBox = best;
			
			if (boxInfo.attackPhase >= 0 && boxInfo.attackPhase < action.CurrentAction.attacks.size()):
				result[1] = action.CurrentAction.attacks[boxInfo.attackPhase]
				
				#attackPhase = action.CurrentAction.attacks[boxInfo.attackPhase];
			
			result[0] = true
			return result
			
	result[0] = false
	return result



# 攻击框命中了对手（指定的单位）哪些受击框，一个也没的话就会是空数组了
# <param name="attackBox">攻击框</param>
# <param name="target">对手</param>
# ->Array（BeHitBox）
func AttackBoxHitTargetIn(attackBox:AttackHitBox,target:CharacterObj)->Array:
	
	var res:Array
	if (!_boxTouches.has(attackBox)):return res
	for hitBox in _boxTouches[attackBox]:
		if (hitBox.Master == target):
			res.append(hitBox)
	return res



# 添加命中记录
# <param name="target">谁被命中</param>
# <param name="attackPhase">算是第几阶段的攻击命中的</param>
func AddHitRecord(target:CharacterObj,attackPhase:int)->void:
	
	var idx:int = action.IndexOfAttack(attackPhase)
	if (idx < 0):return    #没有这个伤害阶段，结束
	
	var rec:HitRecord = GetHitRecord(target, attackPhase)
	if (rec == null):
		HitRecords.append(HitRecord.new(target, attackPhase, action.CurrentAction.attacks[idx].canHitSameTarget - 1,
			action.CurrentAction.attacks[idx].hitSameTargetDelay))
	else:
		rec.Cooldown = action.CurrentAction.attacks[idx].hitSameTargetDelay
		rec.CanHitTimes -= 1;
	
	
# 找出关于目标的HitRecord，如果没有就是null
# <param name="target">谁被命中</param>
# <param name="phase">算是第几阶段的攻击命中的</param>
func GetHitRecord(target:CharacterObj,phase:int)->HitRecord:
	for record in HitRecords:
		if (record.UniqueId == target.get_instance_id() && record.Phase == phase):
			return record
	return null



# 这一帧的移动 todo 目前只有NatureMove，还没有Forced
func ThisTickMove(delta:float)->Vector2:
	#硬直时候不做移动
	if (action.Freezing):return Vector2.ZERO;
	#有强制位移有限强制位移
	var flag:bool = (_forceMove.WasElapsed < _forceMove.Data.inSec)
	if (flag):
		var fMove:Vector2 = _forceMove.MoveTween.call_funcv([_forceMove])
		_forceMove.Update(delta)
		return fMove
	#下落重量的增幅，不应该在Update做，而是外部调用update的地方去做
	if (_falling):_curWeight += weight * delta;
	else:_curWeight = 0
	#有强制位移的时候强制位移，没有的时候自然移动
	return  NatureMove(delta)



# 设置强制移动，只接受最新的一个
# <param name="force"></param>
func SetForceMove(force:MoveInfo)->void:
	_forceMove = ForceMove.new(force)

