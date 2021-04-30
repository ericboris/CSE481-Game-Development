package entities;

import flixel.util.FlxColor;

class Obstacle extends Entity
{
	public function new(width:Int, height:Int, color:FlxColor)
	{
		super();

		this.type = EntityObstacle;

		this.setSprite(width, height, color);
		this.sprite.immovable = true;
	}

	override public function update(elapsed:Float) {}
}
