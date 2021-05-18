package entities;

import flixel.FlxG;
import flixel.FlxObject;
import js.html.Console;

class BerryBush extends Obstacle
{
    var isEmpty:Bool = false;
    public function new()
    {
        super();
        this.sprite.loadGraphic(AssetPaths.berry_bush__png, 16, 16, false);
        sprite.immovable = true;

        setHitboxSize(4, 4);

        this.type = EntityBerryBush;
    }

    public function swipe()
    {
        if (!isEmpty)
        {
            isEmpty = true;
            
            // Set graphic to empty bush
            this.sprite.loadGraphic(AssetPaths.empty_bush__png, 16, 16, false);
            setHitboxSize(4, 4);

            // Spawn berry
            var berry = new Berry();
            var sprite = berry.getSprite();
            PlayState.world.addEntity(berry);
            berry.setPosition(getX() - sprite.frameWidth / 2, getY() - sprite.frameHeight / 2);

            // Choose random destination coordiantes
            for (i in 0...20)
            {
                var x = berry.getX() + FlxG.random.float(-20, 20);
                var y = berry.getY() + FlxG.random.float(-20, 20);
                if (berry.jumpTo(x, y, true, null, 80.0))
                {
                    break;
                }
            }
        }
    }
}
