Packet loss add/change/remove localhost
sudo tc qdisc add dev lo root netem loss 10.0%
sudo tc qdisc change dev lo root netem loss 10.0%
sudo tc qdisc del dev lo root netem loss

Packet delay add/change/remove localhost
sudo tc qdisc add dev lo root netem delay 250ms
sudo tc qdisc change dev lo root netem delay 500ms
sudo tc qdisc del dev lo root netem delay
