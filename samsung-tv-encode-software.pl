#!/usr/bin/perl
use strict;
use warnings;
use Data::Dumper;
use JSON;

my $src='/DataVolume/TVRecordings/CONTENTS/';
my $dst='/DataVolume/TVRecordings/prelucrate/';
opendir my $dir, "$src" or die "Can't open directory $src. $!";
my @files = readdir($dir);
closedir $dir;


my %metadata;
my $notification;
#for each new file
foreach my $file (@files){
	`logger -s -t "$0" "Looking at file $file"`;
	print "$file\n";
	my $filetimestamp = 0;
	if($file=~/([0-9]+)\./){
		#extract date
		$filetimestamp = $1;
	}
	if($file=~/\.inf/){
		#try to extract the show's name
		my $name = `strings '$src/$file'`;
		if(length($name) > 5){
			$name=~s/\r|\n//;
			$name=~s/[^A-Za-z0-9 -_]+/_/g;
			$metadata{$filetimestamp}{'name'} = $name;
		}
	}
	if($file=~/\.srf/){
		# convert to mp4 with ffmpeg - hw accelerated
		`logger -s -t "$0" "Converting ${filetimestamp}_$metadata{name}.mp4"`;
		#get video resolution
		my $height = `mediainfo '$src/$file' | grep Height | cut -d ':' -f 2 | cut -d 'p' -f 1 | sed 's/\\s//g'`;
		$height=~s/\r|\n//g;
		my $bandwidth = 1500;
		if($height >= 600 && $height <=720){
			$bandwidth = 2200;
		}
		elsif($height > 720){
			$bandwidth = 4000;
		}

		#get audio streams
		my $audioMapping="";
		my @audioStreams = `ffmpeg -i '$src/$file' 2>&1 | grep Audio: |  egrep "r[ou]m|eng"`;
		my $totalAudioStreams = 0;
		foreach my $audio (@audioStreams){
			if($audio=~/Stream #([0-9]+:[0-9]+)/){
				$audioMapping.= " -map $1 -c:a:$totalAudioStreams copy ";
				$totalAudioStreams++;
			}
		}

		`logger -s -t "$0" "Video has the following audio streams: $audioMapping"`;
		`logger -s -t "$0" "Video size is $height, bandwidth is $bandwidth"`;
		#open CMD, "/usr/bin/ffmpeg -y -i '$src/$file' -threads 1 -map 0:0 -map 0:1 -map 0:3? -c:v libx264 -preset ultrafast -r 25 -pix_fmt yuv420p -b:v ${bandwidth}k -acodec copy '$dst/${filetimestamp}_$metadata{name}.mp4' |";
		#open CMD, "/usr/bin/ffmpeg -y -i '$src/$file' -threads 1 -map 0:0 -map 0:1  -c:v libx264 -preset ultrafast -r 25 -pix_fmt yuv420p -b:v ${bandwidth}k -acodec copy '$dst/${filetimestamp}_$metadata{name}.mp4' |";
#		open CMD, "/usr/bin/ffmpeg -y -i '$src/$file' -codec:v copy -codec:a none -bsf:v h264_mp4toannexb -f rawvideo - | /usr/bin/ffmpeg -r 25 -vf 'scale=trunc(iw/64)*64:trunc(ih/64)*64' -i -  -i '$src/$file' -map 0:v:0 -vcodec h264 -b:v ${bandwidth}k -r 25 -pix_fmt nv21 $audioMapping '$dst/${filetimestamp}_$metadata{name}.mp4' |";
		open CMD, "/usr/bin/cgexec -g cpuset:bigcores /usr/bin/ffmpeg -y -i '$src/$file' -map 0:0 -codec:v libx264 -b:v ${bandwidth}k -pix_fmt nv21 -vf 'yadif' $audioMapping '$dst/${filetimestamp}_$metadata{name}.mp4' |";
		while(<CMD>){
			print "$_";
		}

		#once encoding has finished 
		#1. Check if conversion was ok (>10MB) and if yes, delete source files
		if(-s "$dst/${filetimestamp}_$metadata{name}.mp4" > 10_000_000){
			`logger -s -t "$0" "Conversion of ${filetimestamp}_$metadata{name}.mp4 was ok. Deleting source"`;
			`logger -s -t "$0" "rm -f \"$src/$filetimestamp.*\""`;
			print `rm -f $src/$filetimestamp.*`;
            chown 1001, 1001, "$dst/${filetimestamp}_$metadata{name}.mp4"
			$notification.="${filetimestamp}_$metadata{name}.mp4 [Ok],";
		}
		else{
			`logger -s -t "$0" "Converting ${filetimestamp}_$metadata{name}.mp4 failed!"`;
            $notification.="${filetimestamp}_$metadata{name}.mp4 [Fail],";
		}
		#2. Wait for a minute to cool off
		`logger -s -t "$0" "Sleeping 10s to cool off"`;
		sleep(10);

	}
}
print Dumper(\%metadata);

print "Notification is: $notification\n";
