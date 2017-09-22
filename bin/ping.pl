#!/opt/local/bin/perl -w
# -------------------------------------------------------------------------------------
# $Id: ping.pl 5 2012-06-08 19:44:25Z stefan $
# -------------------------------------------------------------------------------------
# Trivadis AG, Infrastructure Managed Services
# Europa-Strasse 5, 8152 Glattbrugg, Switzerland
# -------------------------------------------------------------------------------------
# File-Name........: ping.pl
# Author...........: Stefan Oehrli (oes) stefan.oehrli@trivadis.com
# Editor...........: $LastChangedBy: stefan $
# Date.............: $LastChangedDate: 2012-06-08 21:44:25 +0200 (Fri, 08 Jun 2012) $
# Revision.........: $LastChangedRevision: 5 $
# Purpose..........: simple script to ping a host
# Usage............: ping.pl <HOSTNAME> <COUNT>
# Reference........: --
# Group/Privileges.: --
# File formats.....: dont use files
# Input parameters.: none
# Output.......... :  
# Called by........:  
# Libraries........: none
# Error handling...: just die if something is missing / failing
# Restrictions.....: unknown
# Notes............: --
# -------------------------------------------------------------------------------------
# Revision history.:      see svn log
# -------------------------------------------------------------------------------------

use strict;
use POSIX qw(strftime);
use Net::Ping;
use Time::HiRes;
use File::Basename; 
use sigtrap 'handler', \&terminate, 'normal-signals';  # define a signal handler to do a smooth stop
$|++;                     # force flush of STDOUT 

my $name = basename($0);  # just to have a my name a bit nicer
my $timeout=5;            # timeout for ping
my $count=1;
my $sleeptime=1;          # sleep between ping's
my $protocol='tcp';       # protocol used by ping
my($host) = shift() || die("Usage: $0 <host.somewhere.com> <count> <sleep>\n");
$count = shift() || die("Usage: $0 <host.somewhere.com> <count> <sleep>\n");
$sleeptime = shift() || die("Usage: $0 <host.somewhere.com> <count> <sleep>\n");
my $ping = Net::Ping->new($protocol,$timeout);
$ping->hires();

print "Start $name at " . strftime("%Y.%m.%d %H:%M:%S", localtime) . " will terminate on HUP, INT, PIPE or TERM  => kill -s TERM $$\n";
for (my $i=0; $i < $count; $i++) {  # my endless loop
   my ($status,$time,$ip) = $ping->ping($host,$timeout);
   if ($status) {
       printf("Pinging %s (%s) at %s responded in %.3f msec\n", $host, $ip, strftime("%Y.%m.%d %H:%M:%S", localtime), $time * 1000);
   } else {
       printf("Pinging %s at %s unreachable\n", $host, strftime("%Y.%m.%d %H:%M:%S", localtime));
   }
   sleep($sleeptime);    # sleep before the next ping
}


# Catch the signal and terminate
sub terminate {
   my($signal) = @_;
   print "Recived Signal $signal at " . strftime("%Y.%m.%d %H:%M:%S", localtime) . " terminate $name \n";
   $ping->close();
   exit;
}

print "Successful end $name at " . strftime("%Y.%m.%d %H:%M:%S", localtime) . "\n";
$ping->close();
exit;

=head1 NAME

ping.pl - Simple ping script!

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use test;

    my $foo = test->new();
    ...

=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=head1 SUBROUTINES/METHODS

=head2 function1

=cut

sub function1 {
}

=head2 function2

=cut

sub function2 {
}

=head1 AUTHOR

"Stefan Oehrli", C<< <"stefan.oehrli at postgasse.ch"> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-test at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=test>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc test


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=test>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/test>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/test>

=item * Search CPAN

L<http://search.cpan.org/dist/test/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2012 "Stefan Oehrli".

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of test
