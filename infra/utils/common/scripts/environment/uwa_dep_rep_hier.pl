#!/usr/bin/perl -w
##***********************************************************************
#* Script      : uwa_dep_rep_hier.pl                                    *
#* Description :                                                        * 
#*                                                                      * 
#* ---------------------------------------------------------------------*
#* Revision      number  : V00001                                       *
#*               added by: Amir Duvdevani                               *
#*               date    : at Thu Oct  3 09:17:14 IDT 2019              *
#*               description: first version released                    * 
#************************************************************************
#use lib '/project/infra/utils/common/test_env/scripts/environment/packages/';
use lib '/project/infra/utils/common/scripts/environment/packages/';
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
my $iScrip_version = "V00001";
my $sCommand = basename($0);
chomp($sCommand);
my $cmd = "";
my $s_project_name = "";
my $s_project_space = "";
my $s_log_message = "";
my $s_work_area_fullpath = "";
my $sScriptName        = $sCommand;
my $sUser_name         =  $ENV{USER}; 
my $b_block            =  0; 
my $b_cluster          =  0; 
my $b_top              =  0; 
my $bHelp              =  0; 
my $b_debug            =  0; 
my $i_bRelease         =  0; 
my $i_sWorkArea_name   =  ""; 
my $i_sBlock_name      =  ""; 
my $i_sTag_suffix_name =  ""; 
my $s_tag_level = "";
my $i_sTag_message     =  ""; 
my @l_all_hier_sub_blocks = ();
my @l_all_hier_sub_blocks_tmp = ();
my $s_new_string_tag = "";
my $s_curr_wa         = "";
my $s_curr_block_name = "";
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
# Usage : uwa_dep_rep_hier
#
sub ffnUsage { 
	if ($sCommand eq "uwa_dep_hier_rep") {
		print "\n";
		print "Usage: uwa_dep_hier_rep [-help|-h]\n"; 
		print "                                              \n";
		print "Description: generate hierarchy report for each block's child and report his tag version \n";
		print "             this script must be run directly under some of one block's folder in user project work area: \n";
		print "             \$UWA_PROJECT_ROOT/\$UWA_NAME/<block_name> \!\n";
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
        print color("red")."\n**************************************************\n";
        print color("red")."Script '$sCommand' Failed on Error:\n";
        print color("red")."$message\n";
        print color("red")."**************************************************\n";
        print color("reset")."";
        print "\n\t* Info: you can find log file '$sLogFile' \n\n";
        close(LOGFILE);
	exit 1;
  }	
  if ( $message =~ /Warning:/ ) {
        print color("red")."$message";
        print color("reset")."";
  }	

};# End sub fnPrintMessageOut
#----------------------------------------------------------
# Procedure:
# Description: 
#-------------
sub fnIncreaseTagVer {

	my ($s_blockCurrTagVer) = (@_);

	$s_new_string_tag = "";

	open(my $fh, '<:encoding(UTF-8)', $s_blockCurrTagVer)
	  or die "Could not open file '$s_blockCurrTagVer' $!";
	 
	while (my $row = <$fh>) {
	  chomp $row;
	  next if ($row eq "");
	  my $s_blockName = $i_sBlock_name;
		my $s_curr_tag_tmp = $row;
		$s_curr_tag_tmp =~ s/$s_blockName\_V//;
		my @l_curr_tag_tmp = split("\_",$s_curr_tag_tmp);
		$s_curr_tag_tmp = $l_curr_tag_tmp[0];
		$s_curr_tag_tmp =~ s/^0+//g ;
		$s_curr_tag_tmp++;
		my $s_new_tag = sprintf("%07d", $s_curr_tag_tmp);
		if ($i_sTag_suffix_name eq "") {
			$s_new_string_tag = "$s_blockName\_V$s_new_tag";	
		} else {
			$s_new_string_tag = "$s_blockName\_V$s_new_tag\_$i_sTag_suffix_name";	
		}
		close($fh);
		goto NEW_TAG_CREATED;
		
	}
	NEW_TAG_CREATED:

	return "$s_new_string_tag";

};# End sub fnIncreaseTagVer
#----------------------------------------------------------
# Procedure:
# Description: 
#-------------
sub fnUpdateAllDependsFileOfSubBlocks_withNewTag {

	my ($s_new_tag) = (@_);

	my $s_valid_row = 0; 

	chdir($s_work_area_fullpath);
	#foreach my ($s_curr_subBlock,$s_curr_subBlock_ver) (@l_all_hier_sub_blocks) {
        @l_all_hier_sub_blocks_tmp = @l_all_hier_sub_blocks;
	while( my($s_curr_subBlock,$s_curr_subBlock_ver,$s_sub_block_parent) = splice(@l_all_hier_sub_blocks_tmp,0,3)) {
		chdir($s_curr_subBlock);
		my $s_dep_listFile = "depends.list";
		if (-f "$s_dep_listFile") {
			
			open(my $fh_new, '>', "$s_dep_listFile\.new") or die "Could not open file '$s_dep_listFile\.new' $!";
			open(my $fh_dep, '<:encoding(UTF-8)', $s_dep_listFile)
			  or die "Could not open file '$s_dep_listFile' $!";
				 
			$s_valid_row = 0; 
			while (my $row = <$fh_dep>) {
			  chomp $row;
			  if (($row =~ /^\/\//) || ($row =~ /^\#/) || ($row eq "")) {		
				print $fh_new "$row\n";
				next;
			  }
			  my @l_row = split(" ",$row);
			  $s_valid_row = 1; 
			  printf $fh_new "%-35s %-35s\n",$l_row[0],$s_new_tag;
			}
			close($fh_new);
			close($fh_dep);
			if ($s_valid_row) {
				`mv $s_dep_listFile\.new $s_dep_listFile`; 
				print "Info: file updated '$s_dep_listFile' with the new version of tag\n";
				print LOGFILE "Info: file updated '$s_dep_listFile' with the new version of tag\n";
				`git commit -m \"at_git_commit: sub block tag version has been updated by user '$ENV{USER}'\" $s_dep_listFile 2>&1`;
				`git push 2>&1`;		
			} else {
				`\\rm -fr $s_dep_listFile\.new`; 
			}

		} else {
			print "Info: no such depend list file - '$s_dep_listFile' \n";
		}
	    chdir($s_work_area_fullpath);
	}

};# End sub fnUpdateAllDependsFileOfSubBlocks_withNewTag 
#----------------------------------------------------------
# Procedure:
# Description: 
#-------------
sub fnCreate_release_note {
	
	if ($b_debug) {print "Info: In fnCreate_release_note\n";}

	my $filename = "/tmp/release_note\_$$.txt";
	open(my $fh, '>>', $filename) or die "Could not open file '$filename' $!";
	printf $fh "#------------------------------------------------------------\n";
	printf $fh "# Release note for new tag '$s_new_string_tag'\n";
	printf $fh "# This tag built by the version of the following blocks:\n";
	printf $fh "#------------------------------------------------------------\n";
#	printf $fh "%-25s %-50s\n","Block_name","Tag_name";	
#	printf $fh "%-25s %-50s\n","----------","--------";	
#	foreach my $s_curr_subBlock (@l_all_hier_sub_blocks) {
#		chdir($s_curr_subBlock);
#		if (-f ".git_block_last_tag") {
#			my $s_curr_bl_tag = `cat .git_block_last_tag`; 
#			chomp($s_curr_bl_tag);
#			if ($b_debug) {
#				print "Info: write release note for block='$s_curr_subBlock' , tag ver='$s_curr_bl_tag'\n";
#			}
#			printf $fh "%-25s %-50s\n","$s_curr_subBlock","$s_curr_bl_tag";	
#		} else {
#			printf $fh "%-25s %-50s\n","$s_curr_subBlock","latest (not tagged yet)";	
#		}
#		chdir($s_work_area_fullpath);
#	}
	close $fh;

};# End sub fnCreate_release_note
#----------------------------------------------------------
# Procedure:
# Description: 
#-------------
sub fnCheckAllSubBlocksFilesCommited {

	my $s_curr_pwd = `pwd`;
	chomp($s_curr_pwd);

	if ($b_debug) {print "Info: In sub fnCheckAllSubBlocksFilesCommited \n";}

	chdir($s_work_area_fullpath);
	my $i_exit_status = 0;
	
	#foreach my ($s_curr_subBlock,$s_curr_subBlock_ver) (@l_all_hier_sub_blocks) {
	#while( my($s_curr_subBlock,$s_curr_subBlock_ver) = arrayeach(@l_all_hier_sub_blocks)) {
        @l_all_hier_sub_blocks_tmp = @l_all_hier_sub_blocks;
	while( my($s_curr_subBlock,$s_curr_subBlock_ver,$s_sub_block_parent) = splice(@l_all_hier_sub_blocks_tmp,0,3)) {
		next if ($s_curr_block_name ne "$s_curr_subBlock");
		if ($b_debug) {print "Info: curent block '$s_curr_subBlock'\n";}
		$i_exit_status = 0;
		chdir($s_curr_subBlock);
		#----------------------------
		# need to synch all HEAD blocks git tag vesrion file 
		my $s_all_tags_block = `git status \| grep git_block_last_tag`;
		my @l_all_tags_block = split("\n",$s_all_tags_block);
		foreach my $s_one_tagB (@l_all_tags_block) {
			my @l_one_tagB = split(" ",$s_one_tagB);
			my $s_curr_tag_block_f = $l_one_tagB[-1];
			`git checkout HEAD $s_curr_tag_block_f 2>&1`;
		}
		#----------------------------------
		# check that git status is clean
		# for each sub block before we are
		# going to tagging
		$cmd = `git status 2>&1`;
		if ($b_debug) {
			print "Info: git status'\n";
			print "      result: $cmd'\n";
		}
		if (($cmd =~ /\# Changes to be committed/) ) {
			print "Warning: you cannot create new tag \! ,because git status \n"; 	
			print "         is not clean under block '$s_curr_subBlock' \n"; 	
			print "         for create new tag the git status must be clean under this block \n"; 	
			print LOGFILE "Info: run command 'git status $s_curr_subBlock'\n";
			print LOGFILE "Result:\n";
			print LOGFILE "$cmd\n\n";
			print LOGFILE "Warning: you cannot create new tag \! ,because git status \n"; 	
			print LOGFILE "         is not clean under block '$s_curr_subBlock' \n"; 	
			print LOGFILE "         for create new tag the git status must be clean under this block \n"; 	
			$i_exit_status = 1;
		}
		if (!($cmd =~ /nothing to commit, working directory clean/)) {
			print "Warning: you cannot create new tag \! ,because git status \n"; 	
			print "         is not clean under block '$s_curr_subBlock' \n"; 	
			print "         for create new tag the git status must be clean under this block \n"; 	
			print LOGFILE "Info: run command 'git status $s_curr_subBlock'\n";
			print LOGFILE "Result:\n";
			print LOGFILE "$cmd\n\n";
			print LOGFILE "Warning: you cannot create new tag \! ,because git status \n"; 	
			print LOGFILE "         is not clean under block '$s_curr_subBlock' \n"; 	
			print LOGFILE "         for create new tag the git status must be clean under this block \n"; 	
			$i_exit_status = 1;
		}

		if ($i_exit_status) {
			$s_log_message = "\nError: git status is not clear for sub blocks \!\!\! \n         New tag creation is failed .\n\n";
			fnPrintMessageOut($s_log_message);
		}
		chdir($s_work_area_fullpath);

	};# check all blocks clean status

	#---------------------------------------------------
	# create release note to store all block's version
	# that comes before creating the new tag
	#fnCreate_release_note();
	#---------------------------------------------------

	#=================================================
	# generate the next new tag for the parent block 
	my $s_new_tag = "";
	#foreach my ($s_curr_subBlock,$s_curr_subBlock_ver)  (@l_all_hier_sub_blocks) {;# all is clean
	#while( my($s_curr_subBlock,$s_curr_subBlock_ver) = arrayeach(@l_all_hier_sub_blocks)) {
        @l_all_hier_sub_blocks_tmp = @l_all_hier_sub_blocks;
	while( my($s_curr_subBlock,$s_curr_subBlock_ver,$s_sub_block_parent) = splice(@l_all_hier_sub_blocks_tmp,0,3)) {
		# need to generate new (next) prefix tag name	
		# for each block
		chdir($s_curr_subBlock);
		if ($s_curr_subBlock ne "$i_sBlock_name"){;# create new tag only for parent block
			chdir($s_work_area_fullpath);
			next;	
		}
		#--------------------------------
		# get the last block tag
		# only tag that created under
		# parent block
		#-------------
		my @l_blocks_tag = `git tag`;
		my @l_curr_block_tags = ();
		foreach my $s_one_tag (@l_blocks_tag) {
			chomp($s_one_tag);
			if ( $s_one_tag =~ /^$i_sBlock_name/) {
				my $s_idx = $s_one_tag;
				$s_idx =~ s/^$i_sBlock_name\_V//;
				my @l_idx = split("_",$s_idx);
				$s_idx = $l_idx[0];
				push(@l_curr_block_tags,$s_idx);
			}
		}
		my $s_max_last_tag_exact = "";
		if (scalar(@l_curr_block_tags) > 0 ) {
			my @nums = sort { $a <=> $b } @l_curr_block_tags;
			my $s_max_last_tag = $nums[-1];
			foreach my $s_one_tag (@l_blocks_tag) {
				next if (!($s_one_tag =~ /^$i_sBlock_name\_V$s_max_last_tag/));
				$s_max_last_tag_exact = $s_one_tag;
			}
		}

		# last tag store $s_max_last_tag_exact

		if ((-f ".git_block_last_tag") && ($s_max_last_tag_exact ne "")) {
			system("echo \"$s_max_last_tag_exact\" > .git_block_last_tag");
			print LOGFILE "Info: block's last tag was '$s_max_last_tag_exact'\n\n";
			$s_new_tag = fnIncreaseTagVer(".git_block_last_tag");
		} else {;# first time 
			my $s_newTag = "$s_curr_subBlock\_V0000001";
			if ($i_sTag_suffix_name ne "") {
				$s_newTag = "$s_curr_subBlock\_V0000001_$i_sTag_suffix_name";
			}
			$s_new_tag = "$s_newTag";
			#system("echo \"$s_new_tag\" > .git_block_last_tag");
		}
		#---------------------------------------------------
		# create release note to store all block's version
		# that comes before creating the new tag
		$s_new_string_tag = $s_new_tag;
		fnCreate_release_note();
		#---------------------------------------------------
		chdir($s_curr_subBlock);
		system("echo \"$s_new_tag\" > .git_block_last_tag");

		`git add .git_block_last_tag 2>&1`;
		`git commit -m \"at_git_commit: new tag created $s_new_tag by user '$ENV{USER}'\" .git_block_last_tag 2>&1`;

		print LOGFILE "Info: new tag has been created '$s_new_tag'\n\n";
		print "Info: new tag has been created '$s_new_tag'\n\n";

		if (-f "/tmp/release_note\_$$.txt") {
			if (-f "depends.list") {
				`cat depends.list >> /tmp/release_note\_$$.txt`;
			}
			`cp /tmp/release_note\_$$.txt pre-release_note.txt`; 
		}
		if (-f "pre-release_note.txt") {
			if ($b_debug) {print "Info: commit file '/$s_curr_subBlock/pre-release_note.txt'\n";}
			`git add pre-release_note.txt 2>&1`;
			`git commit -m \"at_git_commit: add pre release note for tag '$s_new_tag' ,done by $ENV{USER}\" pre-release_note.txt 2>&1`;
		}
		# push to all
		my $cmd_r = "git push origin master 2\>\&1";
		if (system($cmd_r) != 0) {
			die "system '$cmd_r' failed: $?";
		}

		#fnUpdateAllDependsFileOfSubBlocks_withNewTag("$s_new_tag"); 
		chdir($s_curr_subBlock);
		`git tag -a \"$s_new_tag\" -m \"new tag released '$s_new_tag' for block '$i_sBlock_name'\" 2>&1`; 		
		`git push -u origin master 2>&1`;
		`git push origin --tags 2>&1`;

		chdir($s_work_area_fullpath);

	};# generate the next new tag for parent block and push
	#=================================================
	#
	# now create the same tags to all child
        #
#	foreach my $s_curr_subBlock (@l_all_hier_sub_blocks) {;# all is clean
#		next if ($s_curr_subBlock eq "$i_sBlock_name");# create new tag for all child
#		chdir($s_curr_subBlock);
#		system("echo \"$s_new_tag\" > .git_block_last_tag");
#		`git add .git_block_last_tag 2>&1`;
#		`git commit -m \"at_git_commit: new tag created\" .git_block_last_tag 2>&1`;
#
#		if (-f "/tmp/release_note\_$$.txt") {
#			`cp /tmp/release_note\_$$.txt pre-release_note.txt`; 
#		}
#		if (-f "pre-release_note.txt") {
#			if ($b_debug) {print "Info: commit file '/$s_curr_subBlock/pre-release_note.txt'\n";}
#			`git add pre-release_note.txt 2>&1`;
#			`git commit -m \"at_git_commit: add pre release note for tag '$s_new_tag' ,done by $ENV{USER}\" pre-release_note.txt 2>&1`;
##		}
#
#		`git push origin master 2>&1`;
#		print LOGFILE "Info: new tag has been created '$s_new_tag' for child '$s_curr_subBlock'\n\n";
#		print "Info: new tag has been created '$s_new_tag' for child '$s_curr_subBlock'\n\n";
#
#		`git tag -a \"$s_new_tag\" -m \"new tag released '$s_new_tag' for block '$i_sBlock_name'\" 2>&1`; 		
#		`git push -u origin master 2>&1`;
#		`git push origin --tags 2>&1`;
#
#		chdir($s_work_area_fullpath);
#
#	};# create new tags to all child + commit & push
	#=================================================

	# update all depends.list with the last tag
        #fnUpdateAllDependsFileOfSubBlocks_withNewTag("$s_new_tag"); 

	chdir($s_curr_pwd);

};# End sub fnCheckAllSubBlocksFilesCommited
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
        my @l_row = split(" ",$row);
        next unless my ($setenv ,$var, $value) = (@l_row);
        $ENV{$var} = $value;
    }
}
#----------------------------------------------------------
# Procedure:
# Description: 
#-------------
sub fnCreateGenFileList {

	my ($i_sTopCluster_name,$s_new_string_tag) = (@_);

	my $s_currPWD = `pwd`;
	chomp($s_currPWD);

	my $s_release_fullPath = "$s_currPWD/$s_new_string_tag";
	chdir($s_new_string_tag);
	`gen_filelist -b $i_sTopCluster_name -l`;

	if (-f "./$i_sTopCluster_name\.list") {
		`mv ./$i_sTopCluster_name\.list $i_sTopCluster_name/.`;
	}
	
	chdir($s_currPWD);

};# End sub fnCreateGenFileList 
#----------------------------------------------------------
# Procedure:   fnCheckIfBlocksVersionReleased
# Description: check if block's tag released to
#              
#-------------
sub fnCheckIfBlocksVersionReleased {

	my $s_user_release_root_area = uc("$s_project_name\_RELEASE_AREA");
        @l_all_hier_sub_blocks_tmp = @l_all_hier_sub_blocks;
	while( my($s_one_sub_block,$s_one_sub_block_ver,$s_sub_block_parent) = splice(@l_all_hier_sub_blocks_tmp,0,3)) {
		next if ($s_one_sub_block_ver eq "head");
		next if ($s_one_sub_block eq "$i_sBlock_name");
		if (!(-d "$ENV{$s_user_release_root_area}/$s_one_sub_block/$s_one_sub_block_ver")) {
			$s_log_message = "\nError: no such release '$s_one_sub_block_ver' for block '$s_one_sub_block' \n\t under '\$$s_user_release_root_area'\n\n";
			fnPrintMessageOut($s_log_message);
		}
	}

};# End sub fnCheckIfBlocksVersionReleased
#----------------------------------------------------------
# Procedure:   fnCheckIfRunDirIsUnderBlocksProjectDir
# Description: Check if user under project area
#-------------
sub fnCheckIfRunDirIsUnderBlocksProjectDir {

	my $s_current_dir = `pwd`;
	chomp($s_current_dir);

	if (!($s_current_dir =~ /$ENV{UWA_PROJECT_ROOT}/)) {;# must be under project home
		print "\nWarning: you must run it under '$ENV{UWA_PROJECT_ROOT}/<work_area>/<block_name>' folder\!\!\!\n";
		exit 0;
	} 
	$s_current_dir =~ s/$ENV{UWA_PROJECT_ROOT}//;
	$s_current_dir =~ s/^\///;

	if (length($s_current_dir) > 0) {
		my @l_up_dirs = split("\/",$s_current_dir);
		if (scalar(@l_up_dirs) > 1 ) {
			$s_curr_wa = $l_up_dirs[0]; 
			$s_curr_block_name = $l_up_dirs[1]; 
			chdir("$ENV{UWA_PROJECT_ROOT}/$s_curr_wa/$s_curr_block_name");
		} else {
			print "\nWarning: you must run it under '$ENV{UWA_PROJECT_ROOT}/<work_area>/<block_name>' folder\!\!\!\n";
			exit 0;
		}
	} else {
		print "\nWarning: you must run it under '$ENV{UWA_PROJECT_ROOT}/<work_area>/<block_name>' folder\!\!\!\n";
		exit 0;
	}

};# End sub fnCheckIfRunDirIsUnderBlocksProjectDir
#---------------------------------------------------------------------------
#
#
#     ---------- MAIN   'uwa_dep_rep_hier' -----------------------
#
#
#---------------------------------------------------------------------------
        if (not(&GetOptions('b!'       => \$b_block   ,
			    'c!'       => \$b_cluster   ,
			    't!'       => \$b_top   ,
			    's=s'      => \$i_sTag_suffix_name   ,
			    'm=s'      => \$i_sTag_message   ,
			    'rel!'     => \$i_bRelease   ,
			    'debug!'   => \$b_debug   ,
                            'help!'    => \$bHelp     )) || $bHelp ) {
          &ffnUsage;
        }
        #=============================================
        # check args validation 
        #-----
	if (!(defined $ENV{PROJECT_NAME}) || !(defined $ENV{PROJECT_HOME}) || !(defined $ENV{GIT_PROJECT_ROOT}) ) {
		print "\nWarning: you must run 'setup_proj' command before \!\!\!\n\n";	
		exit 0;
	}
	$s_project_name = $ENV{PROJECT_NAME};
	$s_project_space = $ENV{UWA_SPACE_ROOT};
        if ($bHelp) { &ffnUsage; }	
	print "\n\n--------------\n";
	print "  uwa_dep_rep_hier \n";
	print "--------------\n";
	print LOGFILE  "\n\n--------------\n";
	print LOGFILE  "  uwa_dep_rep_hier \n";
	print LOGFILE  "--------------\n";


	fnCheckIfRunDirIsUnderBlocksProjectDir();

	if (-f "$ENV{UWA_SPACE_ROOT}/$s_curr_wa/usr_setup_path") {
                source "$ENV{UWA_SPACE_ROOT}/$s_curr_wa/usr_setup_path";
		$i_sWorkArea_name = $ENV{UWA_NAME};
	} else {
		print "\nWarning: you must run this script directly under block's folder in user work area \!\n\n"; 
		close(LOGFILE);
		exit 0;	
	}

        #=============================================
	# set init variable
	#--------
        $s_tag_level = "";
        if ($b_block)   { $s_tag_level = "block";}
        if ($b_cluster) { $s_tag_level = "cluster";}
        if ($b_top)     { $s_tag_level = "top";}
	
	$i_sBlock_name = $s_curr_block_name;
	$i_sWorkArea_name = $s_curr_wa;

	my $s_proj_rev = basename($ENV{PROJECT_HOME});	
	$s_work_area_fullpath = "/space/users/$ENV{USER}/$ENV{PROJECT_NAME}\_$s_proj_rev/$i_sWorkArea_name/project";
	if (!(-d "$s_work_area_fullpath")) {
		print "\nWarning: no such folder '$s_work_area_fullpath' \!\!\! \n\n";
		exit 0;
	}
	if (!(-d "$s_work_area_fullpath/$i_sBlock_name")) {
		print "\nWarning: no such block name folder '$s_work_area_fullpath/$i_sBlock_name' \!\!\! \n\n";
		exit 0;
	}

	my $s_curr_dir = `pwd`;
        chomp($s_curr_dir);
        close(LOGFILE);
        #=============================================
	# get all child sub block list 
	# to check if all their files are 
	# committed to git repo
        my $s_all_hier_sub_blocks = "";
	my $s_user_release_root_area = uc("$s_project_name\_USER_RELEASE_AREA");
	$s_all_hier_sub_blocks = fnGet_all_hier_child_depends_list_new("$s_work_area_fullpath/$i_sBlock_name",$sLogFile,"$s_all_hier_sub_blocks");
	open LOGFILE, ">>$sLogFile" or die "cannot open file $sLogFile : $!\n";
        @l_all_hier_sub_blocks = split(" ",$s_all_hier_sub_blocks); 
	fnCheckIfBlocksVersionReleased();
        @l_all_hier_sub_blocks_tmp = @l_all_hier_sub_blocks;
        print "\n=========================================\n";
        print "Info: All sub blocks \n";
        print "      under '$i_sBlock_name'\n";
        print "-------------------------\n";
        print LOGFILE "\n=========================================\n";
        print LOGFILE "Info: All sub blocks \n";
        print LOGFILE "      under '$i_sBlock_name'\n";
        print LOGFILE "-------------------------\n";
	if (scalar(@l_all_hier_sub_blocks) < 2) {
		print "      *** NO sub block defined ***\n";
		print LOGFILE "      *** NO sub block defined ***\n";
		print "\n=========================================\n";
		print LOGFILE "\n=========================================\n";
		goto END_PROC;
	}
	#foreach my ($s_one_sub_block,$s_one_sub_block_ver) (@l_all_hier_sub_blocks) {
	printf "%-25s %-40s %-25s\n","Block_name","Block's_tag","Block's_parent";
	printf "%-25s %-40s %-25s\n","--------------------","--------------------","--------------------";
	printf LOGFILE "%-25s %-40s %-25s\n","Block_name","Block's_tag","Block's_parent";
	printf LOGFILE "%-25s %-40s %-25s\n","--------------------","--------------------","--------------------";
	my @l_all_blocks_path = ();
	while( my($s_one_sub_block,$s_one_sub_block_ver,$s_sub_block_parent) = splice(@l_all_hier_sub_blocks_tmp,0,3)) {
		next if ($s_one_sub_block_ver eq "head");
		#next if ($s_one_sub_block eq "$i_sBlock_name");
		next if ($s_one_sub_block_ver eq "head");
		printf "%-25s %-40s %-25s\n",$s_one_sub_block,$s_one_sub_block_ver,$s_sub_block_parent;
		printf LOGFILE "%-25s %-40s %-25s\n",$s_one_sub_block,$s_one_sub_block_ver,$s_sub_block_parent;
		#-------------------------------------------------------------
		# check contradiction 
		if (scalar(@l_all_blocks_path) == 0 ) {
			push(@l_all_blocks_path,$s_one_sub_block);
			push(@l_all_blocks_path,$s_one_sub_block_ver);
			push(@l_all_blocks_path,$s_sub_block_parent);
		} else {
			my $s_exist_flag = 0;
			my @l_all_blocks_path_tmp = @l_all_blocks_path;	
			while( my($s_curr_block_name,$s_curr_block_path,$s_curr_block_parent) = splice(@l_all_blocks_path_tmp,0,3)) {
				if ($s_curr_block_name eq "$s_one_sub_block") {
					$s_exist_flag = 1;
					if ($s_curr_block_path ne "$s_one_sub_block_ver") {
						$s_log_message = "Error: contradiction block '$s_curr_block_name' assigned twice \n\t with different versions \n\t 1) '$s_curr_block_path' under parent $s_curr_block_parent \n\t 2) '$s_one_sub_block_ver' under parent $s_sub_block_parent";
						fnPrintMessageOut($s_log_message);
					}
				}
			}
			if (!($s_exist_flag)) {
				push(@l_all_blocks_path,$s_one_sub_block);
				push(@l_all_blocks_path,$s_one_sub_block_ver);
				push(@l_all_blocks_path,$s_sub_block_parent);
			}
		}
		#-------------------------------------------------------------
	}
        print "\n=========================================\n";
        print LOGFILE "\n=========================================\n";

	#===============================================================
        FINISHED_SUCCESS:
	print LOGFILE  "\n\n--------------------------------------------------------------\n";
	print LOGFILE  "  uwa_dep_rep_hier finished successfully !!!\n";
	print LOGFILE  "  work area folder is ready under '$s_work_area_fullpath'. \n";
	print LOGFILE  "--------------------------------------------------------------\n";
	print color("green")."\n\n--------------------------------------------------------------\n";
	print color("green")."  uwa_dep_rep_hier finished successfully !!!\n";
	print color("green")."  work area folder is ready under '$s_work_area_fullpath'. \n";
	print color("green")."--------------------------------------------------------------\n";
        print color("reset")."";
	
        print "\n\n\t* Info: you can find log file '$sLogFile' \n\n";

	END_PROC:
        close(LOGFILE);
        exit 0;

#-------------------------------------------------------
#
#
#         --------   END  uwa_dep_rep_hier.pl -------------     
#
#
#---------------------------------------------------

