package entities;

import flixel.FlxState;
import flixel.util.FlxColor;

class Entity
{
	public var sprite:SpriteWrapper<Entity>;
	public var type:EntityType;

	public function new()
	{
		sprite = new SpriteWrapper<Entity>(this);
	}

	function setSprite(width:Int, height:Int, color:FlxColor)
	{
		sprite.makeGraphic(width, height, color);
		sprite.setSize(width, height);
	}

	public function update(elapsed:Float)
	{
		sprite.update(elapsed);
	}

	public function handlePlayerCollision(player:Player) {}

	public function handlePreyCollision(prey:Prey) {}
}
