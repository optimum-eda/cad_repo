#! /usr/bin/perl
#************************************************************************
#************************************************************************
#* Description                                                          * 
#*    Comman Perl Module                                                *
#*                                                                      * 
#* Revision                                                             * 
#*    2019-01-17 : Amir Duvdevani : Created                             *
#*									*
#************************************************************************
package Common;
use base 'Exporter';
our @EXPORT=('fnPrntVariable','fnErrMsg','fnWarnMsg','fnUsage','fnGetTimestamp','fnSetModule','fnGet_all_child_in_depends_list','fnGet_all_child_in_depends_list_andCheckout','fnGetBlockVersion','fnGetBlockVersion_old','fnGet_all_hier_child_depends_list','fnGet_all_hier_child_depends_list_new');
use strict;
use warnings;
use Dump qw(dump);
use Cwd;
use Cwd 'abs_path';
use Getopt::Long;
use Common;
use File::Basename;
use Term::ANSIColor;
use POSIX qw/strftime/;
#______________________________________________________________________
sub fnPrntVariable {
  my $bSort=0; 
  if ($#_==2) {
    $bSort = pop;
  }
  my $variable = shift; 
  my $level    = shift; 
  if    ( ref $variable eq ref {} ) {
    if ($bSort==0) {
      foreach my $key (keys %{$variable}) {
	my $value = $variable->{$key}; 
	printf ("%s%-30s => %-30s\n",$level,$key, $value) ;
	if    ( ref $value eq ref {} || ref $value eq ref []) {
	  &fnPrntVariable($value,"    $level",$bSort); 
	} 
      }
    } 
    else { 
      foreach my $key (sort keys %{$variable}) {
	my $value = $variable->{$key}; 
	printf ("%s%-30s => %-30s\n",$level,$key, $value) ;
	if    ( ref $value eq ref {} || ref $value eq ref []) {
	  &fnPrntVariable($value,"    $level",$bSort); 
	} 
      }
    }
  }
  elsif ( ref $variable eq ref [] ) {
    for my $index (0..$#{$variable}) {
      my $value = $variable->[$index];
      printf ("%s%4d - %-30s\n",$level,$index,$value) ;
      if    ( ref $value eq ref {} || ref $value eq ref []) {
#	$level = "    $level";
	&fnPrntVariable($value,"    $level",$bSort); 
      }
    }

  }
  else {
    printf STDOUT ("%s%s",$level,$variable); 
  }
}
#______________________________________________________________________
# proc : fnGetBlockVersion
# description:
#  get all .git_block_last_tag file under each
#  block and checkout the latest version ,
#  and read the tag version inside
sub fnGetBlockVersion {

  my ($s_depend_list_file,$sLogFile) = (@_);
  #print "debug: $s_depend_list_file,$sLogFile\n";
  my $s_latest_status = "";
  my $s_latest_index = 0;
  my $s_folder = dirname($s_depend_list_file);
  my $s_one_tag = "";

  my $s_curr_dir = `pwd`;
  chomp($s_curr_dir);	
  chdir($s_folder);	
  `git checkout .git_block_last_tag 2>&1`;  
  my $s_master_or_branch = `git branch 2>&1`;
  chomp($s_master_or_branch);	
  if ($s_master_or_branch =~ /master/) { 
	$s_master_or_branch = "master" 
  } else {	
	if ($s_master_or_branch =~ /Not a git repository/) { 
		$s_master_or_branch = "Not in git" 
	} else {
		$s_master_or_branch = "branch" 
	}
  }
  if (!(-f ".git_block_last_tag")) {
	if ($s_master_or_branch eq "master") {
		$s_one_tag = "latest";
	}
  } else {
	  $s_one_tag = `cat .git_block_last_tag`;
	  chomp($s_one_tag);
	  $s_latest_status = `git diff origin\/master \-\- .git_block_last_tag`;	  
	  if ($s_latest_status eq "") {$s_latest_index = 1;}
	  if ($s_master_or_branch ne "master") {$s_latest_index = 0;}
  }
  chdir($s_curr_dir);	
  open LOGFILE, ">>$sLogFile" or die "cannot open file $sLogFile : $!\n";
  my $s_curr_block = dirname($s_depend_list_file);
  printf "%-3s %-13s %-3s %-20s %-3s %-40s %-1s\n","|","$s_master_or_branch","|","$s_curr_block","|","$s_one_tag","|"; 
  printf LOGFILE "%-3s %-13s %-3s %-20s %-3s %-40s %-1s\n","|","$s_master_or_branch","|","$s_curr_block","|","$s_one_tag","|"; 
  if ( $s_latest_index ) {
	  printf "%-3s %-13s %-3s %-20s %-3s %-40s %-1s\n","|","$s_master_or_branch","|"," ","|","latest","|"; 
	  printf LOGFILE "%-3s %-13s %-3s %-20s %-3s %-40s %-1s\n","|","$s_master_or_branch","|"," ","|","latest","|"; 
  }
  printf "%-1s %-13s %-1s %-20s %-1s %-40s %-1s\n","+","---------------","+","----------------------","+","------------------------------------------","+"; 
  printf LOGFILE "%-1s %-13s %-1s %-20s %-1s %-40s %-1s\n","+","---------------","+","----------------------","+","------------------------------------------","+"; 

  close(LOGFILE);
  return 0; 
} ;#End sub fnGetBlockVersion
#______________________________________________________________________
sub fnGetBlockVersion_old {

  my ($s_depend_list_file,$sLogFile) = (@_);

  #print "debug: s_depend_list_file: $s_depend_list_file\n";
  open LOGFILE, ">>$sLogFile" or die "cannot open file $sLogFile : $!\n";
  #print "debug: cmd = git log -- $s_depend_list_file\n";
  my $s_file_log_res = `git log -- $s_depend_list_file`;	
  my @l_file_log_res = split("\n",$s_file_log_res);	
  my $s_last_commit = "";
  foreach my $s_one_line (@l_file_log_res) {
	if ($s_one_line =~ /^commit/) {
		$s_last_commit = $s_one_line;
		goto FIRST_COMMIT;
        }
  }
  FIRST_COMMIT:
  my @l_last_commit = split(" ",$s_last_commit);
  if (scalar(@l_last_commit) > 1 ) {	
	  my $s_last_commit = $l_last_commit[1];
          my $s_git_tags_for_file = `git tag --contains $s_last_commit`;		
          chomp($s_git_tags_for_file);
	  my $s_curr_block = dirname($s_depend_list_file);
          my @l_tags_list = split("\n",$s_git_tags_for_file);
	  my $s_idx = 0;
	  my $s_latest_index = 0;
	  my $s_latest_status = "";
	  my @l_tag_list = ();
          if (scalar(@l_tags_list) == 0 ) {@l_tags_list = "latest";}
	  foreach my $s_one_tag (@l_tags_list) {
		  $s_latest_status = `git diff origin\/master \-\- $s_depend_list_file`;	  
		  if ($s_latest_status eq "") {$s_latest_index = 1;}
                  next if !($s_one_tag =~ /$s_curr_block/);
		  if ($s_idx == 0 ) {
			$s_idx++;
			printf "%-3s %-20s %-3s %-40s %-1s\n","|","$s_curr_block","|","$s_one_tag","|"; 
			printf LOGFILE "%-3s %-20s %-3s %-40s %-1s\n","|","$s_curr_block","|","$s_one_tag","|"; 
		  } else {
			printf "%-3s %-20s %-3s %-40s %-1s\n","|"," ","|","$s_one_tag","|"; 
			printf LOGFILE "%-3s %-20s %-3s %-40s %-1s\n","|"," ","|","$s_one_tag","|"; 
		  }
		  push(@l_tag_list,$s_one_tag);
	  }
	  if ($s_latest_index) {
		  my $s_latest_exist = 0; 
		  foreach my $s_one_tag (@l_tag_list) {
			if ($s_one_tag eq "latest") { $s_latest_exist = 1;}
		  }
	          if ($s_latest_exist == 0 ) {
			if ($s_idx != 0 ) {
				printf "%-3s %-20s %-3s %-40s %-1s\n","|"," ","|","latest","|"; 
				printf LOGFILE "%-3s %-20s %-3s %-40s %-1s\n","|"," ","|","latest","|"; 
			} else {
				printf "%-3s %-20s %-3s %-40s %-1s\n","|","$s_curr_block","|","latest","|"; 
				printf LOGFILE "%-3s %-20s %-3s %-40s %-1s\n","|","$s_curr_block","|","latest","|"; 
			}
		  }
	  }
	  printf "%-1s %-20s %-1s %-40s %-1s\n","+","----------------------","+","------------------------------------------","+"; 
	  printf LOGFILE "%-1s %-20s %-1s %-40s %-1s\n","+","----------------------","+","------------------------------------------","+"; 
  } else {
	print "\nWarning: no found file '$s_depend_list_file' in git repo \!\!\!\n\n";
	print LOGFILE "\nWarning: no found file '$s_depend_list_file' in git repo \!\!\!\n\n";
	close(LOGFILE);
	return 0;
  }



  close(LOGFILE);
  return 0; 
} ;#End sub fnGetBlockVersion_old
#______________________________________________________________________
#
# Procedure: fnGet_all_hier_child_depends_list
#
# Description: get a list of all child depend list 
#
#-------------
sub fnGet_all_hier_child_depends_list {

	my ($sRlease_path,$sLogFile,$s_all_hier_sub_blocks) = (@_);

	open LOGFILE, ">>$sLogFile" or die "cannot open file $sLogFile : $!\n";
	my $sRelease_work_area  = dirname($sRlease_path);
	my $sCurrent_block      = basename($sRlease_path);
	$s_all_hier_sub_blocks = $s_all_hier_sub_blocks  . " " . $sCurrent_block ;
	#print "--->'$sRlease_path/depends.list'-------\n";
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
			close(LOGFILE);
			exit 0;
		   }
		   close(LOGFILE);
		   $s_all_hier_sub_blocks = fnGet_all_hier_child_depends_list($sChild_folder,$sLogFile,"$s_all_hier_sub_blocks");
		}
	} else {
		print "Info: no such depend list file - '$sRlease_path/depends.list' \n";
	}

   close(LOGFILE);
   return "$s_all_hier_sub_blocks";	
   	
};# End sub fnGet_all_hier_child_depends_list
#______________________________________________________________________
#
# Procedure: fnGet_all_hier_child_depends_list_new
#
# Description: get a list of all child depend list 
#
#-------------
sub fnGet_all_hier_child_depends_list_new {

	my ($sRlease_path,$sLogFile,$s_all_hier_sub_blocks) = (@_);

	
	open LOGFILE, ">>$sLogFile" or die "cannot open file $sLogFile : $!\n";
	my $sRelease_work_area  = dirname($sRlease_path);
	my $sCurrent_block      = basename($sRlease_path);
	$s_all_hier_sub_blocks = $s_all_hier_sub_blocks  . " " . $sCurrent_block . " head" . " " . $sCurrent_block;
	#print "--->'$sRlease_path/depends.list'-------\n";
	if (-f "$sRlease_path/depends.list") {
		my $sDep_filename = "$sRlease_path/depends.list";
		my $s_blocks_dep = basename($sRlease_path);
		open(my $fh_dep, '<:encoding(UTF-8)', $sDep_filename)
		  or die "Could not open file '$sDep_filename' $!";
		 
		while (my $row = <$fh_dep>) {
		  chomp $row;
	          next if($row =~ /^\/\//);		
	          next if($row =~ /^\#/);		
		  my @l_row = split(" ",$row);
		  my $s_num_elem_in_line = scalar(@l_row);			
                  my $sChild_folder = "$l_row[0]";
		  if ($s_num_elem_in_line < 2 ) {
			print color("red")."\nError: no found tag version for block '$sChild_folder' in depens.list file\!\!\!\n\n";
			print color("reset")."";
			print LOGFILE "\nError: no found tag version for block '$sChild_folder' in depens.list file\!\!\!\n\n";
			close(LOGFILE);
			exit 0;
		   }
                   my $sChild_ver = "$l_row[1]";
		   close(LOGFILE);
		   $s_all_hier_sub_blocks = $s_all_hier_sub_blocks  . " " . $sChild_folder . " " . $sChild_ver . " " . $s_blocks_dep;
		   my $s_project_name = $ENV{PROJECT_NAME};
		   my $s_release_root_area = uc("$s_project_name\_RELEASE_AREA");

                   my $sChild_name = $sChild_folder;
                   $sChild_name =~ s/_path//; 
		   $s_all_hier_sub_blocks = fnGet_all_hier_child_depends_list_new("$ENV{$s_release_root_area}/$sChild_name/$sChild_ver",$sLogFile,"$s_all_hier_sub_blocks");
		}
	} else {
		print "Info: no such depend list file - '$sRlease_path/depends.list' \n";
	}

   close(LOGFILE);
   return "$s_all_hier_sub_blocks";	
   	
};# End sub fnGet_all_hier_child_depends_list_new
#______________________________________________________________________
sub fnErrMsg {
  my $ErrorCode = shift;
  my $ErrorMsg  = shift;
  my $szErrTxt  = sprintf("Error:(%d): $0: \t%s",$ErrorCode,$ErrorMsg);
  print STDERR color 'bold red on_black';
  print STDERR $szErrTxt;
  print STDERR color 'reset'; 
  print STDERR "\n";
  &fnUsage();
}
#______________________________________________________________________
sub fnWarnMsg {
  my $ErrorCode = shift;
  my $ErrorMsg  = shift;
  my $szErrTxt  = sprintf("Warning:(%d): $0: %s",$ErrorCode,$ErrorMsg);
  print STDERR color 'bold cyan on_black';
  print STDERR $szErrTxt;
  print STDERR color 'reset'; 
  print STDERR "\n";
}
#______________________________________________________________________
#
# Procedure: fnGet_all_child_in_depends_list
# Description: get a list of all child depend list 
#-------------
sub fnGet_all_child_in_depends_list {

	my ($sRlease_path,$sLogFile) = (@_);

	my $sRelease_work_area      = dirname($sRlease_path);
	my $sCurrent_block          = basename($sRlease_path);
	my @l_child_in_depends_list = ();

	open LOGFILE, ">>$sLogFile" or die "cannot open file $sLogFile : $!\n";
	if (-f "$sRlease_path/depends.list") {
		my $sDep_filename = "$sRlease_path/depends.list";
		open(my $fh_dep, '<:encoding(UTF-8)', $sDep_filename)
		  or die "Could not open file '$sDep_filename' $!";
		 
		while (my $row = <$fh_dep>) {
		  chomp $row;
	          next if($row =~ /^\/\//);		
	          next if($row =~ /^\#/);		
	          next if($row eq "" );		
		  my @l_row = split(" ",$row);
                  my $sChild_folder = "$sRelease_work_area/$l_row[0]";
		  if (!(-d "$sChild_folder")) {
			print "\nWarning: no such blcok directory  '$sChild_folder' \!\!\!\n\n";
			print LOGFILE "\nWarning: no such blcok directory  '$sChild_folder' \!\!\!\n\n";
			close(LOGFILE);
			return 1;
		   }
		   push(@l_child_in_depends_list,$sChild_folder);	
		}
	} 
	close(LOGFILE);
	return @l_child_in_depends_list;

};# End sub fnGet_all_child_in_depends_list
#______________________________________________________________________
#
# Procedure: fnGet_all_child_in_depends_list_andCheckout
# Description: get a list of all child depend list 
#              and checkout following the input tag
#-------------
sub fnGet_all_child_in_depends_list_andCheckout {

	my ($sRlease_path,$sLogFile,$scurrTagName) = (@_);

	my $sRelease_work_area      = dirname($sRlease_path);
	my $sCurrent_block          = basename($sRlease_path);

	open LOGFILE, ">>$sLogFile" or die "cannot open file $sLogFile : $!\n";
	if (-f "$sRlease_path/depends.list") {
		my $sDep_filename = "$sRlease_path/depends.list";
		open(my $fh_dep, '<:encoding(UTF-8)', $sDep_filename)
		  or die "Could not open file '$sDep_filename' $!";
		 
		while (my $row = <$fh_dep>) {
		  chomp $row;
	          next if($row =~ /^\/\//);		
	          next if($row =~ /^\#/);		
	          next if($row eq "" );		
		  my @l_row = split(" ",$row);
		  my $s_child_name = $l_row[0];	
                  my $sChild_folder = "$sRelease_work_area/$l_row[0]";
		  if (!(-d "$sChild_folder")) {
			print "\nWarning: no such blcok directory  '$sChild_folder' \!\!\!\n\n";
			print LOGFILE "\nWarning: no such blcok directory  '$sChild_folder' \!\!\!\n\n";
			close(LOGFILE);
			return 1;
		   }
		   my $cmd = "git checkout $scurrTagName $s_child_name/*";
                   #print "Info: running '$cmd'\n";			
		   system($cmd); 
	           $cmd = "git checkout $scurrTagName $s_child_name/depends.list";
                   #print "2Info: running '$cmd'\n";			
		   system($cmd); 
		   printf "Info: for block %-20s the version that checked out is %-30s\n",$s_child_name,$scurrTagName;
		   printf LOGFILE "Info: for block %-20s the version that checked out is %-30s\n",$s_child_name,$scurrTagName;

		   close(LOGFILE);
                   #print "2Info: running 'fnGet_all_child_in_depends_list_andCheckout\($sChild_folder,$sLogFile,$scurrTagName\)'\n";			
		   fnGet_all_child_in_depends_list_andCheckout("$sChild_folder",$sLogFile,$scurrTagName);
 
		}
	} 

};# End sub fnGet_all_child_in_depends_list_andCheckout
#______________________________________________________________________
sub fnGetTimestamp {
#  return my $szTimeStamp = sprintf(strftime('%d-%b-%Y %H:%M:%S',localtime)); ## outputs 17-Dec-2008 10:08:33
  return my $szTimeStamp = sprintf(strftime('%Y%m%d_%H%M%S',localtime));
}
#______________________________________________________________________
sub fnUsage {
  print STDERR color 'bold';# green on_black';
  print STDERR $main::szUsage;
  print STDERR color 'reset'; 
  exit;
}
#______________________________________________________________________
#---------------------------------------------------
# fnSetModule
#
#  discription : according to env file set module setting if needed 
#
#-----------------------------------------------------  

#perl /tools/common/pkgs/modules/current/init/perl.pm
# define modules runtine quarantine configuration
#$ENV{'MODULES_RUN_QUARANTINE'} = 'ENVVARNAME';
#--------------------------------------------
# setup quarantine if defined

1



