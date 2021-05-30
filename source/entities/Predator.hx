package entities;

import flixel.FlxG;
import flixel.FlxObject;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import js.html.Console;
import flixel.system.FlxSound;
import flixel.util.FlxTimer;

class Predator extends Dino
{
    /* Unherded state */
    static final SPEED = 60.0;
    static final ACCELERATION = 50.0;
    static final ELASTICITY = 1.0;
    static final PURSUING_ELASTICITY = 1.0;

    /* Pursuing state */
    static final ANGULAR_ACCELERATION = GameWorld.toRadians(20);
    
    static final MAX_PURSUING_SPEED = 1.1;
    static final MIN_PURSUING_SPEED = 0.6;
    static var PURSUING_SPEED = 100.0;

    static final SEEN_TIMER = 1.5;

    static final MAX_SATIATED_TIMER = 4.0;
    static final MIN_SATIATED_TIMER = 1.5;
    static var SATIATED_TIMER = 0.0;

    static final MAX_DAZED_TIMER = 4.0;
    static final MIN_DAZED_TIMER = 1.5;
    static var DAZED_TIMER = 0.0;

    static final MIN_SIGHT_RANGE = 100;
    static final MAX_SIGHT_RANGE = 200;

    static final MIN_SIGHT_RADIUS = 20;
    static final MAX_SIGHT_RADIUS = 60;
    
    static final FLASHING_RATE = 0.04;

    /* ADAPTIVE AGGRESSION */
    static public var aggression:Float = 0.5;
    static public function adjustAggression(f:Float)
    {
        aggression += f;
        if (aggression < 0) aggression = 0;
        if (aggression > 1) aggression = 1;
        updateAggression();
    }

    static public function updateAggression()
    {
        var speed = GameWorld.getPlayerSpeed();
        PURSUING_SPEED = GameWorld.map(0.0, 1.0, speed * MIN_PURSUING_SPEED, speed * MAX_PURSUING_SPEED, aggression);

        SATIATED_TIMER = GameWorld.map(0.0, 1.0, MAX_SATIATED_TIMER, MIN_SATIATED_TIMER, aggression);
        DAZED_TIMER = GameWorld.map(0.0, 1.0, MAX_DAZED_TIMER, MIN_DAZED_TIMER, aggression);
    
        if (PlayState.world.isDebug())
        {
            Console.log("Aggression: " + aggression);
            Console.log("Speed: " + PURSUING_SPEED);
            Console.log("Satiated Timer: " + SATIATED_TIMER);
            Console.log("Dazed Timer: " + DAZED_TIMER);
        }
    }

    var lastSeenEntity:Entity;
    var lastSeenTimer:Float = 0;
    var moveAngle:Float;

    var satiated:Bool = false;
    var satiatedTimer:Float = 0;
    var alphaRate:Float = FLASHING_RATE;

    var attackRoar:FlxSound;
    var hasRoared:Bool = false;

    var dazed:Bool = false;
    var dazedTimer:Float = 0;

    public function new()
    {
        super();

        this.type = EntityPredator;
        this.canJumpCliffs = false;

        setGraphic(32, 32, AssetPaths.RedDragon__png, true);

        sprite.animation.add("d", [0, 1, 2, 3], 6, false);
        sprite.animation.add("u", [4, 5, 6, 7], 6, false);
        sprite.animation.add("l", [8, 9, 10, 11], 6, false);
        sprite.animation.add("r", [12, 13, 14, 15], 6, false);

        moveAngle = GameWorld.random(0, Math.PI * 2.0);
        this.sprite.velocity.x = Math.cos(moveAngle) * SPEED;
        this.sprite.velocity.y = Math.sin(moveAngle) * SPEED;
        this.sprite.elasticity = ELASTICITY;
        this.sprite.mass = 2.0;

        this.SIGHT_ANGLE = GameWorld.toRadians(120);
        this.SIGHT_RANGE = 200;
        this.NEARBY_SIGHT_RADIUS = 80;

        setHitboxSize(10, 10);

        this.attackRoar = FlxG.sound.load(AssetPaths.PredatorRoar1__mp3, 0.7);
        attackRoar.proximity(sprite.x, sprite.y, FlxG.camera.target, FlxG.width * 0.6);
        this.thought.setOffset(0, -17);

        this.state = Sleeping;
    }

    function flash()
    {
        sprite.alpha += alphaRate;
        if (sprite.alpha <= 0.3 || sprite.alpha >= 1.0)
        {
            alphaRate *= -1;
        }
    }

    public override function update(elapsed:Float)
    {
        SIGHT_RANGE = GameWorld.map(0.0, 1.0, MIN_SIGHT_RANGE, MAX_SIGHT_RANGE, aggression);
        NEARBY_SIGHT_RADIUS = GameWorld.map(0.0, 1.0, MIN_SIGHT_RADIUS, MAX_SIGHT_RADIUS, aggression);
        
        if (dazed)
        {
            dazedTimer -= elapsed;
            if (dazedTimer < 0)
            {
                dazed = false;
            }

            flash();
        }
        else if (!satiated && !dazed)
        {
            if (state == Sleeping)
            {
                
            }

            // Can only puruse if not dazed.
            else if (seenEntities.length > 0)
            {
                if (state != Pursuing)
                {
                    think("!", 0.3);
                }
                state = Pursuing;
            }
            else
            {
                if (state == Pursuing)
                {
                    think("?", 0.3);
                }
                state = Unherded;
            }
        }

        if (satiated)
        {
            state = Unherded;
            satiatedTimer -= elapsed;
            if (satiatedTimer < 0)
                satiated = false;
        }

        if (dazed || satiated)
        {
            // Flash while in these states.
            flash();
        }
        else
        {
            // If not in these states, return to completely opaque.
            if (sprite.alpha < 1.0)
            {
                sprite.alpha += FLASHING_RATE;
            }
        }

        if (state == Pursuing)
            pursuing(elapsed);

        super.update(elapsed);
        move();
    }

    function move()
    {
        if (Math.abs(sprite.velocity.y) > Math.abs(sprite.velocity.x))
        {
            if (sprite.velocity.y >= 0)
            {
                sprite.animation.play("d");
            }
            else
            {
                sprite.animation.play("u");
            }
        }
        else
        {
            if (sprite.velocity.x >= 0)
            {
                sprite.animation.play("r");
            }
            else
            {
                sprite.animation.play("l");
            }
        }
    }

    function speedUp(maxSpeed:Float)
    {
        var angle = GameWorld.pointAngle(1, 0, sprite.velocity.x, sprite.velocity.y);
        var speed = GameWorld.magnitude(sprite.velocity);
        if (speed >= maxSpeed)
        {
            sprite.acceleration.x = 0;
            sprite.acceleration.y = 0;

            sprite.velocity.x = Math.cos(angle) * maxSpeed;
            sprite.velocity.y = Math.sin(angle) * maxSpeed;
        }
        else
        {
            // Set sprite's acceleration to speed up in the same direction
            sprite.acceleration.x = Math.cos(angle) * ACCELERATION;
            sprite.acceleration.y = Math.sin(angle) * ACCELERATION;
        }
    }

    private override function unherded(elapsed:Float)
    {
        this.sprite.elasticity = ELASTICITY;
        // Bounce off walls if colliding
        var horizontalCollision = sprite.touching & (FlxObject.LEFT | FlxObject.RIGHT);
        var verticalCollision = sprite.touching & (FlxObject.UP | FlxObject.DOWN);
        if (horizontalCollision > 0)
        {
            sprite.velocity.x *= 0.95;
        }

        if (verticalCollision > 0)
        {
            sprite.velocity.y *= 0.95;
        }

        speedUp(SPEED);
    }

    function pursuing(elapsed: Float)
    {
        // Don't bounce off objects
        this.sprite.elasticity = PURSUING_ELASTICITY;

        if (seenEntities.length == 0 && lastSeenTimer <= 0)
        {
            // After a certain amount of time has passed, return to Unherded
            lastSeenTimer -= elapsed;
            if (lastSeenTimer <= 0)
            {
                // Return to Unherded state
                this.sprite.elasticity = ELASTICITY;
                this.state = Unherded;
                hasRoared = false;
                return;
            }
        }
        // Rotate towards nearest entity
        lastSeenTimer = SEEN_TIMER;
            
        var entity:Entity;
        if (seenEntities.length > 0)
        {
            entity = GameWorld.getNearestEntity(this, seenEntities);
        }
        else
        {
            entity = lastSeenEntity;
        }

        var moveAngle = GameWorld.pointAngle(1, 0, sprite.velocity.x, sprite.velocity.y);
        var angleBetween = GameWorld.entityAngle(this, entity);
        var angleDiff = angleBetween - moveAngle;


        // Angular acceleration
        var sign = angleDiff < 0 ? -1 : 1;
        var acceleration = Math.min(Math.abs(angleDiff), ANGULAR_ACCELERATION);
        acceleration *= sign;

        if (angleDiff > Math.PI / 2.0)
        {
            // Predator has a long way to turn around.
            // Slow down and turn more towards the entity
            sprite.velocity.scale(0.8);
            sprite.velocity.rotate(FlxPoint.weak(), GameWorld.toDegrees(acceleration));
        }

        sprite.velocity.rotate(FlxPoint.weak(), GameWorld.toDegrees(acceleration));

        //sprite.velocity.rotate(FlxPoint.weak(), angleDiff);
        this.lastSeenEntity = entity;

        if (hasRoared == false) 
        {
            attackRoar.setPosition(sprite.x, sprite.y);
            attackRoar.play();
            
            var distance = GameWorld.entityDistance(this, PlayState.world.getPlayer());
            if (distance < 160)
            {
                attackRoar.volume = 0.7;
            }
            else
            {
                attackRoar.volume = 0.3;
            }

            hasRoared = true;
        }
        speedUp(PURSUING_SPEED);
    }

    public override function handleCaveDeposit(cave:Cave)
    {
        if (dazed)
        {
            PlayState.world.collectDino(this, cave);
        }
    }

    public override function handlePredatorCollision(predator:Predator)
    {
        if (state == Sleeping)
        {
            wakeUp();
        }
    }

    var lastHitTimestamp:Float = 0.0;
    public function hitWithStick()
    {
        if (!dazed)
        {
            sprite.velocity.x *= -1;
            sprite.velocity.y *= -1;
        }

        // Log predator swipe
        var timestamp = haxe.Timer.stamp();
        if (timestamp - lastHitTimestamp > 0.4)
        {
            lastHitTimestamp = timestamp;
            PlayLogger.recordPredatorSwipe(this);
        }


        var random = FlxG.random.float(0, 1.0);
        var timer = DAZED_TIMER - 0.5;
        if (random < 0.3)
            this.think(":O", timer);
        else if (random < 0.6)
            this.think(":|", timer);
        else
            this.think(":o", timer);

        this.dazed = true;
        this.dazedTimer = DAZED_TIMER;
        this.state = Fleeing;
    }

    public function isDazed()
    {
        return satiated || dazed;
    }

    public function canEat(entity:Entity)
    {
        var canEat = !satiated && !dazed;
        if (canEat)
        {
            if (state == Sleeping)
            {
                wakeUp();            
                return false;
            }
            else
            {
                // Eat this entity! Set satiated to true and reverse direction.
                sprite.velocity.x *= -1;
                sprite.velocity.y *= -1;
                satiated = true;
                satiatedTimer = SATIATED_TIMER;
                hasRoared = false;
                state = Fleeing;

                think(">:)", SATIATED_TIMER - 0.5);

                return true;
            }
        }
        else
        {
            return false;
        }
    }

    public function wakeUp():Void
    {
        if (!isWaking)
        {
            isWaking = true;
            attackRoar.play(); 
            new FlxTimer().start(0.5, function (FlxTimer) 
                {
                   this.state = Unherded; 
                });
        }
    }

    public function track(entity:Entity)
    {
        wakeUp();
        seenEntities.push(entity);
    }

    override function canBeCollected()
    {
        return dazed;
    }
}
