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

    // When removed from the game world, this is true.
    public var dead:Bool = false;

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

    var lastVelocity:FlxPoint = FlxPoint.weak();

    public var nextJumps: Array<FlxPoint> = new Array<FlxPoint>();

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
            sprite.alpha -= 0.1;
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

            // Attempt to jump to the next spot.
            while (nextJumps.length > 0)
            {
                var nextJump = nextJumps.pop();
                var angle = GameWorld.pointAngle(1, 0, nextJump.x - sprite.x, nextJump.y - sprite.y);
                var magn = GameWorld.pointDistance(sprite.x, sprite.y, nextJump.x, nextJump.y);

                var multipliers = [0.8, 0.9, 1.0, 1.1, 1.2, 1.3, 1.4, 1.7];
                for (m in multipliers)
                {
                    var jumpX = Math.cos(angle) * magn * m;
                    var jumpY = Math.sin(angle) * magn * m;
                    var canJump = jumpTo(sprite.x + jumpX, sprite.y + jumpY, true);
                    if (canJump)
                    {
                        sprite.health = PlayState.world.topLayerSortIndex();
                        nextJumps.resize(0);
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
        lastVelocity = new FlxPoint(sprite.velocity.x, sprite.velocity.y);
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
            sprite.setPosition(x - sprite.frameWidth/2, y - sprite.frameHeight/2);
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

    public function handleCliffCollision(direction1:Int, direction2:Int)
    {
        if (!canJumpCliffs || isJumping)
        {
            return;
        }

        var jumpDist = 28;

        var jumpX:Float = 0;
        var jumpY:Float = 0;
        
        var isTouchingSide:Int = 0;
        switch (direction1)
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

        var jump2X = 0;
        var jump2Y = 0;
        switch (direction2)
        {
            case FlxObject.UP:
                jump2Y = -jumpDist;
            case FlxObject.DOWN:
                jump2Y = jumpDist;
            case FlxObject.LEFT:
                jump2X = -jumpDist;
            case FlxObject.RIGHT:
                jump2X = jumpDist;
        }

        // Jump angle based on velocity
        var angle = GameWorld.pointAngle(1, 0, lastVelocity.x, lastVelocity.y);
        var velocityJump = new FlxPoint(getX() + Math.cos(angle) * jumpDist, getY() + Math.sin(angle) * jumpDist);
        
        if (direction2 != 0)
        {
            // Order decides priority jumps are attempted.
            // Last inserted = first to be tried
            nextJumps.push(new FlxPoint(sprite.x + jumpX + jump2X, sprite.y + jumpY + jump2Y));
            nextJumps.push(new FlxPoint(sprite.x + jump2X, sprite.y + jump2Y));
            nextJumps.push(new FlxPoint(sprite.x + jumpX, sprite.y + jumpY));
            nextJumps.push(velocityJump);
        }
        else
        {
            nextJumps.push(velocityJump);
            nextJumps.push(new FlxPoint(sprite.x + jumpX, sprite.y + jumpY));
        }
    }

    function checkCollision(point:FlxPoint):Bool
    {
        // Check if sprite will land on a tile if they jump
        var startX = sprite.x;
        var startY = sprite.y;

        sprite.setPosition(point.x, point.y);
        var colliding = GameWorld.collidingWithObstacles(this);
        sprite.setPosition(startX, startY);

        return colliding;
    }

    public function jumpTo(x:Float, y:Float, collisionCheck:Bool = true, ?completeCallback: Entity -> Void,
                           jumpSpeed:Float = 80.0, heightMultiplier:Float = 1.5):Bool
    {
        if (isJumping)
        {
            return false;
        }

        var start = new FlxPoint(sprite.x, sprite.y);
        var end = new FlxPoint(x, y);

        if (collisionCheck && checkCollision(end))
        {
            return false;
        }

        var control = new FlxPoint((end.x + start.x) / 2, (end.y + start.y) / 2);
        if (Math.abs(end.x - start.x) > Math.abs(end.y - start.y))
            control.y -= 20.0 * heightMultiplier;
        else
            control.x += 10.0 * heightMultiplier;
        
        var options = {ease: FlxEase.sineInOut, type: ONESHOT, onComplete: function(tween:FlxTween)
        {
            sprite.allowCollisions = FlxObject.ANY;
            isJumping = false;

            if (completeCallback != null)
            {
                completeCallback(this);
            }
        }};
        FlxTween.quadPath(this.sprite, [start, control, end], jumpSpeed, false, options);
        
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
            thought.appear(fadeOutDelay * 1.5);
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
        this.sprite.allowCollisions = FlxObject.NONE;
    }

    public function setHitboxSize(width:Int, height:Int)
    {
        sprite.setSize(width, height);
        sprite.centerOffsets();
    }
}
