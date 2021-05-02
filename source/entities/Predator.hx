package entities;

import js.html.Console;
import flixel.FlxObject;

class Predator extends Dino
{
	public function new()
	{
		super();

		this.type = EntityPredator;

        setGraphic(16, 16, AssetPaths.boss__png, true);

        sprite.setFacingFlip(FlxObject.LEFT, false, false);
        sprite.setFacingFlip(FlxObject.RIGHT, true, false);

        sprite.animation.add("lr", [0], 0, false);
        //sprite.animation.add("u", [6, 7, 6, 8], 6, false);
        //sprite.animation.add("d", [0, 1, 0, 2], 6, false);

        sprite.screenCenter();

        sprite.setSize(8, 8);
	}

	public override function update(elapsed:Float)
	{
		super.update(elapsed);
	}

    private override function unherded(elapsed:Float)
    {
        idle(elapsed);
    }
}
