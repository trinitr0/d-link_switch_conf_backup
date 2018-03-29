#!/usr/bin/perl

$ENV{"PATH"} = "/bin";

use Net::Telnet;
use DBI;
require "GetConf.pm";

my $ip;
my $name = 'sa';
my $pass = 'cmIFyC89';

my $qry = ("SELECT ip FROM computers WHERE unit_id='76' ORDER BY ip");
my $dbh = DBI -> connect ("DBI:Pg:dbname=info user=info_bckp_switch host=10.0.0.4 password=ofra2000HaZA");
my $sth = $dbh -> prepare($qry);
my $rv = $sth -> execute();

if (!defined $rv) {
  print "ERROR on while execute '$qry': " . $dbh->errstr . "\n";
  exit(0);
}

while (my @row = $sth -> fetchrow_array())
{	
	$ip = $row[0]; #get ip switch
	foreach $ip(@row)
	{
	    my $ping =  "ping -c 1 -q $ip";
    	    my @lines = `$ping`;

            for my $line (@lines)
	    {
        	if ($line =~ /\s+(\d+)% packet loss/)
         	{
            	    if ($1 eq '100')
            	    {
			print "$ip - FAIL!\n";
		    }
		    else
		    {
			print "$ip - OK!, then backup config $ip to continue...\n";
			$conf = GetConf::getconf($ip);
	    		#&getconf();
		    }
		}
	    }
	}   
}	

$sth -> finish();
$dbh -> disconnect();

__END__
