#!/usr/bin/perl -w
##************************************************************************
#* Description                                                          * 
#*                                                                      * 
#* Revision                                                             * 
#************************************************************************
#
use lib '/home/amird/scripts/perl/packages';
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

my $aProject_dir_struct;
my $sUWApath = "";
my $cmd = "";
my $sScriptName        = $sCommand;
my $sUser_name         =  $ENV{USER}; 
my $sTop_dir_name      = "";
my $sBlock_name        =  "";
my $sWorkArea_name     =  "";
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
	if ($sCommand eq "create_repo_dir_structure") {
		print "\n";
		print "Usage: create_repo_dir_structure -wa <work_area_name> # work area name that should be created under local directory\n";
		print "						   # that should contains project's directories structure\n";
		print "			      [ -help | -h ]       # print script usage\n"; 
		print "\n";
		print "Description: create user work area with name '-wa <work_area_name>' for project \$PROJCT_NAME\n";
		print "	     under folder local directory\n";
		print "\n";
		print "script version : $iScrip_version\n";	
		exit 0;
	}
}


#----------------------------------------------------------
#
# Procedure:
#
# Description:
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
sub fnLoadProjectDirStructure {

  # Read structure 
  my $projectDirStr = "$ENV{PROJECT_HOME}/$ENV{PROJECT_NAME}\_dir_structure.pm";	
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
  # Debug data        
  #print "-- $aProject_dir_struct --\n";
  #dump $aProject_dir_struct;

} # End sub fnLoadProjectDirStructure
#----------------------------------------------------------
#
# Procedure:
#
# Description:
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
				`echo \"# Block_name        Tag_name \" >> $s_depends_file`;
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
#----------------------------------------------------------
#
# Procedure:
#
# Description:
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
}

#----------------------------------------------------------
#
# Procedure:
#
# Description:
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

}
#---------------------------------------------------------------------------
#
#           MAIN   'create_uwa'
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
	my $s_current_dir = `pwd`;
	chomp($s_current_dir);
	if (!(-d $sWorkArea_name)) {
		#$cmd = "mkdir -p $sWorkArea_name";
		#$cmd = "git clone -n $ENV{GIT_PROJECT_ROOT} $sWorkArea_name --depth 1";
		$cmd = "git clone $ENV{GIT_PROJECT_ROOT} $sWorkArea_name ";
		fnRunSysCMD($cmd); 
		chdir($sWorkArea_name);

		fnLoadProjectDirStructure();

		fnCreateUWAfollowProjStructure();
	        # add .gitignore file under empty directory
		$cmd = "find -name .git -prune -o -type d -empty -exec sh -c \"echo this directory needs to be empty because reasons \> \{\}\/\.gitignore\" \\;";
		fnRunSysCMD($cmd); 

	} else {
		chdir($s_current_dir);
		print "\nError: you already have work area with that name '$sWorkArea_name' \!\!\! \n\n";
		close(LOGFILE);
		exit 0;
	}
	chdir($s_current_dir);

print LOGFILE  "\n\n--------------------------------------------------------------\n";
print LOGFILE  "  create_repo_dir_structure finished successfully !!!\n";
print LOGFILE  "  work area folder created under '$s_current_dir/$sWorkArea_name'. \n";
print LOGFILE  "--------------------------------------------------------------\n";
print "\n\n--------------------------------------------------------------\n";
print "  create_repo_dir_structure finished successfully !!!\n";
print "  work area folder created under '$s_current_dir/$sWorkArea_name'. \n";
print "--------------------------------------------------------------\n";





        close(LOGFILE);
        print "\n\n\t* Info: you can find log file '$sLogFile' \n\n";
        exit 0;


