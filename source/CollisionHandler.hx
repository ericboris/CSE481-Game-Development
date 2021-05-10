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

        obstacles.setTileProperties(TileType.WATER_EDGE_RIGHT+42, FlxObject.NONE);
        obstacles.setTileProperties(TileType.WATER_EDGE_LEFT+42, FlxObject.NONE);
        obstacles.setTileProperties(TileType.WATER_EDGE_UP+42, FlxObject.NONE);
        obstacles.setTileProperties(TileType.WATER_EDGE_DOWN+42, FlxObject.NONE);
        obstacles.setTileProperties(TileType.WATER_EDGE_UP_RIGHT+42, FlxObject.NONE);
        obstacles.setTileProperties(TileType.WATER_EDGE_UP_LEFT+42, FlxObject.NONE);
        obstacles.setTileProperties(TileType.WATER_EDGE_DOWN_RIGHT+42, FlxObject.NONE);
        obstacles.setTileProperties(TileType.WATER_EDGE_DOWN_LEFT+42, FlxObject.NONE);

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
        if (Math.abs(tile.y - entity.y) > Math.abs(tile.x - entity.x))
        {
            return;
        }
        handleWaterEdge(tile, entity, FlxObject.RIGHT);
    }

    static public function handleLeftWaterEdgeCollision(tile:FlxObject, entity:FlxObject)
    {
        if (Math.abs(tile.y - entity.y) > Math.abs(tile.x - entity.x))
        {
            return;
        }
        handleWaterEdge(tile, entity, FlxObject.LEFT);
    }

    static public function handleUpWaterEdgeCollision(tile:FlxObject, entity:FlxObject)
    {
        if (Math.abs(tile.y - entity.y) < Math.abs(tile.x - entity.x))
        {
            return;
        }
        handleWaterEdge(tile, entity, FlxObject.UP);
    }

    static public function handleDownWaterEdgeCollision(tile:FlxObject, entity:FlxObject)
    {
        if (Math.abs(tile.y - entity.y) < Math.abs(tile.x - entity.x))
        {
            return;
        }
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
                var boulder:Boulder = cast entity;
                var tilemap = PlayState.world.getObstacles();

                var waterOffset = tile.mapIndex;
                switch (direction)
                {
                    case FlxObject.RIGHT:
                        waterOffset -= 1;
                    case FlxObject.LEFT:
                        waterOffset += 1;
                    case FlxObject.UP:
                        waterOffset -= tilemap.widthInTiles;
                    case FlxObject.DOWN:
                        waterOffset += tilemap.widthInTiles;
                }

                var waterTileIndex = tilemap.getTileByIndex(waterOffset);
                if (waterTileIndex == TileType.WATER)
                {
                    disableWaterEdgeColliders(waterOffset, tilemap);

                    var coords = tilemap.getTileCoordsByIndex(waterOffset, false);
                    boulder.goIntoWater(coords.x, coords.y, waterOffset);
                }
            }
        }
    }

    static function disableWaterEdgeColliders(index: Int, tilemap:FlxTilemap)
    {
        // Check all tiles around this tile, setting any cliffs to their no collision version.
        var indices = [index-1, index+1, index+tilemap.widthInTiles, index-tilemap.widthInTiles];
        for (i in indices)
        {
            var tile = tilemap.getTileByIndex(i);
            Console.log("Hey " + i + " " + tile);
            if (tile == TileType.WATER_EDGE_UP_RIGHT || tile == TileType.WATER_EDGE_UP || tile == TileType.WATER_EDGE_UP_LEFT
             || tile == TileType.WATER_EDGE_RIGHT || tile == TileType.WATER_EDGE_LEFT
             || tile == TileType.WATER_EDGE_DOWN_RIGHT || tile == TileType.WATER_EDGE_DOWN || tile == TileType.WATER_EDGE_DOWN_LEFT)
            {
                Console.log("Updating");
                tilemap.setTileByIndex(i, tile+42);
            }
        }
        Console.log("Done");
    }
}
