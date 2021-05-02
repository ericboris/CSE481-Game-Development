package entities;

// This is an invisible entity that is used to create "hitboxes" or invisible boundaries
// that another entity wants to test collisions on.
class Hitbox extends Entity
{
    var owner:Entity;
    var id:Int;

    var offsetX:Float;
    var offsetY:Float;

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
        // Center on owner's position
        var ownerSprite = owner.getSprite();
        var centerX = ownerSprite.x + ownerSprite.width / 2 - sprite.width / 2;
        var centerY = ownerSprite.y + ownerSprite.height / 2 - sprite.height / 2;
        sprite.setPosition(centerX + offsetX, centerY + offsetY);

        super.update(elapsed);
    }

    public function getId()
    {
        return id;
    }

    public override function handleCollision(entity:Entity)
    {
        owner.notifyHitboxCollision(this, entity);
    }

    public function setOffset(x:Float, y:Float)
    {
        offsetX = x;
        offsetY = y;
    }
}
