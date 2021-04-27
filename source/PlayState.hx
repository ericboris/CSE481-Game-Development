package;

import flixel.FlxG;
import flixel.FlxState;
import flixel.group.FlxGroup;

class PlayState extends FlxState
{
	var player:Player;
	var dinos:Array<Dino>;

	var dinoSprites:FlxGroup;

	override public function create()
	{
		super.create();

		player = new Player();
		player.addToWorld(this);

		dinoSprites = new FlxGroup();
		dinos = new Array<Dino>();
		for (i in 0...6)
		{
			var dino = new Dino();
			dino.sprite.setPosition(Math.random() * FlxG.width, Math.random() * FlxG.height);
			dinoSprites.add(dino.sprite);
			dino.addToWorld(this);
			dinos.push(dino);
		}
	}

	override public function update(elapsed:Float)
	{
		player.update(elapsed);
		for (dino in dinos)
		{
			dino.update(elapsed);
			if (FlxG.overlap(player.sprite, dino.sprite) && dino.state == Roaming)
			{
				// Player is touching this dino! Set it to be following the player.
				player.addDino(dino);
			}
		}

		// Collision resolution
		FlxG.collide(player.sprite, dinoSprites);
		FlxG.collide(dinoSprites, dinoSprites);

		super.update(elapsed);
	}
}
