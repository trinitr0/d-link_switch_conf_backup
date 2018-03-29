package GetConf;

$name = 'admin';
$pass = 'password';

sub getconf {

    $ip = shift; 
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
         $cmd2="upload cfg_toTFTP 10.0.107.45 $file_name"; #for HardVer A1
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
        s/cmIFyC89//g;
        print OF $_;
    }

    close (OF);
    close (IF);

        rename "/var/tftp/$file_name", "/var/tftp/$file_name.bkp";
        rename "/var/tftp/$file_name.tmp", "/var/tftp/$file_name";
        unlink "/var/tftp/$file_name.bkp";
    
    $date = localtime();
    open(IF, ">> /var/tftp/$file_name") or die $!;
        print IF "\n#$date";
    close (IF);

        system "chmod 0666 /var/tftp/$file_name";
}
1;
