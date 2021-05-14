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

ROWS = 16
COLS = 16

GROUND_TILEMAP = {0: 36, 
                255: 16}

OBSTACLE_TILEMAP = {(0, 0, 0, 0, 0, 0, 0, 0, 0): -1,
                    (255, 255, 0, 255, 0, 0, 0, 0, 0): 28,
                    (255, 255, 255, 255, 0, 0, 255, 0, 0): 28,
                    (255, 255, 255, 0, 0, 0, 0, 0, 0): 29,
                    (0, 255, 255, 0, 0, 0, 0, 0, 0): 29,
                    (255, 255, 0, 0, 0, 0, 0, 0, 0): 29,
                    (0, 255, 255, 0, 0, 255, 0, 0, 0): 30,
                    (255, 255, 255, 0, 0, 255, 0, 0, 255): 30,
                    (255, 0, 0, 0, 0, 0, 0, 0, 0): 31,
                    (0, 0, 255, 0, 0, 0, 0, 0, 0): 32,
                    (255, 0, 0, 255, 0, 0, 255, 0, 0): 35,
                    (0, 0, 0, 255, 0, 0, 255, 0, 0): 35,
                    (255, 0, 0, 255, 0, 0, 0, 0, 0): 35,
                    (0, 0, 255, 0, 0, 255, 0, 0, 255): 37,
                    (0, 0, 0, 0, 0, 255, 0, 0, 255): 37,
                    (0, 0, 255, 0, 0, 255, 0, 0, 0): 37,
                    (0, 0, 0, 0, 0, 0, 255, 0, 0): 38,
                    (0, 0, 0, 0, 0, 0, 0, 0, 255): 39,
                    (0, 0, 0, 255, 0, 0, 255, 255, 0): 42,
                    (255, 0, 0, 255, 0, 0, 255, 255, 255): 42,
                    (0, 0, 0, 0, 0, 0, 255, 255, 255): 43,
                    (0, 0, 0, 0, 0, 0, 0, 255, 255): 43,
                    (0, 0, 0, 0, 0, 0, 255, 255, 0): 43,
                    (0, 0, 0, 0, 0, 255, 0, 255, 255): 44,
                    (0, 0, 255, 0, 0, 255, 255, 255, 255): 44}


def main():
    # Load the image
    img = np.array(Image.open('test.png').convert('L'))

    # Build the layer dictionaries.
    entities = getEntities(name=ENTITIES_NAME, _eid=ENTITIES_EID)
    obstacles = getTileset(name=OBSTACLES_NAME, _eid=OBSTACLES_EID, tileset=TILESET, data=getObstacleData(img))
    ground = getTileset(name=GROUND_NAME, _eid=GROUND_EID, tileset=TILESET, data=getGroundData(img))

    # Compose the layers parameter.
    layers = [entities, obstacles, ground]

    # Build the root dictionary.
    root = getRoot(layers=layers)

    # Get the json of root.
    rootJson = json.dumps(root, indent=2)

    # Write the json to file.
    with open('result.json', 'w') as f:
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


def getGroundData(img):
    d = []
    for y in range(ROWS):
        for x in range(COLS):
            val = GROUND_TILEMAP[img[y, x]]
            d.append(val)
    return d


def getObstacleData(img):
    # The list of tile indices.
    d = []

    # Visit every pixel in img.
    for y in range(ROWS):
        for x in range(COLS):
            # Only build region if pixel is filled.
            if img[y, x] == 255:
                d.append(-1)
                continue

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

            # Use the region as a hash key to determine the 
            # current (x, y) tile index.
            index = OBSTACLE_TILEMAP[tuple(region)]

            # Insert that value into the data list.
            d.append(index)
    return d
 

if __name__ == '__main__':
    main()
