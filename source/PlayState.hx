package;

import entities.*;
import entities.EntityType;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.group.FlxGroup;
import flixel.util.FlxColor;

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
	var spriteGroups:Map<EntityType, FlxGroup>;

	// A group containing all collidable entities
	var collidableSprites:FlxGroup;

	override public function create()
	{
		super.create();

		// Set singleton reference
		world = this;

		spriteGroups = new Map<EntityType, FlxGroup>();
		entities = new Array<Entity>();
		collidableSprites = new FlxGroup();

		// Set world size
		FlxG.worldBounds.set(0, 0, worldWidth, worldHeight);

		// Create background sprite
		var ground = new FlxSprite(0, 0);
		ground.makeGraphic(640, 480, FlxColor.fromRGB(47, 79, 79, 255));
		add(ground);

		// Create ridge
		var ridge = new Ridge(7, cast(worldHeight / 2, Int), FlxObject.LEFT);
		ridge.setPosition(worldWidth / 2, 0);
		addEntity(ridge);

		// Create tree boundaries
		for (x in 0...21)
		{
			createTree(x * worldWidth / 21, 0);
			createTree(x * worldWidth / 21, worldHeight - 22);
		}
		for (y in 0...16)
		{
			createTree(0, y * worldHeight / 16);
			createTree(worldWidth - 22, y * worldHeight / 16);
		}

		// Create cave
		var cave = new Cave();
		cave.setPosition(160, 120);
		addEntity(cave);

		// Create player
		player = new Player();
		addEntity(player);

		// Create prey
		for (i in 0...18)
		{
			var dino = new Prey();
			var x = worldWidth / 10.0 + Math.random() * worldWidth * 0.8;
			var y = worldHeight / 10.0 + Math.random() * worldHeight * 0.8;

			dino.setPosition(x, y);
			addEntity(dino);
		}

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

		// Add to collidable entities
		if (collidable)
		{
			collidableSprites.add(sprite);
		}
	}

	function createTree(x:Float, y:Float)
	{
		var obstacle = new Obstacle(22, 22, FlxColor.GREEN);
		obstacle.setPosition(x, y);
		addEntity(obstacle);
	}

	function collisionChecks()
	{
		var playerGroup = spriteGroups[EntityPlayer];
		var preyGroup = spriteGroups[EntityPrey];
		var caveGroup = spriteGroups[EntityCave];
		var hitboxGroup = spriteGroups[EntityHitbox];

		// Collision resolution -- notify entities of collisions
		FlxG.overlap(playerGroup, preyGroup, handleCollision);
		FlxG.overlap(playerGroup, caveGroup, handleCollision);
		FlxG.overlap(hitboxGroup, collidableSprites, handleCollision);
		FlxG.overlap(caveGroup, preyGroup, handleCollision);

		// Collision resolution -- physics
		FlxG.collide(collidableSprites, collidableSprites);
	}

	/* --------------------------
		Collision handler methods
		------------------------- */
	function handleCollision(s1:SpriteWrapper<Entity>, s2:SpriteWrapper<Entity>)
	{
		var e1 = s1.entity;
		var e2 = s2.entity;

		e1.handleCollision(e2);
		e2.handleCollision(e1);
	}
}
