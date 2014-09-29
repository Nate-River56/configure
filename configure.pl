#! /usr/bin/env perl

use utf8;
#use warnings;
use strict;

my $start=0.05;
my $interval=0.05;
my $end=0.95;

my $sum;
my @list=("$start");
my $pr=0;
my @ls;

$sum=$start;
while ($sum <= $end) {
    $sum = $sum + $interval;
    push @list,$sum;
}

$pr = $ARGV[0];
@ls=@ARGV;

#print "$str1"
#print "$pr\n";
#print "@ls\n";

my $inputfile="nebula-$pr.sh";
open(FILE,">$inputfile") or die $!;
my $str1=<<"EOF";
#! /bin/sh

J=0.0000
seed=1

for K in @ls
do
./sol.out \${J} \${K} \${seed}
done

EOF

print FILE $str1;
close(FILE);




