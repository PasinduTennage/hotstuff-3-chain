import os
import argparse
import json

# this file takes as inputs timeout_delay, min_block_delay, replica ips and generate 1) private configs 2) .parameters.json, 3) .committee.json

# Set up command-line argument parsing
parser = argparse.ArgumentParser(description='Generate node-parameters.yml and client-parameters.yml files.')

parser.add_argument('--timeout_delay', type=int, default=30000, help='Hotstuff timeout (default: 30s)')
parser.add_argument('--min_block_delay', type=int, default=100, help='Minimum block delay (default: 100ms)')
parser.add_argument('--replicas', type=str, default="", nargs='+', help='Replicas IPs')
parser.add_argument('--output_path', type=str, default="logs/dedis-10/", nargs='+', help='output dir')

args = parser.parse_args()

# File 1: .parameters.yml
node_parameters_dict = {
    "consensus": {
        "max_payload_size": 500,
        "min_block_delay": args.min_block_delay,
        "sync_retry_delay": 10000,
        "timeout_delay": args.timeout_delay
    },
    "mempool": {
        "max_payload_size": 15000,
        "min_block_delay": 0,
        "queue_capacity": 10000,
        "sync_retry_delay": 100000
    }
}

############
# params

with open(args.output_path + '.parameters.json', 'w') as json_file:
    json.dump(node_parameters_dict, json_file, indent=4)

############
# key files
for i in range(len(args.replicas)):
    os.system(f".{args.output_path}node keys --filename {args.output_path}.node-{i}.json")


##########
# committee file


def load_from_file(filename):
    with open(filename, 'r') as f:
        data = json.load(f)
    return data['name'], data['secret']


keys = []
key_files = [f"{args.output_path}.node-{i}.json" for i in range(len(args.replicas))]

for filename in key_files:
    keys += [load_from_file(filename)]

names = [x.name for x in keys]
consensus_addr = [f'{x}:{9000}' for x in args.replicas]
front_addr = [f'{x}:{10000}' for x in args.replicas]
mempool_addr = [f'{x}:{11000}' for x in args.replicas]


def _build_consensus(consensus, names):
    node = {}
    for a, n in zip(consensus, names):
        node[n] = {'name': n, 'stake': 1, 'address': a}
    return {'authorities': node, 'epoch': 1}


def _build_mempool(names, front, mempool):
    node = {}
    for n, f, m in zip(names, front, mempool):
        node[n] = {'name': n, 'front_address': f, 'mempool_address': m}
    return {'authorities': node, 'epoch': 1}


cmt = {
    'consensus': _build_consensus(),
    'mempool': _build_mempool()
}

with open(args.output_path + ".committee.json", 'w') as f:
    json.dump(cmt, f, indent=4, sort_keys=True)
