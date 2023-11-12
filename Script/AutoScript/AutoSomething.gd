extends Node
#这个的单例放一些小巧的内部结构


#定义的有效按键对应的命令
enum KeyMap {
	Punch = 100, #拳
	Kick = 101, #脚
	Backward = 4, #左
	UpBackward = 7, #左上
	Up = 8, #上
	UpForward = 9, #右上
	Forward = 6, #右
	DuckForward = 3, #右下
	Duck = 2, #下
	DuckBackward = 1, #左下
	NoDirection = 0,    #没有输入方向
	NoInput = -1        #没有输入任何按钮
}



# 可以理解为力的方向，实际上是攻击的判定方向

enum ForceDirection{
	  #向前的
	#在我这个demo里面，说实话方向只有前后，这确实有些偷懒的，就是意思意思吧
	#根据动作游戏的具体设计不同，方向枚举自然是不同的。
	Forward,

	#向后的
	Backward,

	#虽然在demo用不上，但是不意打、锁骨割这些Overhead（特指站着攻击却不能蹲防的那些动作）
	#在头顶上
	Overhead,
}

#Action的变化类型
enum ActionChangeType {
	# 不发生变化
	Keep = 0,
	 #预约某个指定的ActionId的动画
	ChangeToActionId = 1,
	#根据Catalog来预约Action
	ChangeByCatalog = 2
}
