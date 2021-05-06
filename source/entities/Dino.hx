package entities;

import flixel.FlxG;
import flixel.FlxObject;
import flixel.math.FlxPoint;
import flixel.util.FlxColor;
import js.html.Console;

enum DinoState
{
    Herded;
    Unherded;
    Pursuing;
    Fleeing;
}

class Dino extends Entity
{
    var state:DinoState;
    
    // Constants
    final MAX_FOLLOWING_RADIUS = 150.0;
    final FOLLOWING_RADIUS = 15.0;
    final DAMPING_FACTOR = 0.7;
    final UNHERDED_SPEED = 30.0;

    /* State for herded behavior */
    var herdedPlayer:Player;
    var herdedLeader:Entity;
    var herdedSpeed:Float;

    public var herdedDisableFollowingRadius = false;

    /* State for unherded behavior */
    var idleTimer:Float;
    var moveDirection:Float;

    public function new()
    {
        super();

        setSprite(20, 20, FlxColor.YELLOW);
        sprite.mass = 0.5; // Make the dino easier to push by player.
        state = Unherded;

        idleTimer = 0;
    }

    public override function update(elapsed:Float)
    {
        switch (state)
        {
            case Unherded:
                unherded(elapsed);
            case Herded:
                herded(elapsed);
            case Fleeing:
                fleeing(elapsed);
            default:
        }

        // If we're herded but our leader is unherded, switch to unherded.
        if (state == Herded && Std.is(herdedLeader, Dino) && cast(herdedLeader, Dino).getState() == Unherded)
        {
            setUnherded();
        }

        if ((sprite.velocity.x != 0 || sprite.velocity.y != 0) && sprite.touching == FlxObject.NONE)
        {
            if (Math.abs(sprite.velocity.x) > Math.abs(sprite.velocity.y))
            {
                if (sprite.velocity.x < 0)
                    sprite.facing = FlxObject.LEFT;
                else
                    sprite.facing = FlxObject.RIGHT;
            }
            else
            {
                if (sprite.velocity.y < 0)
                    sprite.facing = FlxObject.UP;
                else
                    sprite.facing = FlxObject.DOWN;
            }

            switch (sprite.facing)
            {
                case FlxObject.LEFT, FlxObject.RIGHT:
                    sprite.animation.play("lr");

                case FlxObject.UP:
                    sprite.animation.play("u");

                case FlxObject.DOWN:
                    sprite.animation.play("d");
            }
        }
        super.update(elapsed);
    }

    // Used by Player class to update herd ordering.
    public function setLeader(entity:Entity)
    {
        herdedLeader = entity;
    }

    // Called by Player when the herd has been scattered
    public function notifyScattered()
    {
        this.state = Unherded;
    }

    function unherded(elapsed:Float)
    {
        sprite.velocity.set(0, 0);
    }

    function herded(elapsed:Float)
    {
        herdedSpeed = herdedPlayer.getSpeed();
        var pos1 = herdedLeader.sprite.getPosition();
        var pos2 = sprite.getPosition();
        var dist = pos1.distanceTo(pos2);

        if (dist > MAX_FOLLOWING_RADIUS)
        {
            setUnherded(true);
        }
        else if (herdedDisableFollowingRadius || dist > FOLLOWING_RADIUS)
        {
            var dir = new FlxPoint(pos1.x - pos2.x, pos1.y - pos2.y);
            var angle = Math.atan2(dir.y, dir.x);
            sprite.velocity.set(Math.cos(angle) * herdedSpeed, Math.sin(angle) * herdedSpeed);
        }
        else
        {
            // Slow dino down
            sprite.velocity.scale(DAMPING_FACTOR);
        }
    }

    /* State transition methods */
    public function setUnherded(notify:Bool = false)
    {
        var player = herdedPlayer;
        herdedLeader = null;
        herdedPlayer = null;
        state = Unherded;

        herdedDisableFollowingRadius = false;

        player.notifyUnherded(this);
    }

    public function getState()
    {
        return state;
    }

    function idle(elapsed:Float)
    {
        if (idleTimer <= 0)
        {
            if (FlxG.random.bool(25))
            {
                moveDirection = -1;
                sprite.velocity.x = sprite.velocity.y = 0;
            }
            else
            {
                moveDirection = FlxG.random.int(0, 8) * 45;

                sprite.velocity.set(UNHERDED_SPEED * 0.5, 0);
                sprite.velocity.rotate(FlxPoint.weak(), moveDirection);
            }
            idleTimer = FlxG.random.int(1, 4);
        }
        else
        {
            idleTimer -= elapsed;
        }
    }

    function fleeing(elapsed:Float)
    {
        if (seenEntities.length == 0)
        {
            state = Unherded;
        }
        else
        {
            Console.log("FLEEING");
            var entity = GameWorld.getNearestEntity(this, seenEntities);
            var dir = new FlxPoint(this.sprite.x - entity.getSprite().x, this.sprite.y - entity.getSprite().y);
            var angle = Math.atan2(dir.y, dir.x);
            sprite.velocity.set(Math.cos(angle) * UNHERDED_SPEED, Math.sin(angle) * UNHERDED_SPEED);
        }
    }
}
