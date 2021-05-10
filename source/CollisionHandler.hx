package;

import entities.*;
import entities.EntityType;
import flixel.math.FlxMath;
import flixel.FlxObject;
import flixel.math.FlxPoint;
import flixel.FlxG;
import js.html.Console;
import flixel.tile.FlxTile;
import flixel.tile.FlxTilemap;

class CollisionHandler
{
    static public function setTileCollisions(obstacles: FlxTilemap)
    {
        obstacles.setTileProperties(TileType.CLIFF_DOWN, FlxObject.ANY, CollisionHandler.handleDownCliffCollision);
        obstacles.setTileProperties(TileType.CLIFF_RIGHT, FlxObject.ANY, CollisionHandler.handleRightCliffCollision);
        obstacles.setTileProperties(TileType.CLIFF_LEFT, FlxObject.ANY, CollisionHandler.handleLeftCliffCollision);
        obstacles.setTileProperties(TileType.CLIFF_UP, FlxObject.ANY, CollisionHandler.handleUpCliffCollision);

        obstacles.setTileProperties(TileType.WATER, FlxObject.ANY, CollisionHandler.handleWaterCollision);
        
        obstacles.setTileProperties(TileType.WATER_NC, FlxObject.NONE);

        obstacles.setTileProperties(TileType.WATER_EDGE_RIGHT_NC, FlxObject.NONE);
        obstacles.setTileProperties(TileType.WATER_EDGE_LEFT_NC, FlxObject.NONE);
        obstacles.setTileProperties(TileType.WATER_EDGE_UP_NC, FlxObject.NONE);
        obstacles.setTileProperties(TileType.WATER_EDGE_DOWN_NC, FlxObject.NONE);

        obstacles.setTileProperties(TileType.WATER_EDGE_RIGHT, FlxObject.ANY, CollisionHandler.handleRightWaterEdgeCollision);
        obstacles.setTileProperties(TileType.WATER_EDGE_LEFT, FlxObject.ANY, CollisionHandler.handleLeftWaterEdgeCollision);
        obstacles.setTileProperties(TileType.WATER_EDGE_UP, FlxObject.ANY, CollisionHandler.handleUpWaterEdgeCollision);
        obstacles.setTileProperties(TileType.WATER_EDGE_DOWN, FlxObject.ANY, CollisionHandler.handleDownWaterEdgeCollision);
    }


    /* CLIFF COLLISIONS */ 
    static public function handleDownCliffCollision(tile:FlxObject, entity:FlxObject)
    {
        handleCliff(entity, FlxObject.UP);
    }

    static public function handleUpCliffCollision(tile:FlxObject, entity:FlxObject)
    {
        handleCliff(entity, FlxObject.DOWN);
    }

    static public function handleRightCliffCollision(tile:FlxObject, entity:FlxObject)
    {
        handleCliff(entity, FlxObject.LEFT);
    }

    static public function handleLeftCliffCollision(tile:FlxObject, entity:FlxObject)
    {
        handleCliff(entity, FlxObject.RIGHT);
    }

    static function handleCliff(entity:FlxObject, direction:Int)
    {
        if (Std.is(entity, SpriteWrapper))
        {
            var sprite:SpriteWrapper<Entity> = cast entity;
            var entity = sprite.entity;
            if (entity.getSprite().facing == direction)
            {
                entity.handleCliffCollision(direction);
            }
        }
    }

    static public function handleWaterCollision(object1:FlxObject, object2:FlxObject)
    {
        if (Std.is(object1, FlxTile) && Std.is(object2, SpriteWrapper))
        {
            var sprite:SpriteWrapper<Entity> = cast object2;
            var tile:FlxTile = cast object1;

            var tilemap = PlayState.world.getObstacles();

            if (sprite.entity.getType() == EntityBoulder)
            {
                var boulder:Boulder = cast sprite.entity;

                boulder.goIntoWater(tile.x, tile.y, tile.mapIndex);
            }
        }
    }


    /* WATER RIDGE & BOULDER COLLISIONS */
    static public function handleRightWaterEdgeCollision(tile:FlxObject, entity:FlxObject)
    {
        handleWaterEdge(tile, entity, FlxObject.RIGHT);
    }

    static public function handleLeftWaterEdgeCollision(tile:FlxObject, entity:FlxObject)
    {
        handleWaterEdge(tile, entity, FlxObject.LEFT);
    }

    static public function handleUpWaterEdgeCollision(tile:FlxObject, entity:FlxObject)
    {
        handleWaterEdge(tile, entity, FlxObject.UP);
    }

    static public function handleDownWaterEdgeCollision(tile:FlxObject, entity:FlxObject)
    {
        handleWaterEdge(tile, entity, FlxObject.DOWN);
    }

    static function handleWaterEdge(object1:FlxObject, object2:FlxObject, direction:Int)
    {
        if (Std.is(object1, FlxTile) && Std.is(object2, SpriteWrapper))
        {
            var sprite:SpriteWrapper<Entity> = cast object2;
            var entity = sprite.entity;

            var tile:FlxTile = cast object1;

            if (entity.getType() == EntityBoulder)
            {
                var tilemap = PlayState.world.getObstacles();

                var expectedTile:Int = 0;
                var offset = 0;
                switch (direction)
                {
                    case FlxObject.RIGHT:
                        expectedTile = TileType.WATER_EDGE_LEFT;
                        offset = -2;
                    case FlxObject.LEFT:
                        expectedTile = TileType.WATER_EDGE_RIGHT;
                        offset = 2;
                    case FlxObject.UP:
                        expectedTile = TileType.WATER_EDGE_DOWN;
                        offset = -tilemap.widthInTiles * 2;
                    case FlxObject.DOWN:
                        expectedTile = TileType.WATER_EDGE_UP;
                        offset = tilemap.widthInTiles * 2;
                }

                var tileIndex = tilemap.getTileByIndex(tile.mapIndex + offset);
                if (tileIndex == expectedTile)
                {
                    // Remove collider on adjacent edge
                    tilemap.setTileByIndex(tile.mapIndex + offset, tileIndex + 42, false);
                }

                // Remove collider on current edge
                tilemap.setTileByIndex(tile.mapIndex, tile.index + 42, false);
            }
        }
    }
}
