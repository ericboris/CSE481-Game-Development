package entities;

import flixel.math.FlxPoint;
import flixel.FlxObject;

// This is an invisible entity that is used to create "hitboxes" or invisible boundaries
// that another entity wants to test collisions on.
class Hitbox extends Entity
{
    var owner:Entity;
    var id:Int;

    var offsetUp:FlxPoint;
    var offsetDown:FlxPoint;
    var offsetLeft:FlxPoint;
    var offsetRight:FlxPoint;

    var active:Bool = true;
    var activeFrames:Int = -1;

    public function new(owner:Entity, id:Int)
    {
        super();

        this.type = EntityHitbox;

        this.owner = owner;
        this.id = id;

        this.sprite.visible = false;
 
        offsetUp = FlxPoint.weak();
        offsetDown = FlxPoint.weak();
        offsetLeft = FlxPoint.weak();
        offsetRight = FlxPoint.weak();
    }

    public override function update(elapsed:Float)
    {
        if (active && activeFrames > 0)
        {
            activeFrames--;
            if (activeFrames == 0)
            {
                active = false;
            }
        }

        // Center on owner's position
        var ownerSprite = owner.getSprite();
        var centerX = ownerSprite.x + ownerSprite.width / 2 - sprite.width / 2;
        var centerY = ownerSprite.y + ownerSprite.height / 2 - sprite.height / 2;

        var offset:FlxPoint;
        switch (ownerSprite.facing)
        {
            case FlxObject.UP:
                offset = offsetUp;
            case FlxObject.DOWN:
                offset = offsetDown;
            case FlxObject.LEFT:
                offset = offsetLeft;
            case FlxObject.RIGHT:
                offset = offsetRight;
            default:
                offset = FlxPoint.weak();
        }
        sprite.setPosition(centerX + offset.x, centerY + offset.y);
    }

    public function getId()
    {
        return id;
    }

    public override function handleCollision(entity:Entity)
    {
        if (active)
        {
            owner.notifyHitboxCollision(this, entity);
        }
    }

    public function setActive(active:Bool = true, frames:Int = -1)
    {
        this.active = active;
        this.activeFrames = frames;
    }

    // Set the offset for this hitbox, assuming the player is facing down.
    public function setOffset(x:Float, y:Float)
    {
        offsetUp = new FlxPoint(x, -y);
        offsetDown = new FlxPoint(x, y);
        offsetLeft = new FlxPoint(-y, x);
        offsetRight = new FlxPoint(y, x);
    }

    // Set this object's hitbox, relative to the player's center
    public function setSize(width:Float, height:Float)
    {
        this.sprite.setSize(width, height);
    }

}
