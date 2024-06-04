#!/usr/bin/perl
use strict;
use warnings;
use Data::Dumper;

my $input = $ARGV[0];
my $output = $input;
$output=~s/\.([^\.]+)$/_.$1/; 

#
#use ffmpeg to extract dimensions, framerate    
my $ffprobe = `ffprobe '$input' 2>&1 | grep Stream | grep Video`;
my %videoInfo = (
   height => '480',
   fps => '24',
   bitrate => 1500,
);
#Stream #0:0(jpn): Video: h264 (High) (avc1 / 0x31637661), yuvj420p(pc, smpte170m), 1920x1080 [SAR 1:1 DAR 16:9], 24097 kb/s, 29.97 fps, 29.97 tbr, 90k tbn, 59.94 tbc (default)
if($ffprobe=~/ ([0-9]{3,4})x([0-9]{3,4})(?:\s*\[[^\]]+\])?,.* ([0-9]+) kb\/s,.* ([0-9\.]+) fps/){
    $videoInfo{'width'}=$1; 
    $videoInfo{'height'}=$2;
    $videoInfo{'bitrate'}=$3;
    $videoInfo{'fps'}=$4;
}
my $scaleDown="";
if($videoInfo{'width'} >= 1080){
    $videoInfo{'width'} = 1080;
    $scaleDown=",scale=-2:$videoInfo{'width'}";
    print "Scaling down video to 1080p\n";
}

print Dumper(\%videoInfo);
    my $bandwidth = 2_500; #by default anything less 720p gets 2.5M
    #my $framerate = $videoInfo->{framerate};
    print "Video width is ".$videoInfo{'width'}."p\n";
    if($videoInfo{width} == 1080){
        $bandwidth = 6_000;
    }
    elsif($videoInfo{width} == 720){
        $bandwidth = 4_000;
    }
    else{
        $bandwidth = 3_500;
    }


my $encode="ffmpeg -y -i \"$input\" -lavfi '[0:v]scale=ih*16/9:-1,boxblur=luma_radius=min(h\\,w)/20:luma_power=1:chroma_radius=min(cw\\,ch)/20:chroma_power=1[bg];[bg][0:v]overlay=(W-w)/2:(H-h)/2,crop=h=iw*9/16$scaleDown' -vb ${bandwidth}k \"$output\" 2>&1";
print $encode."\n";
open FFMPEG, "$encode |" or die "Unable to run $encode\n";
$|=0;
while(<FFMPEG>){ print; }
close FFMPEG;
print `touch -c -r "$input" "$output"`;
