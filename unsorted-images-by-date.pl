#!/usr/bin/perl
use strict;
use warnings;
use File::Basename;
use File::Path qw(make_path);
use File::Copy qw(move);

# Usage check
if (@ARGV != 2) {
    die "Usage: $0 <source_dir> <destination_dir>\n";
}

my ($src_dir, $dst_dir) = @ARGV;

# Validate source directory
die "Source directory does not exist: $src_dir\n" unless -d $src_dir;

# Create destination directory if it doesn't exist
unless (-d $dst_dir) {
    make_path($dst_dir) or die "Cannot create destination directory: $dst_dir\n";
}

# Supported image/video extensions
my %image_exts = map { $_ => 1 } qw(jpg jpeg png gif bmp tiff tif webp heic heif mp4 mov avi mkv);

my $moved    = 0;
my $skipped  = 0;
my $errors   = 0;

opendir(my $dh, $src_dir) or die "Cannot open source directory: $src_dir\n";
my @files = readdir($dh);
closedir($dh);

for my $filename (sort @files) {
    # Skip directories and hidden files
    next if $filename =~ /^\./;
    my $filepath = "$src_dir/$filename";
    next unless -f $filepath;

    # Check extension
    my ($ext) = $filename =~ /\.([^.]+)$/;
    unless (defined $ext && $image_exts{ lc($ext) }) {
        print "Skipping (unsupported type): $filename\n";
        $skipped++;
        next;
    }

    # Extract year and month from filename
    # Supports optional prefixes: IMG_, VID_, MVIMG_, IMG-, VID-
    unless ($filename =~ /^(?:(?:IMG|VID|MVIMG)[_-])?(\d{4})(\d{2})\d{2}[_-]/) {
        print "Skipping (no date in name): $filename\n";
        $skipped++;
        next;
    }

    my ($year, $month) = ($1, $2);
    my $dir_name = "[$year.$month] unsorted";
    my $target_dir = "$dst_dir/$dir_name";

    # Create the target directory if it doesn't exist
    unless (-d $target_dir) {
        make_path($target_dir) or do {
            warn "Cannot create directory: $target_dir\n";
            $errors++;
            next;
        };
        print "Created directory: $dir_name\n";
    }

    my $target_path = "$target_dir/$filename";

    # Handle filename collision
    if (-e $target_path) {
        print "Skipping (already exists at destination): $filename\n";
        $skipped++;
        next;
    }

    if (move($filepath, $target_path)) {
        print "Moved: $filename -> $dir_name\n";
        $moved++;
    } else {
        warn "Failed to move $filename: $!\n";
        $errors++;
    }
}

print "\nDone. Moved: $moved, Skipped: $skipped, Errors: $errors\n";
