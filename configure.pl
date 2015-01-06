#! /usr/bin/env perl

#
#  configure.pl
#  PerlConf
#
#  Created by ludomania on 2014/11/28.
#  Copyright (c) 2014 ludomania. All rights reserved.
#

use utf8;
use warnings;
use strict;
use Parallel::ForkManager;
use File::chdir;
use FindBin;
use Cwd;
use Getopt::Long qw(:config posix_default no_ignore_case gnu_compat);
use Switch;
use Time::HiRes ();
use feature qw/ say /;
use IPC::Semaphore;
use IPC::SysV qw/ IPC_PRIVATE IPC_CREAT S_IWUSR SEM_UNDO /;
#use IO::Handle;
#use Acme::Comment type=>'C++', own_line => 0, one_line => 1;

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
my $hname='';
push(@Slist,$SEED);

$hname=$ENV{'HOSTNAME'};

$CWD=$source_root;

chdir '..';

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

if($gethelp==1){
	die show_help();
}elsif(($argc!=2*6) && ($argc!=2*7)){
	print "Argument error. Your arguments are '@argv'.\n";
	die show_help();
}

print "\n\n";
system("ttytter -ssl -status='Just Start Calc,${hname}.' 1>/dev/null 2>&1");

my $pm = new Parallel::ForkManager($process);

my $sem = IPC::Semaphore->new(IPC_PRIVATE, 1, IPC_CREAT | S_IWUSR); # 大きさ 1 のセマフォをつくる


$pm->run_on_start(
sub {
	my ($pid, $exit_code, $ident, $exit_signal, $core_dump, $data)=@_;
	print "** started, pid: $pid, ";
	my $data_str=localtime;
	print $data_str ."\n";
}
);

$pm->run_on_finish(
sub {
	my ($pid, $exit_code, $ident, $exit_signal, $core_dump, $data) = @_;
	print "** just got out ".
	"with PID $pid and exit code: $exit_code, ";
	my $data_str=localtime;
	print $data_str ."\n";
}
);

#sub test{
#	my @_=$i;
#	my $k=10*rand($i);
#	system("sleep ${k}");
#	Time::HiRes::sleep(0.2);
#}

foreach my $seed(@Slist){
	for(my $i=$start;$i<=$end;$i=sprintf("%.2f",$i+$interval)){
		if (my $pid=$pm->start) {
			Time::HiRes::sleep(0.2);  # fork に時間がかかることを想定
			next;
		}
		$sem->setval($i, $process);# i番目のセマフォに 0 をセット (誰もロックを取得できない)
		switch($choose){
			case 'J' {$J=$i}
			case 'K' {$K=$i}
			default{
				print "Invalid \$choose.";
				die show_help();
			}
		}
		printf("exec sol.out J${J}K${K}s${seed},${hname}.\n");
		system("ttytter -ssl -status='exec sol.out J${J}K${K}s${seed},${hname}.' 1>/dev/null 2>&1");
		system("../sol.out $J $K $seed 1>sol-J${J}K${K}s${seed}.dat 2>sol-J${J}K${K}s${seed}err.dat");
		printf("terminated sol.out J${J}K${K}s${seed},${hname}.\n");
		system("ttytter -ssl -status='terminated sol.out J${J}K${K}s${seed},${hname}.' 1>/dev/null 2>&1");
		
		#安全のため上部分はコメントアウトしてある。なので実際に実行時にはコメントアウトを取り除く。
		$pm->finish;
		$sem->op($i, -1, SEM_UNDO); # i番目からロックを獲得できるまで WAIT する
	}
}

print "waiting child process..,${hname}.\n";
system("ttytter -ssl -status='waiting child process..,${hname}.' 1>/dev/null 2>&1");

$sem->setval($end, $process);# 最終番目のセマフォにプロセス分の値をセット=> すべての子プロセスがロック取得可能に
$pm->wait_all_children;

print "All tasks have already ended,${hname}.\n";
system("ttytter -ssl -status='All tasks have already ended,${hname}.' 1>/dev/null 2>&1");

$sem->remove; # セマフォ削除

