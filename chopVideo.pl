#!/usr/bin/perl
use strict;
use warnings;
use Data::Dumper;
use File::Basename; 

my $input = $ARGV[0];
die "Unable to read $input" if ( ! -f $input);

my $output = $ARGV[1];

my $bypassffprobe = 1;

#we get the timings from stdin.
#Timings should be chronological!
my @timings = ({'duration' => 0, 'keep' => 'd'});

print "Input a duration and whether to keep that section or not ([hh:][mm:]ss k|d)\n";
my $keepers = 0;
while(<STDIN>){
	my $line=$_;
	if($line=~/^([0-9]+)\s*([kd]?)\s*$/){
		#input is in seconds
		push @timings, {'duration' => $1, 'keep' => ((defined ($2))?$2:'d')};
		$keepers++ if($2 eq 'k');
	}
	if($line=~/^([0-9]+):([0-9]+)\s*([kd]?)\s*$/){
		#input is mm:ss
		my $duration = $1*60 + $2;
		push @timings, {'duration' => $duration, 'keep' => ((defined ($3))?$3:'d')};
		$keepers++ if($2 eq 'k');
	}
	if($line=~/^([0-9]+):([0-9]+):([0-9]+)\s*([kd]?)\s*$/){
		#input is hh:mm:ss
		my $duration = $1*3600 + $2*60 + $3;
		push @timings, {'duration' => $duration, 'keep' => ((defined ($4))?$4:'d')};
		$keepers++ if($2 eq 'k');
	}
}
print Dumper(\@timings);

#calculate a base filename for the file
my $base = (defined $output)?$output:$input;
my ($name,$path,$suffix) = fileparse($base, qw/.ts .mp4 .avi .mkv .m4v/);

my $count = 0;
#skip first one, it's a filler
for (my $i=1; $i<scalar(@timings); $i++){
	my $length = $timings[$i]{'duration'} - $timings[$i-1]{'duration'};
	print "Interval $timings[$i]{'duration'} - $timings[$i-1]{'duration'} = $length\n";
	die "Negative interval!" if ($length <= 0);

	#skip chunks to be deleted
	next if((defined($timings[$i]{'keep'}) && $timings[$i]{'keep'} eq 'd')||(! defined $timings[$i]{'keep'})||($timings[$i]{'keep'} eq ''));
	
	my $destination = $path."/".$name."_$count".$suffix;
	print " -> $destination\n";

	$count++;
	my $fps = 25;
    $fps = 23.98;

    if(!$bypassffprobe){	
	#find the closest start time before the timing
	open (CMD, "-|", "ffprobe -select_streams v -show_frames -show_entries frame=pict_type -of csv '$input' 2>&1| egrep -n --line-buffered 'I|fps'");
	print "Opened ffprobe...\n";

	my $currentFrame = 0;
	while(<CMD>){
		print "$_";
		if(/, ([0-9\.]+) fps,/){
			$fps = $1;
			print "Found video fps: $fps\n";
			next;
		}
		if(/^([0-9]+):frame,I/){
			my $frame = $1;
			if($frame <= $timings[$i-1]{'duration'} * $fps){
				$currentFrame = $frame;
				print "Set currentFrame to $currentFrame\n";
			}
			else{
				#we went over it
				#kill ffprobe
				print "Killing ffprobe\n";
				print `pkill ffprobe`;
				last;
			}
		}
	}
	close CMD;

    $currentFrame-- if($currentFrame > 0); #go a frame before the keyframe

	print "Synchronizing on keyframe - ".int($currentFrame/$fps)."s instead of $timings[$i-1]{'duration'}\n";
	$timings[$i-1]{'duration'} = int($currentFrame/$fps);
    }
	#process this chunk
	print `ffmpeg -i "$input" -map 0:0 -map 0:1 -force_key_frames 00:00:00.000 -vcodec copy -acodec copy -ss $timings[$i-1]{'duration'} -t $length "$destination"`;
}
