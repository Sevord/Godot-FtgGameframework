extends Control

onready var HpBar = $HpBar
onready var CostBar = $CostBar


#修改自身数据
func OnDamage(hpValue:float,costValue:float):
	self.HpBar.value = hpValue
	self.CostBar.value = costValue
