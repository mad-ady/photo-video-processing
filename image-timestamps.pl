#!/usr/bin/perl
use strict;
use warnings;
use File::Basename;
use DateTime;
use File::Basename;
use Term::ANSIColor;

my $debug=0;

my $dirname = dirname(__FILE__);
#print "Running from $dirname\n";
die "You must specify a directory!" if (scalar (@ARGV) !=1 || ! -d $ARGV[0]);
print colored("Running on $ARGV[0]\n", 'green');
# step 1 - convert all MVIMGs to IMGs
print "Converting all MVIMGs to IMGs\n";
open(my $pipe, '-|', "$dirname/extract-mvimg.sh \"$ARGV[0]/\"MVIMG*");
while(<$pipe>){
    print;
}
close $pipe;

# step 2 - downscale all 8k photos to 4k (just because they're big and noisy anyway)
print "Downsampling all 8K IMGs to 4k\n";
open($pipe, '-|', "$dirname/downscale-pictures-to-4k.sh \"$ARGV[0]/\"*.jpg");
while(<$pipe>){
    print;
}
close $pipe;


opendir(DIR, $ARGV[0]) || die "can't opendir $ARGV[0]: $!";
my @avi = grep { /\.jpg|.*.mp4/i && -f "$ARGV[0]/$_" } readdir(DIR);
closedir DIR;

my $lastDate; #to set to the directory

foreach my $movie (@avi){
    my $infile = "$ARGV[0]/$movie";
    my ($name, $path, $suffix) = fileparse($infile, (".jpg", ".JPG", ".mp4"));
    if($name=~/^P([A-Z0-9]+)|^IMG_[0-9]+\.|^DSC/){
        print colored("Matched Panasonic\n", "yellow") if ($debug);
        #panasonic file
        my $createDate = `exiftool -CreateDate "$infile"`;
        $createDate=~/([0-9]{4}):([0-9]{2}):([0-9]{2}) ([0-9]{2}):([0-9]{2}):([0-9]{2})/;
        my $year = $1;
        my $month = $2;
        my $day = $3;
        my $hour = $4;
        my $min = $5;
        my $sec = $6;
        if(defined $sec && $month > 0){
            
            #print "$name: Set date to $year-$month-$day $hour:$min:$sec\n";
            printf ("%30s:\tSet date to $year-$month-$day $hour:$min:$sec\n", $name);
            print `touch -c -t '${year}${month}${day}${hour}${min}.${sec}' '$infile'`;
            
            my $dt = DateTime->new( year=> $year, month => $month, day => $day, hour => $hour, minute => $min, second => $sec);
            if(defined $lastDate){
                #select the older date
                if($dt >= $lastDate){
                    $lastDate = $dt;
                }
            }
            else{
                $lastDate = $dt;
            }
        }
        else{
            print "ERROR: $name: unable to extract date from $name\n";
        }
    }
#    elsif($name=~/DSC/i){
#        #sony file
#        print "ERROR: $name: sony files not implemented\n";
#    }
    elsif($name=~/^(?:IMG|VID)-([0-9]{4})([0-9]{2})([0-9]{2})-WA/){
        print colored("Matched WhatsApp\n", "yellow") if ($debug);
        #WhatsApp image/video
        my $year = $1;
        my $month = $2;
        my $day = $3;
        my $hour = "00";
        my $min = "00";
        my $sec = "00";
        #set hh:mm:ss to 00:00:00, since we don't have them
        printf ("%30s:\tSet date to $year-$month-$day $hour:$min:$sec\n", $name);
        my $dt = DateTime->new( year=> $year, month => $month, day => $day, hour => $hour, minute => $min, second => $sec);
        if(defined $lastDate){
            #select the older date
            if($dt >= $lastDate){
                $lastDate = $dt;
            }
        }
        else{
            $lastDate = $dt;
        }
        print `touch -c -t '${year}${month}${day}${hour}${min}.${sec}' '$infile'`;
    
    }
    elsif($name=~/^(?:IMG_|VID_)?([0-9]{4})([0-9]{2})([0-9]{2})_?([0-9]{2})([0-9]{2})([0-9]{2})(?:[0-9]{3})?(?:[_\(][0-9]+[\)]?)?(?:_[0-9]+_[0-9]+)?(?:_-[0-9]+)?(?:--.[0-9]*p)?$/){
        #samsung, nexus, xiaomi, motorola or Insta360 converted file
        print colored("Matched Samsung, Nexus, Xiaomi, Motorola or Insta360\n", "yellow") if ($debug);
        
        my $year = $1;
        my $month = $2;
        my $day = $3;
        my $hour = $4;
        my $min = $5;
        my $sec = $6;
        
        #print "$name: Set date to $year-$month-$day $hour:$min:$sec\n";
        printf ("%30s:\tSet date to $year-$month-$day $hour:$min:$sec\n", $name);
        my $dt = DateTime->new( year=> $year, month => $month, day => $day, hour => $hour, minute => $min, second => $sec);
        if(defined $lastDate){
            #select the older date
            if($dt >= $lastDate){
                $lastDate = $dt;
            }
        }
        else{
            $lastDate = $dt;
        }
        
        
        #clear the exif user comment if needed
        my $comment = `exiftool -b -UserComment "$infile"`;
        if($comment=~/[^[:print:]]/ || $comment=~/---/ || $comment=~/ASCII/ || $comment=~/User comments/){
            #must be garbage - reset it
            $comment=~s/[^[:print:]]|\.//g;
            printf ("%30s: $comment\n", $name);
            print `exiftool -overwrite_original_in_place -P -UserComment="" "$infile"`;
        }
        
        print `touch -c -t '${year}${month}${day}${hour}${min}.${sec}' '$infile'`;
    }
    else{
		# for any other file, try to extract the date from EXIF metadata

		my $createDate = `exiftool -CreateDate "$infile"`;
        $createDate=~/([0-9]{4}):([0-9]{2}):([0-9]{2}) ([0-9]{2}):([0-9]{2}):([0-9]{2})/;
        my $year = $1;
        my $month = $2;
        my $day = $3;
        my $hour = $4;
        my $min = $5;
        my $sec = $6;
        if(defined $sec && $month > 0 && $infile=~/.*jpg$/){
            print colored("Matched else, generic picture\n", "yellow") if ($debug);
			#try to set the exif CreateDate for the file, even if it's not standard.
			printf ("%30s:\tSet date to $year-$month-$day $hour:$min:$sec\n", $name);
            print `touch -c -t '${year}${month}${day}${hour}${min}.${sec}' '$infile'`;

            my $dt = DateTime->new( year=> $year, month => $month, day => $day, hour => $hour, minute => $min, second => $sec);
            if(defined $lastDate){
                #select the older date
                if($dt >= $lastDate){
                    $lastDate = $dt;
                }
            }
            else{
                $lastDate = $dt;
            }
        }
        elsif($name=~/([0-9]{4})([0-9]{2})([0-9]{2})_([0-9]{2})([0-9]{2})([0-9]{2})(?:_[0-9]+_[0-9]+)?--/){
            print colored("Matched generic, non-exif\n", "yellow") if ($debug);

            $year = $1;
            $month = $2;
            $day = $3;
            $hour = $4;
            $min = $5;
            $sec = $6;
            if(defined $sec && $month > 0){
			    printf ("%30s:\tSet date to $year-$month-$day $hour:$min:$sec\n", $name);
                print `touch -c -t '${year}${month}${day}${hour}${min}.${sec}' '$infile'`;

                my $dt = DateTime->new( year=> $year, month => $month, day => $day, hour => $hour, minute => $min, second => $sec);
                if(defined $lastDate){
                    #select the older date
                    if($dt >= $lastDate){
                        $lastDate = $dt;
                    }
                }
                else{
                    $lastDate = $dt;
                }

            }
            else{
                print "ERROR: $name: unable to parse a valid date from $name\n";

            }

            
        }
        else{
            print "ERROR: $name: unable to extract date from $name\n";
        }

		

        #print colored("ERROR: $name: image format not implemented\n", 'red');
    }
}
if(defined $lastDate){
    print colored("Set parent directory $ARGV[0] date to ". $lastDate->strftime("%Y-%m-%d %H:%M:%S")."\n", 'green');
    my $datestring = $lastDate->strftime("%Y%m%d%H%M.%S");
    print `touch -c -t '$datestring' '$ARGV[0]'`;
}
