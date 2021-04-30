package entities;

import flixel.FlxState;
import flixel.util.FlxColor;

class Entity
{
	var sprite:SpriteWrapper<Entity>;
	var type:EntityType;

	// Hitboxes used by this entity.
	// Hitboxes are used by entities to do additional collision checks over other areas.
	var hitboxes:Array<Hitbox>;

	public function new()
	{
		sprite = new SpriteWrapper<Entity>(this);
		hitboxes = new Array<Hitbox>();
	}

	function setSprite(width:Int, height:Int, color:FlxColor)
	{
		sprite.makeGraphic(width, height, color);
		sprite.setSize(width, height);
	}

	public function update(elapsed:Float)
	{
		// Update our sprite
		sprite.update(elapsed);
	}

	public function addHitbox(hitbox:Hitbox)
	{
		// Add to hitboxes array
		hitboxes.push(hitbox);

		// Add hitbox entity to world
		PlayState.world.addEntity(hitbox, false);
	}

	public function handleCollision(entity:Entity)
	{
		switch (entity.type)
		{
			case EntityPlayer:
				handlePlayerCollision(cast entity);
			case EntityPrey:
				handlePreyCollision(cast entity);
			case EntityCave:
				handleCaveCollision(cast entity);
			default:
		}
	}

	public function notifyHitboxCollision(hitbox:Hitbox, entity:Entity) {}

	public function handlePlayerCollision(player:Player) {}

	public function handlePreyCollision(prey:Prey) {}

	public function handleCaveCollision(cave:Cave) {}

	/* Setters & Getters */
	public function setPosition(x:Float, y:Float)
	{
		sprite.setPosition(x, y);
	}

	public function getSprite()
	{
		return sprite;
	}

	public function getType()
	{
		return type;
	}
}
