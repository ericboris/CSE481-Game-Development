package;

import entities.*;
import flixel.graphics.FlxGraphic;

class TileType
{
    public static final CLIFF_DOWN = 29;
    public static final CLIFF_RIGHT = 35;
    public static final CLIFF_LEFT = 37;
    public static final CLIFF_UP = 43;

    public static final CLIFF_DOWN_LEFT = 30;
    public static final CLIFF_DOWN_RIGHT = 28;
    public static final CLIFF_UP_LEFT = 44;
    public static final CLIFF_UP_RIGHT = 42;
    
    public static final CLIFF_DOWN_LEFT_2 = 32;
    public static final CLIFF_DOWN_RIGHT_2 = 31;
    public static final CLIFF_UP_LEFT_2 = 39;
    public static final CLIFF_UP_RIGHT_2 = 38;

    public static final WATER = 16;

    public static final WATER_EDGE_RIGHT = 56;
    public static final WATER_EDGE_LEFT = 58;
    public static final WATER_EDGE_UP = 50;
    public static final WATER_EDGE_DOWN = 64;
    public static final WATER_EDGE_UP_RIGHT = 55;
    public static final WATER_EDGE_UP_LEFT = 57;
    public static final WATER_EDGE_DOWN_RIGHT = 63;
    public static final WATER_EDGE_DOWN_LEFT = 65;

    public static final WATER_NC = 103;

    public static final BERRY_BUSH = 14;
    public static final TREE_2 = 15;
    public static final TREE_3 = 21;
    public static final TREE_4 = 22;
    
    public static function getTileObstacle(tile:Int):Null<Obstacle>
    {
        var tilemap = PlayState.world.getObstacles();
        switch (tile)
        {
            case BERRY_BUSH:
                var object = new BerryBush();
                return object;
            case TREE_2, TREE_3, TREE_4:
                var object = new Obstacle();
                var sprite = object.getSprite();
                sprite.loadGraphic(FlxGraphic.fromFrame(tilemap.frames.frames[tile]), false, 16, 16);
                sprite.immovable = true;
                object.setHitboxSize(4, 4);
                return object;
            default:
                return null;
        }
    }

    public static function isStatic(tile: Int)
    {
        switch (tile)
        {
            case BERRY_BUSH:
                return false;
            case TREE_2, TREE_3, TREE_4:
                return true;
            default:
                return true;
        }
    }
}
