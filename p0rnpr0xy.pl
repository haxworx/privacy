#! /usr/bin/perl

# BLOCK IMAGES PROXY!
# NO PORN OR ADS

use warnings;
use strict;

use LWP::Simple;
use IO::Socket;
use IO::Select;

sub WebBork {
	my ($msg) = @_;
	print "Content-type: text/plain\r\n\r\n";
	print "<h1>No HTTPS</h1>";
	exit;
}

my $EXT_BLOCK = "[jpg|JPG|jpeg|JPEG|gif|GIF|Gif|m4a|M4A|mp4|png|PNG]";

sub ProxyTime {
	my ($socket) = @_;
	my @pids = ();
	my $url = ""; 
	my $data = "";
	my $pid = fork();
	if ($pid == 0) {
		if ($socket->connected()) { 
			read ($socket, $data,128);
			if ($data =~ m/\AGET\s+(.+)\s+HTTP.*/) {
				$url = $1;
				if ($url =~ m/\A.+\.$EXT_BLOCK+\z/) {
					$url = "";	
				}

				if (length($url)) {
					print "URL is $url\n";
				}
			}	

			my $html = get($url);
			$socket->write( $html );
			$socket->close();
		}	
	} elsif ($pid > 0) {
		push @pids, $pid;
	} else {
		exit(1);
	}

	foreach (@pids) {
		waitpid(-1, $_);
	}
	
	return 0;
}
sub StartServer {
	my ($port) = @_;

	my $sock = IO::Socket::INET->new( Listen => SOMAXCONN,
					  LocalAddr => '127.0.0.1',
					  LocalPort => $port,
					  Proto => 'tcp',
					  ReuseAddr => 1 );

	my $read = IO::Select->new();
	my $write = IO::Select->new();

	$read->add($sock);

	for (;;) {
		my @fds = $read->can_read();
		foreach my $fd (@fds) {
			if ($fd == $sock) {
				my $conn = $sock->accept();
				$write->add($conn);
				if ($conn->connected()) {
					ProxyTime($conn);
					$conn->close();
				}
			}
		}
	}
}	 	

print "Blocking all badness\n";
StartServer(9999);

exit(0);
