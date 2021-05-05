package entities;

import flixel.FlxState;
import flixel.FlxObject;
import flixel.math.FlxPoint;
import flixel.util.FlxPath;
import flixel.util.FlxColor;
import js.html.Console;

class Entity
{
    var sprite:SpriteWrapper<Entity>;
    var type:EntityType;

    // Hitboxes used by this entity.
    // Hitboxes are used by entities to do additional collision checks over other areas.
    var hitboxes:Array<Hitbox>;

    var seenEntities:Array<Entity>;

    var isJumpingCliff:Bool;
    var canJumpCliffs = true;

    public function new()
    {
        sprite = new SpriteWrapper<Entity>(this);
        hitboxes = new Array<Hitbox>();
        seenEntities = new Array<Entity>();
    }

    function setGraphic(width:Int, height:Int, dir:String, isAnimated:Bool)
    {
        sprite.loadGraphic(dir, isAnimated, width, height);
        sprite.setSize(width, height);
    }

    function setSprite(width:Int, height:Int, color:FlxColor)
    {
        sprite.makeGraphic(width, height, color);
        sprite.setSize(width, height);
    }

    public function update(elapsed:Float)
    {
        if (isJumpingCliff)
        {
            if (sprite.path.finished)
            {
                sprite.path = null;
                isJumpingCliff = false;
            }

            sprite.velocity.set(0,0);
        }

        // Update our sprite
        sprite.update(elapsed);

        // Delete all seen entities.
        // These will be refilled in during the following collision check cycle.
        seenEntities.resize(0);
    }

    public function addHitbox(hitbox:Hitbox)
    {
        // Add to hitboxes array
        hitboxes.push(hitbox);

        // Add hitbox entity to world
        PlayState.world.addEntity(hitbox, false);
    }

    public function handleCollision(entity:Entity)
    {
        switch (entity.type)
        {
            case EntityPlayer:
                handlePlayerCollision(cast entity);
            case EntityPrey:
                handlePreyCollision(cast entity);
            case EntityCave:
                handleCaveCollision(cast entity);
            case EntityPredator:
                handlePredatorCollision(cast entity);
            default:
        }
    }

    public function notifyHitboxCollision(hitbox:Hitbox, entity:Entity) {}

    public function handlePlayerCollision(player:Player) {}

    public function handlePreyCollision(prey:Prey) {}

    public function handleCaveCollision(cave:Cave) {}

    public function handlePredatorCollision(predator:Predator) {}

    /* Setters & Getters */
    public function setPosition(x:Float, y:Float)
    {
        sprite.setPosition(x, y);
    }

    public function getSprite()
    {
        return sprite;
    }

    public function getType()
    {
        return type;
    }

    public function handleCliffCollision(direction:Int)
    {
        if (!canJumpCliffs)
        {
            return;
        }

        var x = sprite.x;
        var y = sprite.y;
        switch (direction)
        {
            case FlxObject.UP:
                y -= 30;
            case FlxObject.DOWN:
                y += 30;
            case FlxObject.LEFT:
                x -= 30;
            case FlxObject.RIGHT:
                x += 30;
            default:
        }

        isJumpingCliff = true;
        sprite.path = new FlxPath();
        sprite.path.start([new FlxPoint(sprite.x, sprite.y), new FlxPoint(x, y)]);
    }

    public function getSightRange()
    {
        return 0.0;
    }

    public function getSightAngle()
    {
        return 0.0;
    }
 
    public function getNearbySightRadius()
    {
        return 0.0;
    }

    public function seen(entity: Entity)
    {
       seenEntities.push(entity);
    }
}
