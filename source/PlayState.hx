import entities.*;
import entities.EntityType;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.addons.editors.ogmo.FlxOgmo3Loader;
import flixel.group.FlxGroup;
import flixel.tile.FlxTilemap;
import flixel.util.FlxColor;
import js.html.Console;
import flixel.text.FlxText;
import flixel.FlxG;

class PlayState extends FlxState
{
    // A singleton reference to the global PlayState.
    public static var world:PlayState;

    static public final SCREEN_WIDTH = 800;
    static public final SCREEN_HEIGHT = 600;

    // Size of tiles/chunks
    static public final SMALL_TILE_SIZE = 16;
    static public final TILE_WIDTH = 320;
    static public final TILE_HEIGHT = 240;
 
    static final GAME_ID = 202107;
    static final GAME_KEY = "4fc8038359b26ec7a1044c1c6bc85745";
    static final GAME_NAME = "dinosaurherd";
    static final GAME_VERSION = 1;
    static public var logger = new CapstoneLogger(GAME_ID, GAME_NAME, GAME_KEY, GAME_VERSION);
    static public var createdLoggerSession = false;

    // Size of map (in # of tiles)
    var mapWidth = 2;
    var mapHeight = 2;

    // In world entities
    var player:Player;

    // Full array of in world of entities
    var entities:Array<Entity>;

    // FlxSprite groups.
    // Maps GroupdIds (defined above) to a group containing all of that type of entity
    var entityGroups:Map<EntityType, Array<Entity>>;
    var spriteGroups:Map<EntityType, FlxGroup>;
    
    var uncollidableTiles:Array<Int> = new Array<Int>();

    // A group containing all collidable entities
    var collidableSprites:FlxGroup;
    var staticCollidableSprites:FlxGroup;

    // The object that holds the ogmo map.
    var map:FlxOgmo3Loader;

    // The tilemaps generated from the ogmo map.
    var ground:FlxTilemap;
    var obstacles:FlxTilemap;

    var caves:Array<Cave>;
    var respawnCave:Cave;

    // The level's score;
    var scoreText:FlxText;

    // Screen transition
    var transitioningToNextLevel:Bool = false;
    var transitionScreen:FlxSprite;

    // This level's new, previously unseen entity.
    var newEntity:EntityType;
    var hasSeenNewEntity = false;
    var playerReaction:String;
    var entityReaction:String;

    override public function create()
    {
        super.create();

        // Initialize logger
        if (!createdLoggerSession)
        {
            // Get user id
            var userId = logger.getSavedUserId();
            if (userId == null)
            {
                // Generate new user id
                userId = logger.generateUuid();
                logger.setSavedUserId(userId);
            }

            // Start a new logging session.
            // Only start the game once the callback has been called.
            logger.startNewSession(userId, logNewSessionCallback);
        }

        // Set singleton reference
        world = this;

        // Hide the cursor
        FlxG.mouse.visible = false;

        // Initialize member variables
        entityGroups = new Map<EntityType, Array<Entity>>();
        spriteGroups = new Map<EntityType, FlxGroup>();
        entities = new Array<Entity>();
        collidableSprites = new FlxGroup();
        staticCollidableSprites = new FlxGroup();
        caves = new Array<Cave>();

        for (type in Type.allEnums(EntityType))
        {
            entityGroups[type] = new Array<Entity>();
            spriteGroups[type] = new FlxGroup();
        }

        // Must have call to getNewEntity before call to getNextMap
        newEntity = GameWorld.getNewEntity();
        playerReaction = GameWorld.getPlayerReaction(newEntity);
        entityReaction = GameWorld.getEntityReaction(newEntity);

        // Set up the tilemap.
        map = new FlxOgmo3Loader(AssetPaths.DinoHerder__ogmo, GameWorld.getNextMap());

        // Static Entities.
        // Load tiles from tile maps
        ground = map.loadTilemap(AssetPaths.Tileset__png, "ground");
        ground.follow();
        add(ground);

        obstacles = map.loadTilemap(AssetPaths.Tileset__png, "obstacles");
        obstacles.follow();
        add(obstacles);

        // Make all obstacles collidable.
        for (x in 0...obstacles.widthInTiles)
        {
            for (y in 0...obstacles.heightInTiles)
            {
                createTileCollider(x, y, obstacles);
            }
        }
        // Set cliff collision handlers
        obstacles.setTileProperties(TileType.CLIFF_DOWN, FlxObject.ANY, CollisionHandler.handleDownCliffCollision);
        obstacles.setTileProperties(TileType.CLIFF_RIGHT, FlxObject.ANY, CollisionHandler.handleRightCliffCollision);
        obstacles.setTileProperties(TileType.CLIFF_LEFT, FlxObject.ANY, CollisionHandler.handleLeftCliffCollision);
        obstacles.setTileProperties(TileType.CLIFF_UP, FlxObject.ANY, CollisionHandler.handleUpCliffCollision);

        obstacles.setTileProperties(TileType.WATER, FlxObject.ANY, CollisionHandler.handleWaterCollision);
        obstacles.setTileProperties(TileType.WATER_NC, FlxObject.NONE);
        obstacles.setTileProperties(TileType.WATER_EDGE_RIGHT_NC, FlxObject.NONE);

        obstacles.setTileProperties(TileType.WATER_EDGE_RIGHT, FlxObject.ANY, CollisionHandler.handleRightWaterEdgeCollision);

        // Load entities from tilemap
        map.loadEntities(placeEntities, "entities");
        
        // Set the initial respawn cave to be the cave nearest the player at level start.
        respawnCave = cast GameWorld.getNearestEntity(player, entityGroups[EntityCave]);

        // Set world size
        FlxG.worldBounds.set(0, 0, TILE_WIDTH * mapWidth, TILE_HEIGHT * mapHeight);

        // Set camera to follow player
        FlxG.camera.setScrollBoundsRect(0, 0, TILE_WIDTH * mapWidth, TILE_HEIGHT * mapHeight);
        FlxG.camera.zoom = SCREEN_WIDTH / TILE_WIDTH;
        FlxG.camera.follow(player.getSprite(), TOPDOWN, 1);

        var camera_x = SCREEN_WIDTH/2;
        var camera_y = SCREEN_HEIGHT/2;
        var camera_w = TILE_WIDTH/4;
        var camera_h = TILE_HEIGHT/4;
        FlxG.camera.deadzone.set(camera_x - camera_w/2, camera_y - camera_h/2, camera_w, camera_h);

        scoreText = new FlxText(0, 0, 0, "", 10);
        scoreText.alpha = 0;
        scoreText.setBorderStyle(SHADOW, FlxColor.BLACK, 1, 1);
        add(scoreText);

        // Set up transition screen
        transitionScreen = new FlxSprite(0, 0);
        transitionScreen.makeGraphic(TILE_WIDTH * mapWidth, TILE_HEIGHT * mapHeight, FlxColor.BLACK);
        transitionScreen.alpha = 1;
        add(transitionScreen);
    }

    function logNewSessionCallback(initialized:Bool)
    {
        Console.log("Logger initialized: " + initialized);
        createdLoggerSession = true;
    }

    function createTileCollider(tileX:Int, tileY:Int, obstacles:FlxTilemap)
    {
        var tileNum = obstacles.getTile(tileX, tileY);
        if (tileNum == 0) return;

        var width = TileType.getWidthOfTile(tileNum);
        var height = TileType.getHeightOfTile(tileNum);
        if (width == 16 && height == 16)
        {
            // This tile doesn't need a custom hitbox. Keep it in the tilemap.
        }
        else
        {
            if (!uncollidableTiles.contains(tileNum)) uncollidableTiles.push(tileNum);

            var x = tileX * SMALL_TILE_SIZE + SMALL_TILE_SIZE/2 - width/2;
            var y = tileY * SMALL_TILE_SIZE + SMALL_TILE_SIZE/2 - height/2;

            var collider = new StaticObject(x, y, width, height, tileNum);
            collider.immovable = true;
            collider.visible = false;

            /* Uncomment this to visualize the hitboxes*/
            /*
            var collider = new FlxSprite(x,y);
            collider.makeGraphic(width, height, FlxColor.BLACK);
            collider.updateHitbox();
            collider.immovable = true;
            collider.visible = true;
            */

            staticCollidableSprites.add(collider);
            add(collider);
        }
    }

    function updateTransitionScreen()
    {
        // Check to load next level.
        transitioningToNextLevel = player.isInRangeOfCave() && levelIsComplete();
        if (FlxG.keys.anyPressed([N]))
        {
            FlxG.switchState(new PlayState());
        }

        // Update transition screen
        if (transitioningToNextLevel)
        {
            transitionScreen.alpha += 0.03;
            if (transitionScreen.alpha >= 1.0)
            {
                // Go to next level!
                FlxG.switchState(new PlayState());
            }
        }
        else if (transitionScreen.alpha > 0)
        {
            transitionScreen.alpha -= 0.03;
        }
    }

    function updateScore()
    {
        scoreText.text = "" + Score.get();
        scoreText.x = player.getX() - scoreText.textField.textWidth/2;
        scoreText.y = player.getY() - scoreText.textField.textHeight/2 - 16;

        // Fade out score text.
        if (scoreText.alpha > 0)
        {
            scoreText.alpha -= 0.01;
        }
    }

    override public function update(elapsed:Float)
    {
        if (!createdLoggerSession)
        {
            // Don't execute update method until logger session has been created.
            return;
        }

        // Do collision checks
        collisionChecks();
 
        updateTransitionScreen();
        updateScore();
 
        // Update all entities
        for (entity in entities)
        {
            entity.update(elapsed);
        }

        if (FlxG.keys.anyPressed([P]))
        {
            var prey = new Prey();
            prey.setPosition(player.getSprite().x, player.getSprite().y);
            addEntity(prey);
        }

        super.update(elapsed);
    }

    // Adds entity to the world and respective sprite group.
    public function addEntity(entity:Entity, collidable:Bool = true)
    {
        var type = entity.getType();
        var sprite = entity.getSprite();

        // Add to entities array
        entityGroups[type].push(entity);
        entities.push(entity);

        // Add sprite to FlxGroup (used for collision detection)
        spriteGroups[type].add(sprite);
        add(sprite);

        // Add to collidable entities
        if (collidable)
        {
            collidableSprites.add(sprite);
        }
    }

    public function removeEntity(entity:Entity)
    {
        var type = entity.getType();

        // Remove from entity arrays
        entityGroups[type].remove(entity);
        entities.remove(entity);

        // Remove from FlxGroups
        var sprite = entity.getSprite();
        spriteGroups[type].remove(sprite);
        collidableSprites.remove(sprite);
        remove(sprite);
    }

    public function removeFromCollidableSprites(entity:Entity)
    {
        collidableSprites.remove(entity.getSprite());
    }

    function collisionChecks()
    {
        var playerGroup = spriteGroups[EntityPlayer];
        var preyGroup = spriteGroups[EntityPrey];
        var predatorGroup = spriteGroups[EntityPredator];
        var caveGroup = spriteGroups[EntityCave];
        var hitboxGroup = spriteGroups[EntityHitbox];
        var boulderGroup = spriteGroups[EntityBoulder];

        // Collision resolution

        // Check collidable entity overlap
        FlxG.overlap(playerGroup, collidableSprites, handleCollision);
        FlxG.overlap(preyGroup, collidableSprites, handleCollision);
        FlxG.overlap(hitboxGroup, collidableSprites, handleCollision);

        // Check cliff overlap
        FlxG.overlap(playerGroup, obstacles);
        FlxG.overlap(preyGroup, obstacles);

        // Check boulder overlap
        FlxG.overlap(playerGroup, boulderGroup, handleCollision);

        // Check cave overlap
        FlxG.overlap(playerGroup, caveGroup, handleCollision);
        FlxG.overlap(preyGroup, caveGroup, handleCollision);

        // Collision resolution -- physics
        FlxG.collide(collidableSprites, collidableSprites);
        FlxG.collide(collidableSprites, staticCollidableSprites);
        
        // Collide with tilemap.
        // First, disable collisions for tiles that shouldn't be collided with.
        for (tileNum in uncollidableTiles)
        {
            obstacles.setTileProperties(tileNum, FlxObject.NONE);
        }

        // Do collision check.
        FlxG.collide(collidableSprites, obstacles);
        
        // Reenable collisions (these collisions are used when raycasting).
        for (tileNum in uncollidableTiles)
        {
            obstacles.setTileProperties(tileNum, FlxObject.ANY);
        }


        // Vision checks
        for (predator in entityGroups[EntityPredator])
        {
            if (GameWorld.checkVision(predator, player))
            {
                predator.seen(player);
            }

            for (prey in entityGroups[EntityPrey])
            {
                if (GameWorld.checkVision(predator, prey))
                {
                    predator.seen(prey);
                }
                if (GameWorld.checkVision(prey, predator))
                {
                    prey.seen(predator);
                }
            }
        }


        if (newEntity != EntityNull)
        {
            for (entity in entityGroups[newEntity])
            {
                if (!hasSeenNewEntity && GameWorld.checkVision(player, entity)) // and in range
                {
                    player.think(playerReaction);
                    entity.think(entityReaction);
                    hasSeenNewEntity = true;
                }
            }
        }
    }

    function placeEntities(entity:EntityData)
    {
        var x = entity.x;
        var y = entity.y;

        switch (entity.name)
        {
            case "player":
                player = new Player();
                player.setPosition(x, y);
                addEntity(player);
            case "prey":
                var prey = new Prey();
                prey.setPosition(x, y);
                addEntity(prey);
            case "predator":
                var predator = new Predator();
                predator.setPosition(x, y);
                addEntity(predator);
            case "cave":
                var cave = new Cave();
                cave.setPosition(x, y);
                addEntity(cave, false);
                caves.push(cave);
            case "boulder":
                var boulder = new Boulder();
                boulder.setPosition(x, y);
                addEntity(boulder);
        }
    }

    function handleCollision(s1:SpriteWrapper<Entity>, s2:SpriteWrapper<Entity>)
    {
        var e1 = s1.entity;
        var e2 = s2.entity;

        e1.handleCollision(e2);
        e2.handleCollision(e1);
    }

    public function getCaves()
    {
        return caves;
    }

    function levelIsComplete()
    {
        return entityGroups[EntityPrey].length == 0;
    }

    public function incrementScore(amount:Int):Void
    {
        Score.increment(amount);
        scoreText.alpha = 1;
    }

    public function getObstacles()
    {
        return obstacles;
    }

    public function getStaticObstacles()
    {
        return staticCollidableSprites;
    }

    public function triggerLevelTransition()
    {
        transitioningToNextLevel = true;
    }

    public function getRespawnCave():Cave
    {
        return this.respawnCave;
    }

    public function setRespawnCave(cave:Cave):Void
    {
        this.respawnCave = cave;
    }
}
