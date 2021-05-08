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

    // A group containing all collidable entities
    var collidableSprites:FlxGroup;
    var staticCollidableSprites:FlxGroup;

    // The object that holds the ogmo map.
    var map:FlxOgmo3Loader;

    // The tilemaps generated from the ogmo map.
    var ground:FlxTilemap;
    var obstacles:FlxTilemap;

    var caves:Array<Cave>;

    // The level's score;
    var scoreText:FlxText;

    // Screen transition
    var transitioningToNextLevel:Bool = false;
    var transitionScreen:FlxSprite;

    override public function create()
    {
        super.create();

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

        // Set up the tilemap.
        map = new FlxOgmo3Loader(AssetPaths.DinoHerder__ogmo, GameWorld.getNextMap());

        // Static Entities.
        // Load tiles from tile maps
        ground = map.loadTilemap(AssetPaths.Tileset__png, "ground");
        ground.follow();
        add(ground);

        obstacles = map.loadTilemap(AssetPaths.Tileset__png, "obstacles");
        obstacles.follow();
        //staticCollidableSprites.add(obstacles);
        add(obstacles);

        // Load entities from tilemap
        map.loadEntities(placeEntities, "entities");
        
        // Make all obstacles collidable.
        for (x in 0...obstacles.widthInTiles)
        {
            for (y in 0...obstacles.heightInTiles)
            {
                createTileCollider(x, y, obstacles);
            }
        }

        obstacles.setTileProperties(TileType.CLIFF_DOWN, FlxObject.ANY, GameWorld.handleDownCliffCollision);
        obstacles.setTileProperties(TileType.CLIFF_RIGHT, FlxObject.ANY, GameWorld.handleRightCliffCollision);
        obstacles.setTileProperties(TileType.CLIFF_LEFT, FlxObject.ANY, GameWorld.handleLeftCliffCollision);
        obstacles.setTileProperties(TileType.CLIFF_UP, FlxObject.ANY, GameWorld.handleUpCliffCollision);
        
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

        scoreText = new FlxText(0, 0, 180, "");
        scoreText.alpha = 0;
        add(scoreText);

        // Set up transition screen
        transitionScreen = new FlxSprite(0, 0);
        transitionScreen.makeGraphic(TILE_WIDTH * mapWidth, TILE_HEIGHT * mapHeight, FlxColor.BLACK);
        transitionScreen.alpha = 1;
        add(transitionScreen);
    }

    function createTileCollider(tileX:Int, tileY:Int, obstacles:FlxTilemap)
    {
        var tileNum = obstacles.getTile(tileX, tileY);
        
        var width = TileType.getWidthOfTile(tileNum);
        var height = TileType.getHeightOfTile(tileNum);
        if (width == 16 && height == 16)
        {
            // This tile doesn't need a custom hitbox. Keep it in the tilemap.
        }
        else
        {
            obstacles.setTileProperties(tileNum, FlxObject.NONE);
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
        scoreText.x = player.getX();
        scoreText.y = player.getY() - 16;
        scoreText.text = "" + Score.get();

        // Fade out score text.
        if (scoreText.alpha > 0)
        {
            scoreText.alpha -= 0.01;
        }
    }

    override public function update(elapsed:Float)
    {
        updateTransitionScreen();
        updateScore();


        // Update all entities
        for (entity in entities)
        {
            entity.update(elapsed);
        }

        // Do collision checks
        collisionChecks();

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
        FlxG.collide(collidableSprites, obstacles);

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
}
