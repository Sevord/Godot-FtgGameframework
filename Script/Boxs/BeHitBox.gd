extends Area2D
class_name BeHitBox

#受击盒
#正确的做法：每个动作帧每个角色可能都会有若干受击盒。
#但是受限于Unity和UE之类的对于游戏的理解非常外行，所以给的框架不能很好的实现动作游戏
#于是我们只能凑效果，就是在角色身上先绑定了受击盒，然后在合适的时候开启或者关闭他们


# 标签，可以被当做一种分类方式
# 比如我们开启一些受击盒的时候可以byTag，只要tags里面有指定的tag就算是符合条件了。
export(Array) var tags



# 肉质，就是MH里面的那个肉质，打在这个部位掉血的伤害值x这个数字等于伤害量，所以越大代表越软。
# 【关键1】
# 如果是MH这样复杂的游戏，肉质本身是一个struct，里面包含了斩击、打击等数据，这里就简化为一个float了
# 【关键2】
# 除了肉质之外，还可以有很多其他属性，根据游戏的具体需要去添加，这里只是一个范例。
# 比如我们需要某个受击盒对应一个角色部位，打中这个盒子，部位耐久度下降，最后部位还会被破坏，也应该在受击盒提供对应信息。
export(float,0,1) var meat  = 1


	

# 这个框的主人，外部赋值给予
var Master


#当同一帧有多个攻击盒命中了同一个角色的受击盒时，我们算是命中了，这点没错
# 但是有一个问题，到底应该算哪个攻击盒打中了对手呢？总得有个结论的，所以用Priority来进行冒泡
export(int) var basePriority 



#临时的优先级

var _tempPriority:int = 0;

# 受击盒当前的优先级
var Priority:int setget setPriority,getPriority
func setPriority(value):
	Priority = value
func getPriority():
	return _tempPriority + basePriority

	

#当前是否开启了
var Active:bool 

func _process(delta):
	Active = Master && Master.ShouldBeHitBoxActive(tags);




# 是否有一个tag在checkTags里面
func TagHit(checkTags:Array)->bool:
	for t in tags:
		if (checkTags.has((t))):
			return true
	return false


#手写推移效果
func _on_BeHitBox_area_entered(body):
	#获取到目标
	var Chara
	if (body.name == "BeHitBox"):
		Chara = body.Master
	
	if (Chara != null && Chara.Falling == false):
		#设置反方向 自身方向 向前？
		var moveInfo:MoveInfo
		
		var disVec:Vector2 = (Master.position - Chara.position)
		#反向的
		if disVec.x < 0:
			moveInfo = MoveInfo.new(Vector2(50,0),0.5,"Slowly")
		#正向的
		else:
			moveInfo = MoveInfo.new(Vector2(-50,0),0.5,"Slowly")
		#设置强制移动力
		Chara.SetForceMove(moveInfo)
	
	
