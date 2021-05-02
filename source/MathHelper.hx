package;

import flixel.math.FlxPoint;
import flixel.math.FlxRandom;

class MathHelper
{
	static public function radians(degrees:Int)
	{
		return degrees * Math.PI / 180.0;
	}

	static public function magnitude(vector:FlxPoint)
	{
		return GameWorld.distance(0, 0, vector.x, vector.y);
	}

	static public function random(min:Float, max:Float)
	{
		return Math.random() * (max - min) + min;
		// return Math.random().
	}
}
