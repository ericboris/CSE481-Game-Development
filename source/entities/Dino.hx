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
    public static final MAX_FOLLOWING_RADIUS = 140.0;
    static final FOLLOWING_RADIUS = 18.5;
    static final DAMPING_FACTOR = 0.7;
    static final UNHERDED_SPEED = 60.0;

    /* State for herded behavior */
    var herdedPlayer:Player;
    var herdedLeader:Entity;
    public var herdedFollower:Dino;
    var herdedSpeed:Float;

    var lastPosition:FlxPoint = new FlxPoint();
    var framesStuck:Int = 0;
    var herdedPath:Array<FlxPoint> = new Array<FlxPoint>();
    var framesSincePathGenerated:Int = 0;
    var isPathfinding:Bool = false;
    var newLeaderFlag:Bool = false;

    var pathLeader:Entity;

    /* State for unherded behavior */
    var idleTimer:Float;
    var moveDirection:Float;

    var collidedWithCave:Cave = null;
    var caveCollisionCount:Int = 0;

    public function new()
    {
        super();

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
            setUnherded(true);
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

        if (canBeCollected() && collidedWithCave != null)
        {
            caveCollisionCount++;
            if (caveCollisionCount == 5)
            {
                handleCaveDeposit(collidedWithCave);
                caveCollisionCount = 0;
            }
        }
        else
        {
            caveCollisionCount = 0;
        }
        collidedWithCave = null;

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

        if (Std.is(entity, Dino))
        {
            var dino:Dino = cast entity;
            dino.herdedFollower = this;
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

        var leader = herdedLeader;

        var dist = GameWorld.entityDistance(this, leader);
        if (dist > MAX_FOLLOWING_RADIUS)
        {
            var newLeader = false;
            for (dino in herdedPlayer.getFollowers())
            {
                if (dino != this && GameWorld.entityDistance(this, dino) < MAX_FOLLOWING_RADIUS)
                {
                    newLeader = true;
                    herdedLeader = dino;
                    leader = dino;
                    break;
                }
            }

            if (!newLeader)
            {
                // We are still too far away from the herd.
                setUnherded(true);
                return;
            }
            newLeaderFlag = true;
        }

        if (newLeaderFlag)
        {
            // We just got a new leader.
            herdedPath.resize(0);
            framesStuck = 0;
        }

        // Following radius and speed. These may be adjusted by the following logic.
        var followingRadius = FOLLOWING_RADIUS;
        var speed = herdedSpeed;
        
        // If player is calling, head towards player
        if (herdedPlayer.getIsCalling())
        {
            leader = herdedPlayer;
            followingRadius *= 2;
            speed *= 1.05;
            dist = GameWorld.entityDistance(this, leader);
        }

        // If player is at cave, head towards cave
        if (herdedPlayer.isDepositingToCave())
        {
            leader = herdedPlayer;
            followingRadius = 0;
        }
        
        if (dist < followingRadius)
        {
            // Slow dino down
            sprite.velocity.scale(DAMPING_FACTOR);
            return;
        }

        // Check if we're stuck
        var position = new FlxPoint(getX(), getY());
        var positionDiff = new FlxPoint(lastPosition.x - position.x, lastPosition.y - position.y);
        var notMovingCheck = GameWorld.magnitude(positionDiff) < 1.5;
        
        // Check if we can see our destination
        var visionCheck = !GameWorld.checkVision(this, leader);
        
        if (visionCheck || notMovingCheck)
        {
            framesStuck++;
        }
        else
        {
            framesStuck = 0;
            herdedPath.resize(0);
        }

        
        // Check if the leader is pathfinding. If they are, also begin pathfinding to get around obstacle.
        var isLeaderPathfinding = false;
        if (Std.is(herdedLeader.getType(), Dino) && cast(herdedLeader, Dino).getIsPathfinding())
        {
            isLeaderPathfinding = true;
        }

        // If our leader is pathfinding or we're stuck, then generate a path to follow
        if ((isLeaderPathfinding || framesStuck > 6) && herdedPath.length == 0)
        {
            pathTowards(leader);
        }

        if (herdedPath.length > 0)
        {
            // We are currently following a path!
            followPath(speed);
        }
        else
        {
            // Move directly towards leader
            isPathfinding = false;
            var dir = new FlxPoint(leader.getX() - position.x, leader.getY() - position.y);
            var angle = Math.atan2(dir.y, dir.x);
            sprite.velocity.set(Math.cos(angle) * speed, Math.sin(angle) * speed);
        }
    }

    function pathTowards(entity:Entity)
    {
        pathLeader = entity;
        var position = new FlxPoint(getX(), getY());
        var leaderPosition = new FlxPoint(pathLeader.getX(), pathLeader.getY());

        // Attempt to pathfind towards herded leader
        var newPath = PlayState.world.getObstacles().findPath(leaderPosition, position, true, false, NONE);
        if (newPath != null)                     
        {                                        
            herdedPath = newPath;                
        }
        framesSincePathGenerated = 0;
    }

    function followPath(speed:Float)
    {
        if (herdedPath.length == 0) return;
        
        if (framesSincePathGenerated > 10)
        {
            pathTowards(pathLeader);
        }

        // Follow the path towards the leader
        isPathfinding = true;
        var pathPoint = herdedPath[herdedPath.length-1];
        var position = new FlxPoint(getX(), getY());
        var dir = new FlxPoint(pathPoint.x - position.x, pathPoint.y - position.y);
        if (GameWorld.magnitude(dir) < 8.0)
        {
            herdedPath.pop();
            if (herdedPath.length == 0) return;
            pathPoint = herdedPath[herdedPath.length-1];
            dir = new FlxPoint(pathPoint.x - position.x, pathPoint.y - position.y);
            if (speed > GameWorld.magnitude(dir)) {
                speed = GameWorld.magnitude(dir);
            }
        }

        var angle = Math.atan2(dir.y, dir.x);
        sprite.velocity.set(Math.cos(angle) * speed, Math.sin(angle) * speed);
        framesSincePathGenerated++;
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
        if (state != Unherded)
        {
            PlayLogger.recordUnherded(this);

            var player = herdedPlayer;
            herdedLeader = null;
            herdedFollower = null;
            herdedPlayer = null;
            state = Unherded;

            canJumpCliffs = false;
            think("?", 2.0);

            if (notify)
            {
                player.notifyUnherded(this);
            }
        }
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

    public override function handleCaveCollision(cave:Cave)
    {
        collidedWithCave = cave;
    }

    public function handleCaveDeposit(cave:Cave) {}

    function canBeCollected()
    {
        return false;
    }
}
