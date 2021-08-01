#!/usr/bin/perl -w
##***********************************************************************
#* Script      : gen_filelist.pl                                        *
#* Description :                                                        * 
#*                                                                      * 
#* ---------------------------------------------------------------------*
#* Revision      number  : V00001                                       *
#*               added by: Amir Duvdevani                               *
#*               date    : at Wed Mar  6 16:41:51 IST 2019              * 
#*               description: first version released                    * 
#* Revision      number  : V00002                                       *
#*               added by: Amir Duvdevani                               *
#*               date    : Tue Apr  2 11:00:57 IDT 2019                 *
#*               description: added option to generate filelist from    *
#*                            specific block's revision                 *
#************************************************************************
#

#
use lib '/home/amird/scripts/perl/packages';
use strict;
use warnings;
use Carp;
use Dump qw(dump);
use Cwd;
use Cwd 'abs_path';
use Getopt::Long;
use Common;
use File::Basename;
use Term::ANSIColor;
my $iScrip_version = "V00002";
my $sCommand = basename($0);
chomp($sCommand);
my $s_new_block_index = 0;
my $aProject_dir_struct;
my $sUWApath = "";
my $cmd = "";
my $s_log_message = "";
my $sScriptName        = $sCommand;
my $sUser_name         =  $ENV{USER}; 
my $sTop_dir_name      = "";
my $sBlock_name        = "";
my $sStab_block_list   = "";
my $sFix_release_file  = "";
my $sBlock_revision    = "";
my $b_notInWorkArea    = 0;
my $sWorkArea_name     = "";
my $sTop_name          = ""; 
my $sCluster_name      = ""; 
my $sRevision_number   = ""; 
my $bHelp              =  0; 
my $b_debug            =  0; 
my $sBlockCluster_name = "";
my $s_current_dir      = "";
my $s_project_dir      = "";
my $s_uc_project_name = "";
my @l_all_hier_sub_blocks = ();
my @lStab_block_list = ();
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
# Usage : gen_filelist
#
sub ffnUsage { 
	if ($sCommand eq "gen_filelist") {
		print "\n";
		print "Usage: gen_filelist -b <block_name> [-s <child_blocks_name_list>]\n"; 
		print "\n";
		print "               -b <block_name>              # generate block's file list locally ,all files path in block's filelist should be created \n";
		print "                                            # following the order below: \n";
		print "                                            #  1) taken from run folder - if exist \n"; 
		print "                                            #  2) taken from the current work area under - if exist\n"; 
		print "                                            #  3) from block's release revision in usr_setup_path file under current work space \n"; 
		print "                -s <child_blocks_name_list> # give a list of child blocks name that should take the stub list for them \n";
		print "                                            # example: -s \"blockA_name blockB_name blockC_name\" \n"; 
		print "                -fix <fix_release_file>     # option to give relative path to fix release file that contains list of files \n";
		print "                                            # that should be taken \n";
		print "                                            # and overwrite on the same files that exist in the release \n";
		print "                                            # file list ( gen_filelist result file )\n";
		print "                [ -help | -h ]              # print script usage\n"; 
		print "\n";
		print "Description: generate block's file list following the steps above.\n";
		print "             This script should run directly under work area folder \n";          
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
# Procedure: fnMkdirIfNotExist
#
# Description: create folder if not exist
#
#----------------------------------------------------------
sub fnMkdirIfNotExist {

  my ($sDirToMake,$top_name) = (@_);
  if ($sDirToMake =~ /block_level/) {
	$sDirToMake =~ s/block_level\///;
  }
  if (!(-d $sDirToMake)) {	
	  $cmd = "mkdir -p $sDirToMake";
	  fnRunSysCMD($cmd); 
  } else {
	print LOGFILE "Info: this path '$sDirToMake' already exist in git repository .\n";
  }
};# End sub fnMkdirIfNotExist
#----------------------------------------------------------
# Procedure: fnPrintMessageOut
# Description: write message to output log file
#-------------
sub fnPrintMessageOut  {

  my ($message) = (@_);

  if ((!( $message =~ /mkdir/ )) && ( $message =~ /Info:/ ) ) {
        print "$message";
  }
  print LOGFILE "$message";


    if ( $message =~ /Error:/ ) {
        print color("red")."\n**************************************************\n";
        print color("red")."Script 'create_uwa' Failed on Error:\n";
        print color("red")."$message\n";
        print color("red")."**************************************************\n";
        print color("reset")."";
        print "\n\t* Info: you can find log file '$sLogFile' \n\n";
        close(LOGFILE);
	close(FILELIST);
	if (-d "$sWorkArea_name") {
		#`rm -fr $sWorkArea_name`;
	}
	exit 1;
  }	
  if ( $message =~ /Warning:/ ) {
        print color("red")."$message";
        #print "\n\n\t* Info: you can find log file '$sLogFile' \n\n";
        print color("reset")."";
        close(LOGFILE);
	close(FILELIST);
	exit 1;
  }	

};# End sub fnPrintMessageOut
#----------------------------------------------------------
#
# Procedure: fnGet_all_child_hier_depends_list
#
# Description: get a list of all child depend list 
#
#-------------
sub fnGet_all_child_hier_depends_list {

	my ($sRlease_path) = (@_);

	my $sRelease_work_area  = dirname($sRlease_path);
	my $sCurrent_block      = basename($sRlease_path);
	push(@l_all_hier_sub_blocks,$sCurrent_block);
	if (-f "$sRlease_path/depends.list") {
		my $sDep_filename = "$sRlease_path/depends.list";
		open(my $fh_dep, '<:encoding(UTF-8)', $sDep_filename)
		  or die "Could not open file '$sDep_filename' $!";
		 
		while (my $row = <$fh_dep>) {
		  chomp $row;
	          next if($row =~ /^\/\//);		
	          next if($row =~ /^\#/);		
		  my @l_row = split(" ",$row);
                  my $sChild_folder = "$sRelease_work_area/$l_row[0]";
		  if (!(-d "$sChild_folder")) {
			print "\nWarning: no such release directory  '$sChild_folder' \!\!\!\n\n";
			print LOGFILE "\nWarning: no such release directory  '$sChild_folder' \!\!\!\n\n";
			chdir($s_current_dir);
			`rm -fr $sWorkArea_name`; # remove work area that not completed
			close(LOGFILE);
			exit 0;
		   }
		   fnGet_all_child_hier_depends_list($sChild_folder);
		}
	} else {
		print "Info: no such depend list file - '$sRlease_path/depends.list' \n";
	}
}
#----------------------------------------------------------
#
# Procedure: fnSet_usr_setup_path
#
# Description: write message to output log file
#
#-------------
sub fnSet_usr_setup_path {

	my ($sRevision_number,$sBlock_name,$sCluster_name,$sTop_name) = (@_);

	my $sRlease_path = "";
	if ($sCluster_name ne "") {
		$sRlease_path = $ENV{"$s_uc_project_name\_CLUSTER_ROOT"}/$sCluster_name/$sRevision_number/$sCluster_name;
	}
	if ($sTop_name ne "") {
		$sRlease_path = $ENV{"$s_uc_project_name\_TOP_ROOT"}/$sTop_name/$sRevision_number/$sTop_name;
	}

	if (!(-d "$sRlease_path")) {
		print "\nWarning: no such release directory  '$sRlease_path' \!\!\!\n\n";
		print LOGFILE "\nWarning: no such release directory  '$sRlease_path' \!\!\!\n\n";
		chdir($s_current_dir);
		`rm -fr $sWorkArea_name`; # remove work area that not completed
		close(LOGFILE);
		exit 0;
	}

	fnGet_all_child_hier_depends_list($sRlease_path);

        my $sMain_release_path = dirname($sRlease_path);
	my $filename = 'usr_setup_path';
	open(my $fh, '>', $filename) or die "Could not open file '$filename' $!";
	printf $fh "#----------------------------------------------------#\n";
	printf $fh "#  usr_setup_path file for '$sWorkArea_name'           \n";
	printf $fh "#----------------------------------------------------#\n";
	my $s_current_pwd = `pwd`;
	chomp($s_current_pwd);
	my $s_uwa_root = dirname($s_current_pwd);
	printf $fh "%-2s %-25s %-20s\n","setenv", "UWA_NAME", "$sWorkArea_name";
	foreach my $sOne_block (@l_all_hier_sub_blocks) {
		printf $fh "%-2s %-25s %-20s\n","setenv", "$sOne_block\_path", "$sMain_release_path/$sOne_block";
	}
	close $fh;
	print "Info: $sWorkArea_name/usr_setup_path file created follow the release revision .\n";

};# End sub fnSet_usr_setup_path
#----------------------------------------------------------
#
# Procedure: fn_GetAllChild_inDependsList
#
# Description: 
#
#-------------
sub fn_GetAllChild_inDependsList {

	my ($sCurrentBlockName) = (@_);

	if ($b_debug) {
		print "Info: In sub fn_GetAllChild_inDependsList\n";
		print "\t sCurrentBlockName='$sCurrentBlockName'\n";
	}

	my $sBlock_dependsList = "";
	if (-f "$ENV{UWA_PROJECT_ROOT}/$ENV{UWA_NAME}/$sCurrentBlockName/depends.list" ) {
		$sBlock_dependsList = "$ENV{UWA_PROJECT_ROOT}/$ENV{UWA_NAME}/$sCurrentBlockName/depends.list";
	} else {
		$sBlock_dependsList = $ENV{"$sCurrentBlockName\_path"} . "/depends.list";
	}
        if (!(-f $sBlock_dependsList)) {
		print "\nError: no such depend file '$sBlock_dependsList' \n\n"; 
		close(LOGFILE);
		exit 0;
	}
	#-------------------------------------
	# read block's depends list file 

	my $sDep_filename = "$sBlock_dependsList";
	open(my $fh_dep, '<:encoding(UTF-8)', $sDep_filename)
	  or die "Could not open file '$sDep_filename' $!";
	 
	while (my $row = <$fh_dep>) {

		chomp $row;
		next if($row =~ /^\/\//);		
		next if($row =~ /^\#/);		
		my @l_row = split(" ",$row);
		my $sChild_folder = $l_row[0];
		$sChild_folder =~ s/ //;
		if ($b_debug) {print "Info: row in depends.list = '@l_row'\n";}
		my $sBlock_filelist = "";
		if (-f "$ENV{UWA_PROJECT_ROOT}/$ENV{UWA_NAME}/$sChild_folder/LISTS/$sChild_folder.list" ) {
			$sBlock_filelist = "$ENV{UWA_PROJECT_ROOT}/$ENV{UWA_NAME}/$sChild_folder/LISTS/$sChild_folder.list"
		} else {
			$sBlock_filelist = $ENV{"$sChild_folder\_path"} . "/LISTS/$sChild_folder.list";
		}

		if ($b_debug) {print "Info: sBlock_filelist = '$sBlock_filelist'\n";}
		if (!(-f "$sBlock_filelist")) {
			$s_log_message = "\nError: no such file '$sBlock_filelist' \!\!\!\n";
			fnPrintMessageOut($s_log_message);
		}

		print LOGFILE "Info: load file list '$sBlock_filelist' \n"; 
		fnGen_block_fileList($sBlock_filelist,$sChild_folder);
	}


} ;# End sub fn_GetAllChild_inDependsList
#----------------------------------------------------------
#
# Procedure: fnGen_block_fileList_fromSTAB
#
# Description: create block's geb file list from STAB 
#
#-------------
sub fnGen_block_fileList_fromSTAB {

	my ($sBlock_fileList_stab,$s_inCurrentBlockName) = (@_);

	open FILELIST, ">>./$sBlock_name.list" or die "cannot open file ./$sBlock_name.list : $!\n";

	print FILELIST "\/\/-----> Start block: '$s_inCurrentBlockName' ------\n";

	open my $fh, "<", $sBlock_fileList_stab
	or croak "could not open $sBlock_fileList_stab: $!";
	while (my $row = <$fh>) {
		chomp $row;
		#next if($row =~ /^\/\//);		
		#---------------------------------------
		# take care on call to child filelist
		if ($row =~ /^-f/) {
			my @l_row = split(" ",$row);
			my $sNext_file_list = $l_row[1];
			my $sNext_filelist_name = basename($sNext_file_list);
			#----------------------------
			# if child filelist exist locally under current folder
			if (-f "$sNext_filelist_name") {
				close(FILELIST);
				fnGen_block_fileList($sNext_filelist_name ,"");
				next;
			}
			my @l_current_block_path = split("\/",$sNext_file_list);
			my $s_current_block_path = $l_current_block_path[0];
			$s_current_block_path =~  s/\$//;
			if (defined $ENV{$s_current_block_path}) {
				my $s_curr_block_name = basename($ENV{$s_current_block_path});
				my $s_local_block_list = "$s_curr_block_name/LISTS/$s_curr_block_name.list";
				if (-f "$s_local_block_list") {
					close(FILELIST);
					fnGen_block_fileList($s_local_block_list,"");
					next;
				}
				# take the child filelist as is in the usr_setup_path 				
				$sNext_file_list =~ s/\$$s_current_block_path/$ENV{$s_current_block_path}/;
				$sNext_file_list =~ s/ //g;
				if (-f "$sNext_file_list") {
					print FILELIST "// ------ Start $sNext_file_list -------\n"; 
					close(FILELIST);
					fnGen_block_fileList($sNext_file_list,"");
					print FILELIST "// ------ End $sNext_file_list -------\n"; 
					next;
				}
			} else {
				print "\nError: the environment variable '$ENV{$s_current_block_path}' not defined \!\!\!\n\n";
				print LOGFILE "\nError: the environment variable '$ENV{$s_current_block_path}' not defined \!\!\!\n\n";
				close(LOGFILE);
				close(FILELIST);
				exit 0;
			} 
		}
		#---------------------------------------
		# take care on file
		if ($row =~ /^\$/) {
			my $sTmp_row = $row;
			my @l_current_row = split("\/",$row);
			my $s_current_row = $l_current_row[0];
			$s_current_row =~  s/\$//;
			if (defined $ENV{$s_current_row}) {
				my $s_pwd = `pwd`;
				chomp($s_pwd);	
				#----------------------------------
				# check if we have local file under
				# current folder
				my $s_file_name = basename($row);
				if (-f "$s_file_name") {
					print FILELIST "$s_pwd/$s_file_name\n";
					next;
				}
				#----------------------------------
				# check if we have local file under
				# block's folder
				my $s_curr_block_name = basename($ENV{$s_current_row});
			       # take the block's local file 
				$sTmp_row =~ s/\$$s_current_row/$s_curr_block_name/;
				$sTmp_row =~ s/ //g;
				chomp($sTmp_row);
				if (-f "$sTmp_row") {
					print FILELIST "$$sTmp_row\n";
					next;
				}
				$sTmp_row = $row;		
				$sTmp_row =~ s/\$$s_current_row/$ENV{$s_current_row}/;
				$sTmp_row =~ s/ //g;
				if (-f "$sTmp_row") {
					print FILELIST "$s_pwd/$sTmp_row\n";
					next;
				} else {
					#print "Error: no such file '$sTmp_row' \!\!\!\n\n";
					#print LOGFILE "Error: no such file '$sTmp_row' \!\!\!\n\n";
					#close(LOGFILE);
					#close(FILELIST);
					#exit 0;
					$s_log_message = "\nError: no such file '$sTmp_row' \!\!\!\n";
print "----1----\n";
					fnPrintMessageOut($s_log_message);
				}
			} else {
				print "\nError: the environment variable '$ENV{$s_current_row}' not defined \!\!\!\n\n";
				print LOGFILE "\nError: the environment variable '$ENV{$s_current_row}' not defined \!\!\!\n\n";
				close(LOGFILE);
				close(FILELIST);
				exit 0;
			}

		} else {
			print FILELIST "$row\n";
		}
	}



};# End sub fnGen_block_fileList_fromSTAB 
#----------------------------------------------------------
#
# Procedure: fnGet_fileFollowing_priority_order 
#
# Description: search the file list following the
#              priority oredr :
#              	- under run (current) directory
#              	- under block's locally work space
#               - under release integrator (craton workspace) area
#-------------
sub fnGet_fileFollowing_priority_order {

	my ($sNext_file_list,$sCurrent_blockName) = (@_);

	my $sNext_filelist_name = basename($sNext_file_list);
	my $s_pwd = `pwd`;
	chomp($s_pwd);	
	#----------------------------
	# if child filelist exist locally under current folder
	if (-f "$sNext_filelist_name") {
		print "\nInfo: taking the stub file form '$sNext_filelist_name' \n";
		print LOGFILE "\nInfo: taking the stub file form '$sNext_filelist_name' \n";
		return "$s_pwd/$sNext_filelist_name";
	}
	if (-f "$ENV{UWA_PROJECT_ROOT}/$ENV{UWA_NAME}/$sCurrent_blockName/STUB/$sNext_filelist_name") {
		print "\nInfo: taking the stub file form '$ENV{UWA_PROJECT_ROOT}/$ENV{UWA_NAME}/$sCurrent_blockName/STUB/$sNext_filelist_name' \n";
		print LOGFILE "\nInfo: taking the stub file form '$ENV{UWA_PROJECT_ROOT}/$ENV{UWA_NAME}/$sCurrent_blockName/STUB/$sNext_filelist_name' \n";
		return "$ENV{UWA_PROJECT_ROOT}/$ENV{UWA_NAME}/$sCurrent_blockName/STUB/$sNext_filelist_name";
	}
        my $s_current_block_path = "$sCurrent_blockName\_path";
	if (defined $ENV{$s_current_block_path}) {
		my $s_local_block_list = "$ENV{$s_current_block_path}/STUB/$sCurrent_blockName.list";
		if (-f "$s_local_block_list") {
			print "\nInfo: taking the stub file form '$s_local_block_list' \n";
			print LOGFILE "\nInfo: taking the stub file form '$s_local_block_list' \n";
			return "$s_local_block_list";
		}
	}

	return "";
}
#----------------------------------------------------------
#
# Procedure: fnGen_block_fileList
#
# Description: create block's geb file list  
#
#-------------
sub fnGen_block_fileList {

	my($sBlock_fileList,$sCurrentBlockName) = (@_);

	if($b_debug) {
		print "In: sub fnGen_block_fileList\n";	
		print "\t sBlock_fileList  ='$sBlock_fileList'\n";
		print "\t sCurrentBlockName='$sCurrentBlockName'\n";
	}

	my $s_uc_project_name = uc($ENV{PROJECT_NAME});	

	my $s_curr_block_stab_idx = 0;
	foreach my $sStab_curr_block (@lStab_block_list) {
		if ($sStab_curr_block eq $sCurrentBlockName) {$s_curr_block_stab_idx =1;}
	}
	#---------------------------------------------
	# check if need to take stab for current block 
	if ($s_curr_block_stab_idx) {
		my $sBlock_fileList_stab = $sBlock_fileList;
		$sBlock_fileList_stab =~ s/\/LISTS\//\/STUB\//;
		my $sBlock_fileList_stab_tmp = fnGet_fileFollowing_priority_order($sBlock_fileList_stab,$sCurrentBlockName);
		if ($sBlock_fileList_stab_tmp eq "") {
			if (!(-f "$sBlock_fileList_stab")) {
				print "\n\nError: no such stub file '$sBlock_fileList_stab' \!\!\!\n\n";
				print LOGFILE "\nError: no such stub file '$sBlock_fileList_stab' \!\!\!\n\n";
				close(LOGFILE);
				close(FILELIST);
				exit 0;
			} else {
				fnGen_block_fileList_fromSTAB($sBlock_fileList_stab,$sCurrentBlockName);
			}
		} else {
			fnGen_block_fileList_fromSTAB($sBlock_fileList_stab_tmp,$sCurrentBlockName);
		}
	} else {;# no stab for current block 

		fn_GetAllChild_inDependsList($sCurrentBlockName);

		open FILELIST, ">>./$sBlock_name.list" or die "cannot open file ./$sBlock_name.list : $!\n";

		print FILELIST "\/\/-----> Start block: '$sCurrentBlockName' ------\n";

		open my $fh, "<", $sBlock_fileList
		or croak "could not open $sBlock_fileList: $!";
		while (my $row = <$fh>) {
			chomp $row;
			next if ($row eq "");
			#next if($row =~ /^\/\//);		
			#---------------------------------------
			# take care on call to child filelist
			if ($row =~ /^-f/) {
				my @l_row = split(" ",$row);
				my $sNext_file_list = $l_row[1];
				my $sNext_filelist_name = basename($sNext_file_list);
				#----------------------------
				# if child filelist exist locally under current folder
				if (-f "$sNext_filelist_name") {
					close(FILELIST);
					fnGen_block_fileList($sNext_filelist_name ,"");
					next;
				}
				my @l_current_block_path = split("\/",$sNext_file_list);
				my $s_current_block_path = $l_current_block_path[0];
				$s_current_block_path =~  s/\$//;
				if (defined $ENV{$s_current_block_path}) {
					my $s_curr_block_name = basename($ENV{$s_current_block_path});
					my $s_local_block_list = "$s_curr_block_name/LISTS/$s_curr_block_name.list";
					if (-f "$s_local_block_list") {
						close(FILELIST);
						fnGen_block_fileList($s_local_block_list,"");
						next;
					}
					# take the child filelist as is in the usr_setup_path 				
					$sNext_file_list =~ s/\$$s_current_block_path/$ENV{$s_current_block_path}/;
					$sNext_file_list =~ s/ //g;
					if (-f "$sNext_file_list") {
						print FILELIST "// ------ Start $sNext_file_list -------\n"; 
						close(FILELIST);
						fnGen_block_fileList($sNext_file_list,"");
						print FILELIST "// ------ End $sNext_file_list -------\n"; 
						next;
					}
				} else {
					print "\nError: the environment variable '$ENV{$s_current_block_path}' not defined \!\!\!\n\n";
					print LOGFILE "\nError: the environment variable '$ENV{$s_current_block_path}' not defined \!\!\!\n\n";
					close(LOGFILE);
					close(FILELIST);
					exit 0;
				} 
			}
			#---------------------------------------
			# take care on file
			my $s_in_line_sub = 0;

			if ($row =~ /\$/) {
				if ($row =~ /^\/\//) { # comment
					print FILELIST "$row\n";
					next;
				}
				my $s_pwd = `pwd`;
				chomp($s_pwd);	
				my $sTmp_row = $row;
				my @l_current_row = split("\/",$row);
				my $s_current_row = "";
				if ($row =~ /^\$/) {
					$s_current_row = $l_current_row[0];
				} else {
					my $s_curr_row_str = "@l_current_row";
					my @l_curr_row_str = split(" ",$s_curr_row_str);
					foreach my $one_word (@l_curr_row_str) {	
						if ($one_word =~ /^\$/) {
							$s_current_row = $one_word;
							$s_in_line_sub = 1;
						}
					}
					if ($s_in_line_sub == 0) {
						if ($row =~ /incdir/) {
							my @l_var_in_line = split("\/",$row);
							foreach my $s_one_var (@l_var_in_line) {
								if ($s_one_var =~ /\$/) {
									my @l_split_plus = split("\\\+",$s_one_var);
									
									foreach my $s_one_element (@l_split_plus) {
										if ($s_one_element =~ /^\$/) {
											my $s_curr_block_name_path = $s_one_element;
											$s_curr_block_name_path =~ s/\$//;
											my $s_curr_block_name = $s_curr_block_name_path;
											$s_curr_block_name =~ s/_path//;
											my $s_test_area = `pwd`;
											chomp($s_test_area);
											print FILELIST "+incdir+$s_test_area\n";
											print FILELIST `echo $row`;
										        my $s_new_row = $row;			
											$s_new_row =~ s/$s_curr_block_name_path/$s_uc_project_name\_RELEASE_AREA\/$s_curr_block_name\/latest/;
											print FILELIST `echo $s_new_row`;
										        $s_new_row = $row;			
											$s_new_row =~ s/$s_curr_block_name_path/$s_uc_project_name\_USER_RELEASE_AREA\/$s_curr_block_name\/latest/;
											print FILELIST `echo $s_new_row`;
											goto NEXT_LINE;
										}
									}
								}
							}
				
						}
						print FILELIST `echo $row`;
						NEXT_LINE:
						next;
					}
				}
				$s_current_row =~  s/\$//;
				if (defined $ENV{$s_current_row}) {
					if ($s_in_line_sub) {
						print FILELIST `echo $row`;
						next;
					}
					#----------------------------------
					# check if we have local file under
					# current folder
					my $s_file_name = basename($row);
					if (-f "$s_file_name") {
						print FILELIST "$s_pwd/$s_file_name\n";
						next;
					}
					#----------------------------------
					# check if we have local file under
					# block's folder
					my $s_curr_block_name = basename($ENV{$s_current_row});
				       # take the block's local file 
					$sTmp_row =~ s/\$$s_current_row/$s_curr_block_name/;
					$sTmp_row =~ s/ //g;
					chomp($sTmp_row);
					if (-f "$sTmp_row") {
						print FILELIST "$s_pwd/$sTmp_row\n";
						next;
					}
					$sTmp_row = $row;		
					$sTmp_row =~ s/\$$s_current_row/$ENV{$s_current_row}/;
					$sTmp_row =~ s/ //g;
					if (-f "$sTmp_row") {
						print FILELIST "$sTmp_row\n";
						next;
					} else {
						$s_log_message = "\nError: no such file '$sTmp_row' \!\!\!\n";
print "----2----\n";
						fnPrintMessageOut($s_log_message);
						#print "Error: no such file '$sTmp_row' \!\!\!\n\n";
						#print LOGFILE "Error: no such file '$sTmp_row' \!\!\!\n\n";
						#close(LOGFILE);
						#close(FILELIST);
						#exit 0;
					}
				} else {
					print "\nError: the environment variable not defined in row '$row'\!\!\!\n\n";
					print LOGFILE "\nError: the environment variable not defined in row '$row'\!\!\!\n\n";
					close(LOGFILE);
					close(FILELIST);
					exit 0;
				}

			} else {
				print FILELIST "$row\n";
			}
		}
	}
	print FILELIST "\/\/-----< Finished block: '$sCurrentBlockName' ------\n";
	close(FILELIST);


};# End fnGen_block_fileList
#----------------------------------------------------------
#
# Procedure: 
#
# Description: 
#
#-------------
sub fnUpdate_genFileList_withFixReleaseFile {

	my ($sBlockFileList,$s_iFix_release_file) = (@_);

	my $sNew_fileList = "$sBlockFileList\_new";
	if (-f "$sNew_fileList") {`rm -fr $sNew_fileList`;}

	open(my $fh_new, '>', $sNew_fileList) or die "Could not open file '$sNew_fileList' $!";

	open my $fh_fix, "<", $s_iFix_release_file
		or croak "could not open $s_iFix_release_file: $!";

	#-----------------------------------
	# Load all fix files on table
	my @l_fix_files = ();		
	my @l_fix_path  = ();		
	while (my $row_fix = <$fh_fix>) {
		chomp $row_fix;
		next if($row_fix =~ /^\/\//);		
		next if($row_fix =~ /^\#/);		
		next if($row_fix eq "");		
		$row_fix =~ s/^\s+//;
		my $s_fix_fileName = basename($row_fix);	
		push(@l_fix_files,$s_fix_fileName);
		push(@l_fix_path,$row_fix);
	}
	close $fh_fix;
	#-----------------------------------

	
		#-------------------------------------
		# search fix line in orig fileList 
		open my $fh_origFileList, "<", $sBlockFileList
			or croak "could not open $sBlockFileList: $!";
		while (my $row_orig = <$fh_origFileList>) {
			chomp $row_orig;
			my $s_curr_fileName = basename($row_orig);	
			my $s_found_already = 0;	
			my $s_replace_path  = "";	
			my $s_elemnt_idx = 0;
			foreach my $one_already_fix (@l_fix_files) {
				if ($s_curr_fileName eq "$one_already_fix") {
					$s_found_already = 1;	
					 last;
				}
				$s_elemnt_idx++;
			}
			if ($s_found_already) {
				print $fh_new "\/\/$row_orig\n";
				print $fh_new "$l_fix_path[$s_elemnt_idx]\n";
				next;
			} else {
				print $fh_new "$row_orig\n";
			}	
		}
		close $fh_origFileList;
		close $fh_new;
	#-----------------------------
	# add the new lines that exist 
	# in fix_release file and did 
	# not find match files in 
	# gen_filelist result file

	my $s_new_file_flag = 0;
	open($fh_new, '>>', $sNew_fileList) or die "Could not open file '$sNew_fileList' $!";
	open $fh_fix, "<", $s_iFix_release_file
		or croak "could not open $s_iFix_release_file: $!";
	while (my $row_fix = <$fh_fix>) {
		chomp $row_fix;
		next if($row_fix =~ /^\/\//);		
		next if($row_fix =~ /^\#/);		
		next if($row_fix eq "");		
		$row_fix =~ s/^\s+//;
		my $s_fix_fileName = basename($row_fix);	
		#-------------------------------------
		# search match file in filelist result
		my @l_grep_res = `grep \"$s_fix_fileName\" $sNew_fileList`;
		if (scalar(@l_grep_res) == 0 ) {;# new file to add
				if ($s_new_file_flag == 0) {
					print $fh_new "//------------Additional files came from fix_release file--------\n";
				}
				$s_new_file_flag = 1;
				print $fh_new "$row_fix\n";
		}
		#---------------
	}
	close $fh_fix;
	close $fh_new;
	#-----------------------------


        my $s_cksum = `cksum $sNew_fileList`;
	chomp($s_cksum); 
	my @l_split_cksum_res = split(" ",$s_cksum);
	my $s_fileSize = $l_split_cksum_res[1];
	if ($s_fileSize != 0 ) {
		`cp -f $sNew_fileList $sBlockFileList`;
		print LOGFILE "Info: the  block's file list '$sBlockFileList' is overwritten by \n";
		print LOGFILE "      files in fix release file '$s_iFix_release_file'\n\n";
		print "\nInfo: the  block's file list '$sBlockFileList' is overwritten by \n";
		print "      files in fix release file '$s_iFix_release_file'\n";
	}
	#------------------------
	# clean temp file
	`rm -fr $sNew_fileList`;

};# End fnUpdate_genFileList_withFixReleaseFile
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
#----------------------------------------------------------
#
# Procedure: fnPrintMessageOut_old
#
# Description: write message to output log file
#
#-------------
sub fnPrintMessageOut_old  {

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

};# End sub fnPrintMessageOut_old
#----------------------------------------------------------
#
# Procedure: fnUpdate_usr_setup_path_withNewVersion
#
# Description: 
#
#-------------
sub fnUpdate_usr_setup_path_withNewVersion {


	# check if top/cluster revision exist 
	my $s_top_or_cluster   = "";
	my $s_new_version_path = "";
	
        my $s_cluster_root_dir = $ENV{"$s_uc_project_name\_CLUSTER_ROOT"};
	if (-d "$s_cluster_root_dir/$sBlock_name/$sBlock_revision") {
		$s_new_version_path = "$s_cluster_root_dir/$sBlock_name/$sBlock_revision";
		$s_top_or_cluster = "cluster";
	}
        my $s_top_root_dir = $ENV{"$s_uc_project_name\_TOP_ROOT"};
	if (-d "$s_top_root_dir/$sBlock_name/$sBlock_revision") {
		$s_new_version_path = "$s_top_root_dir/$sBlock_name/$sBlock_revision";
		$s_top_or_cluster = "top";
	}

	if ($s_top_or_cluster eq "") {
		if ((!(-d "$s_top_root_dir/$sBlock_name")) && (!(-d "$s_top_root_dir/$sBlock_name"))) {
			print "\n** Error: the name of the block you gave as input,was not match to top or cluster name\n";
			print "          under top or cluster release area:\n"; 
			print "          - cluster release area: '$s_cluster_root_dir/'\n"; 
			print "          - top release area    : '$s_top_root_dir/\n"; 
			print "          if you run with option -r <revision_number> you must give in option -b <block_name>\n"; 
			print "          block_name that match 'top' or 'cluster' name \!\!\!\n\n"; 
			close(LOGFILE);
			exit 0;	
		}
		print "\n** Error: no such block's path version under top or cluster release area:' \!\n"; 
		print "          cluster release area: '$s_cluster_root_dir/$sBlock_name/$sBlock_revision'\n"; 
		print "          top release area    : '$s_top_root_dir/$sBlock_name/$sBlock_revision'\n\n"; 
		close(LOGFILE);
		exit 0;	
	}

	if (-f "./usr_setup_path" ) {
		my $f_newFile = "/tmp/usr_setup_path\_$$";
		open USER_SETUP_F, ">$f_newFile" or die "cannot open file $f_newFile : $!\n";
		open(my $fh_dep, '<:encoding(UTF-8)', "./usr_setup_path")
		  or die "Could not open file './usr_setup_path' $!";
		 
		while (my $row = <$fh_dep>) {
		  chomp $row;
		  my @l_row = split(" ",$row);
		  if (!(scalar(@l_row) > 1)) {
			print USER_SETUP_F "$row\n";
			next;
		  }
		  if ($l_row[0] ne "setenv")  { 
			print USER_SETUP_F "$row\n";
			next;
		  }
		  if (($l_row[0] eq "setenv") && (!($l_row[1] =~ /_path$/ ))) { 
			print USER_SETUP_F "$row\n";
			next;
		  } else {
			my $s_currBlock      = basename($l_row[2]);
			my $s_new_block_path = "$s_new_version_path/$s_currBlock";
			if ((!(-d "$s_new_block_path")) && ($sBlock_name eq "$s_currBlock")) {
				print "\nError: no such block's path version '$s_new_block_path' \!\n\n"; 
				close(LOGFILE);
				exit 0;	
			}
			if ((!(-d "$s_new_block_path")) && ($sBlock_name ne "$s_currBlock")) {
				print "Warning: no such block's path version '$s_new_block_path'\n"; 
				print "         the vesrion for this block stay as before '$l_row[2]'\n"; 
				print LOGFILE "Warning: no such block's path version '$s_new_block_path'\n"; 
				print LOGFILE "         the vesrion for this block stay as before '$l_row[2]'\n"; 
				print USER_SETUP_F "$row\n";
				next;
			}
			printf USER_SETUP_F "%-2s %-25s %-20s\n","$l_row[0]", "$l_row[1]", "$s_new_block_path";
		  }	

		}
		close($fh_dep);	
		close(USER_SETUP_F);	
		`mv $f_newFile ./usr_setup_path`;
	} else {
		print "\nWarning: you must run this script directly under folder \$\{UWA_SPACE_ROOT\}/\$\{UWA_NAME\} \!\n\n"; 
		close(LOGFILE);
		exit 0;	
	}

};# End sub fnUpdate_usr_setup_path_withNewVersion
#----------------------------------------------------------
#
# Procedure:
#
# Description:
#
#-------------
sub fnRemoveDuplicationFiles {

  my ($sOutFileName) = (@_);  
  
  my @l_uniq_line_list = ();

  open(my $fh, '<:encoding(UTF-8)', $sOutFileName)
      or die "Could not open file '$sOutFileName' $!";
  
  open OUTFILE, ">$sOutFileName\.tmp"  or die "Error could not open file  $sOutFileName\.tmp for output $! \n";

  while (my $row = <$fh>) {
    chomp $row;
    #if ((!($row ~~ @l_uniq_line_list )) && ($row ne "" )) 
    my $s_duplicate_flag = 0 ;	
    if ($row ne "") {
	    foreach my $s_one_exist_row (@l_uniq_line_list) { 	
		if ($row eq "$s_one_exist_row") {
		    $s_duplicate_flag = 1 ;	
		    goto DUPLICATE_FOUND;
		}	
            }  		
	    DUPLICATE_FOUND:	
	    if ($s_duplicate_flag == 0) {
		push(@l_uniq_line_list,$row);
		print OUTFILE "$row\n";
	    }
    } else {;# empty row
		print OUTFILE "$row\n";
    }
  }
  close($fh);
  close OUTFILE ;
  `mv $sOutFileName\.tmp $sOutFileName`;
}
#---------------------------------------------------------------------------
#
#
#     ---------- MAIN   'gen_filelist' -----------------------
#
#
#---------------------------------------------------------------------------
#
        if (not(&GetOptions('b=s'      => \$sBlock_name   ,
			    's=s'      => \$sStab_block_list   ,
			    'fix=s'    => \$sFix_release_file   ,
			    'r=s'      => \$sBlock_revision   ,
			    'local!'   => \$b_notInWorkArea   ,
			    'debug!'   => \$b_debug   ,
                            'help!'    => \$bHelp     )) || $bHelp ) {
          &ffnUsage;
        }
        #---------------------------
        # check args validation 
        #-----
        #if ($#ARGV==-1) { &ffnUsage; } 
	if (!(defined $ENV{PROJECT_NAME}) || !(defined $ENV{PROJECT_HOME}) || !(defined $ENV{GIT_PROJECT_ROOT}) ) {
		print "\nWarning: you must run 'setup_proj' command before \!\!\!\n\n";	
		close(LOGFILE);
		exit 0;
	}
        if ($bHelp) { &ffnUsage; }	
        if ($sBlock_name eq "") { 
		&ffnUsage; 
	}	

	print "-----------------\n";
	print "  gen_filelist \n";
	print "-----------------\n";
	print LOGFILE  "\n\n-----------------\n";
	print LOGFILE  "  gen_filelist \n";
	print LOGFILE  "-----------------\n";

	$s_uc_project_name = uc($ENV{PROJECT_NAME});	
	@lStab_block_list = split(" ",$sStab_block_list);
	$s_current_dir = `pwd`;
	chomp($s_current_dir);
        # initalize 
	if (defined $ENV{UWA_NAME}) {$ENV{UWA_NAME} = ""};

	#-----------------------------------
	# check if we need to look to specific revision block
	if ($sBlock_revision ne "") {
		if (-d "project") {
			fnUpdate_usr_setup_path_withNewVersion();
			chdir($s_current_dir);
		} else {
			$s_current_dir =~ s/\/project\//\/space\//;
			if (-f "$s_current_dir/usr_setup_path") {
				source "$s_current_dir/usr_setup_path";
				$sWorkArea_name = $ENV{UWA_NAME};
				chdir("$s_current_dir")
			} else {
				print "\nWarning: you must run this script directly under folder \$\{UWA_SPACE_ROOT\}/\$\{UWA_NAME\} \!\n\n"; 
				close(LOGFILE);
				exit 0;	
			}
		}
	}	
	#-----------------------------------
	if ($b_notInWorkArea) {
		if (-f "./usr_setup_path" ) {
			source "./usr_setup_path";
		} else {
			$s_current_dir =~ s/\/project\//\/space\//;
			if (-f "$s_current_dir/usr_setup_path") {
				source "$s_current_dir/usr_setup_path";
				$sWorkArea_name = $ENV{UWA_NAME};
				chdir("$s_current_dir")
			} else {
				print "\nWarning: you must run this script directly under folder \$\{UWA_SPACE_ROOT\}/\$\{UWA_NAME\} \!\n\n"; 
				close(LOGFILE);
				exit 0;	
			}
		}
	} else {
		if (-f "./project/usr_setup_path" ) {
			chdir("project");
			source "./usr_setup_path";
		} else {
			$s_current_dir =~ s/\/project\//\/space\//;
			if (-f "$s_current_dir/usr_setup_path") {
				source "$s_current_dir/usr_setup_path";
				$sWorkArea_name = $ENV{UWA_NAME};
				chdir("$s_current_dir")
			} else {
				print "\nWarning: you must run this script directly under folder \$\{UWA_SPACE_ROOT\}/\$\{UWA_NAME\} \!\n\n"; 
				close(LOGFILE);
				exit 0;	
			}
		}
	}
	# check usr_setup_path is valid
	if ($ENV{UWA_PROJECT_ROOT} eq "") {
		print "\nError: usr_setup_path file is not valid ,difenition is missing for '\$ENV{UWA_PROJECT_ROOT}' \n\n";
		close(LOGFILE);
		exit 0;
	}
	if ($ENV{UWA_NAME} eq "") {
		print "\nError: usr_setup_path file is not valid ,difenition is missing for '\$ENV{UWA_NAME}' \n\n";
		close(LOGFILE);
		exit 0;
	}

	# check if this block defined in usr_setup_path work-area's file
        if (!(defined $ENV{"$sBlock_name\_path"})) {
		print "\nError: this block '$sBlock_name' is not defined under this work area '$ENV{UWA_PROJECT_ROOT}/$ENV{UWA_NAME}'\n\n";
		close(LOGFILE);
		exit 0;
	} 
	my $sBlock_filelist = "";
	if (-f "$ENV{UWA_PROJECT_ROOT}/$ENV{UWA_NAME}/$sBlock_name/LISTS/$sBlock_name.list" ) {
		$sBlock_filelist = "$ENV{UWA_PROJECT_ROOT}/$ENV{UWA_NAME}/$sBlock_name/LISTS/$sBlock_name.list"
	} else {
		$sBlock_filelist = $ENV{"$sBlock_name\_path"} . "/LISTS/$sBlock_name.list";
	}
        if (!(-f $sBlock_filelist)) {
		$s_log_message = "\nError: no such file '$sBlock_filelist' \!\!\!\n";
print "----3----\n";
		fnPrintMessageOut($s_log_message);
		#print "\nError: no such file list '$sBlock_filelist' \n\n"; 
		#close(LOGFILE);
		#exit 0;
	}

	if (-f "$sBlock_name.list") {`\\rm -f "$sBlock_name.list"`;}

	fnGen_block_fileList($sBlock_filelist,$sBlock_name);

	if ($sFix_release_file ne "") {
		if (!(-f "$sFix_release_file")) {
			print "\n\nError: no such fix release file '$sFix_release_file' \n\n"; 
			print LOGFILE "\nError: no such fix release file '$sFix_release_file' \n\n"; 
			close(LOGFILE);
			exit 0;
		}
		fnUpdate_genFileList_withFixReleaseFile("./$sBlock_name.list" ,$sFix_release_file);
	}

	if (-f "$s_current_dir/project/$sBlock_name.list") {
		`mv $s_current_dir/project/$sBlock_name.list $s_current_dir/.`;
	}
	#-----------------------------
	# remove duplications 
	if (-f "$s_current_dir/$sBlock_name\.list") {
		fnRemoveDuplicationFiles("$s_current_dir/$sBlock_name.list"); 
	}
	#-----------------------------
	print LOGFILE  "\n\n-----------------------------------------------------------------------\n";
	print LOGFILE  "  gen_filelist for block '$sBlock_name' finished successfully !!!\n";
	print LOGFILE  "  filelist result created under:\n";
	print LOGFILE  "        '$ENV{UWA_SPACE_ROOT}/$ENV{UWA_NAME}/$sBlock_name.list'   \n";
	print LOGFILE  "-----------------------------------------------------------------------\n";
	print color("green")."\n\n--------------------------------------------\n";
	print color("green")."  gen_filelist for block '$sBlock_name' \n";
	print color("green")."  finished successfully !!!\n";
	print color("green")."--------------------------------------------\n";
        print color("reset")."";
	print "\n*Info:  filelist result created under:\n\n";
	print "         '$ENV{UWA_SPACE_ROOT}/$ENV{UWA_NAME}/$sBlock_name.list'   \n";

        close(LOGFILE);
        print "\n\nInfo: you can find log file '$sLogFile' \n\n";
        exit 0;

#-------------------------------------------------------
#
#
#         --------   END  gen_filelist.pl -------------     
#
#
#-------------------------------------------------------

