package entities;

import flixel.FlxG;
import flixel.FlxObject;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import js.html.Console;

class Predator extends Dino
{
    /* Unherded state */
    final PREDATOR_SPEED = 30.0;
    final PREDATOR_ACCELERATION = 30.0;
    final PREDATOR_ELASTICITY = 0.9;

    final PREDATOR_SIGHT_RANGE = 100.0;
    final PREDATOR_SIGHT_ANGLE = GameWorld.toRadians(50);


    /* Pursuing state */
    final PREDATOR_ROTATION = GameWorld.toRadians(10);
    final PREDATOR_FAST_SPEED = 45.0;
    final PREDATOR_SEEN_TIMER = 5;

    var seenEntity: Entity;
    var lastSeenTimer:Float = 0;
    var moveAngle:Float;

    public function new()
    {
        super();

        this.type = EntityPredator;

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
        // idle(elapsed);

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
        if (seenEntities.length > 0)
        {
            lastSeenTimer = PREDATOR_SEEN_TIMER;
            var entity = GameWorld.getNearestEntity(this, seenEntities);

            var moveAngle = GameWorld.pointAngle(1, 0, sprite.velocity.x, sprite.velocity.y);
            var angleBetween = GameWorld.entityAngle(this, entity);
            var angleDiff = angleBetween - moveAngle;

            Console.log(angleDiff);
            sprite.velocity.rotate(FlxPoint.weak(), GameWorld.toDegrees(Math.min(angleDiff, PREDATOR_ROTATION)));
        }
        else
        {
            lastSeenTimer -= elapsed;
            if (lastSeenTimer <= 0)
            {
                // Return to unherded state
                this.state = Unherded;
            }
        }

        speedUp(PREDATOR_FAST_SPEED);
    }

    public override function getSightRange()
    {
        return this.PREDATOR_SIGHT_RANGE;
    }

    public override function getSightAngle()
    {   
        return this.PREDATOR_SIGHT_ANGLE;
    }
}
