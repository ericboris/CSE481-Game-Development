package;

import flixel.FlxG;
import flixel.FlxState;
import flixel.group.FlxGroup;
import js.html.Console;

class PlayState extends FlxState
{
	// In world entities
	var player:Player;
	var prey:Array<Prey>;

	// FlxSprite groups
	var preySprites:FlxGroup;

	override public function create()
	{
		super.create();

		player = new Player();
		add(player.sprite);

		preySprites = new FlxGroup();
		prey = new Array<Prey>();
		for (i in 0...6)
		{
			var dino = new Prey();
			dino.sprite.setPosition(Math.random() * FlxG.width, Math.random() * FlxG.height);
			preySprites.add(dino.sprite);
			add(dino.sprite);
			prey.push(dino);
		}
	}

	override public function update(elapsed:Float)
	{
		// Update all entities
		player.update(elapsed);
		for (p in prey)
		{
			p.update(elapsed);
		}

		// Do collision checks
		collisionChecks();

		super.update(elapsed);
	}

	function collisionChecks()
	{
		// Collision resolution -- notify entities
		FlxG.overlap(player.sprite, preySprites, handlePlayerPreyCollision);

		// Collision resolution -- physics
		FlxG.collide(player.sprite, preySprites);
		FlxG.collide(preySprites, preySprites);
	}

	/* --------------------------
		Collision handler methods
		------------------------- */
	function handlePlayerPreyCollision(e1:SpriteWrapper<Player>, e2:SpriteWrapper<Prey>)
	{
		var player = e1.entity;
		var prey = e2.entity;

		player.handlePreyCollision(prey);
		prey.handlePlayerCollision(player);
	}
}
