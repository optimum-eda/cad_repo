#!/usr/bin/perl -w
##***********************************************************************
#*                                                                      * 
#* Script name : uwa_create.pl                                          * 
#*                                                                      * 
#*                                                                      * 
#* Description                                                          * 
#*                                                                      * 
#* Revision V00001                                                      * 
#*                                                                      * 
#*                                                                      * 
#*                                                                      * 
#*                                                                      * 
#*                                                                      * 
#*------------------------------------                                  * 
#* updated by AmirD : V00003                                            * 
#* date             : Wed Jul 17 17:53:18 IDT 2019                      * 
#* description      : added the git hook to work area env               * 
#*------------------------------------                                  * 
#* updated by AmirD : V00004                                            * 
#* date             : Mon Sep  2 18:04:53 IDT 2019                      *
#* description      : - changed the work with GitLab to Bitbocket       *
#*                    - changed the work flow with one Git repo for     * 
#*                      craton3 project to multi repositories for one   *
#*                      project, each repository per block              *
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
my $iScrip_version = "V00004";
my $sCommand = basename($0);
chomp($sCommand);
my $s_new_block_index = 0;
my $aProject_dir_struct;
my $sUWApath = "";
my $cmd = "";
my $sScriptName        = $sCommand;
my $sUser_name         =  $ENV{USER}; 
my $sTop_dir_name      = "";
my $sBlock_name        =  "";
my $sWorkArea_name     =  "";
my $sTop_name          = ""; 
my $sCluster_name      = ""; 
my $b_newBlock         = 0; 
my $b_debug            = 0; 
my $b_no_dep           = 0; 
my $b_branch           = 0; 
my $s_contradiction_flag = 0;
my $sRevision_number   = "git_head"; # git head of tree 
my $sPre_release_depList = ""    ; # block's depends.list that following the child tag
                                 ; # version we build the user work area   
my $s_ref_top_dependList = "";
my $bHelp              =  0; 
my $sBlockCluster_name = "";
my $s_project_dir      = "";
my $s_curr_space_dir      = "";
my @l_all_hier_sub_blocks = ();
my @l_inp_depens_child     = ();
my @l_inp_depens_child_ver = ();
my $s_log_message   = "";
my $s_project_name  = "";
my $s_project_nameUP = "";
my $s_proj_rev      = "";
my @l_all_blocks_path_in_usr = ();
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
	if ($sCommand eq "uwa_create") {
		print "\n";
		print "Usage: uwa_create -wa <work_area_name> [-t <top> | -c <cluster> | -b <block>] [-r <revision_number>] [-pre <depends.list>]\n"; 
		print "                       -wa <work_area_name>   # work area name that should be created under local directory\n";
		print "					      # that should contains project's blocks git repo directories structure\n";
		print "                       -t <top_name>          # create a work area for this current top and his hierarchy sub clusters\n";
		print "                       -c <cluster_name>      # create a work area for this current cluster and his hierarchy sub blocks\n";
		print "                       -b <block_name>        # create a work area for this current block and his hierarchy sub blocks\n";
		print "                                              # for block level option the work area created directly from git repository\n";
		print "                                              # checkout block and his sub blocks latest vesrion from git to user work area.\n";
		print "                       [-new]                 # create skelaton of mandatory directories for new top/cluster/block that not exist yet\n";
		print "                                              # under git repository. This option should run only after the UWA is alraedy exist\n";
		print "                       [-r <revision_number>] # checkout the block/cluster/top tag revision number under UWA\n";
		print "                                              # 1) default is latest of block's version under '\$\{PROJECT_NAME\}_RELEASE_AREA'\n";
		print "                                              #    in this stage the script checkout the origin HEAD to user WA and after checkout\n";
		print "                                              #    the tag version that latest symboliclink point to \n"; 
		print "                                              #    * if latest symboliclink was not exist for block,the script only checkout origin HEAD\n"; 
		print "                                              # 2) for option '-revision <rev_name>' the script checkout origin HEAD to user WA \n";  
		print "                                              #    and after checkout the tag revison\n";
		print "                       [-branch]              # checked out block and Instead of pointing the newly created HEAD \n";
		print "                                              #    to the branch pointed to by the cloned repository's\n";
		print "                                              #    HEAD, point to <name> branch instead. In a non-bare repository, \n";
		print "                                              #    this is the branch that will be checked out.\n";
		print "                       [-pre <depends.list>]  # full path to depends.list file ,prepare pre-release user work area \n";
		print "                                              # following block's tag version in depends.lis file\n"; 
		print "                       [-no_dep]              # checkout the block to UWA and not refer to the existence of his depense.list file \n";
		print "                       [ -help | -h ]         # print script usage\n"; 
		print "  \n";
		print "Description: create user work area under \$UWA_PROJECT_ROOT with name '-wa <work_area_name>' for project \$PROJCT_NAME\n";
		print "	     checkout top/cluster/block following the revision into local user work area \n";
		print "	     - if version is latest (default) we set the child blocks path to look on last \n";  
		print "	       last block's release under global \$$ENV{PROJECT_NAME}\_RELEASE_AREA work area\n";  
		print "	     - if version is not latest we set the child blocks path to look on specific \n";
		print "	       block's release verison under global \$$ENV{PROJECT_NAME}\_RELEASE_AREA work area\n";
		print "  \n";
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
# Procedure: fnHide_notStagedForCommit_message 
# Description: 
#-------------
sub fnHide_notStagedForCommit_message {

	  my $s_last_line = "";
	  my $s_last_use_inline = "";
	  my $s_last_not_staged_inline = "";
	  foreach my $s_line (@_) {
		chomp($s_line);
		if ($s_last_not_staged_inline =~ /Changes not staged for commit/) {
			if ($s_line =~ /\(use/) { 
				if ($s_last_use_inline eq "use passed") {;# new section after 'Changes not staged for commit'
					print STDOUT "$s_last_line\n";
					print STDOUT "$s_line\n";
					$s_last_line = $s_line;
					$s_last_use_inline = "";
				        $s_last_not_staged_inline = "";
				}	
				$s_last_use_inline = "use";
			} else {
				$s_last_use_inline = "use passed";
			}
			$s_last_line = $s_line ;next;
		}	
		if ($s_line =~ /Changes not staged for commit/) {$s_last_not_staged_inline = $s_line;$s_last_line = $s_line ;next;}	
		print STDOUT "$s_line\n";
		$s_last_line = $s_line;
	  }

};# End sub fnHide_notStagedForCommit_message
#----------------------------------------------------------
# Procedure: fnHide_Unstaged_changes_after_reset 
# Description: 
#-------------
sub fnHide_Unstaged_changes_after_reset {

	  my $i_last_line = 0; 
	  foreach my $s_line (@_) {
		chomp($s_line);
		if ($s_line =~ /Unstaged changes after reset/) {
			$i_last_line = 1; 
		} 
		if ($i_last_line == 0 ) {print STDOUT "$s_line\n";}	
	  }

};# End sub fnHide_Unstaged_changes_after_reset
#----------------------------------------------------------
# Procedure:
#
# Description: load perl hash skelaton with definition of 
#              block/cluster directory structure 
#-------------
sub fnLoadProjectDirStructure {

  my $projectDirStr ;
  # Read structure 
  if (!($s_new_block_index)) {
	  $projectDirStr = "$ENV{PROJECT_HOME}/$ENV{PROJECT_NAME}\_dir_structure_new_block.pm";	
	  `cp $projectDirStr /tmp/uwa_create.$ENV{USER}.$$`;
           $projectDirStr = "/tmp/uwa_create.$ENV{USER}.$$";

	   if ($sBlock_name ne "")  { 
		`cat $projectDirStr \| sed -e s/NEW_BLOCK/$sBlock_name/ > $projectDirStr\_$$`;
	   } 
	   if ($sCluster_name ne "")  { 
		`cat $projectDirStr \| sed -e s/NEW_BLOCK/$sCluster_name/ > $projectDirStr\_$$`;
	   }
	   if ($sTop_name ne "")  { 
		`cat $projectDirStr \| sed -e s/NEW_BLOCK/$sTop_name/ > $projectDirStr\_$$`;
	   }
           $projectDirStr = "$projectDirStr\_$$";
	    
  } else {
	  $projectDirStr = "$ENV{PROJECT_HOME}/$ENV{PROJECT_NAME}\_dir_structure.pm";	
  }
  if (-f $projectDirStr) {
          open my $in, '<', $projectDirStr or die $!;
          {
              local $/;    # slurp mode
              $aProject_dir_struct = eval <$in>;
          }
          close $in;
  } else {
          print "\nError: Cannot find project directory structure file '$projectDirStr' !!!\n\n";
          exit 1;
  }

} # End sub fnLoadProjectDirStructure
#----------------------------------------------------------
#
# Procedure: fnCreateUWAfollowProjStructure
#
# Description: read & create the project data structure 
#              under user work area 
#
#----------------------------------------------------------
sub fnCreateUWAfollowProjStructure {

  my %copied_hash = %{ $aProject_dir_struct };

  #--------------------------------------
  # Check if project's user workarea exist        
  $sUWApath = `pwd`;
  chomp($sUWApath);

  $sUWApath = "$sUWApath/$sWorkArea_name";
	
  if ($b_debug) { 
	print "Info: In sub fnCreateUWAfollowProjStructure \n";
	print "Info: current dir '$sUWApath'\n";
  }
  if (!(-d $sUWApath)) {
    $cmd = "mkdir -p $sUWApath";
    fnRunSysCMD($cmd); 
    print LOGFILE  "\nInfo: UWA folder created '$sUWApath'\n\n";        
  }    
  my $sSetFile = "/tmp/set_UWA_NAME_var$sUser_name\_$$.log";
  if (-f $sSetFile) {
    #system("rm -f $sSetFile");
  }
  my $sDir_block_folder = "";
  my $sDir_block_level1 =  "";
  my $sDir_block_level2 =  "";
  my $sDir_block_level3 =  "";
  my $sDir_block_level4 =  "";
  my $sDir_block_level5 =  "";
  my $sDir_block_level6 =  "";
  my $iBlockExist_flag  = 0;

  foreach my $top_name (sort keys %copied_hash) {
    $iBlockExist_flag  = 0;
    my @keys  = (keys %{ $copied_hash{$top_name} }) ;
    if (scalar(@keys) == 0 ) {
      $sDir_block_folder =  "$sUWApath/$top_name";   
      fnMkdirIfNotExist($sDir_block_folder,$top_name); 
    } else {
      #------------        
      # check if default mode or top_name is equal to input top        
      if (($sTop_dir_name eq "" ) || ($sTop_dir_name eq $top_name )) {
        foreach my $block_name (keys %{ $copied_hash{$top_name} }) {
          if (($sBlock_name ne "" ) && ($block_name eq $sBlock_name )) {
            $iBlockExist_flag  = 1;
          }
          if ($block_name eq "block_level"){
	    foreach my $item ($copied_hash{$top_name}{$block_name}){
                if(ref($item) eq 'ARRAY') {
                  $sDir_block_folder =  "$sUWApath/$top_name/$block_name";   
                  #It's an array reference...
                  my @dirL = @{$copied_hash{$top_name}{$block_name}};	
                  foreach my $ldir (@dirL) {
                    if (ref($ldir) eq 'ARRAY') {
                      my @folderList = @{$ldir};
                      foreach my $folder2 (@folderList) {
                        if (ref($folder2) eq 'ARRAY') {
                          my @folderList2 = @{$folder2};
                          foreach my $folder3 (@folderList2) {
				if (ref($folder3) eq 'ARRAY') {
				  my @folderList3 = @{$folder3};
				  foreach my $folder4 (@folderList3) {
					if (ref($folder4) eq 'ARRAY') {
					  my @folderList4 = @{$folder4};
					  foreach my $folder5 (@folderList4) {
						if (ref($folder5) eq 'ARRAY') {
						  my @folderList5 = @{$folder5};
						} else {
						    $sDir_block_level6 =  "$sDir_block_level5/$folder5";   
						    fnMkdirIfNotExist($sDir_block_level6,$top_name); 
						}
					  }
					} else {
					    $sDir_block_level5 =  "$sDir_block_level4/$folder4";   
					    fnMkdirIfNotExist($sDir_block_level5,$top_name); 
					}
				  }
				} else {
				    $sDir_block_level4 =  "$sDir_block_level3/$folder3";   
				    fnMkdirIfNotExist($sDir_block_level4,$top_name); 
				}
                          }
                        } else {
                          #not an array in any way...
                          $sDir_block_level3 =  "$sDir_block_level2/$folder2";   
                          fnMkdirIfNotExist($sDir_block_level3,$top_name); 
                        }
                      }
                    } else {
                      #not an array in any way...
		      my $sTmp_sDir_block_folder = $sDir_block_folder;
		      $sTmp_sDir_block_folder =~ s/block_level\///;
		      $sTmp_sDir_block_folder =~ s/block_level//;
		      if (!(-d "$sTmp_sDir_block_folder")) {
				`mkdir -p $sTmp_sDir_block_folder`;
		      }	
                      my $s_depends_file = "$sTmp_sDir_block_folder/depends.list";
		      $s_depends_file =~ s/\/\//\//;
		      if (!(-f $s_depends_file)) {
				`touch $s_depends_file`;
				`echo \"#----------------------------------------------\" >> $s_depends_file`;
				`echo \"# Depends list for block '$top_name' \" >> $s_depends_file`;
				`echo \"#----------------------------------------------\" >> $s_depends_file`;
				`echo \"# Block_name                        Tag_name \" >> $s_depends_file`;
		      }
		      $sDir_block_level2 =  "$sDir_block_folder/$ldir";   
		      fnMkdirIfNotExist($sDir_block_level2,$top_name); 
                    }
                  }
                } else {
                  #not an array in any way...
                  $sDir_block_level1 =  "$sUWApath/$top_name/$block_name";   
                  fnMkdirIfNotExist($sDir_block_level1,$top_name); 
              }
            }
            $sDir_block_folder =  "$sUWApath/$top_name";   
	    fnMkdirIfNotExist($sDir_block_folder,$top_name); 
            next;
          }
          next if ($block_name eq "");
          #------------        
          # check if default mode or block_name is equal to input block        
        } # block_name loop 

      } # if top_name
    } # if top_name empty
  } # top_nam loop

} # End sub fnCreateUWAfollowProjStructure
#----------------------------------------------------------
#
# Procedure: fnMkdirIfNotExist
#
# Description: create folder if not exist
#
#----------------------------------------------------------
sub fnMkdirIfNotExist {

  my ($sDirToMake,$top_name) = (@_);
  if ($b_debug) { 
	print "Info: In sub fnMkdirIfNotExist \n";
	print "Info: sDirToMake='$sDirToMake'\n";
	print "Info: top_name  ='$top_name'\n";
  }	
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
# Procedure: fnGet_all_child_hier_depends_list
# Description: get a list of all child depend list 
#-------------
sub fnGet_all_child_hier_depends_list {

	my ($sRlease_path,$s_uwa_root) = (@_);
	my $sRelease_work_area      = "";
	my $sCurrent_block_version  = "";
	my $sCurrent_block          = "";
	if ($sRlease_path =~ /$sWorkArea_name/) {
		$sRelease_work_area      = dirname($sRlease_path);
		$sCurrent_block          = basename($sRlease_path);
		$sCurrent_block_version  = "latest";
	} else {
		$sRelease_work_area      = dirname($sRlease_path);
		$sCurrent_block_version  = basename($sRlease_path);
		$sCurrent_block          = basename($sRelease_work_area);
	}
	#------------------------------------------
	# check block's repository exist under Git
	my $s_block_repo = 1; ;# default is exist
	my $sProj_gitignore_files = `git ls-remote $ENV{GIT_PROJECT_ROOT}/$sCurrent_block\.git \| grep HEAD`;
	print LOGFILE "Info: cmd 'git ls-remote $ENV{GIT_PROJECT_ROOT}/$sCurrent_block\.git \| grep HEAD'\n";
	#print "Info: cmd 'git ls-remote $ENV{GIT_PROJECT_ROOT}/$sCurrent_block\.git \| grep HEAD'\n";
	my @lProj_gitignore_files = split("\n",$sProj_gitignore_files);
	foreach my $one_gitignore_file (@lProj_gitignore_files) {
		if (  $one_gitignore_file =~ /Repository not found/) {
			print "Error: 'git ls-remote $ENV{GIT_PROJECT_ROOT}/$sCurrent_block\.git \| grep HEAD'\n";
			print LOGFILE "Error: 'git ls-remote $ENV{GIT_PROJECT_ROOT}/$sCurrent_block\.git \| grep HEAD'\n";
			$s_block_repo = 0;
		}
	}
	
	if ($s_block_repo == 0) { # block exist in git depo
		print "\nWarning: no such block's repository under GIT '$ENV{GIT_PROJECT_ROOT}/$sCurrent_block\.git' \!\!\!\n\n";
		print LOGFILE "\nWarning: no such block's repository under GIT '$ENV{GIT_PROJECT_ROOT}/$sCurrent_block\.git' \!\!\!\n\n";
		chdir($s_curr_space_dir);
		#`\\rm -fr $sWorkArea_name`; # remove work area that not completed
		if (-d "$s_project_dir/$sWorkArea_name") {
			#`\\rm -fr $s_project_dir/$sWorkArea_name`;
		}
		close(LOGFILE);
		exit 0;
	}
	#------------------------------------------
	# check if this run with is on block level design
	# if yes , need to checkout to local user work area
	if (($sBlock_name ne "") && ($b_newBlock == 0 )) {
		#$sCurrent_block = $sCurrent_block_version;# only for user worka area	
		if (!(-d "$s_uwa_root/$sCurrent_block")) {
			if ($sPre_release_depList eq "") {;# if not pre release option
				$cmd = "git clone $ENV{GIT_PROJECT_ROOT}/$sCurrent_block\.git $s_uwa_root/$sCurrent_block";
				print LOGFILE "Info: cmd '$cmd'\n";
				fnRunSysCMD($cmd); 
				$cmd = "cp /project/infra/utils/common/scripts/git/prepare-commit-msg $s_uwa_root/$sCurrent_block/.git/hooks/.";
				fnRunSysCMD($cmd); 
			} else {;# checkout the branch 
			} 
		}
	}

	push(@l_all_hier_sub_blocks,"$sCurrent_block $sCurrent_block_version");
	if (-f "$sRlease_path/depends.list") {
		my $sDep_filename = "$sRlease_path/depends.list";
		open(my $fh_dep, '<:encoding(UTF-8)', $sDep_filename)
		  or die "Could not open file '$sDep_filename' $!";
		 
		while (my $row = <$fh_dep>) {
		  chomp $row;
	          next if($row =~ /^\/\//);		
	          next if($row =~ /^\#/);		
		  my @l_row = split(" ",$row);
		  #$sRelease_work_area = dirname(dirname($sRlease_path));	 
		  $sRelease_work_area = $ENV{"$s_project_nameUP\_RELEASE_AREA"};
                  my $sChild_folder = "$sRelease_work_area/$l_row[0]";
		  my $sChild_ver_folder = "";
		  if (scalar(@l_row) > 1 ) {
			  $sChild_ver_folder = "$l_row[1]";
		  } else {
			#$sChild_ver_folder = "latest";# empty is like default 'latest'
			$s_log_message = "Error: the block '$l_row[0]' tag version in depends list cannot be with empty\!\!\!\n\n*** You can run the uwa_create with -no_dep option that ignore the option to look on depens.list file\n";
			fnPrintMessageOut($s_log_message);
		  }
		  $sChild_ver_folder = "$sChild_folder/$sChild_ver_folder";

		  fnGet_all_child_hier_depends_list($sChild_ver_folder,$s_uwa_root);
		}
	} else {
		print "Info: no such depend list file - '$sRlease_path/depends.list' \n";
	}
};# End sub fnGet_all_child_hier_depends_list
#----------------------------------------------------------
# Procedure: fnCheckDuplications
# Description: check duplication in usr_setup_path
#-------------
sub fnCheckDuplications {

	my ($filename) = (@_);

	my $s_blocks_path = `grep setenv $filename \|grep _path`;	
	my @l_blocks_path = split("\n",$s_blocks_path);

	my $s_block_name ;
	my @l_one_block_path = ();
	my @l_all_blocks_path = ();
	my $s_block_path ;
	foreach my $s_one_block_path (@l_blocks_path) {
	        @l_one_block_path = split(" ",$s_one_block_path); 	
		my $s_sc = scalar(@l_one_block_path);
		next if ($s_sc < 3);
		$s_block_name = $l_one_block_path[1];
		$s_block_path = $l_one_block_path[2];
		if (scalar(@l_all_blocks_path) == 0 ) {
			push(@l_all_blocks_path,$s_block_name);
			push(@l_all_blocks_path,$s_block_path);
		} else {
			my $s_exist_flag = 0;
			my @l_all_blocks_path_tmp = @l_all_blocks_path;	
			while( my($s_curr_block_name,$s_curr_block_path) = splice(@l_all_blocks_path_tmp,0,2)) {
				if ($s_curr_block_name eq "$s_block_name") {
					if ($s_curr_block_path =~ /$sWorkArea_name/) {
						$s_block_path = $s_curr_block_path;
					}
					$s_exist_flag = 1;
					if ($s_curr_block_path ne "$s_block_path") {
						#$s_log_message = "Error: contradiction block '$s_curr_block_name' assigned twice \n\t with different versions \n\t 1) '$s_curr_block_path' \n\t 2) '$s_block_path'\n\n";
						print color("red")."Error: contradiction block '$s_curr_block_name' assigned twice \n\t with different versions \n\t 1) '$s_curr_block_path' \n\t 2) '$s_block_path'\n\n";
						print color("reset")."";
						print LOGFILE "Error: contradiction block '$s_curr_block_name' assigned twice \n\t with different versions \n\t 1) '$s_curr_block_path' \n\t 2) '$s_block_path'\n\n";
						$s_contradiction_flag = 1;
						#fnPrintMessageOut($s_log_message);
					}
				}
			}
			if (!($s_exist_flag)) {
				push(@l_all_blocks_path,$s_block_name);
				push(@l_all_blocks_path,$s_block_path);
			}
		}
	}
	my @l_all_blocks_path_tmp = @l_all_blocks_path;	
	`cp $filename /tmp/filename\_tmp_$$`;
	while( my($s_curr_block_name,$s_curr_block_path) = splice(@l_all_blocks_path_tmp,0,2)) {
		`cat  /tmp/filename\_tmp_$$ \| grep -v $s_curr_block_name >>  /tmp/filename\_tmpNEW_$$`;
		`echo setenv $s_curr_block_name $s_curr_block_path  >>  /tmp/filename\_tmpNEW_$$`;
		`mv /tmp/filename\_tmpNEW_$$ /tmp/filename\_tmp_$$`;
	}
	open(my $fh_new, '>', "/tmp/filename\_tmpNEW_$$") or die "Could not open file /tmp/filename\_tmpNEW_$$ $!";
	open(my $fh_usr, '<:encoding(UTF-8)', "/tmp/filename\_tmp_$$")
	  or die "Could not open file '/tmp/filename\_tmp_$$' $!";
	 
	while (my $row = <$fh_usr>) {
		chomp $row;
		if (!($row =~ /setenv/) && !($row =~ /UWA_NAME/)) {
			printf $fh_new "$row\n";
			next;
		} 
		my @l_row = split(" ",$row);
		my $s_block_name = $l_row[1];
		my $s_block_path = $l_row[2];
		printf $fh_new "%-2s %-25s %-20s\n","setenv", "$s_block_name", "$s_block_path";
        } 
	close $fh_new;
	close $fh_usr;

	`mv /tmp/filename\_tmpNEW_$$ $filename`;
	
	return $s_contradiction_flag;

};# End sub fnCheckDuplications
#----------------------------------------------------------
# Procedure: fnCheckContradiction
# Description: 
#-------------
sub fnCheckContradiction {

	my ($s_block_name,$s_block_path) = (@_);

	my @l_all_blocks_path_tmp = @l_all_blocks_path_in_usr;	

	while( my($s_curr_block_name,$s_curr_block_path) = splice(@l_all_blocks_path_tmp,0,2)) {
		if ($s_curr_block_name eq "$s_block_name") {
			if ($s_curr_block_path ne "$s_block_path") {
				$s_curr_block_name =~ s/_path//;
				$s_log_message = "Error: contradiction block '$s_curr_block_name' assigned twice \n\t with different versions \n\t 1) '$s_curr_block_path' \n\t 2) '$s_block_path'\n\n";
				#fnPrintMessageOut($s_log_message);
				print color("red")."Error: contradiction block '$s_curr_block_name' assigned twice \n\t with different versions \n\t 1) '$s_curr_block_path' \n\t 2) '$s_block_path'\n\n";
				print color("reset")."";
				print LOGFILE "Error: contradiction block '$s_curr_block_name' assigned twice \n\t with different versions \n\t 1) '$s_curr_block_path' \n\t 2) '$s_block_path'\n\n";
				return 1;
			}
		}
	}
	return 0;
}
#----------------------------------------------------------
# Procedure: fnSet_usr_setup_path
# Description: write message to output log file
#-------------
sub fnSet_usr_setup_path {

	my ($sRevision_number,$sBlock_name,$sCluster_name,$sTop_name) = (@_);
	
	if ($b_no_dep) { goto END_PROC ;}
	if ($b_debug) { 
		print "Info: In sub fnSet_usr_setup_path\n";
		print "Info: sRevision_number='$sRevision_number' , sBlock_name='$sBlock_name'\n";  
		print "Info: sCluster_name='$sCluster_name' ,sTop_name='$sTop_name'\n";  
	}
	my $sRlease_path = "";
	my $sUWA_block_path = "";
	my $s_top_root = "";

	my $sBlockCluster_name_tmp = "$sBlock_name $sCluster_name $sTop_name";
	$sBlockCluster_name_tmp =~ s/ //g;

	if ($sCluster_name ne "") {
		my $s_cluster_root = $ENV{"$s_project_nameUP\_RELEASE_AREA"};
		$sRlease_path = "$s_cluster_root/$sCluster_name/$sRevision_number";
		$sUWA_block_path = "$ENV{UWA_PROJECT_ROOT}/$sWorkArea_name/$sCluster_name";
	} 
	if ($sTop_name ne "") {
		$s_top_root = $ENV{"$s_project_nameUP\_RELEASE_AREA"};
		$sRlease_path = "$s_top_root/$sTop_name/$sRevision_number";
		$sUWA_block_path = "$ENV{UWA_PROJECT_ROOT}/$sWorkArea_name/$sTop_name";
	} 
	if ($sBlock_name ne "") {
		my $s_block_root = $ENV{"$s_project_nameUP\_RELEASE_AREA"};
		$sRlease_path = "$s_block_root/$sBlock_name/$sRevision_number";
		$sUWA_block_path = "$ENV{UWA_PROJECT_ROOT}/$sWorkArea_name/$sBlock_name";
	} 
	my $s_current_pwd = `pwd`;
	chomp($s_current_pwd);
	my $s_uwa_root = dirname($s_current_pwd);

	if ($sBlock_name ne "") {
		if ($b_newBlock) {
			push(@l_all_hier_sub_blocks,"$sBlock_name latest");
		} else {
			$s_top_root = "$ENV{UWA_PROJECT_ROOT}/$sWorkArea_name";
			$sRlease_path = "$s_top_root/$sBlock_name";
		}
	} 

	if ($sRevision_number eq "git_head") {
		$sRlease_path = $sUWA_block_path;
	}
	my $s_curr_top = $sTop_name . $sCluster_name . $sBlock_name;
	$s_curr_top =~ s/ //g;
	$sTop_name = $s_curr_top;

	# if block level ,then all is local under user work area
	if ($sRevision_number eq "") {
		$sRlease_path = "$s_uwa_root/$sBlock_name/$sRevision_number";
	}

	if ($b_newBlock == 0 ) {
		if (!(-d "$sRlease_path")) {
			print "\nWarning: no such release directory  '$sRlease_path' \!\!\!\n\n";
			print LOGFILE "\nWarning: no such release directory  '$sRlease_path' \!\!\!\n\n";
			chdir($s_curr_space_dir);
			`rm -fr $sWorkArea_name/$sTop_name`; # remove work area that not completed
			if (-d "$s_project_dir/$sWorkArea_name/$sTop_name") {`rm -fr $s_project_dir/$sWorkArea_name/$sTop_name`;}
			close(LOGFILE);
			exit 0;
		}
	}

	my $s_newBlock_flag = 0;
	my $filename; 
	my $sMain_release_path ;
	my $s_space_root ;
	if ($sBlock_name ne "") {
		if ($b_newBlock) {
			$filename = "$ENV{UWA_SPACE_ROOT}/$sWorkArea_name/usr_setup_path";
			$s_space_root = $ENV{UWA_SPACE_ROOT};
			$s_uwa_root = "$ENV{UWA_PROJECT_ROOT}/$sWorkArea_name";
			$sMain_release_path = "";
			$s_newBlock_flag = 1;
		}
	}
	if ($s_newBlock_flag == 0) { 
		fnGet_all_child_hier_depends_list($sRlease_path,$s_uwa_root);
		$sMain_release_path = dirname(dirname($sRlease_path));
		$s_space_root = $s_uwa_root;
		$s_space_root =~ s/\/project\//\/space\//;
		$filename = "$s_space_root/usr_setup_path";
	}
	if (-f $filename) {;
                # if file already exist delete all old blocks path
		# we should replcae the new block's path with the old one
		foreach my $sOne_block_data (@l_all_hier_sub_blocks) {
			my @l_one_block_info = split(" ",$sOne_block_data);
			my $sOne_block = $l_one_block_info[0];
			my $sOne_block_ver = $l_one_block_info[1];
			my $s_grep_res = `grep $sOne_block\_path $filename`;
			if ($s_grep_res ne "" ) {;# block path exist ,need to be removed
	 			my $s_tmp_file = $filename;
				if (-f "$filename\_new_$$") {
					$s_tmp_file = "$filename\_new_$$";
				} 
				#-------------------------------
				# check contradiction 
				my @l_old_block_path = split(" ",$s_grep_res);
				my $s_old_block_path = basename($l_old_block_path[2]);	
				if (($sOne_block_ver ne "$s_old_block_path") && ($sOne_block_ver ne "latest") && (!($l_old_block_path[2] =~ /$sWorkArea_name/)) ) {
					my $s_b_name = $sOne_block;
					$s_b_name =~ s/_path//;
					$s_log_message = "Error: contradiction block '$s_b_name' assigned twice \n\t with different versions \n\t 1) your current WA assigned to version: '$s_old_block_path' \n\t 2) and current block $sBlockCluster_name assigned to version: '$sOne_block_ver'\n\n";
					fnPrintMessageOut($s_log_message);
				}
				#-------------------------------
				#check if the older block path is point to UWA
				my $s_older_bl_path = `cat $s_tmp_file | grep $sOne_block\_path`;
				my $s_b_name = "";
				if ($s_older_bl_path ne "" ) {
					my @l_older_bl_path = split(" ",$s_older_bl_path);
					$s_older_bl_path = $l_older_bl_path[-1];
					$s_b_name = $l_older_bl_path[1];
					$s_b_name =~ s/_path//;
				}
				if ($s_older_bl_path =~ /$sWorkArea_name/) {
					if (-f "$s_older_bl_path/.git_block_last_tag") {
						my $s_old_block_git_tag = `cat $s_older_bl_path/.git_block_last_tag`;
						chomp($s_old_block_git_tag);
						if ($s_old_block_git_tag ne "$sOne_block_ver") {
							$s_log_message = "Error: contradiction block '$s_b_name' assigned twice \n\t with different versions \n\t 1) your current WA assigned to version: '$s_old_block_git_tag' \n\t 2) and current block $sBlockCluster_name assigned to version: '$sOne_block_ver'\n\n";
							fnPrintMessageOut($s_log_message);
						} else {;# same version as in UWA ,not change the path
							goto STEP_CONTINUE ;
						}
					}
				}
				#-------------------------------
				`cat $s_tmp_file | grep -v $sOne_block\_path > $filename\_$$`;
				`mv $filename\_$$ $filename\_new_$$`;
			}
			STEP_CONTINUE:
		}
		if (-f "$filename\_new_$$") {
			`mv $filename\_new_$$ $filename`;
		}
		# append the new blocks path
		open(my $fh, '>>', $filename) or die "Could not open file '$filename' $!";
		foreach my $sOne_block_data (@l_all_hier_sub_blocks) {
			my @l_one_block_info = split(" ",$sOne_block_data);
			my $sOne_block = $l_one_block_info[0];
			my $sOne_block_ver = $l_one_block_info[1];
			if (($sTop_name eq "$sOne_block") || ($b_newBlock == 1 )) {
				if (!(-d "$s_uwa_root/$sTop_name")) {
					`rm -fr $ENV{UWA_PROJECT_ROOT}/$sWorkArea_name/$sBlockCluster_name`;
					$s_log_message = "Error: no such path '$s_uwa_root/$sTop_name' \!\!\! \n";
					fnPrintMessageOut($s_log_message);
				}
				printf $fh "%-2s %-25s %-20s\n","setenv", "$sOne_block\_path", "$s_uwa_root/$sTop_name";
			} else {
					if ($sRevision_number eq "git_head") {
						my $s_release_area = $ENV{"$s_project_nameUP\_RELEASE_AREA"};
						if (!(-d "$s_release_area/$sOne_block/$sOne_block_ver")) {
							`rm -fr $ENV{UWA_PROJECT_ROOT}/$sWorkArea_name/$sBlockCluster_name`;
							$s_log_message = "Error: no such path '$s_release_area/$sOne_block/$sOne_block_ver' \!\!\! \n";
							fnPrintMessageOut($s_log_message);
						}
						printf $fh "%-2s %-25s %-20s\n","setenv", "$sOne_block\_path", "$s_release_area/$sOne_block/$sOne_block_ver";
					} else {
						if (!(-d "$sMain_release_path/$sOne_block/$sOne_block_ver")) {
							`rm -fr $ENV{UWA_PROJECT_ROOT}/$sWorkArea_name/$sBlockCluster_name`;
							$s_log_message = "Error: no such path '$sMain_release_path/$sOne_block/$sOne_block_ver' \!\!\! \n";
							fnPrintMessageOut($s_log_message);
						}
						printf $fh "%-2s %-25s %-20s\n","setenv", "$sOne_block\_path", "$sMain_release_path/$sOne_block/$sOne_block_ver";
					} 
			}
		}
		close $fh;
	} else {
		@l_all_blocks_path_in_usr = ();
		open(my $fh, '>', $filename) or die "Could not open file '$filename' $!";
		printf $fh "#----------------------------------------------------#\n";
		printf $fh "#  usr_setup_path file for '$sWorkArea_name'           \n";
		printf $fh "#----------------------------------------------------#\n";
		printf $fh "%-2s %-25s %-20s\n","setenv", "UWA_NAME", "$sWorkArea_name";
		$s_contradiction_flag = 0;
		foreach my $sOne_block_data (@l_all_hier_sub_blocks) {
			my @l_one_block_info = split(" ",$sOne_block_data);
			my $sOne_block = $l_one_block_info[0];
			my $sOne_block_ver = $l_one_block_info[1];
			if (($sTop_name eq "$sOne_block") || ($b_newBlock == 1 )) {
				if (!(-d "$s_uwa_root/$sTop_name")) {
					`rm -fr $ENV{UWA_PROJECT_ROOT}/$sWorkArea_name/$sBlockCluster_name`;
					$s_log_message = "Error: no such path '$s_uwa_root/$sTop_name' \!\!\! \n";
					fnPrintMessageOut($s_log_message);
				}
				$s_contradiction_flag = fnCheckContradiction("$sOne_block\_path","$s_uwa_root/$sTop_name");
				printf $fh "%-2s %-25s %-20s\n","setenv", "$sOne_block\_path", "$s_uwa_root/$sTop_name";
				push(@l_all_blocks_path_in_usr,"$sOne_block\_path");
				push(@l_all_blocks_path_in_usr,"$s_uwa_root/$sTop_name");
			} else {
					if ($sRevision_number eq "git_head") {
						my $s_release_area = $ENV{"$s_project_nameUP\_RELEASE_AREA"};
						if (!(-d "$s_release_area/$sOne_block/$sOne_block_ver")) {
							`rm -fr $ENV{UWA_PROJECT_ROOT}/$sWorkArea_name/$sBlockCluster_name`;
							$s_log_message = "Error: no such path '$s_release_area/$sOne_block/$sOne_block_ver' \!\!\! \n";
							fnPrintMessageOut($s_log_message);
						}
						$s_contradiction_flag = fnCheckContradiction("$sOne_block\_path","$s_release_area/$sOne_block/$sOne_block_ver");
						printf $fh "%-2s %-25s %-20s\n","setenv", "$sOne_block\_path", "$s_release_area/$sOne_block/$sOne_block_ver";
						push(@l_all_blocks_path_in_usr,"$sOne_block\_path");
						push(@l_all_blocks_path_in_usr,"$s_release_area/$sOne_block/$sOne_block_ver");
					} else {
						if (!(-d "$sMain_release_path/$sOne_block/$sOne_block_ver")) {
							`rm -fr $ENV{UWA_PROJECT_ROOT}/$sWorkArea_name/$sBlockCluster_name`;
							$s_log_message = "Error: no such path '$sMain_release_path/$sOne_block/$sOne_block_ver' \!\!\! \n";
							fnPrintMessageOut($s_log_message);
						}
						$s_contradiction_flag = fnCheckContradiction("$sOne_block\_path","$sMain_release_path/$sOne_block/$sOne_block_ver");
						printf $fh "%-2s %-25s %-20s\n","setenv", "$sOne_block\_path", "$sMain_release_path/$sOne_block/$sOne_block_ver";
						push(@l_all_blocks_path_in_usr,"$sOne_block\_path");
						push(@l_all_blocks_path_in_usr,"$sMain_release_path/$sOne_block/$sOne_block_ver");
					}
			}
			if ( $sOne_block eq "$sTop_name") {
				$s_ref_top_dependList = "$sMain_release_path/$sOne_block/$sOne_block_ver/depends.list";
			}
		}
		close $fh;
	}
	`chmod 755 $filename`;
	#-------------------------------------
	# check duplication in usr_setup_path
	$s_contradiction_flag = fnCheckDuplications($filename);
	#------------------------------------
	if ($s_contradiction_flag) {
		$s_log_message = "Error: contradiction found ' \!\!\! \n";
		fnPrintMessageOut($s_log_message);
	}
	print "\n \nInfo: $s_space_root/usr_setup_path file created follow the release revision .\n";

	END_PROC:

};# End sub fnSet_usr_setup_path
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
	exit 1;
  }	

};# End sub fnPrintMessageOut
#----------------------------------------------------------
# Procedure: fnBuildPreReleaseWorkArea
# Description: create pre-release work area
#-------------
sub fnBuildPreReleaseWorkArea {


	my $i_index_arr  = 0;
	my $s_curr_child = 0;
	if ($b_debug) {
		print "Info: In sub fnBuildPreReleaseWorkArea\n";
		print "Info: s_project_dir ='$s_project_dir'\n";
	}

	foreach my $s_curr_tag (@l_inp_depens_child_ver) {
		chdir("$s_project_dir/$sWorkArea_name");
		$s_curr_child = $l_inp_depens_child[$i_index_arr];

		if ($sPre_release_depList ne "") {;# if pre release option
			if ($s_curr_tag eq "latest") {
				$s_log_message = "Error: the '$s_curr_child' child's tag version in depends list cannot be with 'latest' vesrion \!\!\!";
				fnPrintMessageOut($s_log_message);
			}
			$cmd = "git clone --branch $s_curr_tag $ENV{GIT_PROJECT_ROOT}/$s_curr_child\.git $s_curr_child";
			if ($b_debug) {print "Info: cmd '$cmd'\n";}
			`git clone --branch $s_curr_tag $ENV{GIT_PROJECT_ROOT}/$s_curr_child\.git $s_curr_child `;
		} else {
			chdir("$s_curr_child");
			if ($s_curr_tag ne "latest") {
				if ($b_debug) {print "Info: cmd 'git checkout $s_curr_tag --force .'\n";}
				print LOGFILE "Info: cmd 'git checkout $s_curr_tag --force .'\n";
				`git checkout $s_curr_tag --force . 2>&1`;
			}
			printf "Info: for block %-20s the version that checked out is %-30s\n",$s_curr_child,$s_curr_tag;
			printf LOGFILE "Info: for block %-20s the version that checked out is %-30s\n",$s_curr_child,$s_curr_tag;
		}
		my @l_child_name = fnGet_all_child_in_depends_list("$s_project_dir/$sWorkArea_name/$s_curr_child",$sLogFile);
		
		if (scalar(@l_child_name) > 0 ) {
			foreach my $s_sub_block (@l_child_name) {	
				chdir("$s_project_dir/$sWorkArea_name");
				my $s_child_name = basename($s_sub_block);
				chdir($s_child_name);

				if ($s_curr_tag ne "latest") {
					if ($b_debug) {print "Info: cmd 'git checkout $s_curr_tag --force .'\n";}
					print LOGFILE "Info: cmd 'git checkout $s_curr_tag --force .'\n";
					`git checkout $s_curr_tag --force . 2>&1`;
				}

				printf "Info: for block %-20s the version that checked out is %-30s\n",$s_child_name,$s_curr_tag;
				printf LOGFILE "Info: for block %-20s the version that checked out is %-30s\n",$s_child_name,$s_curr_tag;
				close(LOGFILE);
				fnGet_all_child_in_depends_list_andCheckout("$s_sub_block",$sLogFile,$s_curr_tag);
				open LOGFILE, ">>$sLogFile" or die "cannot open file $sLogFile : $!\n";
			}
		}
		$i_index_arr++;
		chdir("$s_project_dir/$sWorkArea_name");
	}

};# End sub fnBuildPreReleaseWorkArea
#----------------------------------------------------------
# Procedure: fnCreate_release_note
# Description: 
#-------------
sub fnCreate_release_note {

   if (-f "$s_project_dir/$sWorkArea_name/pre-release_note.txt") {`rm -f $s_project_dir/$sWorkArea_name/pre-release_note.txt`;}
   `grep \"the version that checked out is\" $sLogFile > $s_project_dir/$sWorkArea_name/pre-release_note.txt`;
   printf "\nInfo: you can find pre-release note '$s_project_dir/$sWorkArea_name/pre-release_note.txt'\n";
   printf LOGFILE "\nInfo: you can find pre-release note '$s_project_dir/$sWorkArea_name/pre-release_note.txt'\n";
`git commit -m \"update new pre release note following the depend input file '$sPre_release_depList' \" $s_project_dir/$sWorkArea_name/pre-release_note.txt`;

} ;# End sub fnCreate_release_note 
#----------------------------------------------------------
# Procedure: fnCheckDependsChildTagExist
# Description: create pre-release work area
#-------------
sub fnCheckDependsChildTagExist {

	my $s_input_dependsList = $sPre_release_depList;

	print "\n--------------------- pre-release process is running -------------------------\n";
	#----------------------------------
	# get all block in input depend list to compare 
	# with the input depend list
	@l_inp_depens_child     = ();
	@l_inp_depens_child_ver = ();
	open(my $fh_dep, '<:encoding(UTF-8)', $s_input_dependsList)
	  or die "Could not open file '$s_input_dependsList' $!";
	 
	while (my $row = <$fh_dep>) {
	  chomp $row;
	  next if($row =~ /^\/\//);		
	  next if($row =~ /^\#/);		
	  next if($row eq "");		
	  my @l_row = split(" ",$row);
	  if (scalar(@l_row) < 2 ) {
		my $s_log_message1 = "Error: input depends list is not in the right format \!\!\!\n"; 	
		my $s_log_message2 = "       row : '$row'\n";
		my $s_log_message3 = "       not written with right format '<block_name> <block_tag_name>'";
		$s_log_message = $s_log_message1 . $s_log_message2 . $s_log_message3;
		chdir($s_curr_space_dir);
		fnPrintMessageOut($s_log_message);
	  }	
	  push(@l_inp_depens_child,$l_row[0]);
	  push(@l_inp_depens_child_ver,$l_row[1]);
	}
	close $fh_dep;
	my $s_git_tag_exist = "";
	my $i_index_arr = 0;
	if ($sPre_release_depList eq "") {;# if not pre release option
		#-----------------------------------------------------
		# check each block's tag existing under git repository
		if ($b_debug) {print "Info: l_inp_depens_child_ver='@l_inp_depens_child_ver'\n";}
		foreach my $onBlockChild (@l_inp_depens_child) {
			next if ($l_inp_depens_child_ver[$i_index_arr] eq "latest");
			chdir("$s_project_dir/$sWorkArea_name");
			chdir($onBlockChild);
			$s_git_tag_exist = `git tag -l $l_inp_depens_child_ver[$i_index_arr]`;
			chomp($s_git_tag_exist);
			if ($s_git_tag_exist eq "") {;# no tag existing in git repo
				chdir($s_curr_space_dir);
				$s_log_message = "Error: tag name '$l_inp_depens_child_ver[$i_index_arr]' not found in git repository for block '$l_inp_depens_child[$i_index_arr]' \!\!\!";
				fnPrintMessageOut($s_log_message);
			}
			$i_index_arr++;

		}
	}
	$i_index_arr = 0;
	print "---------------------------------------------------------------------\n";
	print LOGFILE "---------------------------------------------------------------------\n";
	print "Info: Child name and his tag name as exist in input depends.list file :\n\n";
	print LOGFILE "Info: Child name and his tag name as exist in input depends.list file :\n\n";
	printf LOGFILE "\t%-35s %-35s \n", "Child Name", "Child Tag Name";
	printf LOGFILE "\t%-35s %-35s \n", "----------", "--------------";
	printf  "\t%-35s %-35s \n", "Child Name", "Child Tag Name";
	printf "\t%-35s %-35s \n", "----------", "--------------";
	foreach my $onBlockChild (@l_inp_depens_child) {
		printf LOGFILE "\t%-35s %-35s \n", "$onBlockChild", "$l_inp_depens_child_ver[$i_index_arr]";
		printf "\t%-35s %-35s \n", "$onBlockChild", "$l_inp_depens_child_ver[$i_index_arr]";
		$i_index_arr++;
	}
	print "\n---------------------------------------------------------------------\n\n";
	print LOGFILE "\n---------------------------------------------------------------------\n\n";


};# End sub fnCheckDependsChildTagExist
#----------------------------------------------------------
#
# Procedure: fnCreateNewBlockInExistingWA
#
# Description: 
#
#-------------
sub fnCreateNewBlockInExistingWA {

	print "\nInfo: 1you already have work area with that name '$sWorkArea_name' \n";
	print "            under project work space '$s_curr_space_dir' \n\n";  
	my $s_curr_dir = `pwd`;
	chomp($s_curr_dir);
	#-------------------------------
	# Check if top exist in GIT repo
	#-------------------------------
	my $sProj_subDir = `git ls-tree -d --name-only master`;
	print LOGFILE "Info: cmd 'git ls-tree -d --name-only master'\n";
	my @lProj_subDir = split("\n",$sProj_subDir);
	$s_new_block_index = 0;
	foreach my $one_subDir (@lProj_subDir) {
		if (($one_subDir eq "$sBlock_name") || ($one_subDir eq "$sCluster_name") || ($one_subDir eq "$sTop_name")) {
			$s_new_block_index = 1;
		}
	}
	#------------------------------------------
	if ($s_new_block_index) { # block exist in git depo
		print "\n\n*** Warning: This block/cluster/top '$sBlockCluster_name' already exit in git repository \n\n";
		chdir($s_curr_space_dir);
		close(LOGFILE);
		exit 0;
	} else {
		if (-d $sBlockCluster_name) {
			print "\nWarning: this block already exist under your work area '$s_curr_dir/$sBlockCluster_name' \n\n";
			chdir($s_curr_space_dir);
			close(LOGFILE);
			exit 0;
		}
		print LOGFILE "Info: block/cluster/top is not exist '$sBlockCluster_name' under git repository \n";
		print "Info: block/cluster name '$sBlockCluster_name' is not exist under git repository \n";
		fnLoadProjectDirStructure();
		fnCreateUWAfollowProjStructure();
		# add .gitignore file under empty directory
		$cmd = "find -name .git -prune -o -type d -empty -exec sh -c \"echo this directory needs to be empty because reasons \> \{\}\/\.gitignore\" \\;";
		fnRunSysCMD($cmd); 
		fnSet_usr_setup_path($sRevision_number,$sBlock_name,$sCluster_name,$sTop_name);
	}

};# End sub fnCreateNewBlockInExistingWA 
#---------------------------------------------------------------------------
#
#
#     ---------- MAIN   'create_uwa' -----------------------
#
#
#---------------------------------------------------------------------------
#
        if (not(&GetOptions('wa=s'     => \$sWorkArea_name   ,
                            'b=s'      => \$sBlock_name   ,
                            'c=s'      => \$sCluster_name   ,
                            't=s'      => \$sTop_name   ,
                            'rev=s'    => \$sRevision_number   ,
                            'pre=s'    => \$sPre_release_depList   ,
                            'new!'     => \$b_newBlock   ,
                            'branch!'  => \$b_branch   ,
                            'debug!'   => \$b_debug   ,
                            'no_dep!'  => \$b_no_dep   ,
                            'help!'    => \$bHelp     )) || $bHelp ) {
          &ffnUsage;
        }
        #---------------------------
        # check args validation 
        #-----
        #if ($#ARGV==-1) { &ffnUsage; } 

        if ($bHelp) { &ffnUsage; }	

	print "\n\n--------------\n";
	print "  uwa_create \n";
	print "--------------\n";
	print LOGFILE  "\n\n--------------\n";
	print LOGFILE  "  uwa_create \n";
	print LOGFILE  "--------------\n";

	if (!(defined $ENV{PROJECT_NAME}) || !(defined $ENV{PROJECT_HOME}) || !(defined $ENV{GIT_PROJECT_ROOT}) ) {
		print "\nWarning: you must run 'setup_proj' command before \!\!\!\n\n";	
		exit 0;
	}
        if ($sWorkArea_name eq "") { &ffnUsage; }	
	if (($sPre_release_depList ne "") && (($sRevision_number ne "git_head"))){
		$s_log_message = "\nWarning: cannot run with these 2 options together -pre <depends_file> -r <block_revision>   \!\!\!\n\n";
		fnPrintMessageOut($s_log_message);
	}
	if ($sPre_release_depList ne "") {;# create pre release work space
		if (!(-f "$sPre_release_depList")) {
			print "\n\nWarning: no such depends list file '$sPre_release_depList' to create pre-release  \!\!\!\n\n";
			exit 0;
		}
		$sRevision_number = "git_head" ;# bring as default the latest version of the top block
	}
        if (($sBlock_name eq "") && ($sCluster_name eq "") && ($sTop_name eq "")) { 
		print "\nWarning: you must run this script with '-b <block_name>' or '-c <cluster_name>' option \!\!\!\\n\n";
		&ffnUsage; 
	}	
        if (($sBlock_name ne "") && ($sCluster_name ne "")) { 
		print "\nWarning: you must run this script with one of the option '-b <block_name>' or '-c <cluster_name>' or '-t <top_name>' \!\!|!|\n\n";
		&ffnUsage; 
	}	
        if (($sBlock_name ne "") && ($sTop_name ne "")) { 
		print "\nWarning: you must run this script with one of the option '-b <block_name>' or '-c <cluster_name>' or '-t <top_name>' \!\!|!|\n\n";
		&ffnUsage; 
	}	
        if (($sTop_name ne "") && ($sCluster_name ne "")) { 
		print "\nWarning: you must run this script with one of the option '-b <block_name>' or '-c <cluster_name>' or '-t <top_name>' \!\!|!|\n\n";
		&ffnUsage; 
	}	
	if (($sBlock_name ne "") && ($sCluster_name eq "")) { 
		$sCluster_name = $sBlock_name;
		$sBlock_name = "";
	} 	
	if (($sRevision_number eq "git_head") && ($b_branch == 1)) {
		$s_log_message = "\nWarning: the '-branch' option must come with '-r <block_revision>' option\n\n";
		fnPrintMessageOut($s_log_message);
	}
	$sBlockCluster_name = "$sBlock_name $sCluster_name $sTop_name";
	$sBlockCluster_name =~ s/ //g;

	if ($sPre_release_depList ne "") {;# create pre release work space
		# should change all as block level ,this will checkout all 
		# block's design under UWA	
		$sBlock_name = $sBlockCluster_name;		
		$sCluster_name = "";
		$sTop_name = "";
	}

	if ($b_newBlock ) { ;# for new all are the same  block/cluster/top
		$sBlock_name = $sBlockCluster_name;	
		$sCluster_name = "";
                $sTop_name = "";
	} 
	$s_project_name = $ENV{PROJECT_NAME};
	$s_project_nameUP = uc $s_project_name;
	$s_proj_rev = basename($ENV{PROJECT_HOME});	

	$s_curr_space_dir = "/space/users/$ENV{USER}/$ENV{PROJECT_NAME}\_$s_proj_rev";
	$s_project_dir = "/project/users/$ENV{USER}/$ENV{PROJECT_NAME}\_$s_proj_rev";
	if (!(-d "$s_project_dir")) {
		`mkdir -p $s_project_dir`;
	}
	if (!(-d "$s_curr_space_dir")) {
		`mkdir -p $s_curr_space_dir`;
		print "Info: new space area created under project '$ENV{PROJECT_NAME}' for user '$ENV{USER}' :\n";  
		print "      '$s_curr_space_dir'\n\n";
		print LOGFILE "Info: new space area created under project '$ENV{PROJECT_NAME}' for user '$ENV{USER}' :\n";  
		print LOGFILE "      '$s_curr_space_dir'\n\n";
	}


	chdir($s_curr_space_dir);
	if (!(-d "$sWorkArea_name/$sBlockCluster_name")) {

	        # create empty work area 
                #-------------------------------- 
                # mkdir work area for block's repository
		`mkdir -p $sWorkArea_name`;
		chdir($s_project_dir);
		if (-d "$sWorkArea_name/$sBlockCluster_name") {
			chdir($s_curr_space_dir);
			print "\n**** Error: you already have block's work area with that name '$sWorkArea_name/$sBlockCluster_name' \n";
			print "            under project work area '$s_project_dir' \n\n";  
			close(LOGFILE);
			exit 0;
		}
		#-------------------------------
		# Check if top exist in GIT repo
		#-------------------------------
		# create all project's directories empty
		$s_new_block_index = 1; ;# default is exist
		$cmd = "git ls-remote $ENV{GIT_PROJECT_ROOT}/$sBlockCluster_name\.git";
		my $sProj_gitignore_files = `$cmd 2>&1`;
		print LOGFILE "Info: cmd 'git ls-remote $ENV{GIT_PROJECT_ROOT}/$sBlockCluster_name\.git \| grep HEAD'\n";
		if ($b_debug) {print "Info: cmd 'git ls-remote $ENV{GIT_PROJECT_ROOT}/$sBlockCluster_name\.git \| grep HEAD'\n";}
		if (($sProj_gitignore_files eq "") || ($sProj_gitignore_files =~ /Repository not found/)) {
				my $s_info_or_erroe_msg = "Error";
				if ($b_newBlock) { $s_info_or_erroe_msg = "Info";}
				print "$s_info_or_erroe_msg: 'git ls-remote $ENV{GIT_PROJECT_ROOT}/$sBlockCluster_name\.git \| grep HEAD'\n";
				print LOGFILE "$s_info_or_erroe_msg: 'git ls-remote $ENV{GIT_PROJECT_ROOT}/$sBlockCluster_name\.git \| grep HEAD'\n";
				$s_new_block_index = 0;
		}
		if (!($s_new_block_index)) { # block exist in git depo
			if (!($b_newBlock)) {
				$s_log_message = "Error: top name '$sBlockCluster_name' is not existing under git repository";
				fnPrintMessageOut($s_log_message);
			}
		}
		#-------------------------------------------------
		# verify that his version exist under release area
		my $s_uc_project_name = uc($ENV{PROJECT_NAME});	
                my $s_release_area = $ENV{"$s_uc_project_name\_RELEASE_AREA"};
		if ($sRevision_number ne "git_head") {
			if (!(-d "$s_release_area/$sBlockCluster_name/$sRevision_number")) {
				$s_log_message = "\nError: no release version like that under release area: \n\t '$s_release_area/$sBlockCluster_name/$sRevision_number' \!\!\! \n\n\n"; 
				fnPrintMessageOut($s_log_message);
			}
		}
		#-------------------------------------------------
               	if ($b_debug) {
			print "Info: input version is '$sRevision_number'\n";
		} 
		#-------------------------------
		if ($b_newBlock) { goto NEW_BLOCK_STAGE ;}
		if (($sRevision_number ne "latest") && ($sRevision_number ne "git_head"))  {
			if ($b_branch) {;# checkot block tag as branch reference
				$cmd = "git clone --branch $sRevision_number $ENV{GIT_PROJECT_ROOT}/$sBlockCluster_name\.git $sWorkArea_name/$sBlockCluster_name";
				if ($b_debug) {print "Info: cmd '$cmd'\n";}
				`git clone --branch $sRevision_number $ENV{GIT_PROJECT_ROOT}/$sBlockCluster_name\.git $sWorkArea_name/$sBlockCluster_name `;
			} else {;# checkout block from HEAD as referenc ,and then checkout the relevant tag 
				$cmd = "git clone $ENV{GIT_PROJECT_ROOT}/$sBlockCluster_name\.git $sWorkArea_name/$sBlockCluster_name";
				if ($b_debug) {print "Info: cmd '$cmd'\n";}
				print LOGFILE "Info: cmd '$cmd'\n";
				`git clone $ENV{GIT_PROJECT_ROOT}/$sBlockCluster_name\.git $sWorkArea_name/$sBlockCluster_name 2>&1`;
				chdir("$sWorkArea_name/$sBlockCluster_name");
				#-------------------------------------------------
				# verify that tag version exist for this block
				my $s_git_tag_exist = `git tag -l $sRevision_number`;
				chomp($s_git_tag_exist);
				if ($s_git_tag_exist eq "") {;# no tag existing in git repo
					chdir($s_curr_space_dir);
					`rm -fr $sWorkArea_name/$sBlockCluster_name`;
					$s_log_message = "Error: tag name '$sRevision_number' not found in git repository for block '$sBlockCluster_name' \!\!\!";
					fnPrintMessageOut($s_log_message);
				}
				#-------------------------------------------------
				if ($b_debug) {print "Info: cmd 'git checkout $sRevision_number --force .'\n";}
				print LOGFILE "Info: cmd 'git checkout $sRevision_number --force .'\n";
				`git checkout $sRevision_number --force . 2>&1`;
			}
			chdir($s_project_dir);
		} else {
			#----------------------
			# check if latest symbolic link exist for this block 
			# under \${PROJECT_ANME}_RELEASE_AREA/<block_name>/latest 
			# if yes :
			#    1) clone riogin HEAD 
			#    2) checkout to the version that latest linked 
			# if no :
			#    1) clone riogin HEAD 
			#----------------------

			if ($sPre_release_depList eq "") {;# if not pre release option
				my $s_cluster_root = $ENV{"$s_project_nameUP\_RELEASE_AREA"};
				if ($sRevision_number eq "latest") {;# check latest symbolic link tag version
					my $s_cluster_root = $ENV{"$s_project_nameUP\_RELEASE_AREA"};
					if (-e "$s_cluster_root/$sBlockCluster_name/latest") {
						my $s_latest_point_to_ver = `ls -lrt $s_cluster_root/$sBlockCluster_name/latest`;
						chomp($s_latest_point_to_ver);
						my @l_latest_point_to_ver = split(" ",$s_latest_point_to_ver);
						$s_latest_point_to_ver = $l_latest_point_to_ver[-1];
						$sRevision_number = $s_latest_point_to_ver;
						if ($b_branch) {;# branch and latest
							$cmd = "git clone --branch $sRevision_number $ENV{GIT_PROJECT_ROOT}/$sBlockCluster_name\.git $sWorkArea_name/$sBlockCluster_name";
							if ($b_debug) {print "Info: cmd '$cmd'\n";}
							`git clone --branch $sRevision_number $ENV{GIT_PROJECT_ROOT}/$sBlockCluster_name\.git $sWorkArea_name/$sBlockCluster_name `;
							chdir($s_project_dir);
						} else {

							$cmd = "git clone $ENV{GIT_PROJECT_ROOT}/$sBlockCluster_name\.git $sWorkArea_name/$sBlockCluster_name";
							print LOGFILE "Info: cmd '$cmd'\n";
							if ($b_debug) {print "Info: cmd '$cmd'\n";}
							`git clone $ENV{GIT_PROJECT_ROOT}/$sBlockCluster_name\.git $sWorkArea_name/$sBlockCluster_name 2>&1`;
						
							chdir("$sWorkArea_name/$sBlockCluster_name");
							if ($b_debug) {print "Info: cmd 'git checkout $sRevision_number --force .'\n";}
							print LOGFILE "Info: cmd 'git checkout $sRevision_number --force .'\n";
							`git checkout $sRevision_number --force . 2>&1`;
							chdir($s_project_dir);
						} 
					} 

				} else {;# git_head option
					$cmd = "git clone $ENV{GIT_PROJECT_ROOT}/$sBlockCluster_name\.git $sWorkArea_name/$sBlockCluster_name";
					print LOGFILE "Info: cmd '$cmd'\n";
					if ($b_debug) {print "Info: cmd '$cmd'\n";}
					`git clone $ENV{GIT_PROJECT_ROOT}/$sBlockCluster_name\.git $sWorkArea_name/$sBlockCluster_name 2>&1`;
				} 
			} else {;# copy the input depends list as basic 
				$cmd = "git clone $ENV{GIT_PROJECT_ROOT}/$sBlockCluster_name\.git $sWorkArea_name/$sBlockCluster_name";
				print LOGFILE "Info: cmd '$cmd'\n";
				if ($b_debug) {print "Info: cmd '$cmd'\n";}
				`git clone $ENV{GIT_PROJECT_ROOT}/$sBlockCluster_name\.git $sWorkArea_name/$sBlockCluster_name 2>&1`;

				chdir("$sWorkArea_name/$sBlockCluster_name");
				$cmd = "cp -fr $sPre_release_depList depends.list";
				fnRunSysCMD($cmd); 
				chdir($s_project_dir);
			} 
		}
		$cmd = "cp /project/infra/utils/common/scripts/git/prepare-commit-msg $sWorkArea_name/$sBlockCluster_name/.git/hooks/.";
		fnRunSysCMD($cmd); 
		chdir("$sWorkArea_name/$sBlockCluster_name");
		# fetch all tags to user workspace
		$cmd = "git fetch origin --tags";
		print LOGFILE "Info: cmd 'git fetch origin --tags'\n";
		fnRunSysCMD($cmd); 

		NEW_BLOCK_STAGE:

		if (!(-e "$s_curr_space_dir/$sWorkArea_name/project")) {
			`ln -s $s_project_dir/$sWorkArea_name $s_curr_space_dir/$sWorkArea_name/project`;
		}

		#------------------------------------------
		if ($b_debug) {print "Info: s_new_block_index='$s_new_block_index'\n";}
		if ($s_new_block_index) { # block exist in git depo
			if ($b_newBlock) {
				print "\n\n*** Warning: This block/cluster/top '$sBlockCluster_name' already exit in git repository \n\n";
				chdir($s_curr_space_dir);
				`rm -fr $sWorkArea_name/$sBlockCluster_name`;
				if (-d "$s_project_dir/$sWorkArea_name/$sBlockCluster_name") {
					`rm -fr $s_project_dir/$sWorkArea_name/$sBlockCluster_name`;
				}
				close(LOGFILE);
				exit 0;
			}
			print LOGFILE "Info: block/cluster/top '$sBlockCluster_name' exit in git repository \n";
			if ( ($sBlock_name ne "") || ($sRevision_number eq "")) { # get latest version to user wa
				fnSet_usr_setup_path($sRevision_number,$sBlock_name,$sCluster_name,$sTop_name);
			} else { # set paths to release version
				if (!(defined $ENV{"$s_project_nameUP\_RELEASE_AREA"})) {
					print LOGFILE "Error: the environment variable '$s_project_nameUP\_RELEASE_AREA' must defined \!\!\!\n\n";
					print "\n\nError: the environment variable '$s_project_nameUP\_RELEASE_AREA'  must defined \!\!\!\n\n";
					chdir($s_curr_space_dir);
					#`rm -fr $sWorkArea_name`;
					close(LOGFILE);
					exit 0;
				}
				fnSet_usr_setup_path($sRevision_number,$sBlock_name,$sCluster_name,$sTop_name);
			}
		} else { # top not exist in git repository
			if ($b_newBlock) {
				print LOGFILE "Info: block/cluster/top is not exist '$sBlockCluster_name' under git repository \n";
				print "Info: block/cluster name '$sBlockCluster_name' is not exist under git repository \n";
				fnLoadProjectDirStructure();
				fnCreateUWAfollowProjStructure();
				# add .gitignore file under empty directory
				$cmd = "find -name .git -prune -o -type d -empty -exec sh -c \"echo this directory needs to be empty because reasons \> \{\}\/\.gitignore\" \\;";
				fnRunSysCMD($cmd); 
				fnSet_usr_setup_path($sRevision_number,$sBlock_name,$sCluster_name,$sTop_name);

			} else {
				print LOGFILE "Error: top name '$sBlockCluster_name' is not existing under git repository \n";
				print "\n\nError: top name '$sBlockCluster_name' is not existing  under git repository \n\n";
				chdir($s_curr_space_dir);
				#`rm -fr $sWorkArea_name`;
				close(LOGFILE);
				exit 0;
			}
		}
		#-------------------------------

	} else {
		if ($b_newBlock) {
			if (-d "$sWorkArea_name/project") {
				chdir("$sWorkArea_name/project");
				fnCreateNewBlockInExistingWA();
				chdir($s_curr_space_dir);
				print LOGFILE  "\n\n--------------------------------------------------------------\n";
				print LOGFILE  "  uwa_create finished to create new block '$sBlockCluster_name' successfully !!!\n";
				print LOGFILE  "  work area folder created under '$s_curr_space_dir/$sWorkArea_name/project'. \n";
				print LOGFILE  "--------------------------------------------------------------\n";
				print "\n\n--------------------------------------------------------------\n";
				print "  uwa_create finished to create new block '$sBlockCluster_name' successfully !!!\n";
				print "  work area folder created under '$s_curr_space_dir/$sWorkArea_name/project/'. \n";
				print "--------------------------------------------------------------\n";
				close(LOGFILE);
				print "\n\n\t* Info: you can find log file '$sLogFile' \n\n";
				exit 0;
			} else {
				print "\n****Error: no such folder '$sWorkArea_name/project' \!\!\!\n";
				print "       somthing is wrong with this work area '$s_curr_space_dir/$sWorkArea_name' \n\n";
				close(LOGFILE);
				print "\n\n\t* Info: you can find log file '$sLogFile' \n\n";
				exit 0;
			}
		} else { 
			chdir($s_curr_space_dir);
			print "\n**** Error: you already have this block under your work area '$sWorkArea_name/$sBlockCluster_name' \n";
			print "            under project work space '$s_curr_space_dir' \n\n";  
			close(LOGFILE);
			exit 0;
		}
	}

	if ($sPre_release_depList ne "") {;# create pre release work space
		my $s_pwddd = `pwd`;
		chomp($s_pwddd);
		fnCheckDependsChildTagExist();	

		chdir($s_project_dir);
		chdir("$sBlockCluster_name");
		if ($b_debug) {print "Info: cmd 'git checkout HEAD --force .'\n";}
		print LOGFILE "Info: cmd 'git checkout HEAD --force .'\n";
		`git checkout HEAD --force . 2>&1`;
		chdir($s_project_dir);

		#fnBuildPreReleaseWorkArea();  put in comment ,not bring it to user work area changes done at 23 Sep 2019
	}


	chdir($s_curr_space_dir);

	print LOGFILE  "\n\n--------------------------------------------------------------\n";
	print LOGFILE  "  uwa_create for '$sBlockCluster_name' finished successfully !!!\n";
	print LOGFILE  "  work area folder created under '$s_curr_space_dir/$sWorkArea_name'. \n";
	print LOGFILE  "--------------------------------------------------------------\n";
	print color("green")."\n\n--------------------------------------------------------------\n";
	print color("green")."  uwa_create for '$sBlockCluster_name' finished successfully !!!\n";
	print color("green")."  work area folder created under '$s_curr_space_dir/$sWorkArea_name'. \n";
	print "--------------------------------------------------------------\n";
        print color("reset")."";

        close(LOGFILE);
        print "\n\n* Info: you can find log file '$sLogFile' \n\n";
        print " \n";
        print "\nUser work area:\n";
	print "$s_curr_space_dir/$sWorkArea_name\n";
        #exit 0;

#-------------------------------------------------------
#
#
#         --------   END  uwa_create.pl -------------     
#
#
#-------------------------------------------------------

