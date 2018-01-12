#!/usr/bin/perl
# File    : check_audiocodes_trunk_utilization.pl
# Author  : Scott Pack
# Created : January 2018
# Purpose : Checks AudioCodes Mediant SBCs for PRI channel utilization.
#
#     Copyright (c) 2016 Scott Pack.
#     Creative Commons Attribution-NonCommercial-NoDerivs 3.0
#
#
#

use strict;
use warnings;
use Getopt::Long qw(:config no_ignore_case bundling);
use Pod::Usage;

my ($addr, $community, $username, $authpass, $authproto, $privpass, $privproto);
my $warn = 75;
my $crit = 90;
my $ver = '2c';
my $port = 161;
my $channels = 23;

# Grab the options passed on the command line.
GetOptions (
  "address|host|a=s"   => \$addr,
  "community|C=s"      => \$community,
  "channels|x=i"       => \$channels,
  "warn|w=i"           => \$warn,
  "crit|c=i"           => \$crit,
  "version|v=s"        => \$ver,
  "port|p=i"           => \$port,
  "user|u=s"           => \$username,
  "authpass|o=s"       => \$authpass,
  "authproto|r=s"      => \$authproto,
  "privpass|O=s"       => \$privpass,
  "privproto|R=s"      => \$privproto,
  "help|?|h"           => sub { pod2usage(1); }, # flag
) or pod2usage("$0: Unrecognized program argument.");

if( !( defined($addr) ) )
{
  pod2usage("$0:  Required argument missing.");
}

my $acPMTrunkUtilizationVal = '1.3.6.1.4.1.5003.10.10.2.21.1.3';

my $state_ok = 0;
my $state_warning = 1;
my $state_critical = 2;
my $state_unknown = 3;


my $retval = $state_ok;

# Build the SNMP command line
my $snmpopts;
if( $ver eq ('2c' or '1') )
{
  pod2usage("$0:  Required argument missing.") unless defined($community);
  $snmpopts = "-v $ver -c $community";
}
elsif( $ver eq '3')
{
  pod2usage("$0:  Required argument missing.") unless (defined($username) and defined($authproto) and defined($privproto) and defined($privpass));
  $snmpopts = "-v $ver -u $username -a $authproto -x $privproto -X $privpass";
}
else
{
  print "Unrecognized SNMP version!\n";
  exit;
}


# Grab all the interfaces and build a list of descriptions for the PRIs
my $ifDescrRet = `snmpwalk $snmpopts $addr ifDescr`;
my @ifDescr = split /\n/, $ifDescrRet;
my @trunkDescr;
foreach( @ifDescr )
{
  if( /IF-MIB::ifDescr\.(\d+) = STRING: Digital DS1 interface (\d)\/(\d)/ )
  {
    $trunkDescr[$3] = "Digital DS1 interface $2/$3";
  }
}

# Grab trunk utilization values
my $trunkUtilizationVarRet = `snmpwalk $snmpopts $addr $acPMTrunkUtilizationVal`;
my $trunkUtilizationTotal = 0;
my $trunkUtilizationStatus;
# Now let's go through all those drives. If they're fixed then grab all the data.
my @trunkUtilizationVar = split /\n/, $trunkUtilizationVarRet;
foreach( @trunkUtilizationVar )
{
  if( /SNMPv2-SMI::enterprises\.5003\.10\.10\.2\.21\.1\.3\.(\d+).0 = Gauge32: (\d+)/ )
  {
    my $trunkIndex= $1;
    my $trunkUsed = $2;

    # Add this trunk to the total used
    $trunkUtilizationTotal += $trunkUsed;

    # Now do all the work to print statistical information on a per trunk basis.
    $trunkUtilizationStatus .= "$trunkDescr[$trunkIndex+1]: $trunkUsed Channels Used\n";

  }
}

# Check the used sizes against the thresholds
my $trunkPer = ($trunkUtilizationTotal / $channels)*100;
$trunkPer = sprintf("%.2f",$trunkPer);
my $channelsFree = $channels - $trunkUtilizationTotal;
if( $trunkPer >= $crit )
{
  print "CRITICAL : Channels Percent Used : $trunkPer%, Total : $channels, Used : $trunkUtilizationTotal,  Free : $channelsFree\n";
  $retval = $state_critical;
}
elsif( $trunkPer >= $warn )
{
  print "WARNING : Channels Percent Used : $trunkPer%, Total : $channels, Used : $trunkUtilizationTotal,  Free : $channelsFree\n";
  $retval = $state_warning unless $retval == $state_critical;
}
else
{
  print "OK : Channels Percent Used : $trunkPer%, Total : $channels, Used : $trunkUtilizationTotal,  Free : $channelsFree\n";
}

print $trunkUtilizationStatus;

exit( $retval );

=head1 NAME

check_audiocodes_trunk_utilization - Fetches all PRI trunks on AudioCodes Mediants and reports trunk utilization

by Scott Pack

=head1 SYNOPSIS

check_audiocodes_trunk_utilization.pl [options]

 Options:
   -a, --address, --host     IP address or host name of host to query
   -C, --community           SNMP Community String
   -w, --warn                Warning threshold as an integer. Default: 75
   -c, --crit                Critical threshold as an integer. Default: 90
   -x, --channels            Total available channels across all PRIs on this device. Default: 23
   -v, --version             SNMP Version. Default: 2c
   -p, --port                SNMP Destination Port. Default: 161
   -h, --help                Brief help message
  SNMP version 3 specific arguments:
   -u, --user                Security Name
   -o, --authpass            Authentication password
   -r, --authproto           Authentication protocol [md5|sha]
   -O, --privpass            Privacy password
   -R, --privproto           Privacy protocol [des|aes|3des]

By Scott Pack

=cut
