#!/bin/env python3

import json
import sys
from pprint import pprint
from argparse import ArgumentParser


def get_attr(node, path):
	if len(path) > 1:
		path = list(path)
		key = path.pop(0)
		if not key in node:
			return None
		return get_attr(node[key], path)
	if not path[0] in node:
		return None
	return node[path[0]]

nodefile = ''

parser = ArgumentParser(description='Nodetool: A freifunk node data tool')
parser.add_argument('nodefile', type=str, help='Freifunk nodes.json')
parser.add_argument('match', type=str)
parser.add_argument('-a', '--attr', dest='attr', type=str)
parser.add_argument('-s', '--substr', dest='substr_match', action='store_true')
parser.add_argument('-i', '--id', dest='attr', action='store_const', const='nodeinfo.node_id')
args = parser.parse_args()

nodes = []

with open(args.nodefile) as file:
	nodes = json.load(file)

print('Nodefile version {0}'.format(nodes['version']))
print('Nodefile timestamp {0}'.format(nodes['timestamp']))

nodes = nodes['nodes']

print('Got {0} {1}'.format(len(nodes), 'node' if len(nodes) == 1 else 'nodes'))

if not args.attr:
	sys.exit()

attr_path = args.attr.split('.')

matchcnt = 0
for node in nodes:
	val = str(get_attr(node, attr_path))
	if not val:
		continue
	match = False
	if args.substr_match:
		match = (val.find(args.match) >= 0)
	else:
		match = (val == args.match)

	if match:
		pprint(node)
		matchcnt += 1

print('Found {0} matching {1}'.format(matchcnt, 'node' if matchcnt == 1 else 'nodes'))
