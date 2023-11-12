extends Node
# 游戏的静态数据，这里有一些是凑效果的，从Json里解析出来
#class GameData

var _loaded:bool = false 
var Actions:Dictionary #所有解析的出来的action都这字典里  string -> ActionInfo
var path:String = "res://Resource/GameData/Action.json"

func _ready():
	Load()
	print("解析完成")

func Load()->void:
	if (_loaded):return
	
	_loaded = true
	Actions.clear()
	
	var file = File.new()
	if (file.open(path,file.READ) == OK):
		var ta = file.get_as_text()
		
		if (ta != null):
			 # 使用JSON.parse方法解析JSON数据
			#	Json文件读出来后要转为自定义的类
			var parsed_json = JSON.parse(ta).result 
			print("Json 解析")
			for action in parsed_json["data"]: #遍历取东西
				
				#初始化一些值类型
				var info:ActionInfo = ActionInfo.new(action["id"],action["animKey"],action["catalog"],action["autoNextActionId"],
				action.get("keepPlayingAnim",false),action.get("priority",0),action.get("flip",false),action.get("autoTerminate",false)) #新建一个填进去,后面四玩意不是必有的，需要get方法进行TryGet
				
				#引用类型封装
				InitActionInfoReference(info,action["cancelTag"],action["beCancelledTag"],action["tempBeCancelledTag"],
				action["commands"],action["inputAcceptance"],action["attacks"],
				action["attackPhase"],action["defensePhase"],action.get("rootMotionTween",{}))
				
				Actions[action["id"]] = info
		
	_loaded = false

#获取到所有 actioninfo
func GetAllActions()->Array:
	if (Actions.values().size() == 0): return []
	return Actions.values()

#-------------------------------------------------------------一堆解析类和方法-------------

# ActionInfo 所有 引用类型封装，其实用工厂模式会稍微好点 从Json里解析出来都是内嵌类型
#[0]目标ActionInfo 【1】 cancelTag 这个动作能取消的Action的id 【2】beCancelledTag 被取消的依据
#[3]tempBeCancelledTag [4]commands 输入的命令序列类型 [5]inputAcceptance 移动范围倍率 [6]AttackInfo 一次伤害
#【7】AttackBoxTurnOnInfo 一段攻击（攻击盒开闭） [8] BeHitBoxTurnOnInfo 一部分防御（受击盒的情况）
#[9]FuncRef 移动函数回调
func InitActionInfoReference(actionInfo:ActionInfo,cancelTags:Array,beCancelledTags:Array,
tempBeCancelledTags:Array,commands:Array,inputAcceptances:Array, 
 attacks:Array,attackPhases:Array,defensePhases:Array,rootMotionTween:Dictionary):
	
	
	
	
	#一个临时装东西的数组
	var cancelTagArray:Array
	var beCancelledTagArray:Array
	var tempBeCancelledTagArray:Array
	var commandArray:Array
	var inputAcceptancesArray:Array
	var attacksArray:Array
	var attackPhaseArray:Array
	var defensePhaseArray:Array
	
	#首先是 cancelTag
	for cancelTag in cancelTags:
		var tempVar = CancleTag.new(cancelTag["tag"],cancelTag["startFromPercentage"],cancelTag["fadeInPercentage"],cancelTag.get("priority",0))
		cancelTagArray.append(tempVar)
		
	# becanceltag
	for beCancelledTag in beCancelledTags:
		var tempVar = BeCancelledTag.new(GetRange(beCancelledTag["percentageRange"]),beCancelledTag["cancelTag"],beCancelledTag["fadeOutPercentage"],beCancelledTag.get("priority",0))
		beCancelledTagArray.append(tempVar)
	#tempBeCancelledTag
	for tempBeCancelledTag in tempBeCancelledTags:
		var tempVar = TempBeCancelledTag.new(tempBeCancelledTag["id"],tempBeCancelledTag["percentage"],tempBeCancelledTag["cancelTag"],tempBeCancelledTag["fadeOutPercentage"],tempBeCancelledTag.get("priority",0))
		tempBeCancelledTagArray.append(tempVar)
	#command
	for command in commands:
		var tempVar = ActionCommand.new(command["keySequence"],command["validInSec"])
		commandArray.append(tempVar)
	#inputAcceptance
	for inputAcceptance in inputAcceptances:
		var tempVar = MoveInputAcceptance.new(GetRange(inputAcceptance["range"]),inputAcceptance["rate"])
		inputAcceptancesArray.append(tempVar)
	#attacks
	for attack in attacks:
		var tempVar = AttackInfo.new(attack["phase"],attack["attack"],attack["forceDir"],GetMoveInfo(attack["pushPower"]),
		attack["hitStun"],attack["freeze"],attack["canHitSameTarget"],attack["hitSameTargetDelay"],GetActionChange(attack["selfActionChange"])
		,GetActionChange(attack["targetActionChange"]),attack["tempBeCancelledTagTurnOn"])
		attacksArray.append(tempVar)
	#attackPhase
	for attackPhase in attackPhases:
		var tempVar = AttackBoxTurnOnInfo.new(GetRangeArray(attackPhase["inPercentage"]),attackPhase["tag"],attackPhase["attackPhase"],attackPhase["attackPhase"])
		attackPhaseArray.append(tempVar)
	for defensePhase in defensePhases:
		var tempVar = BeHitBoxTurnOnInfo.new(GetRangeArray(defensePhase["inPercentage"]),defensePhase["tag"],defensePhase["priority"],defensePhase["tempBeCancelledTagTurnOn"],
		GetActionChange(defensePhase["attackerActionChange"]),GetActionChange(defensePhase["selfActionChange"]))
		defensePhaseArray.append(tempVar)
	
	#封装完成，赋值
	actionInfo.cancelTag = cancelTagArray
	actionInfo.beCancelledTag = beCancelledTagArray
	actionInfo.tempBeCancelledTag = tempBeCancelledTagArray
	actionInfo.commands = commandArray
	actionInfo.inputAcceptance = inputAcceptancesArray
	actionInfo.attacks = attacksArray
	actionInfo.attackPhase = attackPhaseArray
	actionInfo.defensePhase = defensePhaseArray
	actionInfo.rootMotionTween = GetScriptMethodInfo(rootMotionTween) #可能没有这玩意，前面的引用类型是必须的

#-----------以下是一些元类型获取-----
#获取一个vector2类表示范围
static func GetRange(data:Dictionary) ->Vector2:
	return Vector2(data["min"],data["max"])

static func GetRangeArray(data:Array) ->Array:
	var result:Array
	
	for _range in data:
		result.append(GetRange(_range))
	
	return result
	

static func GetMoveInfo(data:Dictionary) -> MoveInfo:
	var movedis:Vector2 = Vector2(data["moveDistance"]["x"],data["moveDistance"]["y"])
	return MoveInfo.new(movedis,data["inSec"],data["tweenMethod"])


static func GetActionChange(data:Dictionary)->ActionChangeInfo:
	return ActionChangeInfo.new(data["changeType"],data["param"],data["priority"],
	data.get("fromNormalized",0),data.get("transNormalized",0))

static func GetScriptMethodInfo(data:Dictionary)->ScriptMethodInfo:
	return ScriptMethodInfo.new(data.get("method",""),data.get("param",[]))
