import json
import numpy as np

def main():
    # Load the raw make.py json.
    with open('west1.json', 'r') as f1:
        j1= json.load(f1)
    
    # Load the edited make.py json.
    with open('west2.json', 'r') as f2:
        j2 = json.load(f2)

    # Check that the dimensions are the same.
    assert(j1['width'] == j2['width'])
    assert(j1['height'] == j2['height'])

    ROWS = j1['height'] // 16 
    COLS = j1['width'] // 16

    # Compare the data in the two datasets.
    data1 = np.array(j1['layers'][1]['data'])
    data1.shape = (ROWS, COLS)
    data2 = np.array(j2['layers'][1]['data'])
    data2.shape = (ROWS, COLS)
    
    # Collect the list of coordinates where the data differ.
    diffs = []
    for y in range(ROWS):
        for x in range(COLS):
            if data1[y, x] != data2[y, x]:
                diffs.append((y, x))
            
    # Output the results 
    print(diffs)


if __name__ == '__main__':
    main()
