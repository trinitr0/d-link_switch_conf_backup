#!/usr/bin/perl

use Net::Telnet;
use DBI;
use strict;

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
###################################################################################################
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
	    		&getconf();
		    }
		}
	    }
	}   
}	
#########################################################################################################
sub getconf {

	$file_name = $number = substr($ip,7,10); #strip ip address
	$file_name =~ s/$number/switch$number.cfg/; #rename config file

	    system "unlink /var/tftp/$file_name";
	    system "touch      /var/tftp/$file_name";
	    system "chmod 0666 /var/tftp/$file_name";

	$telnet = new Net::Telnet (Timeout=>50,Prompt=>'/#/'); #make object net
	$telnet -> open($ip); #connect to switch
	$telnet -> login($name, $pass); #enter to switch
	$telnet -> cmd('dis cli'); #for full output

	     $cmd1="show switch";
	     $cmd2="upload cfg_toTFTP 10.0.107.45 $file_name";
	     $cmd3="upload cfg_toTFTP 10.0.107.45 dest_file $file_name"; #for HardVer C1
			
	@lines = $telnet -> cmd($cmd1);
	chomp (@lines);

	foreach $line (@lines)
	{	
	     ($val) = $line =~ /Hardware Version\s+:\s+([A-Z0-9]+)/;
	     next unless $val;
	
	    if ($val eq "C1")
	    {
		$telnet -> cmd($cmd3);
	    }
   	    else
   	    {
		$telnet -> cmd($cmd2);
    	    }
	}

	$telnet -> print('');
	$telnet -> waitfor('/#/');
	$telnet -> print ('logout');
	$telnet -> close;

	open(IF, "< /var/tftp/$file_name") or die $!;
	open(OF, "> /var/tftp/$file_name.tmp") or die $!;

	while(<IF>)
	{
	    s/create account admin sa//g;
	    s/11388019//g;
	    print OF $_;
	}

	close (OF);
	close (IF);

        rename "/var/tftp/$file_name", "/var/tftp/$file_name.bkp";
        rename "/var/tftp/$file_name.tmp", "/var/tftp/$file_name";
        unlink "/var/tftp/$file_name.bkp";

	    $date = `date +%d-%m-%Y--%H-%M`;
	    open(IF, ">> /var/tftp/$file_name") or die $!;
	    print IF "\n#$date";
	    close (IF);

        system "chmod 0666 /var/tftp/$file_name";
}

$sth -> finish();
$dbh -> disconnect();

__END__
