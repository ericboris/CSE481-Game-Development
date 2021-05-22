package;

import entities.*;
import entities.EntityType;
import flixel.math.FlxMath;
import flixel.FlxObject;
import flixel.math.FlxPoint;
import flixel.FlxG;
import js.html.Console;

class TutorialText
{
    public var text:String;
    public var x:Float;
    public var y:Float;

    public function new(text:String, x:Float, y:Float)
    {
        this.text = text;
        this.x = x;
        this.y = y;
    }
}

class GameWorld
{
    static var levelIndex = 0;
    static var levelArray = [AssetPaths.tutorial0__json, 
                            AssetPaths.tutorial1__json,
                            AssetPaths.tutorial2__json,
                            AssetPaths.tutorial3__json,
                            AssetPaths.map3w50h50__json,
                            AssetPaths.map5w100h54__json,
                            AssetPaths.map6w119h125__json,
                            AssetPaths.map1w125h103__json,
                            AssetPaths.map2w125h125__json];

    static public function levelId()
    {
        return levelIndex;
    }

    static public function restartLevel()
    {
        levelIndex--;
    }

    static public function restart()
    {
        PlayLogger.recordGameOverTryAgain();
        Score.resetTotalScore();
        levelIndex = 0;
    }

    // New entities to display reactions above.
    static var newEntities = [EntityCave,
                            EntityPrey,
                            EntityBoulder,
                            EntityPredator,
                            EntityNull,
                            EntityNull,
                            EntityNull,
                            EntityNull,
                            EntityNull,
                            EntityNull];

    // Reactions shown above entities upon encountering player.
    static var entityReactions = [EntityCave => "V",
                                EntityPrey => ":)",
                                EntityBoulder => "V",
                                EntityPredator => ">:(",
                                EntityNull => ""];

    // Reactions shown above player upon encountering entities.
    static var playerReactions = [EntityCave => "?",
                                EntityPrey => "?",
                                EntityPredator => "!",
                                EntityBoulder => "?",
                                EntityNull => ""];

    // Tutorial info to show the player at the start of a relevant level.
    static var tutorialInformation: Map<Int, Array<TutorialText>>
                                                = [0 => [new TutorialText("Arrow keys to move", 170, 220)],
                                                   1 => [new TutorialText("Hold C to call Mammoths", 120, 270),
                                                         new TutorialText("Deliver Mammoths to the cave!", 470, 145)],
                                                   3 => [new TutorialText("Press space to swipe", 180, 350),
                                                         new TutorialText("Swiping Predators \nstuns them briefly!", 480, 120)]];

    static public function getNearestEntity(src:Entity, entities:Array<Entity>, pathfind:Bool = false):Entity
    {
        var nearestEntity = null;
        var minDistance = FlxMath.MAX_VALUE_FLOAT;

        var tile = PlayState.world.getObstacles();

        for (entity in entities)
        {
            var distance:Float;
            if (pathfind)
            {
                var start = new FlxPoint(src.getX(), src.getY());
                var end = new FlxPoint(entity.getX(), entity.getY());
                var path = tile.findPath(start, end, false);
                if (path != null)
                {
                    distance = path.length;
                }
                else
                {
                    distance = minDistance;
                }
            }
            else
            {
                distance = entityDistance(src, entity);
            }
            
            if (distance < minDistance)
            {
                minDistance = distance;
                nearestEntity = entity;
            }
        }
        
        return nearestEntity;
    }

    static public function pointDistance(x1:Float, y1:Float, x2:Float, y2:Float)
    {
        return Math.sqrt((x1 - x2) * (x1 - x2) + (y1 - y2) * (y1 - y2));
    }

    static public function entityDistance(src:Entity, dst:Entity)
    {
        var midpoint1 = src.getSprite().getMidpoint();
        var midpoint2 = dst.getSprite().getMidpoint();
        return pointDistance(midpoint1.x, midpoint1.y, midpoint2.x, midpoint2.y);
    }

    static public function entityAngle(src:Entity, dst:Entity)
    {
        var midpoint1 = src.getSprite().getMidpoint();
        var midpoint2 = dst.getSprite().getMidpoint();
        return pointAngle(1, 0, midpoint2.x - midpoint1.x, midpoint2.y - midpoint1.y);
    }

    static public function pointAngle(x1:Float, y1:Float, x2:Float, y2:Float)
    {
        var dot = x1 * x2 + y1 * y2;
        var cross = x1 * y2 - x2 * y1;
        return Math.atan2(cross, dot);
    }

    /* VISION CHECKS */
    static public function checkVision(from:Entity, to:Entity):Bool
    {
        if (checkNearbySightRadius(from, to) || checkSightRange(from, to))
        {
            var obstacles = PlayState.world.getObstacles();
            if (obstacles.ray(from.getSprite().getMidpoint(), to.getSprite().getMidpoint(), null, 4))
            {
                return true;
            }
        }
        return false;
    }

    static function checkNearbySightRadius(from:Entity, to:Entity):Bool
    {
        return GameWorld.entityDistance(from, to) < from.getNearbySightRadius();
    }

    static function checkSightRange(from:Entity, to:Entity):Bool
    {
        var range = GameWorld.entityDistance(from, to);

        var velocity = from.getSprite().velocity;
        // Angle between positive x axis and velocity vector
        var velocityAngle = GameWorld.pointAngle(1, 0, velocity.x, velocity.y);
        // Angle between the two entities
        var angleBetween = GameWorld.entityAngle(from, to);
        var angle = angleBetween - velocityAngle;

        return range < from.getSightRange() && Math.abs(angle) < from.getSightAngle() / 2;
    }

    static public function collidingWithObstacles(entity:Entity)
    {
        var sprite = entity.getSprite();
        var tilemap = PlayState.world.getObstacles();
        var staticObstacles = PlayState.world.getStaticObstacles();

        PlayState.world.toggleAdditionalTilemapCollisions(false);
        var collision1:Bool = tilemap.overlaps(sprite);
        PlayState.world.toggleAdditionalTilemapCollisions(true);
        
        var collision2:Bool = FlxG.overlap(sprite, staticObstacles);
        return collision1 || collision2;
    }

    static public function radians(degrees:Int)
    {
        return degrees * Math.PI / 180.0;
    }

    static public function magnitude(vector:FlxPoint)
    {
        return pointDistance(0, 0, vector.x, vector.y);
    }

    static public function random(min:Float, max:Float)
    {
        return Math.random() * (max - min) + min;
    }

    static public function toRadians(degrees:Int)
    {
        return degrees * Math.PI / 180.0;
    }

    static public function toDegrees(radians:Float)
    {
        return radians * 180.0 / Math.PI;
    }

    static public function getNextMap()
    {   
        if (levelIndex < levelArray.length - 1) 
        {
            return levelArray[levelIndex++];
        }
        else
        {
            return levelArray[levelIndex];
        }
    }
   
    /**
     * Return the current level's new, previously unseen Entity.
     */
    static public function getNewEntity():EntityType
    {
        return newEntities[levelIndex];
    }

    /**
     * Return EntityType e's reaction to seeing the player for the first time.
     */
    static public function getEntityReaction(e:EntityType):String
    {
        return entityReactions[e];
    }

    /**
     * Return the player's reaction to seeing EntityType e for the first time.
     */
    static public function getPlayerReaction(e:EntityType):String
    {
        return playerReactions[e];
    }

    /**
     * Return the current level's tutorial information.
     */
    static public function getTutorialInformation():Array<TutorialText>
    {
        var info = tutorialInformation[levelIndex];
        if (info == null)
        {
            return new Array<TutorialText>();
        }
        else
        {
            return tutorialInformation[levelIndex];
        }
    }

    /**
     * Maps num from the range [low1, high1] to the range [low2, high2]
     */
    static public function map(low1:Float, high1:Float, low2:Float, high2:Float, num:Float)
    {
        return (num - low1) / (high1 - low1) * (high2 - low2) + low2;
    }

    static public function oppositeDirection(dir:Int):Int
    {
        if (dir == FlxObject.LEFT)
            return FlxObject.RIGHT;
        else if (dir == FlxObject.RIGHT)
            return FlxObject.LEFT;
        else if (dir == FlxObject.UP)
            return FlxObject.DOWN;
        else if (dir == FlxObject.DOWN)
            return FlxObject.UP;
        else
            return FlxObject.NONE;
    }
}
