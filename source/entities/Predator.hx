package entities;

import flixel.FlxG;
import flixel.FlxObject;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import js.html.Console;

class Predator extends Dino
{
    /* Unherded state */
    final SPEED = 24.0;
    final ACCELERATION = 10.0;
    final ELASTICITY = 0.9;
    final PURSUING_ELASTICITY = 0.3;

    /* Pursuing state */
    final ANGULAR_ACCELERATION = GameWorld.toRadians(5);
    final PURSUING_SPEED = 65.0;
    final SEEN_TIMER = 0.5;

    final SATIATED_TIMER = 1.0;

    var lastSeenTimer:Float = 0;
    var moveAngle:Float;

    var satiated:Bool = false;
    var satiatedTimer:Float = 0;

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

        sprite.screenCenter();

        this.SIGHT_ANGLE = GameWorld.toRadians(60);
        this.SIGHT_RANGE = 200;
        this.NEARBY_SIGHT_RADIUS = 40;

        sprite.setSize(30, 30);
    }

    public override function update(elapsed:Float)
    {
        if (seenEntities.length > 0)
            state = Pursuing;

        if (satiated)
        {
            state = Unherded;
            satiatedTimer -= elapsed;
            if (satiatedTimer < 0)
                satiated = false;
        }

        if (state == Pursuing)
            pursuing(elapsed);

        move();

        super.update(elapsed);
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
            sprite.velocity.x += Math.cos(angle) * ACCELERATION;
            sprite.velocity.y += Math.sin(angle) * ACCELERATION;
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
            sprite.velocity.x *= -1;
        }

        if (verticalCollision > 0)
        {
            sprite.velocity.y *= -1;
        }

        speedUp(SPEED);
    }

    function pursuing(elapsed: Float)
    {
        // Don't bounce off objects
        this.sprite.elasticity = PURSUING_ELASTICITY;

        if (seenEntities.length > 0)
        {
            // Rotate towards nearest entity
            lastSeenTimer = SEEN_TIMER;
            var entity = GameWorld.getNearestEntity(this, seenEntities);

            var moveAngle = GameWorld.pointAngle(1, 0, sprite.velocity.x, sprite.velocity.y);
            var angleBetween = GameWorld.entityAngle(this, entity);
            var angleDiff = angleBetween - moveAngle;

            if (angleDiff > Math.PI / 2.0)
            {
                var startSpeed = UNHERDED_SPEED / 2;
                sprite.velocity.set(Math.cos(angleBetween) * startSpeed, Math.sin(angleBetween) * startSpeed);
            }

            // Angular acceleration
            var sign = angleDiff < 0 ? -1 : 1;
            var acceleration = Math.min(Math.abs(angleDiff), ANGULAR_ACCELERATION);
            acceleration *= sign;

            sprite.velocity.rotate(FlxPoint.weak(), GameWorld.toDegrees(acceleration));
        }
        else
        {
            // After a certain amount of time has passed, return to Unherded
            lastSeenTimer -= elapsed;
            if (lastSeenTimer <= 0)
            {
                // Return to Unherded state
                this.sprite.elasticity = ELASTICITY;
                this.state = Unherded;
            }
        }

        speedUp(PURSUING_SPEED);
    }

    public function canEat(entity:Entity)
    {
        if (!satiated)
        {
            // Eat this entity! Set satiated to true and reverse direction.
            sprite.velocity.x *= -1;
            sprite.velocity.y *= -1;
            satiated = true;
            satiatedTimer = SATIATED_TIMER;
            return true;
        }
        else
        {
            return false;
        }
    }
}
