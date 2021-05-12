package entities;

import flixel.FlxState;
import flixel.FlxObject;
import flixel.math.FlxPoint;
import flixel.util.FlxPath;
import flixel.util.FlxColor;
import js.html.Console;
import flixel.math.FlxMath;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;

class Entity
{
    private var SIGHT_ANGLE:Float = 0.0;
    private var SIGHT_RANGE:Float = 0;
    private var NEARBY_SIGHT_RADIUS:Float = 0.0;

    var sprite:SpriteWrapper<Entity>;
    var type:EntityType;

    // Hitboxes used by this entity.
    // Hitboxes are used by entities to do additional collision checks over other areas.
    var hitboxes:Array<Hitbox>;

    var seenEntities:Array<Entity>;

    var isJumpingCliff:Bool;
    var canJumpCliffs = true;

    var thought:Icon;

    var isFadingOut:Bool = false;

    public function new()
    {
        sprite = new SpriteWrapper<Entity>(this);
        hitboxes = new Array<Hitbox>();
        seenEntities = new Array<Entity>();
        
        thought = new Icon(this, 0, -18);
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
        if (isFadingOut)
        {
            sprite.alpha -= 0.05;
            if (sprite.alpha <= 0)
            {
                PlayState.world.removeEntity(this);
                return;
            }
        }

        if (isJumpingCliff)
        {
            sprite.velocity.set(0,0);
        }


        // Update our sprite
        //sprite.update(elapsed);

        thought.update(elapsed);

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
            case EntityBoulder:
                handleBoulderCollision(cast entity);
            case EntityItem:
                handleGroundItemCollision(cast entity);
            default:
        }
    }

    public function notifyHitboxCollision(hitbox:Hitbox, entity:Entity) {}
    public function handlePlayerCollision(player:Player) {}
    public function handlePreyCollision(prey:Prey) {}
    public function handleCaveCollision(cave:Cave) {}
    public function handlePredatorCollision(predator:Predator) {}
    public function handleBoulderCollision(boulder:Boulder) {}
    public function handleGroundItemCollision(item:GroundItem) {}

    /* Setters & Getters */
    public function setPosition(x:Float, y:Float)
    {
        sprite.setPosition(x + sprite.width/2, y + sprite.height/2);
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
        if (!canJumpCliffs || isJumpingCliff)
        {
            return;
        }

        var jumpDist = 32;

        var start = new FlxPoint(sprite.x, sprite.y);
        var end = new FlxPoint(sprite.x, sprite.y);
        switch (direction)
        {
            case FlxObject.UP:
                end.y -= jumpDist;
            case FlxObject.DOWN:
                end.y += jumpDist;
            case FlxObject.LEFT:
                end.x -= jumpDist;
            case FlxObject.RIGHT:
                end.x += jumpDist;
            default:
        }

        // Check if sprite will land on a tile if they jump
        sprite.x = end.x;
        sprite.y = end.y;
        var colliding = GameWorld.collidingWithObstacles(this);
        sprite.x = start.x;
        sprite.y = start.y;

        if (colliding)
        {
            // Don't jump off cliff if we're jumping into an obstacle.
            return;
        }

        var control = new FlxPoint((end.x + start.x) / 2, (end.y + start.y) / 2);
        if (end.x - start.x != 0)
            control.y -= 20;
        if (end.y - start.y != 0)
            control.x += 10;
        
        var duration = 0.4;
        var options = {ease: FlxEase.sineInOut, type: ONESHOT, onComplete: function(tween:FlxTween)
        {
            sprite.allowCollisions = FlxObject.ANY;
            isJumpingCliff = false;
        }};
        FlxTween.quadPath(this.sprite, [start, control, end], duration, true, options);
        sprite.velocity.x = 0;
        sprite.velocity.y = 0;
        isJumpingCliff = true;
        sprite.allowCollisions = FlxObject.NONE;
    }

    public function getSightRange():Float
    {
        return this.SIGHT_RANGE;
    }

    public function getSightAngle():Float
    {
        return this.SIGHT_ANGLE;
    }

    public function getNearbySightRadius():Float
    {
        return this.NEARBY_SIGHT_RADIUS;
    }

    public function seen(entity: Entity)
    {
       seenEntities.push(entity);
    }

    public function getVelocityX():Float
    {
        return this.sprite.velocity.x;
    }

    public function getVelocityY():Float
    {
        return this.sprite.velocity.y;
    }

    public function getX()
    {
        return this.sprite.getMidpoint().x;
    }
    
    public function getY()
    {
        return this.sprite.getMidpoint().y;
    }

    public function think(content:String, fadeOutDelay:Float=2.5):Void
    {
        if (content == "V")
        {
            thought.appear(fadeOutDelay + 1.0);
        }
        else
        {
            thought.setContent(content, fadeOutDelay);
        }
    }

    public function getThought():Icon
    {
        return thought;
    }

    public function fadeOutAndRemove()
    {
        isFadingOut = true;
    }
}
