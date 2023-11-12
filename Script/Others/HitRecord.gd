extends Reference
class_name HitRecord
#命中信息记录


#打中的目标是谁
var UniqueId:int

#这是第几段伤害
var Phase:int = 0

#还能打中他几次
var CanHitTimes:int = 0

# 冷却多久以后才能继续打他
var Cooldown:float = 0

# [0]cha:CharacterObj
func _init(cha,phase:int,canHitTimes:int,cooldown:float):
	self.UniqueId = cha.get_instance_id()
	self.Phase = phase
	self.CanHitTimes = CanHitTimes
	self.Cooldown = cooldown

#递减冷却
func Update(delta):
	 if (Cooldown > 0):Cooldown = max(0, Cooldown - delta)



