#! /usr/bin/env perl

#
#  semaphore.pl
#  PerlConf
#
#  Created by ludomania on 2014/12/5.
#  Copyright (c) 2014 ludomania. All rights reserved.
#

use utf8;
use Cwd;
use strict;
use FindBin;
use threads;
use warnings;
use Time::HiRes ();
use threads::shared;
use Thread::Semaphore;
use Thread::Queue;
use Getopt::Long qw(:config posix_default no_ignore_case gnu_compat);

#use IO::Handle;

my $process='1';
my $start='0.00';
my $end='0.00';
my $interval='0.01';
my $choose='J';
my $add_para=0.00;
my $gethelp=0;
my $SEED=1;
my $argc=scalar @ARGV;
my @argv=@ARGV;
my @Slist=();
my $source_root=$FindBin::Bin;
my $cur_dir=getcwd;
push(@Slist,$SEED);
my $initial_value=1;
my $up_value=1;
my $thd=4;
srand time;

my $ch=chdir $source_root;
$cur_dir=getcwd;

sub show_help {
	my $help_doc= <<EOF;
	
Usage:
	perl $0 [options]
	
Options:
	--help
	--process	[integer]
	--choose	[J or K]
	--start		[float]
	--end		[float]
	--interval	[float]
	--addition  [float]
	--seed(-r)	[integer]
	
EOF
	return $help_doc;
}

GetOptions(
'--process|p=i' => \$process,
'--choose|c=s' =>\$choose,
'--start|s=f' => \$start,
'--end|e=f' => \$end,
'--interval|i=f' => \$interval,
'--addition|a=f' => \$add_para,
'--help|h' => \$gethelp,
'--seed|r=i' => \$SEED
);

my $J=$add_para;
my $K=$add_para;

#if($gethelp==1){
#	die show_help();
#}elsif(($argc!=2*6) && ($argc!=2*7)){
#	print "Argument error. Your arguments are '@argv'.\n";
#	die show_help();
#}
print "Just Start Calc!!\n\n";

my $semaphore = Thread::Semaphore->new($initial_value);
my $data : shared;
my @threads;

print "Create threads\n";
foreach (1 .. $thd){
	my $thread = threads->new(\&my_thread, $_ , $semaphore);
	push(@threads, $thread);
}

print "Join threads \n";

foreach(@threads){
	my ($return) = $_->join;
	print "$return closed\n";
}

# スレッドの処理
sub my_thread {
	my $i = shift;
	my $semaphore = shift;
	for($j=1;j<=100;$j++){
		$semaphore->down($up_value);
		$data++;
		print "Thread $i b($data)\n";
		Time::HiRes::sleep(0.2);
		print "Thread $i a($data)\n";
		my $k=rand(10);
		system("sleep ${k}");
		$semaphore->up($up_value);
		threads->yield();
	}
	return ($i);
}









