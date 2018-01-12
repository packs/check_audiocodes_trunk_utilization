check_tomcat.py
===============
AudioCodes SBC PRI Channel Utilization Nagios Check

Author: Scott Pack (scott.pack@gmail.com)

Version 1.0

Description
===========
This plugin is intended to monitor PRI channel utilization and alarm on high circuit
status events. It was designed against a single card Mediant 1000 but should be
applicable to any AudioCodes SBC that supports trunks. We assume all PRIs are
bonded into a single pool.
 
Requirements
============
- net-snmp
    The net-snmp utilities must be installed on the Nagios server.
- Perl Modules
    We use the following modules that must also be installed on the Nagios server.
    - Getopt::Long
    - Pod::Usage;

Installation
============
Copy `check_audiocodes_trunk_utilization.pl` to the Nagios plugins directory.

Use
==
By default the script will assume a T1 with 23 available channels. If you are bonding
multiple T1s then you must define a host variable with the total number of available
channels and pass that into the script using the appropriate command line argument.

For contextual purposes the utilization per trunk will be printed, however only the 
total will be used to determine utilization for alarming purposes.
