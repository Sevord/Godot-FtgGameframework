extends Node
#动作的RootMotion的移动函数
#参数1:float：当前动作进行到的百分比
#参数2:string[]：配置在ActionInfo表里actionInfo.rootMotionTween的param部分
#返回值：Vector3，偏移量，假设起始的时候坐标为zero，到normalized==参数float的时候，当时的偏移值
#基底的移动函数

var Methods:Dictionary = {
	"GoStraight":funcref(self,"GoStraightRootMotion"),
	"GoUpward":funcref(self,"GoUpward"),
	"":funcref(self,"NoRootMotion")
}

#直走
static func GoStraightRootMotion(pec:float, param:Array)->Vector2:
	
	var totalDis:float
	var startPec:float
	var endPec:float
	
	if (param.size() > 0): totalDis = float(param[0])
	else: totalDis = 0;
	
	if (param.size() > 1):startPec = float(param[1])
	else: startPec = 0;
	
	if (param.size() > 2):endPec = float(param[2])
	else:endPec = 1
	
	if (pec <= startPec):return Vector2.ZERO
	else:
		if (pec >= endPec): return Vector2(totalDis,0)
		else:return Vector2(pec * totalDis,0)


#向斜上方飞出去一段 二维的，两个参数
static func GoUpward(pec:float,param:Array):
	var x_Dis:float
	var y_Dis:float
	var startPec:float
	var endPec:float
	
	if (param.size() > 0): x_Dis = float(param[0])
	else: x_Dis = 0;
	
	if (param.size() > 1): y_Dis =  float(param[1])
	else:y_Dis = 0
	
	
	if (param.size() > 2):startPec = float(param[1])
	else: startPec = 0;
	
	if (param.size() > 3):endPec = float(param[2])
	else:endPec = 1
	
	if (pec <= startPec):return Vector2.ZERO
	else:
		if (pec >= endPec): return Vector2(x_Dis,y_Dis)
		else:return Vector2(pec * x_Dis,pec * y_Dis)
	


static func NoRootMotion()->Vector2:
	return Vector2.ZERO
