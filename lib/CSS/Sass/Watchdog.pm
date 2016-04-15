# Copyright (c) 2013 David Caldwell.
# Copyright (c) 2014 Marcel Greter.
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

use strict;
use warnings;
use CSS::Sass;

################################################################################
package CSS::Sass::Watchdog;
our $VERSION = "3.3.2";
################################################################################

use Exporter 'import'; # gives you Exporter's import() method directly
our @EXPORT = qw(start_watchdog); # symbols to export by default

####################################################################################################
####################################################################################################

# load function from core module
use List::MoreUtils qw(uniq);

# check if the benchmark module is available
my $benchmark = eval "use Benchmark; 1";

# declare package variables
my ($parent_pid, $child_pid) = ($$, 0);

####################################################################################################
# the watchdog process (maybe put in own module)
####################################################################################################

# the parent is the main (current) process
# wait for events to arive to the message queue
# wait some time until we start the re-compilation
sub watchdog_parent ($$$)
{

	# Try to be smart here. We will not start the compilation after
	# each event right away. There are at least two scenarios where
	# this would be inefficient. First if a user clicks "save all"
	# in its editor, or if multiple files are copied over. We wait
	# for a certain period and only start the compilation when we
	# got no more change events.

	# get input variables
	my ($changes, $files, $compile) = @_;

	# aggregated events
	my @aggregated;

	# print delimiter line
	print '=' x 78, "\n";

	# go into endless loop
	while (1)
	{

		# check if we have something to
		# dequeue in the next seconds
		if ($changes->can_dequeue(0.25))
		{

			# dequeue a key from notifier
			my $item = $changes->dequeue();

			# wait for exit command
			exit if $item eq "stop";

			# push the real hash to the queue
			push(@aggregated, $item);

			# make aggregated list unique
			@aggregated = uniq @aggregated;

		}
		# nothing to dequeue, we waited 0.25 seconds
		# maybe we have something in our to do list
		else
		{

			# autoflush
			local $| = 1;

			# count errors
			my $beeps = 1;

			# do nothing of aggregated is empty
			next if scalar(@aggregated) == 0;

			# now call the compilation step
			my $t0 = $benchmark ? Benchmark->new : 0;
			print "compilation started\n";
			my ($css, $err, $stats) = $compile->();
			my $t1 = $benchmark ? Benchmark->new : 0;
			if (!$err) { print "sucessfully finished\n"; }
			else { print "finished with an error\n"; }

			# only print benchmark result when module is available
			if ($benchmark) { print timestr(timediff($t1, $t0)), "\n"; }

			my @includes = @{$stats->{'included_files'} || []};
			# use the simples equality test
			# should work since they are sorted
			if (!$err && "@{$files}" ne "@includes")
			{
				print "re-start file watcher\n";
				# make sure our child is terminated
				kill 9, $child_pid;
				waitpid($child_pid, 0);
				# new watch file list
				$files = \@includes;
				# start new child process
				unless ($child_pid = fork())
				{ watchdog_child($changes, $files); }
			}

			# beep more in case of errors
			$beeps += 2 if defined $err;

			# ring the bell now
			print "\a" x ($beeps);
			# clear aggregated
			undef @aggregated;
			# print delimiter line
			print '=' x 78, "\n";

		}
		# EO can dequeue

	}
	# EO endless loop

}
# EO sub watchdog_parent

# the child watches all registered files for changes
# changes will be sent to the parent via our fork queue
# the parent will decide when to start the next compilation
sub watchdog_child ($$)
{

	# get input variables
	my ($changes, $files) = @_;

	# try to load the watch module conditional
	unless (eval { require Filesys::Notify::Simple; 1 })
	{ die "module Filesys::Notify::Simple not found"; }

	# print message with watched files
	print "waiting for changes now\n";
	print map { ("  ", $_, "\n") } @{$files || []};
	# print delimiter line
	print '=' x 78, "\n";

	# create the watcher object on all filepaths
	my $watcher = Filesys::Notify::Simple->new($files);

	# go into endless loop
	while (1)
	{

		# watch for file changes
		# this will block forever
		$watcher->wait(sub
		{

			# get all events
			for my $event (@_)
			{
				# print a message when a change occurs
				printf "changed: %s\n", $event->{path};
				# get the normalized path string
				my $path = $event->{path};
				# enqueue changed file
				$changes->enqueue($path);

			}
			# EO all events

		});
		# EO wait for watcher

	}
	# EO endless loop

}
# EO sub watchdog_child

sub start_watchdog ($$)
{

	local $SIG{CHLD} = 'IGNORE';

	# pass compile stats
	my ($stats, $compile) = @_;

	# A simple sequence of compile, wait, compile etc. will not work
	# correctly, since we will miss changes while we are compiling.
	# So a change done while a compile is still running, will not
	# trigger any event, when the previous compilation is done.

	# This could also be solved by using File::ChangeNotify, since
	# it should provide an API that seems to be non blocking. I guess
	# that some platform-specific implementation does not support non-
	# blocking io, which should be the case, as otherwise I would expect
	# File::ChangeNotify::Simple to provide a non-blocking interface. But
	# I really like that deps are optional in File::ChangeNotify::Simple!

	# Therefore we create two "threads" that communicate via
	# a very simple queue object. This allows us to sync changes
	# and running compilations. Since this creates quite a lot
	# of additional dependencies, we try to load them only when
	# this feature is in use (no hard dependencies for core lib).

	# Most of the code and ideas have been copied from webmerge!
	# ToDo: reference optional (should have) deps in build file!

	# create new queue to pass commands/events around
	my $changes = CSS::Sass::Watchdog::Queue->new();

	# get the files from the previous compile stats
	my @files = @{$stats->{'included_files'} || []};

	# start child process
	if ($child_pid = fork())
	{ watchdog_parent($changes, \@files, $compile); }
	else { watchdog_child($changes, \@files); }

}
# EO sub start_watchdog

###################################################################################################

END
{
	# check if we actually are the parent
	if ($parent_pid && $parent_pid == $$)
	{
		# print "parent is terminating\n";
		# make sure our child is terminated
		kill 'TERM', $child_pid if $child_pid;
	}
	# check if we actually are the parent
	elsif ($parent_pid && $parent_pid != $$)
	{
		# print "file watcher was terminated\n";
	}
}

################################################################################
# from http://www.perlmonks.org/?node_id=49335
# 26.06.2012 added can_dequeue function (mgr@rtp.ch)
################################################################################
package CSS::Sass::Watchdog::Queue;
################################################################################

use Socket;

sub new {
    my($this) = @_;
    my $class = ref($this) || $this;
    my $self = {};
    bless $self, $class;
    $self->mksockpair();
    return $self;
}

# make the socketpair
sub mksockpair {
    my($self)=@_;
    socketpair(my $reader, my $writer, AF_UNIX, SOCK_STREAM, PF_UNSPEC);
    if ($^O ne "MSWin32")
    {
      shutdown($reader,1);
      shutdown($writer,0);
    }
    $self->{'READER'}=$reader;
    $self->{'WRITER'}=$writer;
}

# method to put something on the queue
sub enqueue {
    my($self,@data)=@_;
    my($header,$buffer,$tosend);
    my($handle)=$self->{'WRITER'};
    foreach my $item (@data) {
        $header=pack("N",length($item));
        $buffer=$header . $item;
        $tosend=length($buffer);
        my $rv = print $handle $buffer;
        die "write error : $!" unless defined $rv;
        die "write disconnected" if $rv eq 0;
        $handle->flush;
    }
}

# method to pull something off the queue
sub dequeue {
    my($self)=@_;
    my($header,$data);
    my($toread)=4;
    my($bytes_read)=0;
    my($handle)=$self->{'READER'};
    # read 4 byte header
    while ($bytes_read < $toread) {
       my $rv=read($handle,$header,$toread);
       die "read error : $!" unless defined $rv;
       die "read disconnected" if $rv eq 0;
       $bytes_read+=$rv;
    }
    $toread=unpack("N",$header);
    $bytes_read=0;
    # read the actual data
    while ($bytes_read < $toread) {
       my $rv=read($handle,$data,$toread,0);
       die "read error : $!" unless defined $rv;
       die "read disconnected" if $rv eq 0;
       $bytes_read+=$rv;
    }
    return $data;
}

# method to check if something can be dequeued
sub can_dequeue {
    my($self,$timeout)=@_;
    my($handle)=$self->{'READER'};
    if (defined(my $fileno = $handle->fileno())) {
        vec(my $rbit = '', $fileno, 1) = 1; # enable fd in vector table
        vec(my $ebit = '', $fileno, 1) = 1; # enable fd in vector table
        my $rv = select($rbit, undef, $ebit, $timeout); # select for readable handles
        die "can dequeue errors" if vec($ebit, $fileno, 1);
        return vec($rbit, $fileno, 1); # check fd in vector table
    } else { return undef; }
    # my($io) = IO::Select->new($handle);
    # return $io->can_read($timeout);
}

################################################################################
package CSS::Sass::Watchdog;
################################################################################
1;

__END__

=head1 NAME

CSS::Sass::Watchdog - Watchdog plugin for perl-libsass

=head1 SEE ALSO

L<CSS::Sass>

=head1 AUTHOR

David Caldwell E<lt>david@porkrind.orgE<gt>  
Marcel Greter E<lt>perl-libsass@ocbnet.chE<gt>

=head1 LICENSE

The MIT License (MIT)

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

=cut
