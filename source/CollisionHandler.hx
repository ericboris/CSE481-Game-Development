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
        
        obstacles.setTileProperties(TileType.CLIFF_DOWN_RIGHT, FlxObject.ANY, CollisionHandler.handleDownRightCliffCollision);
        obstacles.setTileProperties(TileType.CLIFF_DOWN_LEFT, FlxObject.ANY, CollisionHandler.handleDownLeftCliffCollision);
        obstacles.setTileProperties(TileType.CLIFF_UP_RIGHT, FlxObject.ANY, CollisionHandler.handleUpRightCliffCollision);
        obstacles.setTileProperties(TileType.CLIFF_UP_LEFT, FlxObject.ANY, CollisionHandler.handleUpLeftCliffCollision);
        
        obstacles.setTileProperties(TileType.CLIFF_DOWN_RIGHT_2, FlxObject.ANY, CollisionHandler.handleDownRightCliffCollision);
        obstacles.setTileProperties(TileType.CLIFF_DOWN_LEFT_2, FlxObject.ANY, CollisionHandler.handleDownLeftCliffCollision);
        obstacles.setTileProperties(TileType.CLIFF_UP_RIGHT_2, FlxObject.ANY, CollisionHandler.handleUpRightCliffCollision);
        obstacles.setTileProperties(TileType.CLIFF_UP_LEFT_2, FlxObject.ANY, CollisionHandler.handleUpLeftCliffCollision);

        obstacles.setTileProperties(TileType.WATER, FlxObject.ANY, CollisionHandler.handleWaterCollision);
        
        obstacles.setTileProperties(TileType.WATER_NC, FlxObject.NONE);

        obstacles.setTileProperties(TileType.BERRY_BUSH, FlxObject.NONE);

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
 
        obstacles.setTileProperties(TileType.CAVE_1, FlxObject.ANY, CollisionHandler.handleCaveCollision);
        obstacles.setTileProperties(TileType.CAVE_2, FlxObject.ANY, CollisionHandler.handleCaveCollision);
    }


    /* CLIFF COLLISIONS */ 
    static public function handleDownCliffCollision(tile:FlxObject, entity:FlxObject)
    {
        handleCliff(tile, entity, FlxObject.UP);
    }

    static public function handleUpCliffCollision(tile:FlxObject, entity:FlxObject)
    {
        handleCliff(tile, entity, FlxObject.DOWN);
    }

    static public function handleRightCliffCollision(tile:FlxObject, entity:FlxObject)
    {
        handleCliff(tile, entity, FlxObject.LEFT);
    }

    static public function handleLeftCliffCollision(tile:FlxObject, entity:FlxObject)
    {
        handleCliff(tile, entity, FlxObject.RIGHT);
    }

    static public function handleUpLeftCliffCollision(tile:FlxObject, entity:FlxObject)
    {
        handleCliff(tile, entity, FlxObject.DOWN, FlxObject.RIGHT);
    }

    static public function handleUpRightCliffCollision(tile:FlxObject, entity:FlxObject)
    {
        handleCliff(tile, entity, FlxObject.DOWN, FlxObject.LEFT);
    }

    static public function handleDownLeftCliffCollision(tile:FlxObject, entity:FlxObject)
    {
        handleCliff(tile, entity, FlxObject.UP, FlxObject.RIGHT);
    }

    static public function handleDownRightCliffCollision(tile:FlxObject, entity:FlxObject)
    {
        handleCliff(tile, entity, FlxObject.UP, FlxObject.LEFT);
    }

    static function handleCliff(tile: FlxObject, entity:FlxObject, direction1:Int, direction2:Int = 0)
    {
        if (Std.is(entity, SpriteWrapper))
        {
            var sprite:SpriteWrapper<Entity> = cast entity;
            var entity = sprite.entity;

            var diffX = (tile.x + tile.width/2) - entity.getX();
            var diffY = (tile.y + tile.height/2) - entity.getY();
            var isFacing = false;
            switch (direction1)
            {
                case FlxObject.UP:
                    isFacing = diffY < 0 && Math.abs(diffY) > Math.abs(diffX);
                case FlxObject.DOWN:
                    isFacing = diffY > 0 && Math.abs(diffY) > Math.abs(diffX);
                case FlxObject.LEFT:
                    isFacing = diffX < 0 && Math.abs(diffY) < Math.abs(diffX);
                case FlxObject.RIGHT:
                    isFacing = diffX > 0 && Math.abs(diffY) < Math.abs(diffX);
            }
            
            switch (direction2)
            {
                case FlxObject.UP:
                    isFacing = isFacing || diffY < 0 && Math.abs(diffY) > Math.abs(diffX);
                case FlxObject.DOWN:
                    isFacing = isFacing || diffY > 0 && Math.abs(diffY) > Math.abs(diffX);
                case FlxObject.LEFT:
                    isFacing = isFacing || diffX < 0 && Math.abs(diffY) < Math.abs(diffX);
                case FlxObject.RIGHT:
                    isFacing = isFacing || diffX > 0 && Math.abs(diffY) < Math.abs(diffX);
            }

            if (entity.getType() == EntityBoulder)
            {
                var boulder:Boulder = cast entity;
                if (direction2 == 0)
                {
                    boulder.setFacingCliff(GameWorld.oppositeDirection(direction1));
                }
            }

            if (isFacing)
            {
                entity.handleCliffCollision(direction1, direction2);
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
            if (tile == TileType.WATER_EDGE_UP_RIGHT || tile == TileType.WATER_EDGE_UP || tile == TileType.WATER_EDGE_UP_LEFT
             || tile == TileType.WATER_EDGE_RIGHT || tile == TileType.WATER_EDGE_LEFT
             || tile == TileType.WATER_EDGE_DOWN_RIGHT || tile == TileType.WATER_EDGE_DOWN || tile == TileType.WATER_EDGE_DOWN_LEFT)
            {
                tilemap.setTileByIndex(i, tile+42);
            }
        }
    }

    static function handleCaveCollision(tile:FlxObject, entity:FlxObject)
    {
        if (Std.is(entity, SpriteWrapper))
        {
            var sprite:SpriteWrapper<Entity> = cast entity;
            if (sprite.entity.getType() == EntityPlayer)
            {
                var player:Player = cast sprite.entity;
                player.handleCaveTileCollision();
            }
        }
    }
}
