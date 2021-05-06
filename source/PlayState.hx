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
 
        // Make all obstacles collidable.
        obstacles.setTileProperties(29, FlxObject.ANY, GameWorld.handleDownCliffCollision);
        obstacles.setTileProperties(35, FlxObject.ANY, GameWorld.handleRightCliffCollision);
        obstacles.setTileProperties(37, FlxObject.ANY, GameWorld.handleLeftCliffCollision);
        obstacles.setTileProperties(43, FlxObject.ANY, GameWorld.handleUpCliffCollision);

        // Tree tile indices: 14, 15, 21, 22

        staticCollidableSprites.add(obstacles);
        add(obstacles);

        // Dynamic Entities.
        // Create player
        player = new Player();
        addEntity(player);

        // Load entities from tilemap
        map.loadEntities(placeEntities, "entities");

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
    }

    override public function update(elapsed:Float)
    {
        scoreText.x = player.getX();
        scoreText.y = player.getY() - 16;
        scoreText.text = "" + Score.get();

        // Fade out score text.
        if (scoreText.alpha > 0)
        {
            scoreText.alpha -= 0.01;
        }

        // Update all entities
        for (entity in entities)
        {
            entity.update(elapsed);
        }

        // Do collision checks
        collisionChecks();

        // Check to load next level.
        if (FlxG.keys.anyPressed([N]) || player.isInRangeOfCave() && levelIsComplete())
        {
            FlxG.switchState(new PlayState());
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

        // Collision resolution

        // Check collidable entity overlap
        FlxG.overlap(playerGroup, collidableSprites, handleCollision);
        FlxG.overlap(preyGroup, collidableSprites, handleCollision);
        FlxG.overlap(hitboxGroup, collidableSprites, handleCollision);

        // Check cliff overlap
        FlxG.overlap(playerGroup, obstacles);
        FlxG.overlap(preyGroup, obstacles);

        // Check cave overlap
        FlxG.overlap(playerGroup, caveGroup, handleCollision);
        FlxG.overlap(preyGroup, caveGroup, handleCollision);

        // Collision resolution -- physics
        FlxG.collide(collidableSprites, collidableSprites);
        FlxG.collide(collidableSprites, staticCollidableSprites);

        // Vision checks
        for (predator in entityGroups[EntityPredator])
        {
            if (GameWorld.checkVision(predator, player, GameWorld.checkSightRange))
            {
                predator.seen(player);
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
                player.setPosition(x, y);
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

    function checkSightRange(from:Entity, to:Entity)
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
}
