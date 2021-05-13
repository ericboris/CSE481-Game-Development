package entities;

import flixel.FlxG;
import flixel.FlxObject;
import flixel.math.FlxPoint;
import flixel.util.FlxColor;
import js.html.Console;
import flixel.tile.FlxBaseTilemap;

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
    final MAX_FOLLOWING_RADIUS = 140.0;
    final FOLLOWING_RADIUS = 20.0;
    final DAMPING_FACTOR = 0.7;
    final UNHERDED_SPEED = 60.0;

    /* State for herded behavior */
    var herdedPlayer:Player;
    var herdedLeader:Entity;
    var herdedSpeed:Float;

    var lastPosition:FlxPoint = new FlxPoint();
    var framesStuck:Int = 0;
    var herdedPath:Array<FlxPoint> = new Array<FlxPoint>();
    var framesSincePathGenerated:Int = 0;
    var isPathfinding:Bool = false;
    var newLeaderFlag:Bool = false;

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

        newLeaderFlag = false;
        lastPosition = new FlxPoint(getX(), getY());
        super.update(elapsed);
    }

    // Used by Player class to update herd ordering.
    public function setLeader(entity:Entity)
    {
        if (entity != herdedLeader)
        {
            herdedLeader = entity;
            newLeaderFlag = true;
        }
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

        if (dist > MAX_FOLLOWING_RADIUS)
        {
            // We are far away from our leader! Try following the player instead.
            herdedLeader = herdedPlayer;
            leaderPos = new FlxPoint(herdedPlayer.getX(), herdedPlayer.getY());
            dist = leaderPos.distanceTo(dinoPos);
        }
        
        if (dist > MAX_FOLLOWING_RADIUS)
        {
            // We are still too far away from the herd. 
            setUnherded(true);
            return;
        }

        if (newLeaderFlag)
        {
            // We just got a new leader.
            herdedPath.resize(0);
            framesStuck = 0;
        }

        var followingRadius = FOLLOWING_RADIUS;
        if (herdedPlayer.getIsCalling())
        {
            leaderPos = new FlxPoint(herdedPlayer.getX(), herdedPlayer.getY());
            dist = leaderPos.distanceTo(dinoPos);
            followingRadius *= 3;
        }

        if (!herdedDisableFollowingRadius && dist < followingRadius)
        {
            // Slow dino down
            sprite.velocity.scale(DAMPING_FACTOR);
            framesStuck = 0;
            return;
        }

        var positionDiff = new FlxPoint(lastPosition.x - dinoPos.x, lastPosition.y - dinoPos.y);
        var visionCheck = !GameWorld.checkVision(this, herdedLeader);
        var notMovingCheck = GameWorld.magnitude(positionDiff) < 1.0;
        if (visionCheck || notMovingCheck)
        {
            framesStuck++;
        }
        else
        {
            framesStuck = 0;
        }
        
        // Check if the leader is pathfinding. If they are, also begin pathfinding to get around obstacle.
        var isLeaderPathfinding = false;
        if (Std.is(herdedLeader.getType(), Dino) && cast(herdedLeader, Dino).getIsPathfinding())
        {
            isLeaderPathfinding = true;
        }

        if (framesSincePathGenerated > 6)
        {
            herdedPath.resize(0);
        }

        if ((isLeaderPathfinding || framesStuck > 6) && herdedPath.length == 0)
        {
            // Attempt to pathfind towards herded leader
            var newPath = PlayState.world.getObstacles().findPath(leaderPos, dinoPos, true, false, NONE);
            if (newPath != null)                     
            {                                        
                herdedPath = newPath;                
            }
            framesSincePathGenerated = 0;
        }

        if (herdedPath.length > 0)
        {
            // Follow the path towards the leader
            isPathfinding = true;
            var pathPoint = herdedPath[herdedPath.length-1];
            var dir = new FlxPoint(pathPoint.x - dinoPos.x, pathPoint.y - dinoPos.y);
            if (GameWorld.magnitude(dir) < 8.0)
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
            isPathfinding = false;
            if (herdedDisableFollowingRadius || dist > FOLLOWING_RADIUS)
            {
                var dir = new FlxPoint(leaderPos.x - dinoPos.x, leaderPos.y - dinoPos.y);
                var angle = Math.atan2(dir.y, dir.x);
                sprite.velocity.set(Math.cos(angle) * herdedSpeed, Math.sin(angle) * herdedSpeed);
            }
        }
    }

    function moveTowards(position:FlxPoint, speed:Float)
    {
        var dir = new FlxPoint(position.x - getX(), position.y - getY());
        var angle = Math.atan2(dir.y, dir.x);
        sprite.velocity.set(Math.cos(angle) * speed, Math.sin(angle) * speed);
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

    public function getIsPathfinding()
    {
        return isPathfinding;
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
