#!/usr/bin/perl -w
##************************************************************************
#* Description                                                          * 
#*                                                                      * 
#* Revision                                                             * 
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
my $iScrip_version = "V00001";
my $sCommand = basename($0);
chomp($sCommand);
my $cmd = "";
my $sScriptName        = $sCommand;
my $sUser_name         =  $ENV{USER}; 
my $bHelp              =  0; 
my $sWorkArea_name     =  ""; 
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
# Usage : uwa_dep_rep
#
sub ffnUsage { 
	if ($sCommand eq "uwa_dep_rep") {
		print "\n";
		print "Usage: uwa_dep_rep -wa <work_area_name> -t <top_name [-r <revision_number>] [-pre <depends.list>]\n"; 
		print "                       -wa <work_area_name>   # work area name that should be created under local directory\n";
		print "						     # that should contains project's directories structure\n";
		print "                       -t <top_name>          # create a work area for this current top and his hierarchy sub clusters\n";
		print "                                              # if this top is not exist under git repository ,the script create Skeleton\n";
		print "                                              # of mandatory directories for this top under user work area \n";
		print "                       -c <cluster_name>      # create a work area for this current cluster and his hierarchy sub blocks\n";
		print "                                              # if this cluster is not exist under git repository ,the script create Skeleton\n";
		print "                                              # of mandatory directories for this cluster under user work area \n";
		print "                       -b <block_name>        # create a work area for this current block and his hierarchy sub blocks\n";
		print "                                              # for block level option the work area created directly from git repository\n";
		print "                                              # checkout block and his sub blocks latest vesrion from git to user work area.\n";
		print "                       [-r <revision_number>] # the block/cluster tag revision number , default is latest version\n";
		print "                       [-pre <depends.list>]  # full path for depends.list file ,prepare pre-release user work area \n";
		print "                                              # following block depends.lis file\n"; 
		print "                       [ -help | -h ]         # print script usage\n"; 
		print "\n";
		print "Description: create user work area with name '-wa <work_area_name>' for project \$PROJCT_NAME\n";
		print "	     get top block follow the revision if existing in git repository under local user work area \n";
		print "	     if version is latest (default) we set the path to look on last release on global \$$ENV{PROJECT_NAME}\_TOP_ROOT work area\n";  
		print "	     if version is not latest (default) we set the path to look on release verison on global \$$ENV{PROJECT_NAME}\_TOP_ROOT work area\n";
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
#---------------------------------------------------------------------------
#
#
#     ---------- MAIN   'create_uwa' -----------------------
#
#
#---------------------------------------------------------------------------
#
        if (not(&GetOptions('wa=s'     => \$sWorkArea_name   ,
                            'help!'    => \$bHelp     )) || $bHelp ) {
          &ffnUsage;
        }
        #---------------------------
        # check args validation 
        #-----
        #if ($#ARGV==-1) { &ffnUsage; } 
	if (!(defined $ENV{PROJECT_NAME}) || !(defined $ENV{PROJECT_HOME}) || !(defined $ENV{GIT_PROJECT_ROOT}) ) {
		print "\nWarning: you must run 'setup_proj' command before \!\!\!\n\n";	
		exit 0;
	}
        if ($bHelp) { &ffnUsage; }	
        if ($sWorkArea_name eq "") { &ffnUsage; }	
	my $s_proj_rev = basename($ENV{PROJECT_HOME});	
	my $s_work_area_fullpath = "/space/users/$ENV{USER}/$ENV{PROJECT_NAME}\_$s_proj_rev/$sWorkArea_name";
	if (!(-d "$s_work_area_fullpath")) {
		print "\nWarning: no such folder '$s_work_area_fullpath' \!\!\! \n\n";
		exit 0;
	}
	print "Info:depends report for $s_work_area_fullpath' \n";
#/space/users/amird/craton3_rev_a/
	print LOGFILE  "\n\n--------------------------------------------------------------\n";
	print LOGFILE  "  uwa_dep_rep finished successfully !!!\n";
	print LOGFILE  "  work area folder created under '$s_work_area_fullpath'. \n";
	print LOGFILE  "--------------------------------------------------------------\n";
	print "\n\n--------------------------------------------------------------\n";
	print "  uwa_dep_rep finished successfully !!!\n";
	print "  work area folder created under '$s_work_area_fullpath'. \n";
	print "--------------------------------------------------------------\n";

        close(LOGFILE);
        print "\n\n\t* Info: you can find log file '$sLogFile' \n\n";
        exit 0;

#-------------------------------------------------------
#
#
#         --------   END  uwa_dep_rep.pl -------------     
#
#
#---------------------------------------------------

