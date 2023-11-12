extends Node2D

#使用的主要相机
export(NodePath) var _usingCam
var usingCam:Camera2D

# 玩家角色，其实应该是动态创建的，不过这个demo里面就偷个懒了
export(NodePath) var _player
var player:CharacterObj

# 敌人，也是偷懒的，正确的做法，应该是把所有人放在一个列表里统一处理
# 至少是走代码创建，而不是直接丢在场景里，然后拖到inspector
# 敌人 数组 Array(CharacterObj)
#狗屁引用路径数组
export(Array) var _enemy
var enemy:Array

#一个显示的Label
export(NodePath) var _inputText
var inputText:Label

func _ready():
	
	#初始化节点引用
	initRefer()
	
	#就暂时写在这里读取吧，demo自然就偷懒了
	GameData.Load()
	#同样是偷懒，把数据全塞给角色
	player.action.SetAllActions(GameData.GetAllActions(), "BoxingStand")
	
	for e in enemy:
		e.action.SetAllActions(GameData.GetAllActions(),"TurnBack");
		


#根据节点路径初始化引用
func initRefer():
	usingCam = get_node(_usingCam)
	player = get_node(_player)
	inputText = get_node(_inputText)
	
	for ene in _enemy:
		enemy.append(get_node(ene))


func _process(delta):
	
	var dt:float = delta
	#处理攻击和碰撞
	DealWithAttacks();
	#先处理角色的移动，这里没有地形，所以y<0就是falling了
	
	#Transform pTrans = player.transform;
	var pWas:Vector2 = player.position #单位坐标
	player.Falling = pWas.y < 0 # 是否处于下落状态
	var pMoved:Vector2 = player.ThisTickMove(dt) #
	
	#修正移动坐标
	player.position  = Vector2(
		pWas.x + pMoved.x,
		pWas.y + pMoved.y)
	
	#处理 敌人单位
	for ene in enemy:
		var eWas:Vector2 = ene.position
		ene.Falling = eWas.y < 0
		var eMoved:Vector2 = ene.ThisTickMove(dt)
		ene.position  = Vector2(
			eWas.x + eMoved.x,
			eWas.y + eMoved.y)
		

	#UI简单处理
	inputText.text = player.input.InputText();
	
	#处理摄像机 的 位置（有偏移值）
	usingCam.position = Vector2(600,-200) + player.position




# 处理每个角色的本帧攻击
func DealWithAttacks()->void:
	
	for ene in enemy:
		#玩家对敌人
		
		#[0] 是否成功  【1】攻击阶段的信息 【2】受击 的 信息 [3] 哪个攻击框 [4] 哪个受击框
		#if (player.CanAttackTargetNow(ene, out AttackInfo pAttackPhase, out BeHitBoxTurnOnInfo eDefenseInfo,
				#out AttackHitBox pAttackBox, out BeHitBox eneBox)) 
		var result:Array = player.CanAttackTargetNow(ene)
		
		if (result[0]):
			#先判断，如果hitRecord表示没法命中，那么这个框的信息无效
			var hRec:HitRecord = player.GetHitRecord(ene, result[1].phase);
			if (hRec == null || (hRec.Cooldown <= 0 && hRec.CanHitTimes > 0)):
				DoAttack(player, ene, result[1], result[2])
			
		
		#敌人对玩家 同上，封装的多返回值
		result = ene.CanAttackTargetNow(player)
		
		if (result[0]):
			#先判断，如果hitRecord表示没法命中，那么这个框的信息无效
			var hRec:HitRecord = ene.GetHitRecord(player,result[1].phase);
			if (hRec == null || (hRec.Cooldown <= 0 && hRec.CanHitTimes > 0)):
				DoAttack(ene, player, result[1] , result[2])
		
	

# 根据是否翻转获得方向
# <param name="dir"></param>
# <param name="inversed"></param>

static func GetForceDirection(dir:int,inversed:bool):
	if (!inversed):return dir
	
	match (dir):
		AutoSomething.ForceDirection.Forward: 
			return AutoSomething.ForceDirection.Backward;
		AutoSomething.ForceDirection.Backward: 
			return AutoSomething.ForceDirection.Forward;
	return dir



# 发动攻击
# <param name="attacker"></param>
# <param name="defender"></param>
# <param name="attackInfo"></param>
# <param name="defensePhase"></param>
func DoAttack(attacker:CharacterObj,defender:CharacterObj,attackInfo:AttackInfo,defensePhase:BeHitBoxTurnOnInfo)->void:
	#动作改变，各自动作各自占优，所以>=和>的区别就在这里了
	var attackerChange:ActionChangeInfo
	
	#比较优先级，确定攻击方action变化 
	if (attackInfo.selfActionChange.priority >= defensePhase.attackerActionChange.priority):
		attackerChange = attackInfo.selfActionChange
	else:
		attackerChange = defensePhase.attackerActionChange
	
	var attackerDir = GetForceDirection(attackInfo.forceDir, attacker.input.inversed); 
	attacker.action.PreorderActionByActionChangeInfo(attackerChange, attackerDir);
	
	
	var defenderChange:ActionChangeInfo
	if (attackInfo.targetActionChange.priority > defensePhase.selfActionChange.priority):
		defenderChange = attackInfo.targetActionChange
	else:
		defenderChange = defensePhase.selfActionChange
	
	
	#对受攻击方的改变，比如翻转/临时Action改变
	defender.action.PreorderActionByActionChangeInfo(defenderChange, attackerDir, attackInfo.hitStun);
	
	#攻击方卡帧
	attacker.action.SetFreezing(attackInfo.freeze);
	
	#受击方位移（攻击方位移发生在动作本身了）
	var moveDis:Vector2
	if (attackerDir == AutoSomething.ForceDirection.Forward):
		moveDis = Vector2(attackInfo.pushPower.moveDistance.x,attackInfo.pushPower.moveDistance.y)
	else:
		moveDis = Vector2(attackInfo.pushPower.moveDistance.x * -1,attackInfo.pushPower.moveDistance.y)
	
	#强制移动
	
	defender.SetForceMove(MoveInfo.new(moveDis,attackInfo.pushPower.inSec,attackInfo.pushPower.tweenMethod
	))
	
	#CancelTag开启
	for cTag in attackInfo.tempBeCancelledTagTurnOn:
		attacker.action.AddTempBeCancelledTagById(cTag);
	
	
	for cTag in defensePhase.tempBeCancelledTagTurnOn:
		defender.action.AddTempBeCancelledTagById(cTag);
	
	#造成伤害
	#todo demo里就先不做了
	
	#增加命中记录，确保不连续命中
	attacker.AddHitRecord(defender, attackInfo.phase);
