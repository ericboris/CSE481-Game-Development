package entities;

import flixel.FlxG;
import flixel.FlxObject;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import js.html.Console;

class Predator extends Dino
{
    /* Unherded state */
    final PREDATOR_SPEED = 35.0;
    final PREDATOR_ACCELERATION = 11.0;
    final PREDATOR_ELASTICITY = 0.9;
    final PREDATOR_PURSUING_ELASTICITY = 0.3;

    final PREDATOR_SIGHT_RANGE = 200.0;
    final PREDATOR_SIGHT_ANGLE = GameWorld.toRadians(50);
    final PREDATOR_SIGHT_RADIUS = 24.0;

    /* Pursuing state */
    final PREDATOR_ANGULAR_ACCELERATION = GameWorld.toRadians(5);
    final PREDATOR_PURSUING_SPEED = 39.0;
    final PREDATOR_SEEN_TIMER = 0.1;

    final SATIATED_TIMER = 5;

    var seenEntity:Entity;
    var lastSeenTimer:Float = 0;
    var moveAngle:Float;

    var satiated:Bool = false;
    var satiatedTimer:Float = 0;

    public function new()
    {
        super();

        this.type = EntityPredator;
        this.canJumpCliffs = false;

        setGraphic(16, 16, AssetPaths.boss__png, true);

        sprite.setFacingFlip(FlxObject.LEFT, false, false);
        sprite.setFacingFlip(FlxObject.RIGHT, true, false);

        sprite.animation.add("lr", [0], 0, false);
        // sprite.animation.add("u", [6, 7, 6, 8], 6, false);
        // sprite.animation.add("d", [0, 1, 0, 2], 6, false);

        moveAngle = GameWorld.random(0, Math.PI * 2.0);
        this.sprite.velocity.x = Math.cos(moveAngle) * PREDATOR_SPEED;
        this.sprite.velocity.y = Math.sin(moveAngle) * PREDATOR_SPEED;
        this.sprite.elasticity = PREDATOR_ELASTICITY;

        sprite.screenCenter();

        sprite.setSize(8, 8);
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

        super.update(elapsed);
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
            sprite.acceleration.x = Math.cos(angle) * PREDATOR_ACCELERATION;
            sprite.acceleration.y = Math.sin(angle) * PREDATOR_ACCELERATION;
        }
    }

    private override function unherded(elapsed:Float)
    {
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

        speedUp(PREDATOR_SPEED);
    }

    function pursuing(elapsed: Float)
    {
        // Don't bounce off objects
        this.sprite.elasticity = PREDATOR_PURSUING_ELASTICITY;

        if (seenEntities.length > 0)
        {
            // Rotate towards nearest entity
            lastSeenTimer = PREDATOR_SEEN_TIMER;
            var entity = GameWorld.getNearestEntity(this, seenEntities);

            var moveAngle = GameWorld.pointAngle(1, 0, sprite.velocity.x, sprite.velocity.y);
            var angleBetween = GameWorld.entityAngle(this, entity);
            var angleDiff = angleBetween - moveAngle;

            // Angular acceleration
            var sign = angleDiff < 0 ? -1 : 1;
            var acceleration = Math.min(Math.abs(angleDiff), PREDATOR_ANGULAR_ACCELERATION);
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
                this.sprite.elasticity = PREDATOR_ELASTICITY;
                this.state = Unherded;
            }
        }

        speedUp(PREDATOR_PURSUING_SPEED);
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

    public override function getSightRange()
    {
        return this.PREDATOR_SIGHT_RANGE;
    }

    public override function getSightAngle()
    {   
        return this.PREDATOR_SIGHT_ANGLE;
    }

    public override function getNearbySightRadius()
    {
        return this.PREDATOR_SIGHT_RADIUS;
    }
}
