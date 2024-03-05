#!/usr/bin/perl
use strict;
use warnings;
use File::Find;
use File::Copy;
use POSIX qw(strftime);
use File::Basename;
use Cwd 'realpath';

my $dir = shift or die "Usage: $0 DIRECTORY\n";

my %dates;
my %created_dirs;
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
    my $parent_dir = dirname($dir);
    my $absolute_parent = realpath($parent_dir);
    my $new_dir = "$absolute_parent-$date";
    if (-e $new_dir){
	print(" >> Not creating $new_dir, because it exists!\n") if not defined $created_dirs{$new_dir};
	$created_dirs{$new_dir} = 1;
    }
    else {
    	mkdir $new_dir or die $!;
	print(" >> Created $new_dir\n");
	$created_dirs{$new_dir} = 1;
    }
    print("Moving $_ to $new_dir\n");
    move($_, $new_dir) or die "Failed to move $_ to $new_dir: $!\n";
}, $dir);
