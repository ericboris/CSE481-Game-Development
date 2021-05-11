package entities;

import flixel.FlxObject;
import flixel.FlxG;
import js.html.Console;
import flixel.util.FlxPath;
import flixel.system.FlxSound;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.math.FlxPoint;
import flixel.math.FlxMath;

class Boulder extends Entity
{
    final PUSH_SPEED = 0.4;

    var isInWater:Bool = false;
    // The tile of water that the boulder is being pushed into.
    var tileIndex:Int;

    var splashSound:FlxSound;

    public function new()
    {
        super();

        setGraphic(16, 16, AssetPaths.boulder__png, false);

        this.sprite.immovable = true;
        this.type = EntityBoulder;
        this.sprite.mass = 1000;

        this.thought.setSprite(16, 16, AssetPaths.down_arrow__png);

        this.splashSound = FlxG.sound.load(AssetPaths.splash__mp3, 1.0);
    }

    public function isCollidable():Bool
    {
        return !isInWater;
    }

    public function push(direction:Int)
    {
        if (isInWater)
        {
            // Player doesn't interact with boulder once it's in the water.
            return;
        }

        var prevX = this.sprite.x;
        var prevY = this.sprite.y;
        switch (direction)
        {
            case FlxObject.UP:
                this.sprite.y -= PUSH_SPEED;
            case FlxObject.DOWN:
                this.sprite.y += PUSH_SPEED;
            case FlxObject.RIGHT:
                this.sprite.x += PUSH_SPEED;
            case FlxObject.LEFT:
                this.sprite.x -= PUSH_SPEED;
            default:
        }

        if (GameWorld.collidingWithObstacles(this))
        {
            this.sprite.x = prevX;
            this.sprite.y = prevY;
        }
    }

    public function goIntoWater(x: Float, y: Float, tileIndex:Int)
    {
        if (!isInWater)
        {
            // TODO animate path
            this.tileIndex = tileIndex;

            var start = new FlxPoint(sprite.x, sprite.y);
            var end = new FlxPoint(x, y);
            
            var control = new FlxPoint((end.x + start.x) / 2, (end.y + start.y) / 2);
            control.x -= FlxMath.signOf(start.y - end.y) * 8;
            control.y += FlxMath.signOf(start.x - end.x) * 8;
            
            var duration = 0.8;
            var options = {ease: FlxEase.quadInOut, type: ONESHOT, onComplete:inWater};
            FlxTween.quadPath(this.sprite, [start, control, end], duration, true, options);
            isInWater = true;
        }
    }

    public function inWater(tween:FlxTween)
    {
        splashSound.play();

        this.fadeOutAndRemove();

        // TODO: Set adjacent tile to no collisions, if it's a ridge in the correct orientation
        // This is currently done in CollisionHandler.
        var tilemap = PlayState.world.getObstacles();
        tilemap.setTileByIndex(tileIndex, TileType.WATER_NC, true);
    }
}
