pwd=$(pwd)
. "${pwd}"/experiments/dedis-10/ip.sh

rm -r logs/dedis-10/ ; mkdir -p logs/dedis-10/

remote_home_path="/home/${username}/hotstuff-3-chain/"
reset_directory="sudo rm -r ${remote_home_path}; mkdir -p ${remote_home_path}logs/"
kill_instances="pkill -f node ; pkill -f client"
install_dependencies="sudo apt-get update"

# build the binary in a remote replica, uncomment when needed
sshpass ssh "${replicas[0]}" -i ${cert} "rm -r ${remote_home_path}; git clone https://github.com/PasinduTennage/hotstuff-3-chain; cd hotstuff-3-chain; git checkout 3-chain; sudo apt-get install libfontconfig1-dev; source /home/${username}/.cargo/env; cargo build --quiet --release --features benchmark"
scp -i ${cert} "${replicas[0]}":${remote_home_path}target/release/node logs/dedis-10/node
scp -i ${cert} "${replicas[0]}":${remote_home_path}target/release/client logs/dedis-10/client


for index in "${!replicas[@]}";
do
    echo "copying files to replica ${index}"
    sshpass ssh "${replicas[${index}]}" -i ${cert} "${reset_directory};${kill_instances};${install_dependencies}"
    scp -i ${cert} logs/dedis-10/node "${replicas[${index}]}":${remote_home_path}
    scp -i ${cert} logs/dedis-10/client "${replicas[${index}]}":${remote_home_path}
done

echo "setup complete"