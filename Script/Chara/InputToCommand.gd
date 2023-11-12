extends Node
class_name InputToCommand 
#将输入翻译成命令


 
# 保持一个按键的存在时间最多这么多秒，太早的就释放掉了
const RecordKeepTime:float = 0.5


# 是否接受手柄输入，这个当然可以不是bool，而是接受几号手柄输入
# 这个demo里就用bool区分接受还是不接受
export(bool) var controller


#当前的按键记录,内装私有类 - KeyInputRecord
var _input:Array 
#最新的输入，如果是检查0的话，就会检查这个.私有类  KeyInputRecord
var _newInputs:Array


# 是否是反向的，正向的代表面向右侧
var inversed:bool = false;


# 现在的时间戳
var _timeStamp:float = 0;

# 非方向输入得有个cd，不然频率太高影响连招手感
# 如果没有这个，非常容易出现“全自动连续攻击”，如果攻击派生动作的按键一样的话
const NonDirectionInputCooldown:float = 0.05

var _nonDirectCooldown:float = 0;
	

#值得注意的是：
# 好的输入是会判断up和down的，这样才能得出是tap还是holding
# 但是操作并不是这个demo主要表现的内容，所以我就偷了个懒
# 其实也不是没有动作游戏采取这种“Turbo输入”的
# 没有holding和tap，用这种"Turbo输入"的结果就是一些手感会变差，比如移动，还有蓄力，但不是做不了，得凑


func _process(delta):
	var dt:float = delta
		#开始去掉已经过期的操作记录
	var index:int = 0
	#遍历上次输入和当前输入的关系，移除超时的部分
	while (index < _input.size()):
		#等于的时候还是保留一下，其实无所谓，就那么1帧的差别
		if (_timeStamp - _input[index].TimeStamp > RecordKeepTime):
			_input.remove(index)
		else:
			index += 1
#最新输入刷新了,移除旧输入
	_newInputs.clear()

	if (controller):
		var noKey:bool = true
		#加入新的输入,填进去
		if (_nonDirectCooldown <= 0):
			if (Input.is_action_pressed("Punch")):
				AddInput(AutoSomething.KeyMap.Punch)
				noKey = false
			
			if (Input.is_action_pressed("Kick")):
				AddInput(AutoSomething.KeyMap.Kick);
				noKey = false

			if (!noKey):
				_nonDirectCooldown = NonDirectionInputCooldown;
				
		else:
			_nonDirectCooldown -= dt;
		
		#获取输入
		var xInput:float = Input.get_axis("Left","Right")
		
		var yInput:float = Input.get_axis("Up","Down")
		var deadArea:float = 0.2#死区值
		
		
		var xHasInput:bool = (abs(xInput) >= deadArea)
		var yHasInput = (abs(yInput) >= deadArea)
		var noDir:bool = (!xHasInput && !yHasInput)
	
		#上下左右4个方向,根据水平位置确定四个方向的bool标志
		var dirDown:Array =  [false, false, false, false]
		if (xHasInput):
			if (xInput > 0):
				dirDown[3] = true
			else:
				dirDown[2] = true

		if (yHasInput):
			if (yInput < 0):
				dirDown[0] = true
			else:
				dirDown[1] = true

		#这里不能else，因为可能同一帧有8个方向的输入的，但是unity和ue的input都自作聪明的屏蔽了……
		#尽管他们有问题，但我们不能有问题
		#直接枚举出八个方向然后进行 添加Input输入
		if (dirDown[0]):AddInput(AutoSomething.KeyMap.Up);
		if (dirDown[1]):AddInput(AutoSomething.KeyMap.Duck);
		if (dirDown[2]):AddInput(AutoSomething.KeyMap.Backward);
		if (dirDown[3]):AddInput(AutoSomething.KeyMap.Forward);
		if (dirDown[0] && dirDown[2]):AddInput(AutoSomething.KeyMap.UpBackward);
		if (dirDown[1] && dirDown[2]):AddInput(AutoSomething.KeyMap.DuckBackward);
		if (dirDown[0] && dirDown[3]):AddInput(AutoSomething.KeyMap.UpForward);
		if (dirDown[1] && dirDown[3]):AddInput(AutoSomething.KeyMap.DuckForward);
	
		#最后看是否要加入没有操作的操作
		if (noDir):
			if(noKey):
				AddInput(AutoSomething.KeyMap.NoInput)
			else:
				AddInput(AutoSomething.KeyMap.NoDirection)
	#计数器
	_timeStamp += delta;


#添加一个输入
func AddInput(key):
	var kir:KeyInputRecord = KeyInputRecord.new(key, _timeStamp);
	_input.append(kir);
	_newInputs.append(kir);



#指定的操作是否存在于记录中
func ActionOccur(action:ActionCommand)->bool:
	#这里的顺序非常重要，所以一定要for而不能foreach，尽管C#尽可能保证了顺序执行，但谁知道呢？
	
	var lastStamp:float = _timeStamp - max(action.validInSec,0.02);   #最小就是上1帧
	
	for i in range(0,action.keySequence.size()):
		var idx:int = 0
		var found:bool = false
		#之所以这里不能记录上一次的j，把上一次的j作为j的起点，是因为同一帧会有若干输入
		#他们的排序是不稳定的，但是他们的先后顺序应该都是相等的，比如同一帧输入了前a，那么它既可以是前→a，也可以是a→前。
		#所以我们宁可牺牲一些性能，也要追求精准
		for j in range(0,_input.size()):
			if (_input[j].TimeStamp >= lastStamp && GetKeyInput(_input[j].Key) == action.keySequence[i]):
				found = true;
				lastStamp = _input[j].TimeStamp;
				break;
			
		if (found):continue;
		#特殊处理最后一个，最后一个可以检查_newInput里面获取
		#这是一个策划配表和Update之间的妥协，如果是帧作为单位就不会有问题，但是update……
		#策划作为地球人，可不知道delta是多少，每台电脑的delta都不一样，所以只能做这个补丁
		#当然也可以做成如果检查时间都不符合的情况下，所有的指令都看new，着看你需要咋样的手感了
		#我这里就用最后一个键可以访问new的
		if (i == action.keySequence.size() - 1):
			for j in range(0,_newInputs.size()):
				if (GetKeyInput(_newInputs[j].Key) == action.keySequence[i]):
					found = true;
					lastStamp = _newInputs[j].TimeStamp;
					break;
		if (found):continue
		#有一个输入没找到，那自然就结束了
		return false   
	return true   #肯定找到了才会到这里



# 根据origin和inversed得出实际上输入是什么
# 我们毕竟有左右方向正反手搓招的
func GetKeyInput(origin):
	if (!inversed):return origin;
	match origin:
		AutoSomething.KeyMap.Backward: 
			return AutoSomething.KeyMap.Forward
		AutoSomething.KeyMap.Forward: 
			return AutoSomething.KeyMap.Backward;
		AutoSomething.KeyMap.DuckBackward: 
			return AutoSomething.KeyMap.DuckForward;
		AutoSomething.KeyMap.DuckForward: 
			return AutoSomething.KeyMap.DuckBackward;
		AutoSomething.KeyMap.UpBackward: 
			return AutoSomething.KeyMap.UpForward;
		AutoSomething.KeyMap.UpForward: 
			return AutoSomething.KeyMap.UpBackward;
	return origin;


# 获得输入列表所组成的文字
func InputText()->String:
	var res:String = "输入：\n"
	var pCount:Dictionary = {
		AutoSomething.KeyMap.Punch:0,
		AutoSomething.KeyMap.Kick:0,
		AutoSomething.KeyMap.Up:0,
		AutoSomething.KeyMap.UpForward:0,
		AutoSomething.KeyMap.Forward:0,
		AutoSomething.KeyMap.DuckForward:0,
		AutoSomething.KeyMap.Duck:0,
		AutoSomething.KeyMap.DuckBackward:0,
		AutoSomething.KeyMap.Backward:0,
		AutoSomething.KeyMap.UpBackward:0,
}
	for i in range(0,_input.size()):
		if ((_input[i].Key) in pCount.keys()):
			pCount[_input[i].Key] += 1
	
	#foreach (KeyValuePair<KeyMap,int> pair in pCount)
	for key in pCount.keys():
		var keyText:String = "";
		match (key):
			AutoSomething.KeyMap.Punch: 
				keyText = "【拳】"
				
			AutoSomething.KeyMap.Kick: 
				keyText = "【脚】"
				
			AutoSomething.KeyMap.Backward: 
				keyText = "【←】"
				
			AutoSomething.KeyMap.UpBackward:
				keyText = "【↖】"
				
			AutoSomething.KeyMap.Up:
				keyText = "【↑】"
				
			AutoSomething.KeyMap.UpForward:
				keyText = "【↗】"
				
			AutoSomething.KeyMap.Forward:
				keyText = "【→】"
				
			AutoSomething.KeyMap.DuckForward:
				keyText = "【↘】"
				
			AutoSomething.KeyMap.Duck: 
				keyText = "【↓】"
				
			AutoSomething.KeyMap.DuckBackward:
				keyText = "【↙】"
				
		
		#遍历以确定是否有新输入，只有在有新输入的情况下才会改字
		var hasNew:bool = false
		for record in _newInputs:
			if (record.Key == key):
				hasNew = true
				break
		
		res += keyText + " x " +  String(pCount[key]) + " 次"
		if (hasNew): res += "[新输入]" 
		else: res += ""
		res += "\n"
	return res



#删除所有的非方向输入，在变化动作的时候删除
func CleanNonDirectionInputs()->void:
	var index:int = 0
	while (index < _input.size()):
		if (!IsDirectionInput(_input[index].Key)):_input.remove(index)
		else:index += 1
		
	index = 0
	while (index < _newInputs.size()):
		if (!IsDirectionInput(_newInputs[index].Key)):_newInputs.remove(index);
		else:index += 1
	_nonDirectCooldown = NonDirectionInputCooldown



# 一个输入是否是方向输入
func IsDirectionInput(key)->bool:
	
	var keys:Array = [
		AutoSomething.KeyMap.Backward,
		AutoSomething.KeyMap.UpBackward,
		AutoSomething.KeyMap.Up,
		AutoSomething.KeyMap.UpForward,
		AutoSomething.KeyMap.Forward,
		AutoSomething.KeyMap.DuckForward,
		AutoSomething.KeyMap.Duck,
		AutoSomething.KeyMap.DuckBackward,
		AutoSomething.KeyMap.NoDirection  ] #这个也会出现在搓招操作，所以得算方向
	return keys.has(key)


# 按键记录，放在序列中的

class KeyInputRecord:
	# 按下的时间记录
	var TimeStamp:float

	# 按下的键
	var Key
	
	func _init(key,timeStamp:float):
		self.TimeStamp = timeStamp
		self.Key = key

