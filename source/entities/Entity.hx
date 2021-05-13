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

    var isJumping:Bool;
    var canJumpCliffs = true;

    var thought:Icon;

    var isFadingOut:Bool = false;

    public var nextJump: FlxPoint = null;

    public function new()
    {
        sprite = new SpriteWrapper<Entity>(this);
        hitboxes = new Array<Hitbox>();
        seenEntities = new Array<Entity>();
        
        thought = new Icon(this, 0, -16);
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

        if (isJumping)
        {
            // sprite health is used as a hacky workaround for draw ordering.
            sprite.health = PlayState.world.topLayerSortIndex();
            sprite.velocity.set(0,0);
        }
        else
        {
            // sprite health is used as a hacky workaround for draw ordering.
            sprite.health = 1;

            if (nextJump != null)
            {
                var angle = Math.atan2(nextJump.y - sprite.y, nextJump.x - sprite.x);
                var magn = GameWorld.pointDistance(sprite.x, sprite.y, nextJump.x, nextJump.y);

                var multipliers = [0.8, 0.9, 1.0, 1.4, 1.5];
                for (m in multipliers)
                {
                    var jumpX = Math.cos(angle) * magn * m;
                    var jumpY = Math.sin(angle) * magn * m;
                    var canJump = jumpTo(sprite.x + jumpX, sprite.y + jumpY, true);
                    if (canJump)
                    {
                        break;
                    }
                }
                nextJump = null;
            }
        }

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
    public function setPosition(x:Float, y:Float, centered:Bool = false)
    {
        if (centered)
        {
            sprite.setPosition(x + sprite.width/2, y + sprite.height/2);
        }
        else
        {
            sprite.setPosition(x, y);
        }
    }

    public function updatePosition(x:Float, y:Float)
    {
        sprite.x += x;
        sprite.y += y;
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
        if (!canJumpCliffs || isJumping)
        {
            return;
        }

        var jumpDist = 28;

        var jumpX:Float = 0;
        var jumpY:Float = 0;
        switch (direction)
        {
            case FlxObject.UP:
                jumpY = -jumpDist;
            case FlxObject.DOWN:
                jumpY = jumpDist;
            case FlxObject.LEFT:
                jumpX = -jumpDist;
            case FlxObject.RIGHT:
                jumpX = jumpDist;
        }

        nextJump = new FlxPoint(sprite.x + jumpX, sprite.y + jumpY);
    }

    public function jumpTo(x:Float, y:Float, collisionCheck:Bool = true, ?completeCallback: Entity -> Void):Bool
    {
        if (isJumping)
        {
            Console.log("Already jumping.");
            return false;
        }

        var start = new FlxPoint(sprite.x, sprite.y);
        var end = new FlxPoint(x, y);

        if (collisionCheck)
        {
            // Check if sprite will land on a tile if they jump
            sprite.setPosition(end.x, end.y);
            var colliding = GameWorld.collidingWithObstacles(this);
            sprite.setPosition(start.x, start.y);

            if (colliding)
            {
                // Don't jump off cliff if we're jumping into an obstacle.
                return false;
            }
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
            isJumping = false;

            if (completeCallback != null)
            {
                completeCallback(this);
            }
        }};
        FlxTween.quadPath(this.sprite, [start, control, end], duration, true, options);
        
        sprite.velocity.x = 0;
        sprite.velocity.y = 0;
        sprite.allowCollisions = FlxObject.NONE;
        isJumping = true;

        return true;
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

    public function getTopLeftX()
    {
        return this.sprite.x;
    }

    public function getTopLeftY()
    {
        return this.sprite.y;
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
