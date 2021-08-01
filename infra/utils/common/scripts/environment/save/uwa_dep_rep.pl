#!/usr/bin/perl -w
##************************************************************************
#* Description                                                          * 
#*                                                                      * 
#* Revision                                                             * 
#************************************************************************
#
use lib '/project/infra/utils/common/test_env/scripts/environment/packages/';
use strict;
use warnings;
use Dump qw(dump);
use Carp;
use Cwd;
use Cwd 'abs_path';
use Getopt::Long;
use Common;
use File::Basename;
use Term::ANSIColor;
my $iScrip_version = "V00004";
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
		print "Usage: uwa_dep_rep [-help|-h]\n"; 
		print "\n";
		print "Description: generate tags version report for each block that checkedout under current work area ' \n";
		print "             this script must be run directly under user project work area: \n";
		print "             \$UWA_PROJECT_ROOT/\$UWA_NAME \!\n";
		print "\n";
		print "script version : $iScrip_version\n";	
		exit 0;
	}
exit 0;
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
# Procedure: 
#
# Description: 
#
#-------------
sub source {

    my $file = shift;
    open my $fh, "<", $file
        or croak "could not open $file: $!";
    while (my $row = <$fh>) {
        chomp $row;
        next if($row =~ /^\/\//);		
        next if($row =~ /^\#/);		
        #next unless my ($var, $value) = /\s*(\w+)=([^#]+)/;
        my @l_row = split(" ",$row);
        next unless my ($setenv ,$var, $value) = (@l_row);
        $ENV{$var} = $value;
    }
}
#---------------------------------------------------------------------------
#
#
#     ---------- MAIN   'uwa_dep_rep' -----------------------
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
        if ($bHelp) { &ffnUsage; }	
	print "-----------------\n";
	print "  uwa_blocks_rep \n";
	print "-----------------\n";
	print LOGFILE  "-----------------\n";
	print LOGFILE  "  uwa_blocks_rep \n";
	print LOGFILE  "-----------------\n";

	if (!(defined $ENV{PROJECT_NAME}) || !(defined $ENV{PROJECT_HOME}) || !(defined $ENV{GIT_PROJECT_ROOT}) || !(defined $ENV{UWA_PROJECT_ROOT}) || !(defined $ENV{UWA_SPACE_ROOT}) ) {
		print "\nWarning: you must run 'setup_proj' command before \!\!\!\n\n";	
		exit 0;
	}

	my $s_pwd_dir = `pwd`;
	chomp($s_pwd_dir);	
	if ($s_pwd_dir =~ /$ENV{UWA_PROJECT_ROOT}/) { 
	     $s_pwd_dir =~ s/$ENV{UWA_PROJECT_ROOT}//;
	     $s_pwd_dir =~ s/^\/+//;
	     my @l_tmp_dir = split("/",$s_pwd_dir);
	     if (scalar(@l_tmp_dir) < 2 ) {
			print "\nWarning: you must run this script only under \$UWA_PROJECT_ROOT/\$UWA_NAME folder \!\n\n"; 
			close(LOGFILE);
			exit 0;	
             } else {
		if (-f "$ENV{UWA_SPACE_ROOT}/$l_tmp_dir[0]/usr_setup_path") {
			source "$ENV{UWA_SPACE_ROOT}/$l_tmp_dir[0]/usr_setup_path";
			$sWorkArea_name = $ENV{UWA_NAME};
		} else {
			print "\nWarning: missing file '$ENV{UWA_SPACE_ROOT}/$l_tmp_dir[0]/usr_setup_path' \!\!\! \n";
			close(LOGFILE);
			exit 0;	
		}
	     }
	} else {
		print "\nWarning: you must run this script only under \$UWA_PROJECT_ROOT/\$UWA_NAME folder \!\n\n"; 
		close(LOGFILE);
		exit 0;	
	}

        if ($sWorkArea_name eq "") { &ffnUsage; }	
	my $s_proj_rev = basename($ENV{PROJECT_HOME});	
	my $s_work_area_fullpath = "/space/users/$ENV{USER}/$ENV{PROJECT_NAME}\_$s_proj_rev/$sWorkArea_name/project";
	if (!(-d "$s_work_area_fullpath")) {
		print "\nWarning: no such folder '$s_work_area_fullpath' \!\!\! \n\n";
		exit 0;
	}
	print "Info:depends report for $s_work_area_fullpath' \n";

	my $s_curr_pwd = `pwd`;
	chomp($s_curr_pwd);
	chdir($s_work_area_fullpath);

	my $s_all_dependList_inWA = `ls */depends.list`;
	my @l_all_dependList_inWA = split("\n",$s_all_dependList_inWA);
	#---------------------------------
	# take a look on blocks that jave a reference 
	print "\n#####################################\n";
	print "#  Local Block's version report     # \n";
	print "#####################################\n";
	print LOGFILE "\n#####################################\n";
	print LOGFILE "#  Local Block's version report     # \n";
	print LOGFILE "#####################################\n";
	print STDOUT color 'bold red ';
	printf "%-1s %-20s %-1s %-40s %-1s\n","+","----------------------","+","------------------------------------------","+"; 
	printf "%-3s %-20s %-3s %-40s %-1s\n","|","block_name","|","block_version","|"; 
	printf "%-1s %-20s %-1s %-40s %-1s\n","+","----------------------","+","------------------------------------------","+"; 
        print STDOUT color 'reset'; 
	printf LOGFILE "%-1s %-20s %-1s %-40s %-1s\n","+","----------------------","+","------------------------------------------","+"; 
	printf LOGFILE "%-3s %-20s %-3s %-40s %-1s\n","|","block_name","|","block_version","|"; 
	printf LOGFILE "%-1s %-20s %-1s %-40s %-1s\n","+","----------------------","+","------------------------------------------","+"; 
	if (scalar(@l_all_dependList_inWA) == 0 ) {
		opendir(D, ".") || die "Can't open directory: $!\n";
		while (my $f = readdir(D)) {
		    print "----->\$f = $f\n";
                    next if (($f eq ".") || ($f eq "..") || ($f eq ".git"));			
		    #print "\$f = $f\n";
		    if (!(-d "$f/depends.list")) {	
			my $s_block_path = "$f\_path";
			if (defined $ENV{$s_block_path})  {
				my $s_b_version ;
				if ( $ENV{$s_block_path} =~ /\/$sWorkArea_name\//) {
					$s_b_version = "local";
				} else {
					$s_b_version = basename(dirname($ENV{$s_block_path}));
				}
				printf "%-3s %-20s %-3s %-40s %-1s\n","|","$f","|","$s_b_version","|"; 
			        printf "%-1s %-20s %-1s %-40s %-1s\n","+","----------------------","+","------------------------------------------","+"; 
				printf LOGFILE "%-3s %-20s %-3s %-40s %-1s\n","|","$f","|","$s_b_version","|"; 
			        printf LOGFILE "%-1s %-20s %-1s %-40s %-1s\n","+","----------------------","+","------------------------------------------","+"; 
			}
		    }
		}
		closedir(D);
	}
	#---------------------------------
        #close(LOGFILE);
	foreach my $s_noe_depFile (@l_all_dependList_inWA) {
		close(LOGFILE);
		my $s_return_status = fnGetBlockVersion($s_noe_depFile,$sLogFile);
		open LOGFILE, ">>$sLogFile" or die "cannot open file $sLogFile : $!\n";
		if ($s_return_status) {
			chdir($s_curr_pwd);
			print LOGFILE  "Error:  uwa_dep_rep finished with failure !!!\n\n";
			print "Error:  uwa_dep_rep finished with failure !!!\n\n";
			close(LOGFILE);
			exit 0;
		}
	}
	my @l_all_wa_blocks = ();
	foreach my $s_one_bl (@l_all_dependList_inWA) {
		push(@l_all_wa_blocks,dirname($s_one_bl));
	}
	my $s_usr_setup_path_file = "$ENV{UWA_SPACE_ROOT}/$sWorkArea_name/usr_setup_path";
	my @l_ref_blocks = `grep  \"_path\" $s_usr_setup_path_file \| grep \"\/space\/\"`; 

	if (scalar(@l_ref_blocks) > 0 ) {
		print LOGFILE "\n#####################################\n";
		print LOGFILE "#  Reference Block's version report # \n";
		print LOGFILE "#####################################\n";
		print "\n#####################################\n";
		print "#  Reference Block's version report # \n";
		print "#####################################\n";
		print STDOUT color 'bold red ';
		printf "%-1s %-20s %-1s %-40s %-1s\n","+","----------------------","+","------------------------------------------","+"; 
		printf "%-3s %-20s %-3s %-40s %-1s\n","|","block_name","|","block_version","|"; 
		printf "%-1s %-20s %-1s %-40s %-1s\n","+","----------------------","+","------------------------------------------","+"; 
		print STDOUT color 'reset'; 
		printf LOGFILE "%-1s %-20s %-1s %-40s %-1s\n","+","----------------------","+","------------------------------------------","+"; 
		printf LOGFILE "%-3s %-20s %-3s %-40s %-1s\n","|","block_name","|","block_version","|"; 
		printf LOGFILE "%-1s %-20s %-1s %-40s %-1s\n","+","----------------------","+","------------------------------------------","+"; 
		foreach my $s_ref_block_data (@l_ref_blocks) {
			my @l_ref_block_data = split(" ",$s_ref_block_data); 	
			my $s_b_version = $l_ref_block_data[2];
			my $s_b_name = $l_ref_block_data[1];
			
			printf "%-3s %-20s %-3s %-40s %-1s\n","|","$s_b_name","|","$s_b_version",""; 
			printf "%-1s %-20s %-1s %-40s %-1s\n","+","----------------------","+","------------------------------------------",""; 
			printf LOGFILE "%-3s %-20s %-3s %-40s %-1s\n","|","$s_b_name","|","$s_b_version",""; 
			printf LOGFILE "%-1s %-20s %-1s %-40s %-1s\n","+","----------------------","+","------------------------------------------",""; 
		}
	}


	open LOGFILE, ">>$sLogFile" or die "cannot open file $sLogFile : $!\n";

	chdir($s_curr_pwd);
	print LOGFILE  "\n\n--------------------------------------------------------------\n";
	print LOGFILE  "  uwa_dep_rep finished successfully !!!\n";
	print LOGFILE  "  for work area '$s_work_area_fullpath'. \n";
	print LOGFILE  "--------------------------------------------------------------\n";
	print "\n\n--------------------------------------------------------------\n";
	print "  uwa_dep_rep finished successfully !!!\n";
	print "  for work area '$s_work_area_fullpath'. \n";
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

