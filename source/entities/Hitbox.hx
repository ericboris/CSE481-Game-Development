package entities;

// This is an invisible entity that is used to create "hitboxes" or invisible boundaries
// that another entity wants to test collisions on.
class Hitbox extends Entity
{
    var owner:Entity;
    var id:Int;

    var offsetX:Float = 0;
    var offsetY:Float = 0;

    var active:Bool = true;
    var activeFrames:Int = -1;

    public function new(owner:Entity, id:Int)
    {
        super();

        this.type = EntityHitbox;

        this.owner = owner;
        this.id = id;

        this.sprite.visible = false;
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
        sprite.setPosition(centerX + offsetX, centerY + offsetY);
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

    public function setOffset(x:Float, y:Float)
    {
        offsetX = x;
        offsetY = y;
    }

    // Set this object's hitbox, relative to the player's center
    public function setSize(width:Float, height:Float)
    {
        this.sprite.setSize(width, height);
    }

}
