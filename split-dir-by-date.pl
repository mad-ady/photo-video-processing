#!/usr/bin/perl
use strict;
use warnings;
use File::Find;
use File::Copy;
use POSIX qw(strftime);

my $dir = shift or die "Usage: $0 DIRECTORY\n";

my %dates;

# collect dates
find(sub {
    return unless -f; # Skip directories
    my $mtime = (stat)[9]; # modification time
    my $date = strftime('%Y-%m-%d', localtime($mtime)); 
    $dates{$date}++;
}, $dir);

if(scalar keys %dates == 1){
	print("No need to move files. All are the same date\n");
	exit();
}

# Second pass: move files
find(sub {
    return unless -f; # Skip directories
    my $mtime = (stat)[9]; # modification time
    my $date = strftime('%Y-%m-%d', localtime($mtime)); 
    my $new_dir = "$dir-$date";
    mkdir $new_dir unless -e $new_dir; # Create directory if it doesn't exist
    print("Moving $_ to $new_dir\n");
    move($_, $new_dir) or die "Failed to move $_ to $new_dir: $!\n";
}, $dir);
