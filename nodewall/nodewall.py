#!/usr/bin/env python3

import json
import sys
import requests
import re

from enum import Enum
from queue import Queue


DEBUG = False

NODES_JSON = 'https://hopglass.freifunk.in-kiel.de/nodes.json'
GRAPH_JSON = 'https://hopglass.freifunk.in-kiel.de/graph.json'

FWVERSIONS = {
  "nightly": {
    "min": "2018.1.1~ngly-480",
    "max": "2018.1.4~ngly-591"
  }
}

re_sanitize_address = re.compile('^([0-9a-fA-F]*:*)*$')
re_sanitize_fwversion = re.compile('[\w\~\-\+\.\*\$\[\]&"\\\(\)]+')
re_sanitize_hostname = re.compile('[^\n\r\t\\\]+')

def sanitize(str, expr):
  match = expr.search(str)
  if match:
    return match.group(0)
  return None

def eprint(*args, **kwargs):
  print(*args, file=sys.stderr, **kwargs) if DEBUG else None

def get(dict, key):
  parts = str(key).split('.')
  for part in parts:
    if not part in dict:
      return None
    dict = dict[part]
  return dict

def char_ord(c):
  if c.isdigit():
    return 0
  if c.isalpha():
    return ord(c)
  if ord(c) == 0:
    return -1
  if c == '~':
    return -2
  return ord(c) + 256

class State(Enum):
  CHAR = 0
  ZERO = 1
  NUMBER = 2


def newer_than(a, b, debug=False):
  al = list(a)
  bl = list(b)

  state = State.CHAR
  numa = '0'
  numb = '0'

  for i in range(max(len(al), len(bl))):
    a = "".join(al[i:i + 1]) if i < len(al) else chr(0)
    b = "".join(bl[i:i + 1]) if i < len(bl) else chr(0)

    eprint("Checking {} vs {}, state: {}".format(a, b, state)) if debug else None

    if a.isdigit() or b.isdigit():
      state = State.NUMBER
      if a.isdigit():
        numa += a
      if b.isdigit():
        numb += b
    else:
      ac = char_ord(a)
      ab = char_ord(b)

      if ac != ab:
        return ac > ab

    if state == State.NUMBER:
      if not a.isdigit() and not b.isdigit():
        eprint(numa) if debug else None
        eprint(numb) if debug else None
        if int(numa) != int(numb):
          return int(numa) > int(numb)
        numa = '0'
        numb = '0'
        state = State.CHAR

      elif not a.isdigit() or not b.isdigit():
        return int(numa) > int(numb)

  if state == State.NUMBER:
        return int(numa) > int(numb)

  return False

def get_json(url):
  response = requests.get(url)

  if response.status_code != 200:
    return None

  return json.loads(response.text)

class Node():
  def __init__(self, node):
    self.hostname = get(node, "nodeinfo.hostname")
    self.online = get(node, "flags.online")
    self.gateway = get(node, "statistics.gateway")
    self.nexthop = get(node, "statistics.gateway_nexthop")
    self.nodeid = get(node, "nodeinfo.node_id")
    self.branch = get(node, 'nodeinfo.software.autoupdater.branch')
    self.autoupdate = get(node, 'nodeinfo.software.autoupdater.enabled')
    self.fwversion = get(node, 'nodeinfo.software.firmware.release')
    self.addresses = get(node, 'nodeinfo.network.addresses')
    self.graphid = None
    self.edges = {}
    self.parent = None

  def connected_to(self, other):
    return other in self.edges

  def set_graphid(self, graphid):
    self.graphid = graphid

  def neighbours(self):
    return [ edge.dst for edge in self.edges.values() ]

  def has_direct_uplink(self, mesh):
    gateway = mesh.get_node_by_id(self.gateway)
    return gateway and self.connected_to(gateway)


class Edge():
  def __init__(self, src, dst):
    self.src = src
    self.dst = dst

class Mesh():
  def __init__(self, nodes, graph):
    nodes = nodes['nodes']
    graph = graph['batadv']

    self.node_by_id = {}
    self.node_by_graphid = {}
    self.node_by_hostname = {}
    self.edges = {}

    gateways = {}
    nodes.sort(key=lambda node: get(node, "flags.online"), reverse=True)
    for node in nodes:
      node = Node(node)
      alt = self.get_node_by_hostname(node.hostname)
      if not node.online and alt:
        eprint("Replacing offline node {} with online node {}".format(node.nodeid, alt.nodeid))
        self.node_by_id[node.nodeid] = alt
      else:
        self.node_by_id[node.nodeid] = node
        self.node_by_hostname[node.hostname] = node
        gateways[node.gateway] = True

    self.gateways = list(filter(None, map(self.get_node_by_id, list(gateways.keys()))))

    for i in range(len(graph['nodes'])):
      mapping = graph['nodes'][i]
      nodeid = get(mapping, 'node_id')
      if not nodeid:
        continue
      node = self.get_node_by_id(nodeid)
      if not node:
        eprint("Failed to look up node {}".format(nodeid))
        continue
      node.set_graphid(i)
      self.node_by_graphid[str(i)] = node

    for edge in graph['links']:
      src = self.get_node_by_graphid(get(edge, 'source'))
      dst = self.get_node_by_graphid(get(edge, 'target'))
      if not src or not dst:
        eprint("Lookup of {}/{} in graph failed".format(get(edge, 'source'), get(edge, 'target')))
        continue
      eprint("Edge {} => {}".format(src.hostname, dst.hostname))
      eprint("Edge {} => {}".format(dst.hostname, src.hostname))
      src.edges[dst] = Edge(src, dst)
      dst.edges[src] = Edge(dst, src)

  def get_node_by_id(self, id):
    return get(self.node_by_id, id)

  def get_node_by_graphid(self, id):
    return get(self.node_by_graphid, str(id))

  def get_node_by_hostname(self, hostname):
    return self.node_by_hostname[hostname] if hostname in self.node_by_hostname else None

  def nodes(self):
    return self.node_by_id.values()

  def is_gw(self, node):
    return node in self.gateways

def gw_path(mesh, start, end):
  for node in mesh.nodes():
    node.parent = None
  queue = Queue()
  queue.put(start)
  start.parent = start
  while not queue.empty():
    node = queue.get()
    if node == end:
      eprint('{} reached'.format(node.hostname))
      path = [ node ]
      while node.parent != node:
        path.append(node.parent)
        node = node.parent
      path.reverse()
      return path

    for neighbour in node.neighbours():
      if not neighbour.parent:
        neighbour.parent = node
        queue.put(neighbour)

  return None

nodes = get_json(NODES_JSON)
graph = get_json(GRAPH_JSON)

if not nodes or not graph:
  sys.exit(1)

mesh = Mesh(nodes, graph)

for node in mesh.nodes():
  try:
    eprint('{} on gw {}'.format(node.hostname, node.gateway))

    gateway = mesh.get_node_by_id(node.gateway)
    if not gateway:
      eprint("Excluding {}, no gateway".format(node.hostname))
      continue

    gwpath = gw_path(mesh, node, gateway)
    if not gwpath:
      eprint("Excluding {}, no connection to gw".format(node.hostname))
      continue

    eprint([n.hostname for n in gwpath])

    gwpath = list(filter(lambda node: not mesh.is_gw(node), gwpath))

    eprint([n.hostname for n in gwpath])

    def check_path():
      for member in gwpath:
        eprint('Checking {}'.format(member.hostname))
        if not member.branch in FWVERSIONS:
          eprint("Excluding {}, unknown branch on path to GW".format(node.hostname))
          return False

          constraint = FWVERSIONS[member.branch]
          fwversion = member.fwversion
          if not fwversion:
            eprint("Excluding {}, node without fwversion on path to gateway".format(node.hostname))
            return False

          if member == node and newer_than(fwversion, constraint["max"]):
            eprint("Excluding {}, version too new".format(node.hostname))
            return False

          if newer_than(constraint["min"], fwversion) and not member.autoupdate:
            eprint("Excluding {}, version on path too old and autoupdater disabled".format(node.hostname))
            return False

      return True


    if len(gwpath) > 1 and check_path():
      for addr in filter(lambda addr: not addr.startswith('fe80') and re_sanitize_address.match(addr), node.addresses):
        print("# {} ({})".format(sanitize(node.hostname, re_sanitize_hostname), sanitize(node.fwversion, re_sanitize_fwversion)))
        print("Require not ip {}".format(addr))

  except Exception as e:
    pass
