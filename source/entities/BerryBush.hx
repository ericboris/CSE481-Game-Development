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
            var playerX = PlayState.world.getPlayer().getX();
            var playerY = PlayState.world.getPlayer().getY();
            berry.setPosition(getX(), getY());

            // Choose random destination coordiantes
            // var x = berry.sprite.x + FlxG.random.float(-12, 12);
            // var y = berry.sprite.y + FlxG.random.float(-12, 12);
            berry.jumpTo(playerX, playerY, false, null, 80.0);
        }
    }
}
