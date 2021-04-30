package;

import entities.*;
import entities.EntityType;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.group.FlxGroup;
import flixel.util.FlxColor;
import flixel.util.FlxStringUtil;
import haxe.macro.Type.VarAccess;
import js.html.Console;

class PlayState extends FlxState
{
	var worldWidth = 640;
	var worldHeight = 480;

	// In world entities
	var player:Player;

	// Full array of in world of entities
	var entities:Array<Entity>;

	// FlxSprite groups.
	// Maps GroupdIds (defined above) to a group containing all of that type of entity
	var spriteGroups:Map<EntityType, FlxGroup>;

	override public function create()
	{
		super.create();

		FlxG.worldBounds.set(0, 0, worldWidth, worldHeight);

		spriteGroups = new Map<EntityType, FlxGroup>();
		entities = new Array<Entity>();

		var screenBorder = new FlxSprite(0, 0);
		screenBorder.makeGraphic(640, 480, FlxColor.fromRGB(47, 79, 79, 255));
		add(screenBorder);

		// Create player
		player = new Player();
		addEntity(player);

		// Create prey
		for (i in 0...18)
		{
			var dino = new Prey();
			var x = worldWidth / 10.0 + Math.random() * worldWidth * 0.8;
			var y = worldHeight / 10.0 + Math.random() * worldHeight * 0.8;

			dino.sprite.setPosition(x, y);
			addEntity(dino);
		}

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

		// Set camera to follow player
		Console.log(FlxG.initialWidth);
		FlxG.camera.setScrollBoundsRect(0, 0, worldWidth, worldHeight);
		FlxG.camera.follow(player.sprite, TOPDOWN, 1);
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
	function addEntity(entity:Entity)
	{
		// Add to entities array
		entities.push(entity);

		// Add sprite to FlxGroup (used for collision detection)
		if (!spriteGroups.exists(entity.type))
		{
			spriteGroups[entity.type] = new FlxGroup();
		}
		spriteGroups[entity.type].add(entity.sprite);
		add(entity.sprite);
	}

	function createTree(x:Float, y:Float)
	{
		var obstacle = new Obstacle(22, 22, FlxColor.GREEN);
		obstacle.sprite.setPosition(x, y);
		addEntity(obstacle);
	}

	function collisionChecks()
	{
		var playerGroup = spriteGroups[EntityPlayer];
		var preyGroup = spriteGroups[EntityPrey];
		var obstacleGroup = spriteGroups[EntityObstacle];

		// Collision resolution -- notify entities
		FlxG.overlap(player.sprite, preyGroup, handlePlayerPreyCollision);

		// Collision resolution -- physics
		FlxG.collide(playerGroup, preyGroup);
		FlxG.collide(playerGroup, obstacleGroup);

		FlxG.collide(preyGroup, preyGroup);
		FlxG.collide(preyGroup, obstacleGroup);
	}

	/* --------------------------
		Collision handler methods
		------------------------- */
	function handlePlayerPreyCollision(e1:SpriteWrapper<Player>, e2:SpriteWrapper<Prey>)
	{
		var player = e1.entity;
		var prey = e2.entity;

		player.handlePreyCollision(prey);
		prey.handlePlayerCollision(player);
	}
}
