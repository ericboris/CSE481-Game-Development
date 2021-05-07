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

    var lastPosition:FlxPoint = new FlxPoint();
    var framesStuck:Int = 0;
    var herdedPath:Array<FlxPoint> = new Array<FlxPoint>();
    var framesSincePathGenerated:Int = 0;

    public var herdedDisableFollowingRadius = false;

    /* State for unherded behavior */
    var idleTimer:Float;
    var moveDirection:Float;

    public function new()
    {
        super();

        setSprite(20, 20, FlxColor.YELLOW);
        sprite.mass = 0.4; // Make the dino easier to push by player.
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

        // Update animation
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

        lastPosition = sprite.getPosition();
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
        var leaderPos = new FlxPoint(herdedLeader.getX(), herdedLeader.getY());
        var dinoPos = new FlxPoint(getX(), getY());
        var dist = leaderPos.distanceTo(dinoPos);


        if (dist < FOLLOWING_RADIUS)
        {
            // Slow dino down
            sprite.velocity.scale(DAMPING_FACTOR);
            framesStuck = 0;
            return;
        }

        var positionDiff = new FlxPoint(lastPosition.x - dinoPos.x, lastPosition.y - dinoPos.y);
        if (GameWorld.magnitude(positionDiff) < 4.0)
        {
            framesStuck++;
        }
        else
        {
            framesStuck = 0;
        }
        
        if (framesStuck > 5 && (herdedPath.length == 0 || framesSincePathGenerated > 5))
        {
            // Attempt to pathfind towards herded leader
            var newPath = PlayState.world.getObstacles().findPath(leaderPos, dinoPos);
            if (newPath != null)
            {
                herdedPath = newPath;
                framesSincePathGenerated = 0;
            }
            framesStuck = 0;
        }

        if (herdedPath.length > 0)
        {
            // Follow the path towards the leader
            var pathPoint = herdedPath[herdedPath.length-1];
            var dir = new FlxPoint(pathPoint.x - dinoPos.x, pathPoint.y - dinoPos.y);
            if (GameWorld.magnitude(dir) < 4.0)
            {
                herdedPath.pop();
                if (herdedPath.length == 0) return;
                pathPoint = herdedPath[herdedPath.length-1];
                dir = new FlxPoint(pathPoint.x - dinoPos.x, pathPoint.y - dinoPos.y);
            }

            var angle = Math.atan2(dir.y, dir.x);
            sprite.velocity.set(Math.cos(angle) * herdedSpeed, Math.sin(angle) * herdedSpeed);
            framesSincePathGenerated++;
        }
        else
        {
            // Move directly towards leader
            if (herdedDisableFollowingRadius || dist > FOLLOWING_RADIUS)
            {
                var dir = new FlxPoint(leaderPos.x - dinoPos.x, leaderPos.y - dinoPos.y);
                var angle = Math.atan2(dir.y, dir.x);
                sprite.velocity.set(Math.cos(angle) * herdedSpeed, Math.sin(angle) * herdedSpeed);
            }
        }

        if (dist > MAX_FOLLOWING_RADIUS)
        {
            setUnherded(true);
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

    public function getHerdedPlayer()
    {
        return herdedPlayer;
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
            var entity = GameWorld.getNearestEntity(this, seenEntities);
            var dir = new FlxPoint(this.sprite.x - entity.getSprite().x, this.sprite.y - entity.getSprite().y);
            var angle = Math.atan2(dir.y, dir.x);
            sprite.velocity.set(Math.cos(angle) * UNHERDED_SPEED, Math.sin(angle) * UNHERDED_SPEED);
        }
    }
}
