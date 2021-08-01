#!/usr/bin/perl -w
##************************************************************************
#*                                                                      * 
#* Script : nc_manage_jobs_crontab                                      * 
#*                                                                      * 
#* Description : check all nc jobs that runs ,if jobs are stuck and     * 
#*               cpu progress is not used more than refrent input       *
#*               minutes time that,Then user will get notice message    * 
#*               that his job is going to be suspend                    * 
#*               when the script run again it will suspend all previace * 
#*               jobs that notified to the users.                       * 
#*                                                                      * 
#*                                                                      * 
#*                                                                      * 
#* Written by: Duvdevani Amir                                           * 
#* Revision  : V0000001                                                 * 
#* Date      : Thu Mar 14 15:28:38 IST 2019                             * 
#*                                                                      * 
#************************************************************************
#
use lib '/project/infra/utils/common/scripts/environment/packages/';
use strict;
use warnings;
use Dump qw(dump);
use Cwd;
use Cwd 'abs_path';
use Getopt::Long;
use Common;
use File::Basename;
use Term::ANSIColor;
use Date::Manip;
use Time::Piece;
use Time::ParseDate qw(parsedate);
use POSIX qw(strftime);
my $datestring = strftime "%a %b %e %H:%M:%S %Y", localtime;
my $s_user_mail = "amir.duvdevani\@auto-talks.com -c ron.ahronson\@auto-talks.com -c itain\@auto-talks.com";
#my $s_user_mail = "amir.duvdevani\@auto-talks.com";
my $iScrip_version = "V00001";
my $sCommand = basename($0);
chomp($sCommand);
my $cmd = "";
my $s_jobs_type = "";
my $s_interactive_tool = "";
my $i_cpu_progress = 100 ;
my $s_minMinute_process_not_work = "5"; # deafult 5 min CPU with no progress
my $i_minMinute_process_not_work = 5  ;
my $bSecond_run = 0;
my $sScriptName        = $sCommand;
my $sUser_name         =  $ENV{USER}; 
chomp($sUser_name);
my $bHelp              =  0; 
#-------------- create log file ---------
chomp(my $sRunDate = `date`);
$sRunDate =~ s/ //g;
$sRunDate =~ s/:/_/g;
my $sLogFile = "/tmp/$sScriptName\_$sRunDate\_$sUser_name\_$$.log";
open LOGFILE, ">$sLogFile" or die "cannot open file $sLogFile : $!\n";
print LOGFILE "*----------------------------------------*\n";
print LOGFILE "*        $sCommand log file             \n";
print LOGFILE "*----------------------------------------*\n\n";


#----------- Usage --------------------------
#
# Usage : uwa_create
#
sub ffnUsage { 
	if ($sCommand eq "nc_manage_jobs_crontab.pl") {
		print "\n";
		print "Usage: nc_manage_jobs_crontab -jt <jobs_type> \n"; 
		print "                -jt <jobs_type>      #  nc jobs type to suspend if no cpu progress for them.\n";
		print "                                     #  jobs type should be 'regression' or 'interactive' only \n";
		print "                                     #  all these jobs suspend and when the user want , he should resume it manually\n";
		print "                -cpuP <progress>     #  cpu progress number in 0-100% , if the cpu progress value will be less than that\n"; 
		print "                                     #  and job is interactive job ,Then the job will be suspended\n";
		print "                [ -help | -h ]       # print script usage\n"; 
		print "\n";
		print "Description: \n";
		print "\n";
		print "script version : $iScrip_version\n";	
		exit 0;
	}
};# End ffnUsage
#----------------------------------------------------------
#
# Procedure:
#
# Description: run system command
#
#-------------
sub fnRunSysCMD  {

  my @sys_cmd = (@_);
  system("@sys_cmd");
  if ($?) {
	print "Error: '@sys_cmd' command failed, returned $?\n$!";        
        exit 1;
  } else {
	print LOGFILE "Info '@sys_cmd' command succed !\n";        
  }

} # End sub fnRunSysCMD
#----------------------------------------------------------
#
# Procedure: fnPrintMessageOut
#
# Description: write message to output log file
#
#-------------
sub fnPrintMessageOut  {

  my ($message) = (@_);

  if ((!( $message =~ /mkdir/ )) && ( $message =~ /Info:/ ) ) {
        print "$message";
  }
  print LOGFILE "$message";


    if ( $message =~ /Error:/ ) {
        print color("red")."$message";
        print color("red")."\n\n\t* Info: you can find log file '$sLogFile' \n\n";
        print color("reset")."";
        close(LOGFILE);
	exit 1;
  }	
  if ( $message =~ /Warning:/ ) {
        print color("red")."$message";
        #print "\n\n\t* Info: you can find log file '$sLogFile' \n\n";
        print color("reset")."";
        close(LOGFILE);
	exit 1;
  }	

};# End sub fnPrintMessageOut
#----------------------------------------------------------
#
# Procedure: 
#
# Description: 
#
#-------------
sub fnSuspend_UserJobs {

	my $s_users_jobs_list = `ls /tmp/NC_suspend_jobsCpuProgressLow_*`;
	my @l_users_jobs_list = split("\n",$s_users_jobs_list);
	if (scalar(@l_users_jobs_list) > 0 ) {

		my $filename_toNotify = "/tmp/NC_notify_super_user_about_suspned";
		open(my $fh_notify, '>', $filename_toNotify) or die "Could not open file '$filename_toNotify' $!";
		print $fh_notify "\n\nHi RTDA admin\n";
		print $fh_notify "\nThis mail is to notify message about all jobs that have been suspended now \n";
		print $fh_notify "because they Stuck jobs that LastCpuProgress is bigger than '$i_minMinute_process_not_work' minutes .\n\n\n";

		printf $fh_notify "%-15s %-15s %-15s %-25s %-15s \n","job_id","user_name","job_type","job_class","stuck_job(minute)";
		printf $fh_notify "%-15s %-15s %-15s %-25s %-15s \n","_______ " ,"_________", "_________","__________","_____________";


		foreach my $one_user (@l_users_jobs_list) {
			my $s_current_user = $one_user;
			$s_current_user =~ s/\/tmp\/NC_suspend_jobsCpuProgressLow_//;
			#print "\n----suspend-------$s_current_user------------\n";
			open(my $fh, '<:encoding(UTF-8)', $one_user)
			  or die "Could not open file '$one_user' $!";
			 
			while (my $row = <$fh>) {
			  chomp $row;
			  my @l_row = split(" ",$row);
			  printf $fh_notify "%-15s %-15s %-15s %-25s %-15s \n",$l_row[0],$l_row[1],$l_row[2],$l_row[3],$l_row[4];

			  # ---------------------------------					
			  # **** suspend nc jobs ************
			  # -------------
			  #system("nc suspend $l_row[0]");
			  #system("nc preempt \-v \-v \-v \-manualresume \-method SIGTSTP\+LMREMOVE $l_row[0]");
			  #system("nc preempt \-v \-v \-v \-manualresume \-method SIGTSTP\+SUSPEND $l_row[0]");
			  system("nc preempt \-v \-v \-v \-manualresume \-method SIGTSTP $l_row[0]");
			  # ---------------------------------					
			  print "Info: job_ib '$l_row[0]' have been suspended now .\n";
			  print "      $row\n";
			  print LOGFILE "Info: job_ib '$l_row[0]' have been suspended now .\n";
			  print LOGFILE "      $row\n";

			  #print "---$row\n";
			}
		}
		close($fh_notify);
		my $cmd = "echo \| mutt -s \"NC RTDA - list of jobs that suspended now \" -a /tmp/NC_notify_super_user_about_suspned -c $s_user_mail -i /tmp/NC_notify_super_user_about_suspned";
                system("$cmd");

		
	}

	# remove all temp files
	`rm -fr /tmp/NC_notify_super_user_about_suspned`;

};# End sub fnSuspend_UserJobs 
#----------------------------------------------------------
#
# Procedure: 
#
# Description: 
#
#-------------
sub fnSendMailNotificationAboutSuspend {


	my $s_users_jobs_list = "";
	my $exit_status = system("ls /tmp/NCjobsCpuProgressLow_* 2>&1");

	if ($exit_status != 0) {  
		print "\nInfo: no jobs found to suspend ....\n\n";  
	} else {  
		print "\nInfo: found the following owner's jobs that thier jobs should be suspended :\n"; 
		$s_users_jobs_list = `ls /tmp/NCjobsCpuProgressLow_*`;
	}
	my @l_users_jobs_list = split("\n",$s_users_jobs_list);
	if (scalar(@l_users_jobs_list) > 0 ) {
		printf LOGFILE "Notify users about jobs that should be suspend :\n\n";
		foreach my $one_user (@l_users_jobs_list) {
			my $s_current_user = $one_user;
			$s_current_user =~ s/\/tmp\/NCjobsCpuProgressLow_//;

			my $filename_toNotify = "/tmp/NC_notify_user_before_suspned_$s_current_user";
			open(my $fh_notify, '>', $filename_toNotify) or die "Could not open file '$filename_toNotify' $!";
			print $fh_notify "\n\nHi $s_current_user\n";
			print $fh_notify "\nThis mail is to notify message from NC admin ,that your jobs in the list below are \n";
			print $fh_notify "Stuck jobs that LastCpuProgress is bigger than '$i_minMinute_process_not_work' minutes .\n";
			print $fh_notify "so we are going to suspend these jobs in about 5 minutes .\n";
			print $fh_notify "\n\nTo resume these jobs you should run the following command:\n";
			print $fh_notify "\n\t>nc resume <Job_id> \n\n";
			print $fh_notify "**Note: you can find the jobs id in the list below \n\n\n";

			printf $fh_notify "%-15s %-15s %-15s %-25s %-15s \n","job_id","user_name","job_type","job_class","stuck_job(minute)";
			printf $fh_notify "%-15s %-15s %-15s %-25s %-15s \n","_______ " ,"_________", "_________","__________","_____________";


			#print "\n-----notification------$s_current_user------------\n";
			open(my $fh, '<:encoding(UTF-8)', $one_user)
			  or die "Could not open file '$one_user' $!";
			 
			while (my $row = <$fh>) {
			  chomp $row;
			  #print "---$row\n";

			  my @l_row = split(" ",$row);
			  #print $fh_notify "---$row\n";
			  printf $fh_notify "%-15s %-15s %-15s %-25s %-15s \n",$l_row[0],$l_row[1],$l_row[2],$l_row[3],$l_row[4];
			  printf LOGFILE    "%-15s %-15s %-15s %-25s %-15s \n",$l_row[0],$l_row[1],$l_row[2],$l_row[3],$l_row[4];
  				
			}
			print "Info: notify user '$s_current_user' with email /tmp/NC_notify_user_before_suspned_$s_current_user \n";
			print $fh_notify "\n\nRegards,\n";
			print $fh_notify "RTDA admin\n";
			print $fh_notify "(AmirD Tel:0549755033)\n\n";
			close $fh_notify;
			#--------------------------
			# get user email address
			my $s_curr_user_email = `getent passwd $s_current_user \| cut -d\'\:\' -f5 \| sed \'s/ /./\' \| sed \'s/\$/\@auto-talks.com/\'`;
			chomp($s_curr_user_email);
			my $s_curr_user_email_lc = lc $s_curr_user_email;	
			#my $s_curr_user_email_lc =  $s_user_mail;

			my $cmd = "echo \| mutt -s \"NC RTDA Notify message - your stuck jobs will going to be suspended in about 5 min\" -a /tmp/NC_notify_user_before_suspned_$s_current_user -c $s_user_mail -c $s_curr_user_email_lc -i /tmp/NC_notify_user_before_suspned_$s_current_user";
			system("$cmd");
		}
	}
	# remove all temp files
	`rm -fr /tmp/NC_notify_user_before_suspned_*`;

};# End sub fnSendMailNotificationAboutSuspend 
#----------------------------------------------------------
#
# Procedure: 
#
# Description: 
#
#-------------
sub fnGetAllJobsWithThatType {

	my $s_all_nc_runing_jobs = `nc list -a -r`;
	my @l_all_nc_runing_jobs = split("\n",$s_all_nc_runing_jobs);
	foreach my $s_oneJob_data (@l_all_nc_runing_jobs) {
		my @l_oneJob_data = split(" ",$s_oneJob_data);
		my $i_jobID   = $l_oneJob_data[0];
		my $i_userOWN = $l_oneJob_data[3];
		#print "-- job_id = '$i_jobID'\n";
		#print "-- user   = '$i_userOWN'\n";
		my $s_curr_job_tool  = `nc getfield tool $i_jobID`; 
		my $s_curr_job_inter = `nc getfield ISINTERACTIVE  $i_jobID`; 
		my $s_curr_job_class = `nc getfield JOBCLASS $i_jobID`; 
		my $s_curr_job_cpuprogress = `nc getfield CPUPROGRESS $i_jobID`; 
		my $s_curr_job_lastcpuprogress = `nc getfield LASTCPUPROGRESS $i_jobID`; 
		my $s_curr_job_lastcpuprogressPP = `nc getfield LASTCPUPROGRESSPP $i_jobID`; 
		chomp($s_curr_job_lastcpuprogressPP);
		chomp($s_curr_job_tool);
		chomp($s_curr_job_class);
		chomp($s_curr_job_lastcpuprogress);
		chomp($s_curr_job_inter);
		chomp($s_curr_job_cpuprogress);
		next if (($s_jobs_type eq "regression") && (!($s_curr_job_class =~ /_REG/)));
		next if (($s_jobs_type eq "interactive") && ($s_curr_job_class =~ /_REG/));
		next if (($s_jobs_type eq "interactive") && ($s_interactive_tool eq ""));
		next if (($s_jobs_type eq "interactive") && ($s_interactive_tool ne "$s_curr_job_tool")); # ineractive only if tool name is equal to input s_interactive_tool
		next if (($s_jobs_type eq "interactive") && ($s_curr_job_tool eq "irun") && ($s_curr_job_inter eq "NO")); # ineractive only if tool name is equal to input s_interactive_tool

		if (!($s_curr_job_lastcpuprogressPP =~ /m/) && !($s_curr_job_lastcpuprogressPP =~ /h/)) {
			$s_curr_job_lastcpuprogressPP = 0;
		} else {
			if ($s_curr_job_lastcpuprogressPP =~ /m/) {
				my @l_curr_job_lastcpuprogressPP = split("m",$s_curr_job_lastcpuprogressPP);
				$s_curr_job_lastcpuprogressPP = $l_curr_job_lastcpuprogressPP[0];
			}
			if ($s_curr_job_lastcpuprogressPP =~ /h/) {
				my @l_curr_job_lastcpuprogressPP = split("h",$s_curr_job_lastcpuprogressPP);
				$s_curr_job_lastcpuprogressPP = $l_curr_job_lastcpuprogressPP[0] * 60;
			}
		}

		my $s_last_cpu_progress   = $s_curr_job_lastcpuprogress;
		my $s_curr_time = time();
		print "-- s_last_cpu_progress   = '$s_last_cpu_progress'\n";
		print "-- s_curr_time = '$s_curr_time'\n";
		my $s_diff =  int(($s_curr_time - $s_last_cpu_progress) / (60)); # diff min
		$s_diff =  $s_curr_job_lastcpuprogressPP;
		print "-- job_id           = '$i_jobID'\n";
		print "-- user             = '$i_userOWN'\n";
		print "-- s_jobs_type      = '$s_jobs_type'\n";
		print "-- s_curr_job_class = '$s_curr_job_class'\n";
		print "-----------------\n";
		#---------------------------------------------
		if (($s_jobs_type eq "interactive") && ($s_curr_job_tool eq "irun") && ($s_curr_job_inter ne "NO")) {
			print "-- job is interactive\n";
			print "-- s_curr_job_cpuprogress      = '$s_curr_job_cpuprogress'\n";
			print "-- i_cpu_progress              = '$i_cpu_progress'\n";
			print "-- s_diff                      = '$s_diff'\n";
			print "-- i_minMinute_process_not_work= '$i_minMinute_process_not_work'\n";
			if ($s_curr_job_cpuprogress < $i_cpu_progress) {
				$s_diff =  $i_minMinute_process_not_work + 1; 
				print "-- NEW s_diff                  = '$s_diff'\n";
			}
		}
		#---------------------------------------------
		if ($bSecond_run) {;# second run to resume after notify the user 
			if ($s_diff > $i_minMinute_process_not_work ) {
				#print "-- job_id           = '$i_jobID'\n";
				#print "-- user             = '$i_userOWN'\n";
				#print "-- s_jobs_type      = '$s_jobs_type'\n";
				#print "-- s_curr_job_class = '$s_curr_job_class'\n";
				$s_diff = "$s_diff" . "m00s";
				#print "---Stuck job: LastCpuProgress '$s_diff' ago '\n";
				#print "-----------------\n";
				if (-f "/tmp/NCjobsCpuProgressLow_$i_userOWN") {
					my $s_jobId_in = `grep \"\^$i_jobID\" /tmp/NCjobsCpuProgressLow_$i_userOWN`;
					chomp($s_jobId_in);
					if ($s_jobId_in ne "" ) {;# found job to suspend
						if (-f 	"/tmp/NC_suspend_jobsCpuProgressLow_$i_userOWN") {
							`echo $s_jobId_in >> /tmp/NC_suspend_jobsCpuProgressLow_$i_userOWN`;
						} else {
							`echo $s_jobId_in > /tmp/NC_suspend_jobsCpuProgressLow_$i_userOWN`;
						}
					}
					
				} 
			}
		} else {;# first run only notify the user
			if ($s_diff > $i_minMinute_process_not_work ) {
				#print "-- job_id           = '$i_jobID'\n";
				#print "-- user             = '$i_userOWN'\n";
				#print "-- s_jobs_type      = '$s_jobs_type'\n";
				#print "-- s_curr_job_class = '$s_curr_job_class'\n";
				$s_diff = "$s_diff" . "m00s";
				#print "---Stuck job: LastCpuProgress '$s_diff' ago\n";
				#print "-----------------\n";
				if (-f "/tmp/NCjobsCpuProgressLow_$i_userOWN") {
					`echo $i_jobID $i_userOWN $s_jobs_type $s_curr_job_class $s_diff >> /tmp/NCjobsCpuProgressLow_$i_userOWN`;	
				} else {
					`echo $i_jobID $i_userOWN $s_jobs_type $s_curr_job_class $s_diff > /tmp/NCjobsCpuProgressLow_$i_userOWN`;	
				}
			}
		}

	}
	if ($bSecond_run) {;# second run delete the users temp file 
		`rm -fr /tmp/NCjobsCpuProgressLow_*`;
		fnSuspend_UserJobs();
		# clean temp files
		`rm -fr /tmp/NC_suspend_jobsCpuProgressLow_*`;
	} else {;# send notification to user tha we are 
                 # going to suspend his jobs in about $i_minMinute_process_not_work min
		fnSendMailNotificationAboutSuspend();
	}

};# End sub fnGetAllJobsWithThatType 
#---------------------------------------------------------------------------
#
#
#     ---------- MAIN   'nc_manage_jobs_crontab' -----------------------
#
#
#---------------------------------------------------------------------------
#
        if (not(&GetOptions('jt=s'    => \$s_jobs_type   ,
			    'it=s'    => \$s_interactive_tool  ,
			    'cpuP=i'  => \$i_cpu_progress  ,
			    'sec!'    => \$bSecond_run  ,
			    'min=s'   => \$s_minMinute_process_not_work   ,
                            'help!'   => \$bHelp     )) || $bHelp ) {
          &ffnUsage;
        }
        #---------------------------
        # check args validation 
        #-----
        #if ($#ARGV==-1) { &ffnUsage; } 
        if ($bHelp) { &ffnUsage; }	
        if (($s_jobs_type ne "regression") && ($s_jobs_type ne "interactive")) { &ffnUsage; }	
	$i_minMinute_process_not_work = int($s_minMinute_process_not_work);

	fnGetAllJobsWithThatType();

	#$cmd = "git reset HEAD $sBlockCluster_name";
	#fnRunSysCMD($cmd); 
	print LOGFILE "\nInfo: you are running on jobs type '$s_jobs_type' \n";
	print "\n\nInfo: you are running on jobs type '$s_jobs_type' \n";
	if ($bSecond_run == 0 ) {
		print LOGFILE "      This is the first run only notify the user befure suspend his jobs ...\n";

		print "      This is the first run only notify the user befure suspend his jobs ...\n";
	} else {
		print LOGFILE "      This is the second run suspend user's jobs ...\n";
		print "      This is the second run suspend user's jobs ...\n";
	}
	print LOGFILE  "\n\n--------------------------------------------------------------\n";
	print LOGFILE  "  nc_manage_jobs_crontab finished successfully !!!\n";
	print LOGFILE  "--------------------------------------------------------------\n";
	print "\n\n--------------------------------------------------------------\n";
	print "  nc_manage_jobs_crontab finished successfully !!!\n";
	print "--------------------------------------------------------------\n";

        close(LOGFILE);
        print "\n\n\t* Info: you can find log file '$sLogFile' \n\n";
        exit 0;

#-------------------------------------------------------
#
#
#         --------   END  nc_manage_jobs_crontab.pl -------------     
#
#
#-------------------------------------------------------

