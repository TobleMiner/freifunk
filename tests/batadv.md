#batadv traffic handling capability of different routers
Setup:
* Ethernet MTU: 1500
* Batman MTU: 1500 (To force fragmentation somewhat similar to freifunk vpn)
* [x86 kvm] <--ethernet--> [DUT] <--ethernet--> [x86 kvm]

Devices:
- WDR4300: ~400 Mbit/s (maxed out by softirqs)
