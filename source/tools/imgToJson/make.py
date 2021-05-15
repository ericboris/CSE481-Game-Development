from PIL import Image
import numpy as np
import json


ENTITIES_NAME = 'entities'
ENTITIES_EID = '72465116'

TILESET = 'tiles'

OBSTACLES_NAME = 'obstacles'
OBSTACLES_EID = '72467368'

GROUND_NAME = 'ground'
GROUND_EID = '84372284'

BLACK = 0
WHITE = 255

GRASS_TILE = 36
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

OBSTACLE_TILEMAP = {(0, 0, 0, 0, 0, 0, 0, 0, 0): CENTER,
                    (1, 1, 1, 1, 1, 1, 1, 1, 1): EMPTY,
                    (0, 0, 0, 0, 1, 1, 0, 1, 1): TOP_LEFT_OUT,
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
                    }

def main():
    # Load the image.
    img = np.array(Image.open('sample.jpg').convert('L'))

    # Assign the number of rows and columns.
    ROWS, COLS = img.shape

    # Preprocess the image.
    img = threshold(img, 3, ROWS, COLS)
     
    # Build the layer dictionaries.
    entities = getEntities(name=ENTITIES_NAME, _eid=ENTITIES_EID)
    obstacles = getTileset(name=OBSTACLES_NAME, _eid=OBSTACLES_EID, tileset=TILESET, data=getObstacleData(img, ROWS, COLS))
    ground = getTileset(name=GROUND_NAME, _eid=GROUND_EID, tileset=TILESET, data=getGroundData(img, ROWS, COLS))

    # TODO REMOVE FOR TESTING
    #print(getObstacleData(img, ROWS, COLS))

    # Compose the layers parameter.
    layers = [entities, obstacles, ground]

    # Build the root dictionary.
    root = getRoot(layers=layers, width=COLS*16, height=ROWS*16)

    # Get the json of root.
    rootJson = json.dumps(root, indent=2)

    # Write the json to file.
    with open('sample.json', 'w') as f:
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


def getEntities(name='',
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


def getTileset(name='',
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


def getGroundData(img, ROWS, COLS):
    return [GRASS_TILE] * (ROWS * COLS)


def getObstacleData(img, ROWS, COLS):
    # The list of tile indices.
    d = []

    # Visit every pixel in img.
    for y in range(ROWS):
        for x in range(COLS):
            # Get the pixel region.
            region = getRegion(img, x, y, ROWS, COLS)

            # True if descending into water and false otherwise.
            intoWater = True if min(region) == 0 else False

            # Flatten the region into 1s and 0s.
            flatRegion = flatten(region)   

            try:
                # Get the raw obstacle shape.
                obstacle = OBSTACLE_TILEMAP[tuple(flatRegion)]
            except:
                obstacle = EMPTY

            # Convert the obstacle shape into the typed obstacle.
            if intoWater:
                typed = WATER_TILEMAP[obstacle]
            else:
                typed = GRASS_TILEMAP[obstacle]

            # Insert that value into the data list.
            d.append(typed)

    return d


def flatten(region):
    # Flatten the range of values in region to 0 and 1.
    return [0 if i == min(region) else 1 for i in region]


def threshold(img, n, ROWS, COLS):
    # Reduce the image to n colors. 
    newImg = np.zeros((ROWS, COLS), dtype=np.int8)
    for y in range(ROWS):
        for x in range(COLS):
            newImg[y, x] = img[y, x] // (256 // n)
    return newImg


def getRegion(img, x, y, ROWS, COLS):
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

    # Return an empty tile if this tile
    # doesn't descend into the nearby region.
    regionMin = min(region)
    if img[y, x] == regionMin:
        if regionMin == 0:
            region = [0] * 9
        else:
            region = [1] * 9

    return region

 
if __name__ == '__main__':
    main()
