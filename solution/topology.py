#!/usr/bin/python3

from mininet.topo import Topo
from mininet.net import Mininet
from mininet.node import OVSController
from mininet.cli import CLI
from mininet.link import TCLink
from mininet.log import setLogLevel
from mininet.nodelib import LinuxBridge
from stratum import StratumBmv2Switch, NoIpv6OffloadHost


class LabTopology(Topo):
    """Two hosts connected to a single switch."""

    def build(self):
        # Create a single switch
        switch = self.addSwitch("s1", loglevel="debug")

        # Create two hosts
        homePC = self.addHost("homePC", ip="192.168.0.10/24",
                              defaultRoute="via 192.168.0.1")
        tablet = self.addHost("tablet", ip="192.168.0.12/24",
                              defaultRoute="via 192.168.0.1")
        phone = self.addHost("phone", ip="192.168.0.5/24",
                             defaultRoute="via 192.168.0.1")

        cloud = self.addHost("cloud", ip="10.10.0.32/16",
                             defaultRoute="via 10.10.0.1")
        web = self.addHost("web", ip="10.0.0.16/16",
                           defaultRoute="via 10.0.0.1")

        router = self.addHost("router", ip=None)

        # Connect hosts to the switch
        self.addLink(switch, homePC, port1=2)
        self.addLink(switch, tablet, port1=3)
        self.addLink(switch, phone, port1=4)
        self.addLink(router, switch, port2=1, params1={"ip": "192.168.0.1/24"})
        self.addLink(router, web, params1={"ip": "10.0.0.1/16"})
        self.addLink(router, cloud, params1={"ip": "10.10.0.1/16"})


# Expose topology for `mn --custom topology.py --topo simple`
topos = {
    "simple": (lambda: LabTopology()),
}


def run():
    """Spin up the network, run a quick test, then drop into CLI."""
    net = Mininet(topo=LabTopology(), link=TCLink, 
                  autoSetMacs=True,
                  autoStaticArp=True,
                  host=NoIpv6OffloadHost,
                  switch=StratumBmv2Switch, controller=None)
    net.start()

    # Interactive CLI for exploration
    CLI(net)

    # Clean up
    net.stop()


if __name__ == "__main__":
    setLogLevel("info")
    run()
