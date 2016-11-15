#batadv traffic handling capability of different routers
Setup:
* Ethernet MTU: 1500
* [x86 kvm] <--ethernet--> [DUT] <--ethernet--> [x86 kvm]

Devices:
- WDR4300: ~400 Mbit/s (maxed out by softirqs)
