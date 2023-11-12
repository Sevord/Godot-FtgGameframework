extends Area2D
class_name AttackHitBox

# 攻击盒
# 正确的做法：每个动作帧每个角色可能都会有若干攻击盒。
# 但是受限于Unity和UE之类的对于游戏的理解非常外行，所以给的框架不能很好的实现动作游戏
# 于是我们只能凑效果，就是在角色身上先绑定了攻击盒，然后在合适的时候开启或者关闭他们


#标签，可以被当做一种分类方式
#比如我们开启一些攻击盒的时候可以byTag，只要tags里面有指定的tag就算是符合条件了。
export(Array) var tags 



#这个框的主人，外部赋值给与
var Master


# 伤害倍率，这里的伤害倍率x动作的伤害倍率x角色的攻击力=伤害力，可以这么设计的，标准动作游戏里很常见。
# 【关键1】
# 伤害倍率本身只是一个例子，大多游戏其实是不做的，早期的MH有大剑头部、身体和剑柄伤害有差异
# 靠的就是不同的伤害倍率，后来觉得没意义就干掉了。
# 【关键2】
#除了伤害倍率之外，还可以有很多其他属性，根据游戏的具体需要去添加，这里只是一个范例。
# 比如我们有些攻击某些部位打中人才能令目标着火，着火比如是因为武器附魔了，那么那几个攻击盒算是“武器”呢？
#就可以在这里追加属性去实现，比如bool isEnchantment代表是否是一个附魔有效的攻击盒
export(float,0,1) var damageRate = 1



# 当同一帧有多个攻击盒命中了同一个角色的受击盒时，我们算是命中了，这点没错
# 但是有一个问题，到底应该算哪个攻击盒打中了对手呢？总得有个结论的，所以用Priority来进行冒泡
export(int) var basePriority


# 临时的优先级
var _tempPriority = 0;

#攻击盒当前的优先级
var Priority:int setget setPriority,getPriority
func setPriority(value):
	Priority = value
func getPriority():
	return _tempPriority + basePriority


# 当前是否开启了
var Active:bool

#帧循环，获取修改当前是否被激活
func _process(delta):
	Active = Master && Master.ShouldAttackBoxActive(tags);




func _on_AttackHitBox_entered(body:Node):
	#总是抓住每个盒子，至于那个盒子开不开，就交给CharacterObj判断
	var bhb:BeHitBox
	if (body.name == "BeHitBox"):
		bhb = body
	if (bhb && Master && bhb.Master != Master):
		Master.OnAttackBoxHit(self, bhb);


func _on_AttackHitBox_exited(body:Node):
	var bhb:BeHitBox
	if (body.name == "BeHitBox"):
		bhb = body
	if (bhb && Master && bhb.Master != Master):
		Master.OnAttackBoxExit(self, bhb);




