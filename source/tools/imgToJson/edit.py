import json
import random
from copy import deepcopy
from argparse import ArgumentParser, ArgumentDefaultsHelpFormatter

LAYERS_INDEX = 'layers'
ENTITY_LAYER_INDEX = 0
OBSTACLE_LAYER_INDEX = 1
DATA_INDEX = 'data'
ENTITIES_INDEX = 'entities'
ENTITY_NAME_KEY = 'name'
ENTITY_X_KEY = 'x'
ENTITY_Y_KEY = 'y'
COLS_INDEX = 'gridCellsX'
ROWS_INDEX = 'gridCellsY'

EMPTY = -1

PREY_NAME = 'prey'
PREY_EID = '72472484'

PREDATOR_NAME = 'predator'
PREDATOR_EID = '72474834'

entityId = 0

def main(args):
    infile = str(args.infile)
    assert (infile != ''), 'Must provide a file'
    outfile = str(args.outfile)
    if outfile == '':
        outfile = infile
    entity = str(args.type)
    density = float(args.density)

    # Load json file.
    with open(infile, 'r') as f:
        root = json.load(f)

    # Compute the empty tile area and empty tile (x, y) coordinates. 
    area, emptyTiles = getEmptyTiles(root, entity)

    # Get copy of root with instances of entity removed from entities.
    root = removeEntities(root, entity)

    # Insert new entities to the entities dict.
    root = addNewEntities(root, entity, density, area, emptyTiles)

    # Save the file.
    rootJson = json.dumps(root, indent=2)
    with open(outfile, 'w') as f:
        f.write(rootJson)


def getEmptyTiles(root, entityName):
    '''
    Return the count of empty tiles and a list of (x, y) coordinate pairs 
    representing the tiles eligible to receive an entity.
    Count of empty tiles doesn't necessarily equal len(totalEmptyTiles)
    '''
    emptyObstacleTiles = getEmptyObstacleTiles(root[LAYERS_INDEX][OBSTACLE_LAYER_INDEX])

    nonEmptyEntityTiles = getNonEmptyEntityTiles(root[LAYERS_INDEX][ENTITY_LAYER_INDEX], entityName)

    assert (len(emptyObstacleTiles) >= len(nonEmptyEntityTiles)), 'There must be more empty than non-empty tiles.'

    totalEmptyTiles = []

    for tile in emptyObstacleTiles:
        if tile not in nonEmptyEntityTiles:
            totalEmptyTiles.append(tile)

    return len(emptyObstacleTiles), totalEmptyTiles
 

def getEmptyObstacleTiles(obstacleLayer):
    '''
    Return a list of (x, y) coordinate pairs of empty tiles on the obstacles layer.
    '''
    cols = obstacleLayer[COLS_INDEX]
    rows = obstacleLayer[ROWS_INDEX]
    obstacles = obstacleLayer[DATA_INDEX]
    i = 0

    emptyTiles = []

    for y in range(rows):
        for x in range(cols):
            if obstacles[i] == EMPTY:
                emptyTiles.append((x, y))
            i += 1
    
    return emptyTiles


def getNonEmptyEntityTiles(entitiesLayer, entityName):
    '''
    Return a list of (x, y) coordinate pairs of non-empty tiles on the entities layer.
    Non-empty tiles are all those with names not matching the given entityName.
    '''
    nonEmptyTiles = []

    for entity in entitiesLayer[ENTITIES_INDEX]:
        if entity[ENTITY_NAME_KEY] != entityName:
            x = entity[ENTITY_X_KEY] // 16
            y = entity[ENTITY_Y_KEY] // 16
            nonEmptyTiles.append((x, y))

    return nonEmptyTiles


def removeEntities(root, entityName):
    '''
    Return root with all instances of entities with name matching entityName removed.
    '''
    entities = root[LAYERS_INDEX][ENTITY_LAYER_INDEX][ENTITIES_INDEX]

    newEntities = []
    
    for entity in entities:
        if entity[ENTITY_NAME_KEY] != entityName:
            newEntities.append(entity)

    # Prevent side-effects.
    newRoot = deepcopy(root)
    newRoot[LAYERS_INDEX][ENTITY_LAYER_INDEX][ENTITIES_INDEX] = newEntities

    return newRoot


def numToAdd(density, area):
    '''
    Return the number of new entities to add based on entity density and empty
    tile area.
    '''
    return int(density * area)


def getPreyEntity(x, y): 
    ''' 
    Return a prey type entity entry.
    '''
    global entityId
    e = _getEntity(PREY_NAME, entityId, PREY_EID, x, y)
    entityId += 1
    return e


def getPredatorEntity(x, y): 
    '''
    Return a predator type enitity entry.
    '''
    global entityId
    e = _getEntity(PREDATOR_NAME, entityId, PREDATOR_EID, x, y)
    entityId += 1
    return e


def _getEntity(name, ID, _eid, x, y, originX=0, originY=0):
    ''' 
    Return a typed entity.
    '''
    # Called by getPreyEntity and getPredatorEntity.
    return {'name': name,
            'id': ID, 
            '_eid': _eid,
            'x': x,
            'y': y,
            'originX': originX,
            'originY': originY}


def addNewEntities(root, newEntityName, density, area, emptyTiles):
    '''
    Return root with newEntities added at the given density.
    '''
    # Prevent side-effects.
    newRoot = deepcopy(root)

    toAdd = numToAdd(density, area)
    numAdded = 0

    while numAdded < toAdd:
        # Place new entity on a randomly chosen tile.
        x, y = random.choice(emptyTiles)

        # Remove that tile from the list since it's no longer empty.
        emptyTiles.remove((x, y))

        # Get a new entity.
        if (newEntityName == PREY_NAME):
            newEntity = getPreyEntity(x*16, y*16)
        else:
            newEntity = getPredatorEntity(x*16, y*16)

        # Add the new entity to the entities list.
        newRoot[LAYERS_INDEX][ENTITY_LAYER_INDEX][ENTITIES_INDEX].append(newEntity)

        numAdded += 1

    return newRoot


if __name__ == '__main__':
    parser = ArgumentParser(formatter_class=ArgumentDefaultsHelpFormatter)
    parser.add_argument('--infile', help='File to convert to json', default='')
    parser.add_argument('--outfile', help='Output file name', default='')
    parser.add_argument('--type', help='Type of entity to add "prey" or "predator", default="prey"', default='prey')
    parser.add_argument('--density', help='Density of entity, default=0.03', default=0.03)
    args = parser.parse_args()

    main(args)
