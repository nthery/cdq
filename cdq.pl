#!/usr/bin/env perl

#
# Change Directory Quickly core.
# Do not call this script directly.  Use functions defined in cdq.sourceme.bash in same directory.
#

use strict;
use warnings;
use Getopt::Long;
use Cwd;
use File::Spec;
use File::Spec::Functions;
use Fcntl qw(:flock SEEK_SET);
use Data::Dumper;

my $global_dirs_file;
my $local_dirs_dir;
my $local_dirs_file;

# Return global directories file path.  Create it if necessary.
sub find_global_dirs_file {
	my $file=$ENV{CDQ_GLOBAL_DIRS_FILE};
	$file="$ENV{HOME}/.cdq_global_dirs" unless defined($file);
	if (! -f $file) {
		open(my $fh, ">", $file) or die "cannot create $file: $!";
		close($fh);
	}
	return $file;
}

# Return tuple containing local directories directory and file if any.
sub find_local_dir_and_file {
	my $dir = getcwd();
	while (1) {
		my $file = catdir($dir, ".cdq_local_dirs");
		if (-f $file) {
			return ($dir, $file);
		}
		if ($dir eq rootdir()) {
			return ("", "");
		}
		$dir = Cwd::realpath(catdir($dir, File::Spec->updir()));
	}
}

# Open specified file for r/w access and lock it to prevent corruption from concurrent accesses.
sub open_and_lock {
	my $file = shift;
	open(my $fh, "+<", $file) or die "cannot open $file: $!";
	flock($fh, LOCK_EX) or die "cannot lock $file: $!";
	return $fh;
}

# Unlock and close specified file handle.
sub unlock_and_close {
	my $fh = shift;
	flock($fh, LOCK_UN) or warn "cannot unlock file: $!";
	close($fh) or warn "cannot close file: $!";
}

# Read (usage count, directory) tuples from specified file handle into array of array.
sub load_dirs {
	my ($fh, $dirs) = @_;
	while (<$fh>) {
		chomp;
		my $fields = [ split(/\s+/, $_, 2) ];
		push @$dirs, $fields;
	}
}

# Write back specified (usage count, directory) tuple into specified file
# handle overriding previous file content.
sub save_dirs {
	my ($fh, $dirs) = @_;

	seek($fh, 0, SEEK_SET) or die "cannot seek to beginning of file: $!";
	truncate($fh, 0) or die "cannot truncate file: $!";

	for my $fields (@$dirs) {
		print $fh "$fields->[0]	$fields->[1]\n";
	}
}

# Increment usage count of specified directory if already in table or append it to table.
sub inc_dir_usage_count {
	my ($dirs, $dir_to_inc) = @_;
	for my $d (@$dirs) {
		if ($d->[1] eq $dir_to_inc) {
			$d->[0]++;
			return;
		}
	}
	push @$dirs, [1, $dir_to_inc];
}

# Print dirs sorted most frequently used first.
sub print_dirs {
	my $dirs = shift;
	for my $fields (reverse sort { $a->[0] <=> $b->[0] } @$dirs) {
		print "$fields->[1]\n";
	}
}

# Return true if first specified path is descendant of second specified path.
sub is_descendant_of {
	my ($child, $father) = @_;
	my @c = File::Spec->splitdir($child);
	my @f = File::Spec->splitdir($father);
	return 0 if $#c < $#f;
	for (my $i = 0; $i <= $#f; $i++) {
		return 0 if $f[$i] ne $c[$i];
	}
	return 1;
}

sub cmd_add {
	my $dirs_file;
	if ($local_dirs_dir ne "" && is_descendant_of(getcwd(), $local_dirs_dir)) {
		$dirs_file = $local_dirs_file;
	} else {
		$dirs_file = $global_dirs_file;
	}
	my $fh = open_and_lock($dirs_file);
	my @dirs;
	load_dirs($fh, \@dirs);
	inc_dir_usage_count(\@dirs, getcwd());
	save_dirs($fh, \@dirs);
	unlock_and_close($fh);
}

sub cmd_ls {
	my $global_fh = open_and_lock($global_dirs_file);
	my @global_dirs;
	load_dirs($global_fh, \@global_dirs);

	my $local_fh;
	my @local_dirs = ();
	if ($local_dirs_file ne "") {
		$local_fh = open_and_lock($local_dirs_file);
		load_dirs($local_fh, \@local_dirs);
	}

	print_dirs(\@local_dirs);
	print_dirs(\@global_dirs);

	unlock_and_close($local_fh) if $local_dirs_file ne "";
	unlock_and_close($global_fh);
}

sub main {
	die "missing command" if ! defined($ARGV[0]);
	my $cmd=$ARGV[0];

	$global_dirs_file = find_global_dirs_file();
	($local_dirs_dir, $local_dirs_file) = find_local_dir_and_file();

	if ($cmd eq "add") {
		cmd_add();
	} elsif ($cmd eq "ls") {
		cmd_ls();
	} else {
		die "unsupported command: $cmd\n";
	}
}

main();
