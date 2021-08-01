#!/usr/bin/perl -w
##************************************************************************
#* Description                                                          * 
#*                                                                      * 
#* Revision                                                             * 
#************************************************************************
#
#use lib '/home/amird/scripts/perl/packages';
use strict;
use warnings;
#use Dump qw(dump);
use Cwd;
use Cwd 'abs_path';
use Getopt::Long;
use Common;
use File::Basename;
use Term::ANSIColor;
my $iScrip_version = "V00001";
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
my $sRevision_number   = ""; 
my $bHelp              =  0; 
my $sBlockCluster_name = "";
my $s_current_dir      = "";
my @l_all_hier_sub_blocks = ();
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
# Usage : uwa_set
#
sub ffnUsage { 
	if ($sCommand eq "uwa_set") {
		print "\n";
		print "Usage: uwa_set -wa <work_area_name> [ -b <block_name> | -c <cluster_name ] [-r <revision_number>]\n"; 
		print "                       -wa <work_area_name> # work area name that should be created under local directory\n";
		print "						   # that should contains project's directories structure\n";
		print "                       -b <block_name>      # create a work area for this current block and his hierarchy sub blocks\n";
		print "                                            # if this block is not exist under git repository ,the script create Skeleton\n";
		print "                                            # of mandatory directories fot this block under user work area \n";
		print "                       -c <cluster_name>    # create a work area for this current cluster and his hierarchy sub blocks\n";
		print "                                            # if this cluster is not exist under git repository ,the script create Skeleton\n";
		print "                                            # of mandatory directories fot this cluster under user work area \n";
		print "                       -t <top_name>        # create a work area for this current top and his hierarchy sub clusters\n";
		print "                                            # if this top is not exist under git repository ,the script create Skeleton\n";
		print "                                            # of mandatory directories fot this top under user work area \n";
		print "                       -r <revision_number> # the block/cluster tag revision number , default is latest version\n";
		print "                       [ -help | -h ]       # print script usage\n"; 
		print "\n";
		print "Description: create user work area with name '-wa <work_area_name>' for project \$PROJCT_NAME\n";
		print "	     get block/cluster follow the revision if existing in git repository under local user work area \n";
		print "	     if version is latest (default) we checkout the latest version to uwa\n"; 
		print "	     if version is not latest (default) we set the path to look on global cluster/craton work area\n";
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
# Procedure:
#
# Description: load perl hash skelaton with definition of 
#              block/cluster directory structure 
#
#-------------
sub fnLoadProjectDirStructure {

  my $projectDirStr ;
  # Read structure 
  if (!($s_new_block_index)) {
	  $projectDirStr = "$ENV{PROJECT_HOME}/$ENV{PROJECT_NAME}\_dir_structure_new_block.pm";	
	  `cp $projectDirStr /tmp/uwa_set.$ENV{USER}.$$`;
           $projectDirStr = "/tmp/uwa_set.$ENV{USER}.$$";

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
                  my $sChild_folder = "$sRelease_work_area/$row";
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
		$sRlease_path = "$ENV{CRATON3_CLUSTER_ROOT}/$sCluster_name/$sRevision_number/$sCluster_name";
	}
	if ($sTop_name ne "") {
		$sRlease_path = "$ENV{CRATON3_TOP_ROOT}/$sTop_name/$sRevision_number/$sTop_name";
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
	printf $fh "%-2s %-25s %-20s\n","setenv", "UWA_ROOT", "$s_uwa_root";
	printf $fh "%-2s %-25s %-20s\n","setenv", "UWA_NAME", "$sWorkArea_name";
	foreach my $sOne_block (@l_all_hier_sub_blocks) {
		printf $fh "%-2s %-25s %-20s\n","setenv", "$sOne_block\_path", "$sMain_release_path/$sOne_block";
	}
	close $fh;
	print "Info: $sWorkArea_name/usr_setup_path file created follow the release revision .\n";

};# End sub fnSet_usr_setup_path
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
                            'r=s'      => \$sRevision_number   ,
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
        if (($sBlock_name eq "") && ($sCluster_name eq "") && ($sTop_name eq "")) { 
		print "\nWarning: you must run this script with '-b <block_name>' or '-c <cluster_name>' option \!\!|!|\n\n";
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
	if ( ($sBlock_name ne "") && ($sRevision_number ne "")) { # cannot use this option
		print "\nWarning: wrong option \!\!\!\n";
		print "         for block level you allways checkout the latest version directly from git repository \!\!\!\n\n";
		exit 0;
	}	
        # set the name of block or cluster that requested
	$sBlockCluster_name = "$sBlock_name $sCluster_name $sTop_name";
	$sBlockCluster_name =~ s/ //g;

	$s_current_dir = `pwd`;
	chomp($s_current_dir);
	if (-d $sWorkArea_name) {

		chdir($sWorkArea_name);
		if (-f "./usr_setup_path" ) {
			system("/bin/tcsh ./usr_setup_path");
		} else {
			print "\nError: no found usr_setup_path file under '$sWorkArea_name` \!\!\!\n\n";
			exit 0;	
		}
		print "YAYA $ENV{UWA_ROOT}\n";
		#-------------------------------
		# Check if is new block/cluster
		#-------------------------------
		my $sProj_subDir = `git ls-tree -d --name-only master`;
	        my @lProj_subDir = split("\n",$sProj_subDir);
	        $s_new_block_index = 0;
	        foreach my $one_subDir (@lProj_subDir) {
			if (($one_subDir eq "$sBlock_name") || ($one_subDir eq "$sCluster_name") || ($one_subDir eq "$sTop_name")) {
				$s_new_block_index = 1;
			}
		}
		if ($s_new_block_index) { # block exist in git depo
			print LOGFILE "Info: block/cluster/top '$sBlockCluster_name' exit in git repository \n";
			if ( ($sBlock_name ne "") || ($sRevision_number eq "")) { # get latest version to user wa
				$cmd = "git reset HEAD $sBlockCluster_name";
				fnRunSysCMD($cmd); 
				$cmd = "git checkout $sBlockCluster_name";
				fnRunSysCMD($cmd); 
			} else { # set paths to release version
				fnSet_usr_setup_path($sRevision_number,$sBlock_name,$sCluster_name,$sTop_name);
			}
		} else { # new block in git repository
			print LOGFILE "Info: block/cluster/top is not exist '$sBlockCluster_name' under git repository \n";
			print "Info: block/cluster is not exist '$sBlockCluster_name' under git repository \n";
			fnLoadProjectDirStructure();
			fnCreateUWAfollowProjStructure();
			# add .gitignore file under empty directory
			$cmd = "find -name .git -prune -o -type d -empty -exec sh -c \"echo this directory needs to be empty because reasons \> \{\}\/\.gitignore\" \\;";
			fnRunSysCMD($cmd); 
		}
		#-------------------------------

	} else {
		chdir($s_current_dir);
		print "\nError: no such work area with name '$sWorkArea_name' \!\!\! \n\n";
		close(LOGFILE);
		exit 0;
	}
	#chdir($s_current_dir);

	print LOGFILE  "\n\n--------------------------------------------------------------\n";
	print LOGFILE  "  uwa_set finished successfully !!!\n";
	print LOGFILE  "  work area folder created under '$s_current_dir/$sWorkArea_name'. \n";
	print LOGFILE  "--------------------------------------------------------------\n";
	print "\n\n--------------------------------------------------------------\n";
	print "  uwa_set finished successfully !!!\n";
	print "  work area folder created under '$s_current_dir/$sWorkArea_name'. \n";
	print "--------------------------------------------------------------\n";

        close(LOGFILE);
        print "\n\n\t* Info: you can find log file '$sLogFile' \n\n";
        exit 0;

#-------------------------------------------------------
#
#
#         --------   END  uwa_set.pl -------------     
#
#
#-------------------------------------------------------

