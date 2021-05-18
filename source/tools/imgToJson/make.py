import numpy as np
import json
import random
import perlin
from PIL import Image
from argparse import ArgumentParser, ArgumentDefaultsHelpFormatter


TILESET = 'tiles'

ENTITIES_NAME = 'entities'
ENTITIES_EID = '72465116'

OBSTACLES_NAME = 'obstacles'
OBSTACLES_EID = '72467368'

GROUND_NAME = 'ground'
GROUND_EID = '84372284'

PREY_NAME = 'prey'
PREY_EID = '72472484'

PREDATOR_NAME = 'predator'
PREDATOR_EID = '72474834'

GRASS_TILES = {0: 36, 1: 1, 2: 2}
WATER_TILE = 16

EMPTY = -1
TOP_LEFT_OUT = 0
TOP_CENTER = 1
TOP_RIGHT_OUT = 2
LEFT = 3
CENTER = 4
RIGHT = 5
BOTTOM_LEFT_OUT = 6
BOTTOM_CENTER = 7
BOTTOM_RIGHT_OUT = 8
TOP_LEFT_IN = 9
TOP_RIGHT_IN = 10
BOTTOM_LEFT_IN = 11
BOTTOM_RIGHT_IN = 12

TREE_TILEMAP = {0: 14,
                1: 15,
                2: 21,
                3: 22,
                4: 53}

GRASS_TILEMAP = {-1: -1,
                0: 28,
                1: 29,
                2: 30,
                3: 35,
                4: -1,
                5: 37,
                6: 42,
                7: 43,
                8: 44,
                9: 39,
                10: 38,
                11: 32,
                12: 31}

WATER_TILEMAP = {-1: 16,
                0: 49,
                1: 50,
                2: 51,
                3: 56,
                4: 16,
                5: 58,
                6: 63,
                7: 64,
                8: 65,
                9: 67,
                10: 66,
                11: 60,
                12: 59}

OBSTACLE_TILEMAP = {(0, 0, 0, 0, 1, 1, 0, 1, 1): TOP_LEFT_OUT,
                    (0, 0, 0, 1, 1, 1, 1, 1, 1): TOP_CENTER,
                    (0, 0, 0, 1, 1, 0, 1, 1, 0): TOP_RIGHT_OUT,
                    (0, 1, 1, 0, 1, 1, 0, 1, 1): LEFT,
                    (1, 1, 1, 1, 1, 1, 1, 1, 0): TOP_LEFT_IN,
                    (1, 1, 1, 1, 1, 1, 1, 0, 1): BOTTOM_CENTER,
                    (1, 1, 1, 1, 1, 1, 0, 1, 1): TOP_RIGHT_IN,
                    (1, 1, 0, 1, 1, 0, 1, 1, 0): RIGHT,
                    (1, 1, 1, 1, 1, 0, 1, 1, 1): RIGHT,
                    (1, 1, 1, 0, 1, 1, 1, 1, 1): LEFT,
                    (1, 1, 1, 1, 1, 1, 1, 0, 0): BOTTOM_CENTER,
                    (1, 1, 1, 1, 1, 1, 0, 0, 1): BOTTOM_CENTER,
                    (1, 1, 0, 1, 1, 1, 1, 1, 1): BOTTOM_LEFT_IN,
                    (1, 0, 1, 1, 1, 1, 1, 1, 1): TOP_CENTER,
                    (0, 1, 1, 1, 1, 1, 1, 1, 1): BOTTOM_RIGHT_IN,
                    (1, 1, 1, 1, 1, 0, 1, 1, 0): RIGHT,
                    (1, 1, 1, 0, 1, 1, 0, 1, 1): LEFT,
                    (1, 1, 1, 1, 1, 1, 0, 0, 0): BOTTOM_CENTER,
                    (0, 1, 1, 0, 1, 1, 0, 0, 0): BOTTOM_LEFT_OUT,
                    (1, 1, 0, 1, 1, 0, 0, 0, 0): BOTTOM_RIGHT_OUT,
                    (1, 1, 0, 1, 1, 0, 1, 1, 1): RIGHT,
                    (0, 1, 1, 0, 1, 1, 1, 1, 1): LEFT,
                    (1, 0, 0, 1, 1, 1, 1, 1, 1): TOP_CENTER,
                    (0, 0, 1, 1, 1, 1, 1, 1, 1): TOP_CENTER,
                    (0, 0, 0, 0, 1, 1, 1, 1, 1): TOP_LEFT_OUT,
                    (0, 0, 0, 1, 1, 0, 1, 1, 1): TOP_RIGHT_OUT,
                    (0, 0, 1, 0, 1, 1, 0, 1, 1): TOP_LEFT_OUT,
                    (1, 0, 0, 1, 1, 0, 1, 1, 0): TOP_RIGHT_OUT,
                    (0, 1, 1, 0, 1, 1, 0, 0, 1): BOTTOM_LEFT_OUT,
                    (1, 1, 0, 1, 1, 0, 1, 0, 0): BOTTOM_RIGHT_OUT,
                    (1, 1, 1, 0, 1, 1, 0, 0, 0): BOTTOM_LEFT_OUT,
                    (1, 1, 1, 1, 1, 0, 0, 0, 0): BOTTOM_RIGHT_OUT,
                    (1, 1, 1, 1, 1, 0, 1, 0, 0): BOTTOM_RIGHT_OUT,
                    (1, 1, 1, 0, 1, 1, 0, 0, 1): BOTTOM_LEFT_OUT,
                    (1, 0, 0, 1, 1, 0, 1, 1, 1): TOP_RIGHT_OUT,
                    (0, 0, 1, 0, 1, 1, 1, 1, 1): TOP_LEFT_OUT,
                    (0, 0, 0, 0, 1, 1, 0, 1, 0): RIGHT,
                    (0, 1, 0, 1, 1, 1, 1, 1, 1): TOP_CENTER,
                    (0, 1, 1, 1, 1, 1, 1, 1, 0): BOTTOM_LEFT_OUT,
                    (0, 0, 1, 1, 1, 1, 1, 1, 0): TOP_RIGHT_OUT,
                    (1, 1, 0, 1, 1, 1, 1, 1, 0): RIGHT,
                    (0, 1, 1, 1, 1, 1, 1, 0, 0): BOTTOM_LEFT_OUT,
                    (0, 0, 0, 1, 1, 1, 0, 1, 1): TOP_LEFT_OUT,
                    (1, 1, 1, 1, 1, 1, 0, 1, 0): BOTTOM_CENTER,
                    (0, 1, 1, 1, 1, 1, 0, 1, 1): LEFT,
                    (0, 0, 0, 1, 1, 1, 1, 1, 0): TOP_RIGHT_OUT,
                    (1, 0, 1, 1, 1, 1, 0, 1, 1): TOP_LEFT_OUT,
                    (0, 1, 1, 0, 1, 1, 1, 0, 1): BOTTOM_LEFT_OUT,
                    (1, 1, 0, 1, 1, 1, 0, 0, 1): BOTTOM_RIGHT_OUT,
                    (1, 1, 0, 0, 1, 1, 1, 1, 1): TOP_LEFT_OUT,
                    (0, 1, 1, 0, 1, 1, 0, 1, 0): BOTTOM_LEFT_OUT,
                    (0, 1, 0, 1, 1, 0, 1, 1, 1): TOP_RIGHT_OUT,
                    (1, 0, 0, 0, 1, 1, 0, 1, 1): TOP_LEFT_OUT,
                    (0, 0, 1, 1, 1, 1, 0, 1, 1): TOP_LEFT_OUT,
                    (0, 1, 1, 1, 1, 1, 0, 1, 0): BOTTOM_LEFT_OUT,
                    (1, 1, 1, 1, 1, 0, 0, 0, 1): BOTTOM_RIGHT_OUT,
                    (0, 1, 0, 0, 1, 1, 0, 1, 1): TOP_LEFT_OUT,
                    (1, 0, 1, 0, 1, 1, 1, 1, 1): TOP_LEFT_OUT,
                    (0, 1, 1, 1, 1, 1, 0, 0, 1): BOTTOM_LEFT_OUT,
                    (0, 1, 1, 1, 1, 1, 0, 0, 0): BOTTOM_LEFT_OUT,
                    (1, 1, 1, 1, 1, 0, 0, 1, 1): BOTTOM_RIGHT_OUT,
                    (0, 1, 0, 1, 1, 0, 1, 1, 0): TOP_RIGHT_OUT,
                    (1, 0, 0, 1, 1, 1, 0, 1, 1): TOP_LEFT_OUT,
                    (1, 1, 0, 1, 1, 0, 0, 1, 1): BOTTOM_RIGHT_OUT,
                    (0, 0, 1, 1, 1, 0, 1, 1, 0): TOP_RIGHT_OUT,
                    (1, 1, 1, 0, 1, 1, 1, 0, 0): BOTTOM_LEFT_OUT,
                    (1, 1, 0, 1, 1, 1, 0, 0, 0): BOTTOM_RIGHT_OUT,
                    (0, 0, 1, 1, 1, 0, 1, 1, 1): TOP_RIGHT_OUT,
                    (1, 0, 1, 1, 1, 1, 1, 1, 0): TOP_RIGHT_OUT,
                    (1, 1, 1, 0, 1, 1, 1, 0, 1): BOTTOM_LEFT_OUT,
                    (0, 1, 1, 0, 1, 1, 1, 1, 0): BOTTOM_LEFT_OUT,
                    (1, 1, 1, 1, 1, 0, 1, 0, 1): BOTTOM_RIGHT_OUT,
                    (1, 0, 0, 0, 1, 1, 1, 1, 1): TOP_LEFT_OUT,
                    (1, 0, 1, 1, 1, 0, 1, 1, 0): TOP_RIGHT_OUT,
                    (1, 0, 1, 1, 1, 0, 1, 1, 1): TOP_RIGHT_OUT,
                    (1, 1, 0, 1, 1, 1, 1, 0, 0): BOTTOM_RIGHT_OUT,
                    (0, 1, 0, 0, 1, 1, 1, 1, 1): TOP_LEFT_OUT,
                    (1, 1, 0, 0, 1, 1, 0, 1, 1): TOP_LEFT_OUT,
                    (1, 1, 0, 0, 1, 1, 0, 1, 1): TOP_LEFT_OUT,
                    (1, 1, 0, 1, 1, 0, 0, 1, 0): BOTTOM_RIGHT_OUT,
                    (1, 0, 1, 0, 1, 1, 0, 1, 1): TOP_LEFT_OUT,
                    (0, 1, 1, 0, 1, 1, 1, 0, 0): BOTTOM_LEFT_OUT,
                    (1, 1, 0, 1, 1, 1, 1, 0, 1): BOTTOM_RIGHT_OUT,
                    (1, 1, 1, 0, 1, 1, 1, 1, 0): BOTTOM_LEFT_OUT,
                    (1, 1, 1, 0, 1, 1, 0, 1, 0): BOTTOM_LEFT_OUT,
                    (0, 1, 1, 1, 1, 1, 1, 0, 1): BOTTOM_LEFT_OUT,
                    (1, 1, 1, 1, 1, 0, 0, 1, 0): BOTTOM_RIGHT_OUT,
                    (1, 1, 0, 1, 1, 0, 0, 0, 1): BOTTOM_RIGHT_OUT,
                    (1, 1, 1, 1, 1, 0, 0, 1, 0): BOTTOM_RIGHT_OUT,
                    (0, 1, 1, 1, 1, 0, 1, 1, 0): TOP_RIGHT_OUT,
                    (1, 0, 0, 1, 1, 1, 1, 1, 0): TOP_RIGHT_OUT,
                    }

entityId = 0

def main(args):
    global ROWS, COLS, TREE_NOISE, PREY_NOISE, PREDATOR_NOISE, TREE_THRESHOLD, PREY_THRESHOLD, PREDATOR_THRESHOLD

    infile = args.infile
    outfile = args.outfile
    colorThreshold = int(args.color_threshold)
    treeSimplex = int(args.tree_simplex)
    preySimplex = int(args.prey_simplex)
    predatorSimplex = int(args.predator_simplex)
    TREE_THRESHOLD = float(args.tree_threshold)
    PREY_THRESHOLD = float(args.prey_threshold)
    PREDATOR_THRESHOLD = float(args.predator_threshold)

    # Load the image.
    img = np.array(Image.open(infile).convert('L'))

    # Assign the number of rows and columns.
    ROWS, COLS = img.shape

    # Instantiate the perlin noise class.
    # Arbitrary choice of simplex parameter.
    TREE_NOISE = perlin.SimplexNoise(treeSimplex)
    PREY_NOISE = perlin.SimplexNoise(preySimplex)
    PREDATOR_NOISE = perlin.SimplexNoise(predatorSimplex)

    # Preprocess the image.
    img = threshold(img, colorThreshold)
    
    # Get the entities and obstacles tile data.
    entityData, obstacleData = getObstacleData(img) 

    # Build the layer dictionaries.
    entityLayer = getEntityLayer(name=ENTITIES_NAME, 
                                _eid=ENTITIES_EID, 
                                gridCellsX=COLS,
                                gridCellsY=ROWS,
                                entities=entityData)

    obstacleLayer = getTileLayer(name=OBSTACLES_NAME,
                                _eid=OBSTACLES_EID, 
                                gridCellsX=COLS,
                                gridCellsY=ROWS,
                                tileset=TILESET, 
                                data=obstacleData)

    groundLayer = getTileLayer(name=GROUND_NAME, 
                                _eid=GROUND_EID, 
                                gridCellsX=COLS,
                                gridCellsY=ROWS,
                                tileset=TILESET, 
                                data=getGroundData(img))

    # Compose the layers parameter.
    layers = [entityLayer, obstacleLayer, groundLayer]

    # Build the root dictionary.
    root = getRoot(layers=layers, width=COLS*16, height=ROWS*16)

    # Get the json of root.
    rootJson = json.dumps(root, indent=2)

    # Write the json to file.
    with open(outfile, 'w') as f:
        f.write(rootJson)
               

def getRoot(version='3.4.0',
            width=256,
            height=256,
            offsetX=0,
            offsetY=0,
            layers=[]):
    return {"ogmoVersion": version,
            "width": width,
            "height": height,
            "offsetX": offsetX,
            "offsetY": offsetY,
            "layers": layers}


def getEntityLayer(name='',
                _eid='',
                offsetX=0,
                offsetY=0,
                gridCellWidth=16,
                gridCellHeight=16,
                gridCellsX=16,
                gridCellsY=16,
                entities=[]):
    return {"name": name,
            "_eid": _eid,
            "offsetX": offsetX,
            "offsetY": offsetY,
            "gridCellWidth": gridCellWidth,
            "gridCellHeight": gridCellHeight,
            "gridCellsX": gridCellsX,
            "gridCellsY": gridCellsY,
            "entities": entities}


def getTileLayer(name='',
                _eid='',
                offsetX=0,
                offsetY=0,
                gridCellWidth=16,
                gridCellHeight=16,
                gridCellsX=16,
                gridCellsY=16,
                tileset='',
                data=[],
                exportMode=0,
                arrayMode=0):
    return {"name": name,
            "_eid": _eid,
            "offsetX": offsetX,
            "offsetY": offsetY,
            "gridCellWidth": gridCellWidth,
            "gridCellHeight": gridCellHeight,
            "gridCellsX": gridCellsX,
            "gridCellsY": gridCellsY,
            "tileset": tileset,
            "data": data,
            "exportMode": exportMode,
            "arrayMode": arrayMode}


def getGroundData(img):
    d = []
    for i in range(ROWS * COLS):
        d.append(GRASS_TILES[getGroundType()])
    return d


def getObstacleData(img):
    # The list of tile indices.
    obstacles = []
    entities = []

    # Visit every pixel in img.
    for y in range(ROWS):
        for x in range(COLS):
            # Get the pixel region.
            region = getRegion(img, x, y)

            # True if descending into water and false otherwise.
            intoWater = True if min(region) == 0 else False

            # Flatten the region into 1s and 0s.
            flatRegion = flatten(region)   
    
            # Used with clean.py
            #diffs = []
            #if (y, x) in diffs:
            #    print(tuple(flatRegion))

            try:
                # Get the raw obstacle shape.
                obstacle = OBSTACLE_TILEMAP[tuple(flatRegion)]
            except:
                obstacle = EMPTY

            # Convert the obstacle shape into the typed obstacle.
            if intoWater:
                # Add cliffs into water.
                typed = WATER_TILEMAP[obstacle]
            else:
                # Add trees.
                if obstacle == EMPTY and TREE_NOISE.noise2(x, y) > TREE_THRESHOLD:
                    choice = getTreeType()
                    typed = TREE_TILEMAP[choice]
                # Add cliffs.
                else:
                    typed = GRASS_TILEMAP[obstacle]

                # Add prey.
                if obstacle == EMPTY and PREY_NOISE.noise2(x, y) > PREY_THRESHOLD:
                    entities.append(getPreyEntity(x*16, y*16))

                # Add predators.
                if obstacle == EMPTY and PREDATOR_NOISE.noise2(x, y) > PREDATOR_THRESHOLD:
                    entities.append(getPredatorEntity(x*16, y*16))


            # Insert that value into the data list.
            obstacles.append(typed)

    return entities, obstacles


def flatten(region):
    # Flatten the range of values in region to 0 and 1.
    return [0 if i == min(region) else 1 for i in region]


def threshold(img, n):
    # Reduce the image to n colors. 
    newImg = np.zeros((ROWS, COLS), dtype=np.int8)
    for y in range(ROWS):
        for x in range(COLS):
            newImg[y, x] = img[y, x] // (256 // n)
    return newImg


def getRegion(img, x, y):
    # Build an array of values of the pixel region.
    # Where the region is the current pixel and
    # it's surrounding 8 pixels.
    region = [0] * 9 

    # Top row.
    if y > 0:
        # Top left.
        if x > 0:
            region[0] = img[y-1, x-1]
        # Top middle.
        region[1] = img[y-1, x]
        # Top right.
        if x < COLS - 1:
            region[2] = img[y-1, x+1]

    # Current row.
    # Left.
    if x > 0:
        region[3] = img[y, x-1]
    # Current.
    region[4] = img[y, x]
    # Right.
    if x < COLS - 1:
        region[5] = img[y, x+1]

    # Bottom row.
    if y < ROWS - 1:
        # Bottom left.
        if x > 0:
            region[6] = img[y+1, x-1]
        # Bottom middle.
        region[7] = img[y+1, x]
        # Bottom right.
        if x < COLS - 1:
            region[8] = img[y+1, x+1]

    return region


def getTreeType():
    # Return an int in the range [0, 4].
    r = random.randint(0, 100)
    if r < 5:
        return 0
    elif r < 25:
        return 1
    elif r < 75:
        return 2
    elif r < 95:
        return 3
    else:
        return 4


def getGroundType():
    # Return an int in the range [0, 2].
    r = random.randint(0, 100)
    if r < 50:
        return 0
    elif r < 75:
        return 1
    else:  
        return 2


def getPreyEntity(x, y):
    global entityId
    e = _getEntity(PREY_NAME, entityId, PREY_EID, x, y)
    entityId += 1
    return e


def getPredatorEntity(x, y):
    global entityId
    e = _getEntity(PREDATOR_NAME, entityId, PREDATOR_EID, x, y)
    entityId += 1
    return e


def _getEntity(name, ID, _eid, x, y, originX=0, originY=0):
    # Called by getPreyEntity and getPredatorEntity.
    return {'name': name,
            'id': ID,
            '_eid': _eid,
            'x': x,
            'y': y,
            'originX': originX,
            'originY': originY}
        
 
if __name__ == '__main__':
    parser = ArgumentParser(formatter_class=ArgumentDefaultsHelpFormatter)
    parser.add_argument('--infile', help='File to convert to json', default='west.png')
    parser.add_argument('--outfile', help='Output file name', default='output.json')
    parser.add_argument('--color_threshold', help='Number of colors to use, default=10', default=10)
    parser.add_argument('--tree_simplex', help='default=18', default=18)
    parser.add_argument('--prey_simplex', help='default=19', default=19)
    parser.add_argument('--predator_simplex', help='default=20', default=20)
    parser.add_argument('--tree_threshold', help='Number of trees to add, lower=more, default=0.65', default=0.65)
    parser.add_argument('--prey_threshold', help='Number of prey to add, lower=more, default=0.92', default=0.92)
    parser.add_argument('--predator_threshold', help='Number of predators to add, lower=more, default=0.995', default=0.995)
    args = parser.parse_args()
    
    main(args)

