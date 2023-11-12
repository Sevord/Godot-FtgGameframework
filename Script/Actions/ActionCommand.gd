extends Reference
class_name ActionCommand



#按键顺序,是Auto单例里的 Keycode ,其实就是整型数组
var keySequence:Array

# 检查的按键最远的一次操作距离现在的最远时间（秒）
var validInSec:float

func _init(keySequence:Array,validInSec:float = 0):
	self.keySequence = keySequence
	self.validInSec = validInSec
