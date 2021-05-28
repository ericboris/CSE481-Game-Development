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

    static var levelArrayA = [//AssetPaths.tutorial0__json, 
                            AssetPaths.tutorial1__json,
                            AssetPaths.tutorial2__json,
                            AssetPaths.tutorial3__json,
                            AssetPaths.map7w50h22__json,
                            AssetPaths.map3w50h50__json,
                            AssetPaths.map8w75h75__json,
                            AssetPaths.map5w100h54__json,
                            AssetPaths.map6w119h125__json,
                            AssetPaths.map1w125h103__json,
                            AssetPaths.map2w125h125__json];

    static var levelArrayB = [//AssetPaths.tutorial0__json, 
                            AssetPaths.tutorial1__json,
                            //AssetPaths.tutorial2__json,
                            AssetPaths.tutorial3__json,
                            AssetPaths.map7w75h33__json,
                            AssetPaths.map3w100h100__json,
                            AssetPaths.map8w125h125__json,
                            AssetPaths.map5w150h84__json,
                            AssetPaths.map6w150h158__json,
                            AssetPaths.map1w200h165__json,
                            AssetPaths.map2w200h200__json];

    static var lowDensityLevels = [//AssetPaths.tutorial0__json, 
                            AssetPaths.tutorial1__json,
                            AssetPaths.tutorial2__json,
                            AssetPaths.tutorial3__json,
                            AssetPaths.map1low__json,
                            AssetPaths.map2low__json,
                            AssetPaths.map3low__json];
                            

    static var levelChoice:Int;

    static var levelSizeMap = [0 => levelArrayA,
                               1 => levelArrayB];

    static var newEntities = [0 => EntityPrey,
                              1 => EntityBoulder,
                              2 => EntityPredator];

    static var ABChoiceIsMade:Bool = false;

    static var playerSpeedChoice:Int;
    static var playerSpeedMap = [0 => 100.0,
                              1 => 120.0];

    static var levelDensityChoice:Int;
    static var levelDensityMap = [0 => lowDensityLevels,
                                  1 => lowDensityLevels];


    static public function getABChoice()
    {
        var ABChoice:Int;
        if (levelIndex == 0 && !ABChoiceIsMade)
        {
            ABChoice = FlxG.random.int(0, 2);
            switch (ABChoice)
            {
                case 0:
                    levelDensityChoice = 0;
                    playerSpeedChoice = 0;
                case 1:
                    levelDensityChoice = 1;
                    playerSpeedChoice = 0;
                case 2:
                    levelDensityChoice = 0;
                    playerSpeedChoice = 1;
                case 3:
                    levelDensityChoice = 1;
                    playerSpeedChoice = 1;
            }
            PlayLogger.recordLevelDensityChoice(levelDensityChoice);
            PlayLogger.recordPlayerSpeedChoice(playerSpeedChoice);
            ABChoiceIsMade = true;
        }
    }

    static public function getLevelArray()
    {
        /** No longer needed for A/B tests. 
        if (levelIndex == 0)
        {
            levelChoice = FlxG.random.int(0, 1);
            PlayLogger.recordLevelChoice(levelChoice);
        }
        */
        levelChoice = 0;
        return levelSizeMap[levelChoice];
    }

    static public function getPlayerSpeed()
    {
        Console.log("PLAYER SPEED = " + playerSpeedChoice);
        return playerSpeedMap[playerSpeedChoice];
    }

    static public function getLevelDensity()
    {
        Console.log("LEVEL DENSITY = " + levelDensityChoice);
        return levelDensityMap[levelDensityChoice];
    }

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
        Score.resetScore();
        levelIndex = 0;
    }

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
                                                = [0 => [new TutorialText("WASD to Move", 125, 230),
                                                         new TutorialText("Space to Call Mammoths", 350, 266),
                                                         new TutorialText("lead Mammoths to Caves", 470, 145)],
                                                   1 => [new TutorialText("Shift to Swipe", 160, 370),
                                                         new TutorialText("Swipe to Stun Predators", 515, 170)]];

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
        var la = getLevelDensity();
        if (levelIndex < la.length) 
        {
            return la[levelIndex++];
        }
        else
        {
            return null;
        }
    }
   
    /**
     * Return the current level's new, previously unseen Entity.
     */
    static public function getNewEntity():EntityType
    {
        if (newEntities.exists(levelIndex))
        {
            return newEntities[levelIndex];
        }
        return EntityNull;
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
