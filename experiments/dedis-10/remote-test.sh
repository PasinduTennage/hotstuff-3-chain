timeout_delay_ms=$1
min_block_delay_ms=$2
transaction_size=$3
load=$4
iteration=$5

pwd=$(pwd)
. "${pwd}"/experiments/dedis-10/ip.sh

python3 experiments/python/genrate-configs.py  --timeout_delay ${timeout_delay_ms} --min_block_delay ${min_block_delay_ms} --replicas ${replica1_name} ${replica2_name} ${replica3_name} ${replica4_name} ${replica5_name}  --output_path logs/dedis-10/

nodes="${replica1_name}:10000 ${replica2_name}:10000 ${replica3_name}:10000 ${replica4_name}:10000 ${replica5_name}:10000"

remote_home_path="/home/${username}/hotstuff-3-chain/"
kill_instances="pkill -f node ; pkill -f client"
remote_replica_path="/hotstuff-3-chain/node"
remote_client_path="/hotstuff-3-chain/client"


for index in "${!replicas[@]}";
do
    echo "copying configs to replica ${index}"
    scp -i ${cert} logs/dedis-10/.committee.json   "${replicas[${index}]}":"${remote_home_path}"
    scp -i ${cert} logs/dedis-10/.parameters.json   "${replicas[${index}]}":"${remote_home_path}"
    scp -i ${cert} logs/dedis-10/.node-${index}.json   "${replicas[${index}]}":"${remote_home_path}"

    sshpass ssh "${replicas[${index}]}" -i ${cert} "${kill_instances}; rm -r ${remote_home_path}/logs; mkdir -p ${remote_home_path}/logs"
    sshpass ssh "${replicas[${index}]}" -i ${cert} "${kill_instances}; rm ${remote_home_path}/.db-${index}"
done

sleep 5
rm nohup.out

local_output_path="logs/dedis-10/${timeout_delay_ms}/${min_block_delay_ms}/${transaction_size}/${load}/${iteration}/"

rm -r "${local_output_path}"; mkdir -p "${local_output_path}"

echo "starting replicas"

nohup ssh "${replica1}"    -i ${cert}   "bash -c 'export RUST_LOG=info; .${remote_replica_path}  run --keys ${remote_home_path}.node-0.json --committee ${remote_home_path}.committee.json --store ${remote_home_path}.db-0  --parameters ${remote_home_path}.parameters.json'" >${local_output_path}0.log 2>&1  &
nohup ssh "${replica2}"    -i ${cert}   "bash -c 'export RUST_LOG=info; .${remote_replica_path}  run --keys ${remote_home_path}.node-1.json --committee ${remote_home_path}.committee.json --store ${remote_home_path}.db-1  --parameters ${remote_home_path}.parameters.json'" >${local_output_path}1.log 2>&1  &
nohup ssh "${replica3}"    -i ${cert}   "bash -c 'export RUST_LOG=info; .${remote_replica_path}  run --keys ${remote_home_path}.node-2.json --committee ${remote_home_path}.committee.json --store ${remote_home_path}.db-2  --parameters ${remote_home_path}.parameters.json'" >${local_output_path}2.log 2>&1  &
nohup ssh "${replica4}"    -i ${cert}   "bash -c 'export RUST_LOG=info; .${remote_replica_path}  run --keys ${remote_home_path}.node-3.json --committee ${remote_home_path}.committee.json --store ${remote_home_path}.db-3  --parameters ${remote_home_path}.parameters.json'" >${local_output_path}3.log 2>&1  &
nohup ssh "${replica5}"    -i ${cert}   "bash -c 'export RUST_LOG=info; .${remote_replica_path}  run --keys ${remote_home_path}.node-4.json --committee ${remote_home_path}.committee.json --store ${remote_home_path}.db-4  --parameters ${remote_home_path}.parameters.json'" >${local_output_path}4.log 2>&1  &

sleep 10

nohup ssh "${replica6}"      -i ${cert}   "bash -c 'export RUST_LOG=info; .${remote_client_path} ${replica1_name}:10000 --size ${transaction_size} --rate ${load} --timeout 3000 --nodes ${nodes}'" >${local_output_path}5.log  2>&1 &
nohup ssh "${replica7}"      -i ${cert}   "bash -c 'export RUST_LOG=info; .${remote_client_path} ${replica2_name}:10000 --size ${transaction_size} --rate ${load} --timeout 3000 --nodes ${nodes}'" >${local_output_path}6.log  2>&1 &
nohup ssh "${replica8}"      -i ${cert}   "bash -c 'export RUST_LOG=info; .${remote_client_path} ${replica3_name}:10000 --size ${transaction_size} --rate ${load} --timeout 3000 --nodes ${nodes}'" >${local_output_path}7.log  2>&1 &
nohup ssh "${replica9}"      -i ${cert}   "bash -c 'export RUST_LOG=info; .${remote_client_path} ${replica4_name}:10000 --size ${transaction_size} --rate ${load} --timeout 3000 --nodes ${nodes}'" >${local_output_path}8.log  2>&1 &
nohup ssh "${replica10}"     -i ${cert}   "bash -c 'export RUST_LOG=info; .${remote_client_path} ${replica5_name}:10000 --size ${transaction_size} --rate ${load} --timeout 3000 --nodes ${nodes}'" >${local_output_path}9.log  2>&1 &


sleep 120

for index in "${!replicas[@]}";
do
    echo "killing instance"
    sshpass ssh "${replicas[${index}]}" -i ${cert} "${kill_instances}"
done