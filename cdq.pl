#!/usr/bin/env perl

#
# Change Directory Quickly core.
# Do not call this script directly.  Use functions defined in cdq.sourceme.bash in same directory.
#

use strict;
use warnings;
use Getopt::Long;
use Cwd;
use Fcntl qw(:flock SEEK_SET);

die "missing command" if ! defined($ARGV[0]);
my $cmd=$ARGV[0];

#
# Locate file containing dirs.  Create it if necessary.
#

my $dirs_file=$ENV{CDQ_DIRS_FILE};
$dirs_file="$ENV{HOME}/.cdq_dirs" unless defined($dirs_file);
if (! -f $dirs_file) {
	open(my $fh, ">", $dirs_file) or die "cannot create $dirs_file: $!";
	close($fh);
}

#
# Open file for r/w and lock it to prevent corruption from concurrent accesses.
#

open(my $fh, "+<", $dirs_file) or die "cannot open $dirs_file: $!";
flock($fh, LOCK_EX) or die "cannot lock $dirs_file: $!";

#
# Read file in array of array and increment usage count of current directory if in
# "add" mode.
#

my @dirs;
my $cwd = getcwd();
my $cwd_count_incremented = 0;

while (<$fh>) {
	chomp;
	my $fields = [ split(/\s+/, $_, 2) ];
	if ($cmd eq "add" && $fields->[1] eq $cwd) {
		$cwd_count_incremented=1;
		$fields->[0]++;
	}
	push @dirs, $fields;
}

if ($cmd eq "add") {
	#
	# Add current directory if not already in existing dirs and Write back updated dirs to file.
	#

	push @dirs, [1, $cwd] if !$cwd_count_incremented;

	seek($fh, 0, SEEK_SET) or die "cannot seek to beginning of $dirs_file: $!";
	truncate($fh, 0) or die "cannot truncate file: $!";

	for my $fields (@dirs) {
		print $fh "$fields->[0]	$fields->[1]\n";
	}

} elsif ($cmd eq "ls") {
	#
	# Print dirs sorted most frequently used first.
	#

	for my $fields (reverse sort { $a->[0] <=> $b->[0] } @dirs) {
		print "$fields->[1]\n";
	}
} else {
	die "unsupported command: $cmd\n";
}

flock($fh, LOCK_UN) or warn "cannot unlock $dirs_file: $!";
close($fh) or warn "cannot close $dirs_file: $!";
