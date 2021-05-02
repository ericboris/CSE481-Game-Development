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
}

class Dino extends Entity
{
    var state:DinoState;
    
    // Constants
    final MAX_FOLLOWING_RADIUS = 150.0;
    final FOLLOWING_RADIUS = 20.0;
    final DAMPING_FACTOR = 0.55;
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

    /* ----------------------
        State behavior methods
        ---------------------- */
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

        if (notify)
        {
            player.notifyUnherded();
        }
    }

    /* Getters */
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
}
