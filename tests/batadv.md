#batadv traffic handling capability of different routers

I used iperf3 in TCP mode to make the measurements below.

Setup:
* Ethernet MTU: 1500
* Batman MTU: 1500 (To force fragmentation somewhat similar to freifunk vpn)
* [x86 kvm] <--ethernet--> [DUT] <--ethernet--> [x86 kvm]

Devices:
- TL-WDR4300: ~400 Mbit/s (maxed out by softirqs)
- TL-WR841n/ND (V11): ~80 Mbit/s (maxed out by interface speed)
