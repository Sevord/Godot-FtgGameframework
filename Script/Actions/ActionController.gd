extends Node
class_name ActionController
# 动作管理器，是一个核心组件

#此组件的拥有者
export(NodePath) var _Owner
var Owner

# 角色的animator，要通过这个来播放角色动作的
var anim:AnimationPlayer

# 即使不是玩家控制，也可以有这个组件，ai也可以通过发送操作指令来驱动角色
# 尽管ai有aiCommand这个组件,类型是：InputToCommand
export(NodePath) var _command
var command:InputToCommand

# 当前正在做的动作的信息
var CurrentAction:ActionInfo


#当前激活的BeCancelledTag
var CurrentBeCancelledTag:Array;


#角色所有会的动作 类型：ActionInfo
var AllActions:Array


# 当前帧的动画切换请求，如果一个也没有，则会继续当前的动作 Array(PreorderActionInfo)
var _preorderActions:Array



# 这个动作在上一个update经历了多少百分比了
var _wasPercentage:float = 0


# 当前动作的RootMotion方法
# 参数float：当前动作进行到的百分比
# 参数string[]：配置在ActionInfo表里actionInfo.rootMotionTween的param部分
# 返回值：Vector3，偏移量，假设起始的时候坐标为zero，到normalized==参数float的时候，当时的偏移值
var _rootMotion:ScriptMethodInfo


# 当前激活的攻击盒tag
#这算是一个内存换芯片，就是我先每帧算好了储存下来哪些框开启 Array(string)
var ActiveAttackBoxTag:Array


#同上，只是储存的是具体信息 List<AttackBoxTurnOnInfo>
var  ActiveAttackBoxInfo:Array


#当前帧的移动速度百分比
var moveInputAcceptance:float = 0

# 当前激活的受击盒tag Array(string)//List<BeHitBoxTurnOnInfo>

var ActiveBeHitBoxTag:Array
var ActiveBeHitBoxInfo:Array


# 当前帧的RootMotion信息
var RootMotionMove:Vector2 = Vector2.ZERO


# 硬直（卡帧）时间
var _freezing:float = 0;

# 是否在硬直或者卡帧
var Freezing:bool setget setFreezing,getFreezing
func setFreezing(value):
	pass
func getFreezing():
	var result:bool = (_freezing>0)
	return result



# 更换动作的时候的回调函数
# 参数1：ActionInfo：更换之前的action
# 参数2：ActionInfo：更换之后的action
#只有在ChangeAction时才会调用
var _onChangeAction:FuncRef = null


# 当前动画百分比，放这里方便些，其实最好放一个函数里
# 但是因为要访问动画百分比的频率较高，不如就一次性了
var _pec:float = 0;


func _ready():
	initRefer()

func initRefer():
	Owner = get_node(_Owner)
	command = get_node(_command)
	#anim = find_node()

# 之所以我们都用Update而不是Fixed，因为我们要依赖的核心是Input和Animator
# 用Update做动作游戏会有很多问题，比如跳过了可以Cancel的帧
# 但是无奈，毕竟用了unity

func _process(delta):
	#没有动画就不会工作
	if (AllActions.size() <= 0):return
	
	

	#根据硬直来调整倍率
	if (Freezing):anim.playback_speed = 0
	else: anim.playback_speed = 1
	
	if (_freezing > 0):_freezing -= delta;
	
	#因为动作融合，所以我们优先取下一个动作的normalized当做百分比进度
	var asInfo:Animation
	if (anim.current_animation != ""):
		asInfo = anim.get_animation(anim.current_animation)
	var nextStateInfo:Animation
	if (anim.animation_get_next(anim.current_animation) != ""):
		nextStateInfo= anim.get_animation(anim.animation_get_next(anim.current_animation))
	
	#下一个动画确实存在，要混合
	if ( nextStateInfo != null): _pec = 0;
	else: _pec = anim.current_animation_position / anim.current_animation_length #pos是0-length动画长度
	
	#获得现在的百分比时间，因为会大于等于100%（你敢信，这就是Unity这个愚蠢做法的无奈之处）所以要clamp一下
	#_pec = Mathf.Clamp01(nextStateInfo.length > 0 ? nextStateInfo.normalizedTime : asInfo.normalizedTime);
	
	#算一下攻击盒跟受击盒
	CalculateBoxInfo(_wasPercentage, _pec);
	
	#移动缩放比
	CalculateInputAcceptance(_wasPercentage, _pec);
	
	#测试
	#算一下2帧之间的RootMotion变化   && RootMotionMethod.Methods.has(_rootMotion.function)
	if (!_rootMotion.method.empty() && RootMotionMethod.Methods.has(_rootMotion.method)):
		
		var rootMotionMethod:FuncRef = RootMotionMethod.Methods[_rootMotion.method]
		
		var rmThisTick:Vector2 =   rootMotionMethod.call_funcv([_pec,_rootMotion.param])
		#这里有问题，用的一堆什么字符数组阿？
		var rmLastTick:Vector2 = rootMotionMethod.call_funcv([_wasPercentage,_rootMotion.param])
		
		RootMotionMove = rmThisTick - rmLastTick
		#Debug.Log("RootMotion distance " + RootMotionMove + "=>" + pec + " - " + _wasPercentage);
	else:
		RootMotionMove = Vector2.ZERO
	
	#动作是否要更换了，最终我们为了偷懒，而妥协了引擎的依赖于动画的思路了
	#当然，这只是因为这是个demo，如果正式开发游戏，就要斟酌一下，毕竟自己写一个，可以手感提高不少
	#但是手感的提高，玩家是未必能体验出来的
	#开始观察每个动作，如果他们可以cancel当前动作，并且操作存在，那么就会添加到预约列表里面
	for action in AllActions:
		var result:Array = CanActionCancelCurrent(action, _pec, true)
		#结果数组，约定[0]返回是否成功的bool，[1] bcTag [2] cancelTag
		var bcTag:BeCancelledTag = result[1]
		var cancelTag:CancleTag = result[2]
		
		#假如预约某个动作
		if (result[0]):
			_preorderActions.append(PreorderActionInfo.new(action.id, bcTag.priority + cancelTag.priority + action.priority,
				min(bcTag.fadeOutPercentage, cancelTag.fadeInPercentage), cancelTag.startFromPercentage))
		
	#如果要更换了就预约下一个动作
	#这是第二种预约动作的方式，基本在响应输入后，走的自动预约。
	#当没有符合的输入预约时，采取自动策略 【0】动作时间 大于>1 【1】自动终止
	if (_preorderActions.size() <= 0 && (_pec >= 1 || CurrentAction.autoTerminate)):
		
		#预约下一个自动动作的id
		_preorderActions.append(PreorderActionInfo.new(CurrentAction.autoNextActionId))
	
	#冒泡所有的候选动作，得出应该切换的动作
	_wasPercentage = _pec;   #先设置这个，之后可能会被ChangeAction所改变
	if (_preorderActions.size() > 0):
		#有需要更换的动画就更换
		_preorderActions.sort_custom(self,"custom_sort")
		
		#自己预约的下个动作还是自己，保持动画
		if (_preorderActions[0].ActionId == CurrentAction.id && CurrentAction.keepPlayingAnim):
			anim.play(CurrentAction.animKey)
		else:
			ChangeAction(_preorderActions[0].ActionId, _preorderActions[0].TransitionNormalized,
				_preorderActions[0].FromNormalized, _preorderActions[0].FreezingAfterChangeAction)
	
	#清理一下预约列表
	_preorderActions.clear()

# 自定义排序函数，按照元素的 Priority 属性降序排序
func custom_sort(a:PreorderActionInfo, b:PreorderActionInfo):
	return a.Priority > b.Priority



# 更换动作进行 的 回调函数
func Set(onActionChanged:FuncRef):
	_onChangeAction = onActionChanged

#计算输入百分比
func CalculateInputAcceptance(wasPec:float, pec:float):
	moveInputAcceptance = 0
	if (CurrentAction.inputAcceptance == null):return
	
	for acceptance in CurrentAction.inputAcceptance:
		if (acceptance.PercentageRange.x <= pec && acceptance.PercentageRange.y >= wasPec &&
			(moveInputAcceptance <= 0 || acceptance.rate < moveInputAcceptance)):
			moveInputAcceptance = acceptance.rate
	

# 计算当前动画帧的信息
# <param name="wasPec">上一帧的百分比</param>
#<param name="pec">百分比进度</param>
func CalculateBoxInfo(wasPec:float,pec:float)->void:
	
	#清空并计算攻击盒
	ActiveAttackBoxInfo.clear()
	ActiveAttackBoxTag.clear()
	
	#aBox  AttackBoxTurnOnInfo 类型
	for aBox in CurrentAction.attackPhase:
		var open = false
		for _range in aBox.inPercentage:
			if (pec >= _range.x && wasPec <= _range.y):
				open = true
				break
			
		if (open):
			for aTag in aBox.tag:
				if (!ActiveAttackBoxTag.has(aTag)):
					ActiveAttackBoxTag.append(aTag)
			ActiveAttackBoxInfo.append(aBox)
		
		
	#同理 置空，计算受击盒
	ActiveBeHitBoxInfo.clear()
	ActiveBeHitBoxTag.clear()
	# bHitBox   BeHitBoxTurnOnInfo  类型
	for bHitBox in CurrentAction.defensePhase:
		
		var open:bool = false
		for _range in bHitBox.inPercentage:
			if (pec >= _range.x && pec <= _range.y):
				open = true
				break
		
		if(open):
			for bTag in bHitBox.tag:
				if (!ActiveBeHitBoxTag.has(bTag)):
					ActiveBeHitBoxTag.append(bTag);
			ActiveBeHitBoxInfo.append(bHitBox);
		


# 在当前的情况下，是否能Cancel掉CurrentAction
# <param name="action">动画</param>
# <param name="currentPercentage">当前动画播放到了百分之多少</param>
# <param name="checkCommand">是否检查输入，true代表要输入也合法才行</param>
# <param name="beCancelledTag">符合条件的BeCancelledTag</param>
# <param name="foundTag">符合条件的CancelTag</param>
func CanActionCancelCurrent(action:ActionInfo,currentPercentage:float,checkCommand:bool)->Array:
	
	#
	
	#foundTag = new CancelTag();
	#beCancelledTag = new BeCancelledTag()
	var result:Array = [false,null,null]
	
	for bcTag in CurrentBeCancelledTag:

		#百分比时间符合的情况下，才可能有效  Vector2 的 x和y充当最大和最小值
		if (!(bcTag.percentageRange.y >= _wasPercentage && bcTag.percentageRange.x <= currentPercentage)):continue
		
		#判断CancelTag是否有交集，没有交集，说明也不能cancel
		var tagFit:bool = false
		for cTag in bcTag.cancelTag:
			for cancelTag in action.cancelTag:
				
				if (cancelTag.tag == cTag):
					tagFit = true;
					result[1] = bcTag
					result[2] = cancelTag
					break
			if (tagFit == true):
				break
		
		if (!tagFit):continue
		
		#检查输入
		if (checkCommand):
			for ac in action.commands:
				#任何一条操作符合，就算符合
				if (command.ActionOccur(ac)):
					result[0] = true
					return result
		else:
			result[0] = true
			return result;   #不检查输入，到这里就直接符合了
	
	result[0] = false
	return result;   #很遗憾，找不到


# 更换到某个action
# <param name="actionId">目标actionId</param>
# <param name="transitionNormalized">融合百分比时间</param>
# <param name="fromNormalized">从百分之多少开始播放新的动画</param>
# <param name="freezingAfterChange">切换动作后，硬直多少秒</param>
func ChangeAction(actionId:String,transitionNormalized:float, fromNormalized:float,freezingAfterChange:float)->void:
	
	#多返回值装箱， [0]bool表示 是否成功， [1]ActionInfo
	var result:Array = GetActionById(actionId)
	var aInfo:ActionInfo = result[1]
	
	if (result[0]):
		
		#清除掉非方向操作，连招手感得这么保障，当然刻意为了更容易连招，可以去掉这个
		command.CleanNonDirectionInputs()
		
		#触发 改变Action 的回调
		_onChangeAction.call_funcv([CurrentAction, aInfo])
		
		#这里参数意义有差别，源代码是有 混合时间，混合切入时间的属性要求的。
		anim.play(aInfo.animKey,transitionNormalized)
		#计算动画要前进位置，一般而言一段动画有些是融合用的
		var advanceTime:float = anim.current_animation_length * fromNormalized #动画要前进的时间，一般切换动作时候都是0
		#anim.advance(advanceTime)
		
		print("修改Action:")
		print(actionId)
		anim.seek(advanceTime)
		
		#anim.CrossFade(aInfo.animKey, transitionNormalized, 0, fromNormalized);
		
		CurrentAction = aInfo #修改
		#默认的cancelTag都可以加上
		CurrentBeCancelledTag.clear()
		
		for beCancelledTag in aInfo.beCancelledTag:
			CurrentBeCancelledTag.append(beCancelledTag);
		

		_freezing = freezingAfterChange
		
		#清空，每帧都要重新算
		ActiveBeHitBoxInfo.clear()
		ActiveBeHitBoxTag.clear()
		ActiveAttackBoxTag.clear()
		ActiveAttackBoxInfo.clear()
		
		_rootMotion = aInfo.rootMotionTween
		
		_wasPercentage = fromNormalized;
		
		#顺便修一下面向
		if command.inversed:
			Owner.scale.x = 1
		else:
			Owner.scale.x = -1
			
		#修正完毕才接受新的是否要转向，因为可能这个动作本身自带转向
		if (aInfo.flip):command.inversed = !command.inversed;
		



# 从allActions(已经学会的动作)中抽出第一个id符合条件的动作，如果没有，就会返回当前的动作
# <param name="actionId"></param>
# <param name="found">是否找到了合适的</param>
func GetActionById(actionId:String)->Array:
	
	var result:Array = [false,false]
	var found:bool = false
	
	for action in AllActions:
		if (action.id == actionId):
			result[0] = true
			result[1] = action
			return result
	
	result[1] = CurrentAction
	return result

#反向查询 index
func IndexOfAttack(attackPhase:int)->int:
	
	for i in range(0,CurrentAction.attacks.size()) :
		if (CurrentAction.attacks[i].phase == attackPhase):
			return i
	return -1



# 初始化：设置所有的动作
# <param name="actions"></param>
#<param name="defaultActionId"></param>
func SetAllActions(actions:Array, defaultActionId:String)->void:
	AllActions.clear()
	if (actions != null):AllActions = actions
	ChangeAction(defaultActionId, 0, 0, 0)


# 预约一个动作
# <param name="acInfo">变换动作信息</param>
# <param name="forceDir">如有必要（其实就是byCatalog）得给个动作受力方向</param>
# <param name="freezing">如果切换到这个动作，硬直多少秒</param>
func PreorderActionByActionChangeInfo(acInfo:ActionChangeInfo,forceDir, freezing:float = 0)->void:
	
	#Godot里有莫名其妙的bug match 枚举类型时无效
	
	#三种类型的匹配
	if (acInfo.changeType == AutoSomething.ActionChangeType.Keep):
		return
	elif(acInfo.changeType == AutoSomething.ActionChangeType.ChangeByCatalog):
		
		#根据对目标的 变化拿到 标识string 去取 符合的Action加入（例如受伤Hurt）
		var actions:Array
		for info in AllActions:
			if (info.catalog == acInfo.param):
				actions.append(info)
		
		if (actions.size() > 0):
			var picked:ActionInfo = actions[0]
			#如果有策划设计的脚本，那就走脚本拿到数据
			if (PickActionMethod.Methods.has(acInfo.param)):
				picked = PickActionMethod.Methods[acInfo.param].call_funcv([actions, forceDir])
				#函数回调
			#添加一个新的预备动作Action
			_preorderActions.append(PreorderActionInfo.new(
				picked.id,
				acInfo.priority + picked.priority,
				acInfo.fromNormalized,
				acInfo.transNormalized,
				freezing
			))
	elif(acInfo.changeType == AutoSomething.ActionChangeType.ChangeToActionId):
		#找到对应id的动作，如果有的话；这个方法就是直接从AllAction里根据id拿 新建一个预约动作加入
		#[0] bool是否成功 【1】ActionInfo
		var result:Array = GetActionById(acInfo.param)
		var aInfo:ActionInfo = result[1]

		if (result[0]):
			_preorderActions.append(PreorderActionInfo.new(
				aInfo.id,
				acInfo.priority + aInfo.priority,
				acInfo.fromNormalized,
				acInfo.transNormalized,
				freezing
				))
	
	
#	match (acInfo.changeType):
#		AutoSomething.ActionChangeType.Keep:
#			#既然保持，就啥也不做了
#			return
#		AutoSomething.ActionChangeType.ChangeByCatalog:
#			var actions:Array
#
#			for info in AllActions:
#				if (info.catalog == acInfo.param):
#					actions.append(info)
#
#			if (actions.size() > 0):
#				var picked:ActionInfo = actions[0]
#				#如果有策划设计的脚本，那就走脚本拿到数据
#				if (AutoSomething.PickActionMethod.Methods.has(acInfo.param)):
#					picked =  AutoSomething.PickActionMethod.Methods[acInfo.param].call_funcv([actions, forceDir])
#
#				_preorderActions.append(PreorderActionInfo.new(
#					picked.id,
#					acInfo.fromNormalized,
#					acInfo.priority + picked.priority,
#					acInfo.transNormalized,
#					freezing
#				))
#		AutoSomething.ActionChangeType.ChangeToActionId:
#			#找到对应id的动作，如果有的话
#
#			#[0] bool是否成功 【1】ActionInfo
#			var result:Array = GetActionById(acInfo.param)
#			var aInfo:ActionInfo = result[1]
#
#			if (result[0]):
#				_preorderActions.append(PreorderActionInfo.new(
#					aInfo.id,
#					acInfo.fromNormalized,
#					acInfo.priority + aInfo.priority,
#					acInfo.transNormalized,
#					freezing
#					))



# 加入卡帧，卡帧会叠加，但是最多不会超过一个值，并且越接近的时候增加量越少
# 注意，这只能是卡帧freezing，因为他会立即暂停角色动作，而受击的hitStun是在切换动作之后，切勿走这里
# <param name="freezingSec"></param>
func SetFreezing(freezingSec:float)->void:
	if (_freezing < 0):_freezing = 0   #清理一下
	var maxFreezing:float = 0.5   #卡帧、硬直上限
	var addRate:float = clamp(maxFreezing - _freezing, 0, maxFreezing) / maxFreezing
	_freezing += freezingSec * addRate
	
	if (Freezing):
		anim.playback_speed = 0
	else:
		anim.playback_speed = 1
	



# 开启临时的CancelTag
 #<param name="beCancelledTag"></param>
func AddTempBeCancelledTag(beCancelledTag:TempBeCancelledTag)->void:
	var _beCancelledTag:BeCancelledTag = BeCancelledTag.new()
	_beCancelledTag.FromTemp(beCancelledTag, _pec)
	
	CurrentBeCancelledTag.append(_beCancelledTag)



# 根据TempBeCancelledTag的id来开启
# <param name="tempTagId"></param>
func AddTempBeCancelledTagById(tempTagId:String)->void:
	
	for beCancelledTag in CurrentAction.tempBeCancelledTag:
		if (beCancelledTag.id == tempTagId):
			AddTempBeCancelledTag(beCancelledTag);
			return;
