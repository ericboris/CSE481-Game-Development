import csv
import re
from argparse import ArgumentParser, ArgumentDefaultsHelpFormatter

def main(args):
    with open(args.infile) as f:
        lines = f.readlines()

    with open(args.outfile, 'w', newline='') as f:
        writer = csv.writer(f)
        for line in lines:
            if line.startswith('|'):
                line = re.sub(r'\s*\|+\s*', ' ', line, flags=re.UNICODE).split()
                writer.writerow(line)

if __name__ == '__main__':
    parser = ArgumentParser(formatter_class=ArgumentDefaultsHelpFormatter)
    parser.add_argument('--infile', help='File to convert', default='player_quests_log.out')
    parser.add_argument('--outfile', help='Output file name', default='player_quests_log.csv')
    args = parser.parse_args()

    main(args)
    
