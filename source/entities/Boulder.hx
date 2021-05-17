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
    static var PUSH_SPEED = 0.45;

    var isInWater:Bool = false;
    // The tile of water that the boulder is being pushed into.
    var tileIndex:Int;

    var splashSound:FlxSound;

    var facingCliff:Int = 0;

    public function new()
    {
        super();

        if (PlayState.DEBUG_FAST_SPEED)
        {
            PUSH_SPEED = 1.0;
        }

        setGraphic(16, 16, AssetPaths.boulder__png, false);

        this.sprite.immovable = true;
        this.type = EntityBoulder;
        this.canJumpCliffs = true;

        this.thought.setSprite(16, 16, AssetPaths.down_arrow__png);

        this.splashSound = FlxG.sound.load(AssetPaths.splash__mp3, 1.0);
    }

    public function isCollidable():Bool
    {
        return !isInWater;
    }

    public function setFacingCliff(dir: Int)
    {
        this.facingCliff = dir;
    }

    public function push(entity:Entity, direction:Int)
    {
        if (isInWater)
        {
            // Player doesn't interact with boulder once it's in the water.
            return;
        }

        if (facingCliff != 0)
        {
            // The player is trying to jump on this boulder onto the cliff!

            var shouldJump = false;
            var diffY = entity.getY() - getY();
            var diffX = entity.getX() - getX();

            var jumpDist = 6;
            var jumpX = 0;
            var jumpY = 0;
            var secondJumpMultiplier = 6;
            switch (facingCliff)
            {
                case FlxObject.UP:
                    jumpY = -jumpDist * 2;
                    secondJumpMultiplier = 3;
                    shouldJump = diffY > 0 && Math.abs(diffY) > Math.abs(diffX);
                case FlxObject.DOWN:
                    jumpY = jumpDist;
                    shouldJump = diffY < 0 && Math.abs(diffY) > Math.abs(diffX);
                case FlxObject.LEFT:
                    jumpX = -jumpDist;
                    shouldJump = diffX < 0 && Math.abs(diffY) < Math.abs(diffX);
                case FlxObject.RIGHT:
                    jumpX = jumpDist;
                    shouldJump = diffX > 0 && Math.abs(diffY) < Math.abs(diffX);
            }

            if (shouldJump)
            {
                var secondJump = function (entity:Entity)
                {
                    entity.nextJump = new FlxPoint(entity.getTopLeftX() + jumpX * secondJumpMultiplier,
                                                   entity.getTopLeftY() + jumpY * secondJumpMultiplier);
                }
                entity.jumpTo(entity.getTopLeftX() + jumpX, entity.getTopLeftY() + jumpY, false, secondJump);
            }
        }

        this.facingCliff = 0;

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

            if (control.x - end.x != 0)
                control.y -= 10;
            if (start.y - end.y != 0)
                control.x += 7;

            var duration = 1.0;
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
