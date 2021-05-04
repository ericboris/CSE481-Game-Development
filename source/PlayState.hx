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

class PlayState extends FlxState
{
    // A singleton reference to the global PlayState.
    public static var world:PlayState;

    var worldWidth = 640;
    var worldHeight = 480;

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

    override public function create()
    {
        super.create();

        // Set singleton reference
        world = this;

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
        map = new FlxOgmo3Loader(AssetPaths.DinoHerder__ogmo, AssetPaths.tutorial0__json);

        spriteGroups[EntityCave] = new FlxGroup();
        spriteGroups[EntityPrey] = new FlxGroup();
        spriteGroups[EntityHitbox] = new FlxGroup();

        // Static Entities.
        // Load tiles from tile maps
        ground = map.loadTilemap(AssetPaths.Tileset__png, "ground");
        ground.follow();
        ground.setTileProperties(1, FlxObject.NONE);
        ground.setTileProperties(2, FlxObject.NONE);
        ground.setTileProperties(36, FlxObject.NONE);
        ground.setTileProperties(17, FlxObject.NONE);
        ground.setTileProperties(18, FlxObject.NONE);
        ground.setTileProperties(24, FlxObject.NONE);
        ground.setTileProperties(25, FlxObject.NONE);
        add(ground);

        obstacles = map.loadTilemap(AssetPaths.Tileset__png, "obstacles");
        obstacles.follow();
        // Make all obstacles collidable.
        obstacles.setTileProperties(29, FlxObject.ANY, GameWorld.handleDownCliffCollision);
        obstacles.setTileProperties(35, FlxObject.ANY, GameWorld.handleRightCliffCollision);
        obstacles.setTileProperties(37, FlxObject.ANY, GameWorld.handleLeftCliffCollision);
        obstacles.setTileProperties(43, FlxObject.ANY, GameWorld.handleUpCliffCollision);

        staticCollidableSprites.add(obstacles);
        add(obstacles);

        // Dynamic Entities.
        // Create player
        player = new Player();
        addEntity(player);

        // Load entities from tilemap
        map.loadEntities(placeEntities, "entities");

        // Set world size
        FlxG.worldBounds.set(0, 0, worldWidth, worldHeight);

        // Set camera to follow player
        FlxG.camera.setScrollBoundsRect(0, 0, worldWidth, worldHeight);
        FlxG.camera.follow(player.getSprite(), TOPDOWN, 1);
    }

    override public function update(elapsed:Float)
    {
        // Update all entities
        for (entity in entities)
        {
            entity.update(elapsed);
        }

        // Do collision checks
        collisionChecks();

        super.update(elapsed);
    }

    // Adds entity to the world and respective sprite group.
    public function addEntity(entity:Entity, collidable:Bool = true)
    {
        var type = entity.getType();
        var sprite = entity.getSprite();

        // Add to entities array
        entities.push(entity);

        // Add sprite to FlxGroup (used for collision detection)
        if (!spriteGroups.exists(type))
        {
            spriteGroups[type] = new FlxGroup();
        }
        spriteGroups[type].add(sprite);
        add(sprite);

        if (!entityGroups.exists(type))
        {
            entityGroups[type] = new Array<Entity>();
        }
        entityGroups[type].push(entity);

        // Add to collidable entities
        if (collidable)
        {
            collidableSprites.add(sprite);
        }
    }

    /**
    function createTree(x:Float, y:Float)
    {
        var obstacle = new Obstacle(22, 22, FlxColor.GREEN);
        obstacle.setPosition(x, y);
        addEntity(obstacle);
    }
    */

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
            checkVision(predator, player);
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
            /**
            case "tree":
                createTree(x, y);
            */
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

    function checkVision(from:Entity, to:Entity)
    {
        var range = GameWorld.entityDistance(from, to);

        var velocity = from.getSprite().velocity;
        // Angle between positive x axis and velocity vector
        var velocityAngle = GameWorld.pointAngle(1, 0, velocity.x, velocity.y);
        // Angle between the two entities
        var angleBetween = GameWorld.entityAngle(from, to);
        var angle = angleBetween - velocityAngle;
        
        if (range < from.getSightRange() && Math.abs(angle) < from.getSightAngle() / 2)
        {
            // TODO: Update cliffs tilemap to full tilemap
            if (obstacles.ray(from.getSprite().getMidpoint(), to.getSprite().getMidpoint(), null, 4))
            {
                from.seen(to);
                //from.addSeen(to);
                //from.toPosition = to.getMidpoint();
            }
        }
    }
}
