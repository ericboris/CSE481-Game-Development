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
import flixel.FlxBasic;
import flixel.tile.FlxTile;
import flixel.system.FlxSound;
import flixel.graphics.FlxGraphic;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.util.FlxTimer;
import flixel.FlxSubState;
import flixel.math.FlxPoint;

class MenuPlayState extends FlxState
{
    static public final SCREEN_WIDTH = 800;
    static public final SCREEN_HEIGHT = 600;

    // Size of tiles/chunks
    static public final TILE_SIZE = 16;
    static public final CHUNK_WIDTH = 640;
    static public final CHUNK_HEIGHT = 480;

    // Update every time update() is called.
    var frameCounter:Int = 0;

    // Size of map (in # of tiles)
    var mapWidth = 0;
    var mapHeight = 0;

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

    // The level's score
    var scoreText:FlxText;

    // Screen transition
    var transitioningToNextLevel:Bool = false;
    var transitionScreen:FlxSprite;

    // Used for score display
    public var numPlayerDeaths:Int = 0;
    public var numPreyDeaths:Int = 0;
    public var numPreyCollected:Int = 0;
    public var numPredatorsCollected:Int = 0;
    public var numPrey:Int = 0;
    
    var preySpawnPositions:Array<FlxPoint> = [];

    var cameraZoomDirection:Int = -1;
    var cameraZoomTween:FlxTween;

    static public var menuState:Class<FlxSubState> = MenuState;

    override public function create()
    {
        super.create();

        PlayState.world = cast this;

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
        
        // Set up the tilemap.
        player = new Player();
        map = new FlxOgmo3Loader(AssetPaths.DinoHerder__ogmo, AssetPaths.main_menu__json);

        // Static Entities.
        // Load tiles from tile maps
        ground = map.loadTilemap(AssetPaths.Tileset__png, "ground");
        ground.useScaleHack = true;
        ground.pixelPerfectRender = true;
        add(ground);

        obstacles = map.loadTilemap(AssetPaths.Tileset__png, "obstacles");
        ground.useScaleHack = true;
        ground.pixelPerfectRender = true;
        mapWidth = obstacles.widthInTiles;
        mapHeight = obstacles.heightInTiles;
        add(obstacles);
        

        ground.health = bottomLayerSortIndex() - 1;
        obstacles.health = bottomLayerSortIndex() + 1;

        // Make all obstacles collidable.
        for (x in 0...obstacles.widthInTiles)
        {
            for (y in 0...obstacles.heightInTiles)
            {
                createTileCollider(x, y, obstacles);
            }
        }

        // Load entities from tilemap
        map.loadEntities(placeEntities, "entities");

        // Set cliff collision handlers
        CollisionHandler.setTileCollisions(obstacles);
        
        // Set the initial respawn cave to be the cave nearest the player at level start.
        respawnCave = cast GameWorld.getNearestEntity(player, entityGroups[EntityCave]);

        // Set up camera
        setupCamera();

        // Set up transition screen
        transitionScreen = new FlxSprite(-10, -10);
        transitionScreen.makeGraphic(TILE_SIZE * mapWidth + 10, TILE_SIZE * mapHeight + 10, FlxColor.BLACK);
        transitionScreen.alpha = 1;
        transitionScreen.health = topLayerSortIndex() + 1;
        add(transitionScreen);


        // Spawn prey!
        for (i in 0...Score.getPreyCount())
        {
            var prey = new Prey();
            var position = preySpawnPositions[i % preySpawnPositions.length];
            prey.setPosition(position.x, position.y);
            prey.immortal = true;
            prey.setCanJumpCliffs(true);
            addEntity(prey);
        }
        
        for (i in 0...Score.getPredatorCount())
        {
            var pred = new Predator();
            var position = preySpawnPositions[i % preySpawnPositions.length];
            pred.setPosition(position.x, position.y);
            addEntity(pred);
        }

        player = new Player();
        player.setPosition(-1000, -1000);

        this.persistentDraw = true;
        this.persistentUpdate = true;
 
        openSubState(cast Type.createInstance(menuState, []));

        PlayLogger.startLevel(GameWorld.levelId());
    }

    function baseZoom():Float
    {
        return SCREEN_WIDTH / CHUNK_WIDTH;
    }

    function minZoom():Float
    {
        return baseZoom() * 0.8;
    }

    function setupCamera()
    {
        // Set world size
        FlxG.worldBounds.set(0, 0, TILE_SIZE * mapWidth, TILE_SIZE * mapHeight);

        // Set camera to follow player
        FlxG.camera.setScrollBoundsRect(0, 0, TILE_SIZE * mapWidth, TILE_SIZE * mapHeight);
        FlxG.camera.zoom = baseZoom();
        FlxG.camera.follow(player.getSprite(), TOPDOWN, 1);

        var camera_x = SCREEN_WIDTH/2;
        var camera_y = SCREEN_HEIGHT/2;
        var camera_w = CHUNK_WIDTH/4;
        var camera_h = CHUNK_HEIGHT/4;
        FlxG.camera.deadzone.set(camera_x - camera_w/2, camera_y - camera_h/2, camera_w, camera_h);
    
        FlxG.camera.pixelPerfectRender = true;
    }

    function createTileCollider(tileX:Int, tileY:Int, obstacles:FlxTilemap)
    {
        var tileNum = obstacles.getTile(tileX, tileY);
        if (tileNum == 0) return;

        var obstacle = TileType.getTileObstacle(tileNum);
        if (obstacle == null)
        {
            // This tile doesn't need a custom hitbox. Keep it in the tilemap.
        }
        else
        {
            if (!uncollidableTiles.contains(tileNum)) uncollidableTiles.push(tileNum);

            var sprite = obstacle.getSprite();
            var x = tileX * TILE_SIZE + TILE_SIZE/2 - sprite.width/2;
            var y = tileY * TILE_SIZE + TILE_SIZE/2 - sprite.height/2;
            obstacle.setPosition(x, y);
            
            if (TileType.isStatic(tileNum))
            {
                staticCollidableSprites.add(sprite);
            }
            else
            {
                collidableSprites.add(sprite);
            }
            add(sprite);
        }
    }

    override public function update(elapsed:Float)
    {
        transitionScreen.alpha -= 0.03;
        if (transitionScreen.alpha < 0.1)
            transitionScreen.alpha = 0.1;


        // Do collision checks
        // Don't do collision checks on the very first frame of execution. This prevents weird spawning in bugs.
        if (frameCounter > 0)
        {
            collisionChecks();
        }


        var score = Score.getScore();
        var confettiChance = 0;
        if (score > 0) confettiChance = 2;
        else if (score > 100) confettiChance = 15;
        for (entity in entityGroups[EntityCave])
        {
            var cave:Cave = cast entity;
            if (FlxG.random.bool(confettiChance))
            {
                cave.confetti.emit();
            }
        }

        // Update all entities
        for (entity in entities)
        {
            entity.update(elapsed);
        }

        frameCounter++;

        this.sort(sortSprites);
        super.update(elapsed);
    }
    
    public function topLayerSortIndex()
    {
        return mapHeight * TILE_SIZE * 2;
    }

    public function bottomLayerSortIndex()
    {
        return -mapHeight * TILE_SIZE;
    }

    function sortSprites(order:Int, obj1:FlxBasic, obj2:FlxBasic):Int {
        if (obj1 == null && obj2 == null)
        {
            return 0;
        }
        else if (obj1 == null)
        {
            return -1;
        }
        else if (obj2 == null)
        {
            return 1;
        }
        
        if (Std.is(obj1, FlxObject) && Std.is(obj2, FlxObject))
        {
            var sprite1:FlxObject = cast obj1;
            var sprite2:FlxObject = cast obj2;

            var y1 = sprite1.y + sprite1.height/2;
            if (sprite1.health != 1)
                y1 = sprite1.health;

            var y2 = sprite2.y + sprite2.height/2;
            if (sprite2.health != 1)
                y2 = sprite2.health;

            return cast(y1 - y2);
        }
        else
        {
            return 1;
        }
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
        entity.dead = true;
        var type = entity.getType();

        // Remove from entity arrays
        entityGroups[type].remove(entity);
        entities.remove(entity);

        // Remove from FlxGroups
        var sprite = entity.getSprite();
        spriteGroups[type].remove(sprite, true);
        collidableSprites.remove(sprite, true);
        remove(sprite, true);

        if (entity.getThought() != null)
        {
            remove(entity.getThought().sprite, true);
        }
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

        // Check cave overlap
        FlxG.overlap(collidableSprites, caveGroup, handleCollision);

        // Collision resolution -- physics
        FlxG.overlap(collidableSprites, collidableSprites, handleSeparationCollision);
        FlxG.collide(collidableSprites, staticCollidableSprites);
        
        // Collide with tilemap.
        // First, disable collisions for tiles that shouldn't be collided with.
        toggleAdditionalTilemapCollisions(false);
        // Do collision check.
        FlxG.collide(collidableSprites, obstacles);
        // Reenable the collisions.
        toggleAdditionalTilemapCollisions(true);

        // Vision checks
        // Only check vision every other frame (to save performance)
        if (frameCounter % 2 != 0)
        {
            visionChecks();
        }
    }

    function visionChecks()
    {
    }

    public function toggleAdditionalTilemapCollisions(toggle:Bool)
    {
        // Enable/Disable collisions (these collisions are used when raycasting).
        var collisions = toggle ? FlxObject.ANY : FlxObject.NONE;
        for (tileNum in uncollidableTiles)
        {
            obstacles.setTileProperties(tileNum, collisions);
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
                //addEntity(player);
            case "prey":
                preySpawnPositions.push(new FlxPoint(x, y));
            case "predator":
                var predator = new Predator();
                predator.setPosition(x, y);
                addEntity(predator);
            case "cave":
                var cave = new Cave();
                cave.setPosition(x - TILE_SIZE, y - 2 * TILE_SIZE);
                addEntity(cave, false);
                cave.confetti = new Confetti(x + TILE_SIZE/2, y - TILE_SIZE * 1.5);
                add(cave.confetti.getEmitter());
                caves.push(cave);
            case "boulder":
                var boulder = new Boulder();
                boulder.setPosition(x, y);
                addEntity(boulder);
        }
    }

    function handleCollision(s1:SpriteWrapper<Entity>, s2:SpriteWrapper<Entity>)
    {
        if (Std.is(s2, SpriteWrapper) && Std.is(s2, SpriteWrapper))
        {
            var e1 = s1.entity;
            var e2 = s2.entity;

            e1.handleCollision(e2);
            e2.handleCollision(e1);
        }
        else
        {
            Console.log("handleCollision() : UNEXPECTED TYPE");
        }
    }

    function handleSeparationCollision(s1:SpriteWrapper<Entity>, s2:SpriteWrapper<Entity>)
    {
        var e1 = s1.entity;
        var e2 = s2.entity;

        var player:Player = null;
        if (e1.getType() == EntityPlayer) player = cast e1;
        if (e2.getType() == EntityPlayer) player = cast e2;

        var prey:Prey = null;
        if (e1.getType() == EntityPrey) prey = cast e1;
        if (e2.getType() == EntityPrey) prey = cast e2;

        var pred:Predator = null;
        if (e1.getType() == EntityPredator) pred = cast e1;
        if (e2.getType() == EntityPredator) pred = cast e2;

        if (player != null && prey != null && prey.getHerdedPlayer() == player)
        {
            return;
        }
        else if (pred != null && pred.isDazed())
        {
            return;
        }
        else
        {
            // Only separate them if the other conditions are not met.
            FlxObject.separate(s1, s2);
        }
    }

    public function getObstacles()
    {
        return obstacles;
    }

    public function getStaticObstacles()
    {
        return staticCollidableSprites;
    }

    public function getPlayer()
    {
        return player;
    }
}
