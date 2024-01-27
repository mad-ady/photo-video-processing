#!/usr/bin/perl
use strict;
use warnings;
#use Mediainfo;
use Term::ANSIColor;
use Data::Dumper;

die "You must specify a directory!" if (scalar (@ARGV) !=1 || ! -d $ARGV[0]);

opendir(DIR, $ARGV[0]) || die "can't opendir $ARGV[0]: $!";
my @avi = grep { /^(?:IMG_|VID_|MOV_|P[A-Z]?|MVI_)?[0-9_]+\.(?:mp4|mov|3gp|avi)$/i && -f "$ARGV[0]/$_" } readdir(DIR);
closedir DIR;

foreach my $movie (@avi){


    my $infile="$ARGV[0]/".$movie;
    print "Looking at $infile\n";
    $movie=~/(.*)\.(?:mp4|mov|3gp|avi)/i;
    my $base = $1; 
    print "Base name is $base\n";
    my $size720 = -s "$ARGV[0]/$base--720p.mp4" || 0;
    my $size1080 = -s "$ARGV[0]/$base--1080p.mp4" || 0;
    if( $size720 > 0 || $size1080 > 0){
	print "Skipping $movie because it is already converted\n";
	next;
    }

#    exit;
    
    #my $videoInfo = new Mediainfo("filename" => "$infile");
    #use ffmpeg to extract dimensions, framerate    
    my $ffprobe = `ffprobe '$infile' 2>&1 | grep Stream | grep Video`;
    my %videoInfo = (
       height => '480',
       fps => '24',
       bitrate => 1500,
    );
    #Stream #0:0(jpn): Video: h264 (High) (avc1 / 0x31637661), yuvj420p(pc, smpte170m), 1920x1080 [SAR 1:1 DAR 16:9], 24097 kb/s, 29.97 fps, 29.97 tbr, 90k tbn, 59.94 tbc (default)
    if($ffprobe=~/ ([0-9]{3,4})x([0-9]{3,4})(?:\s*\[[^\]]+\])?,.* ([0-9]+) kb\/s,.* ([0-9\.]+) fps/){
	$videoInfo{'height'}=$2;
	$videoInfo{'bitrate'}=$3;
	$videoInfo{'fps'}=$4; 
    }

    my $outfile=$ARGV[0]."/$base--".$videoInfo{height}."p.mp4";
    print colored ("Infile is $infile, outfile is $outfile\n", 'green');
    
    
    print Dumper(\%videoInfo);
    my $bandwidth = 2_500; #by default anything less 720p gets 2.5M
    #my $framerate = $videoInfo->{framerate};
    print colored ("Video height is ".$videoInfo{'height'}."p\n", 'bold white');
    if($videoInfo{height} == 1080){
        $bandwidth = 6_000;
    }
    elsif($videoInfo{height} == 720){
        $bandwidth = 4_000;
        if($videoInfo{bitrate} <= 4_000){
    	    #do not convert - no need
    	    print  colored ("Skipping video. Bitrate is ".$videoInfo{bitrate}."\n", 'bold white');
        }
    }
    else{
        $bandwidth = 1_500;
    }
    my $rate = 24;
    print colored ("Original framerate is ".$videoInfo{fps}, 'red');
    $rate=$videoInfo{fps} if($videoInfo{fps}>24);
    
    print colored ("Video bandwidth will be $bandwidth, $rate fps\n", 'bold white');
    my $encode = "nice ffmpeg -i '$infile' -c:v libx264 -preset slower -crf 22 -x264-params 'nal-hrd=cbr' -b:v ${bandwidth}k -maxrate ${bandwidth}k -bufsize 2M -c:a aac '$outfile'";
    #    my $encode = "nice HandBrakeCLI -i '$infile' -o '$outfile' -t 1 --angle 1 -c 1 -f mp4  --loose-anamorphic  --modulus 2 -e x264 -b $bandwidth -2  -T  -r $rate --cfr -a 1 -E ca_aac --audio-fallback ca_aac --x264-preset=slow  --x264-profile=high --h264-level='4.1' --verbose=1 2>&1";

    print colored ("Encoding...\n", 'green');
    
    print "$encode\n"; 
    open FFMPEG, "$encode |" or die "Unable to run $encode\n";
    $|=0;
    while(<FFMPEG>){ print; }
    close FFMPEG;
    
    #print colored ("cleanup...\n", 'green');
    #unlink "x264_2pass.log";
    #unlink "x264_2pass.log.mbtree";
    #unlink "$ARGV[0]/ffmpeg2pass-0.log";
    
    # videos from Olympus have the wrong timezone. Extract correct time from metadata
    my $dateChanged=0;
    if($base=~/P[0-9]+/){
        my $taggedDate=`mediainfo "$infile" | grep -i "Tagged date" | head -1`;
        if ($taggedDate=~/([0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2})/){
            my $newdate=$1;
            print "Setting date from metadata to $newdate\n";
            print `touch -c -d "$newdate" "$outfile"`;
            $dateChanged=1;
        }
    }
    if(! $dateChanged){
        #also, correct the date on the destination file
        print `touch -c -r "$infile" "$outfile"`;
    }
    sleep 5;
}
