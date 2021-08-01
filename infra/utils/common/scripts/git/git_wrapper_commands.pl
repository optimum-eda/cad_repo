#!/usr/bin/perl -w
##**********************************************************************+
#*                                                                      * 
#* Script : git commands wrappers                                       *
#*                                                                      * 
#*                                                                      * 
#* Description : this script supporting wrappers                        *
#*                                                                      * 
#*       at_git_add                                                     * 
#*       at_git_clone                                                   *
#*       at_git_commit                                                  *
#*       at_git_revert                                                  *
#*       at_git_status                                                  * 
#*       at_git_push                                                    * 
#*       at_git_diff                                                    * 
#*       at_git_pull                                                    * 
#*       at_git_fetch                                                   * 
#*       at_git_checkout                                                * 
#*       at_git_stash                                                   * 
#*       at_git_branch                                                  * 
#*       at_git_merge                                                   * 
#*       at_git_pre_merge                                               * 
#*       at_git_reset                                                   * 
#*       at_git_rm                                                      * 
#*                                                                      * 
#*                                                                      * 
#* Written by: Duvdevani Amir                                           * 
#* Revision  : V0000001                                                 * 
#* Date      : Thu Mar 14 15:28:38 IST 2019                             * 
#*                                                                      * 
#***********************************************************************+
#
use lib '/project/infra/utils/common/scripts/environment/packages/';
use strict;
use warnings;
use Switch;
use Dump qw(dump);
use Carp;
use Cwd;
use Cwd 'abs_path';
use Getopt::Long;
use Common;
use File::Basename;
use Term::ANSIColor;
use Time::ParseDate qw(parsedate);
use POSIX qw(strftime);
my $iScrip_version = "V00002";
my $s_last_argv = "";
if (defined $ARGV[-1]) {
	$s_last_argv = "$ARGV[-1]";
}
my $sCommand = basename($0);
chomp($sCommand);
my $cmd = "";
my $msg = "";
my $sScriptName        = $sCommand;
my $sUser_name         =  $ENV{USER}; 
chomp($sUser_name);
my $bHelp              =  0; 
my $s_current_dir = "";
my $s_fileToAdd = "";
my $b_allFiles = 0;
my $s_repo_name = "";
my $s_tag_name = "";
my $s_dir_name  = "";
my $b_no_checkout  = 0;
my $s_depth  = "";
my @s_commit_message  = ();
my $s_commit_ish  = "";
my $s_stash_option  = "";
my $s_stash_name  = "";
my $s_new_name  = "";
my $s_del_name  = "";
my $s_branch_name  = "";
my $b_verbose = 0;
my $b_quit = 0;
my $b_index = 0;
my $b_continue = 0;
my $b_abort = 0;
my $b_tag = 0;
my $b_meld = 0;
my $b_tkdiff = 0;
my $b_origin = 0;
my $b_hard = 0;
my $b_commit = 0;
my $b_short = 0;
my $b_no_commit = 0;
my $b_force = 0;
my $b_rec = 0;
my $b_no_tags = 0;
my $b_fast_forward = 0;
my $b_int_single_commit = 0;
my $s_temp_merge_file_list = "";
my $i_red_color = 0;
#-------------- create log file ---------
chomp(my $sRunDate = `date`);
$sRunDate =~ s/ //g;
$sRunDate =~ s/:/_/g;
my $sLogFile = "/tmp/$sScriptName\_$sRunDate\_$sUser_name\_$$.log";
my $fh_merge_file ;
open LOGFILE, ">$sLogFile" or die "cannot open file $sLogFile : $!\n";
print LOGFILE "*----------------------------------------*\n";
print LOGFILE "*        $sCommand log file             \n";
print LOGFILE "*----------------------------------------*\n\n";
#----------- Usage --------------------------
#
#            Usage : git_wrapper_commands
#
#-------------------
sub ffnUsage { 
#--------------------------------------------------------------------------
# at_git_add
# ---------------
if ($sCommand eq "at_git_add") {
our $szUsage=<<EOF; 
usage: at_git_add   [-f <file_name> | -all ] 

    -f <file_name>           Add file contents to the index
    -all <relative_path_dir> add alll new files under relative dir path
   [-help | -h]              print script usage 

Description: Git Add one or more files to staging 
Note:	     This command must run under user work area 
             under folder \$PROJECT_HOME/workarea/\$USER/<user_work_area>/ 

script version : $iScrip_version
EOF
;
print $szUsage;
close(LOGFILE);
exit 0;
}
#--------------------------------------------------------------------------
# at_git_diff
# ---------------
if ($sCommand eq "at_git_diff") {
our $szUsage=<<EOF; 
usage: at_git_diff   [-tkdiff | -meld]  [-f <file_name> | -all ] 

    -f <file_name>           Add file contents to the index
    -all <relative_path_dir> add alll new files under relative dir path
    -orig                    run tkdiff from local master HEAD to origin repository master
    -short                   short report ,but this option can be run without gui -meld/-tkdiff option 
    -tkdiff                  show diff by tkdiff gui 
    -meld                    show diff by meld gui
   [-help | -h]              print script usage 

Description: Show changes between the working tree and the index or a tree, 
             changes between the index and a tree, changes between
             two trees, or changes between two files on disk.


Note:	     This command must run under user work area 
             under folder \$PROJECT_HOME/workarea/\$USER/<user_work_area>/ 

script version : $iScrip_version
EOF
;
print $szUsage;
close(LOGFILE);
exit 0;
};# End sub at_git_diff
#--------------------------------------------------------------------------
# at_git_clone
# ---------------
if ($sCommand eq "at_git_clone") {
our $szUsage=<<EOF; 
usage: at_git_clone [options] [--] -repo <repo_name> [-dir <dir_name>]

    -repo <repo_name>     be more verbose
    [-dir <dir_nam>]      target dir name to checkout
    -ver                  be more verbose
    -noc                  don't create a checkout
    -dep <depth>          create a shallow clone of that depth

Description: Create a working copy of a local repository
Note:	     This command must run under user work area 
             under folder \$PROJECT_HOME/workarea/\$USER/<user_work_area>/ 
script version : $iScrip_version
EOF
;
print $szUsage;
close(LOGFILE);
exit 0;
}
#--------------------------------------------------------------------------
# at_git_status
# ---------------
if ($sCommand eq "at_git_status") {
our $szUsage=<<EOF; 
usage: at_git_status [-rec]  

Description:   List the files you've changed and those you still need to add or commit.
Note:	       This command must run under user work area 
               under folder \$PROJECT_HOME/workarea/\$USER/<user_work_area>/ 

	[-rec] This option run recursive under user work area ,and check all git status
               under each block's folder (block's git repository) 

script version : $iScrip_version
EOF
;
print $szUsage;
close(LOGFILE);
exit 0;
}
#--------------------------------------------------------------------------
# at_git_commit
# ---------------
if ($sCommand eq "at_git_commit") {
our $szUsage=<<EOF; 
usage: at_git_commit -m <commit_message>  [ <file_name> | <directory_path> ] 

Option :
	-m <commit_message>               -  commit message that stored in revison history 
       [<file_name> | <directory_path> ]  -  file name , or relative directory path, for current directory is '.'

Description: Commit changes to head (but not yet to the remote repository)
Note:        This command must run under user work area 
             under folder \$PROJECT_HOME/workarea/\$USER/<user_work_area>/ 

script version : $iScrip_version
EOF
;
print $szUsage;
close(LOGFILE);
exit 0;
}
#--------------------------------------------------------------------------
# at_git_revert
# ---------------
if ($sCommand eq "at_git_revert") {
our $szUsage=<<EOF; 
usage: at_git_revert [options] -commit <commit-ish>

    -cid                 commit changes id
    -quit                end revert or cherry-pick sequence
    -continue            resume revert or cherry-pick sequence
    -abort               cancel revert or cherry-pick sequence

Description: Reverting creates new commits which contain an inverse
             of the specified commits changes. These revert commits 
             can then be safely pushed to remote repositories to 
             share with other developers.
Note:	     This command must run under user work area 
             under folder \$PROJECT_HOME/workarea/\$USER/<user_work_area>/ 

script version : $iScrip_version
EOF
;
print $szUsage;
close(LOGFILE);
exit 0;
};# at_git_revert
#--------------------------------------------------------------------------
# at_git_push
# ---------------
if ($sCommand eq "at_git_push") {
our $szUsage=<<EOF; 
usage: at_git_push [options] 

    -tags                 All refs under refs/tags are pushed, in addition to 
                          refspecs explicitly listed on the command line.
    -ver                  be more verbose

Description: The git push command is used to upload local repository 
             content to a remote repository. Pushing is how you transfer 
             commits from your local repository to a remote repo.
Note:	     This command must run under user work area 
             under folder \$PROJECT_HOME/workarea/\$USER/<user_work_area>/ 

script version : $iScrip_version
EOF
;
print $szUsage;
close(LOGFILE);
exit 0;
}
#--------------------------------------------------------------------------
# at_git_pull
# ---------------
if ($sCommand eq "at_git_pull") {
our $szUsage=<<EOF; 
usage: at_git_pull [options] 

    -ver                  be more verbose
    -commit               default is -no-commit
                          With --no-commit perform the merge but pretend the merge failed and 
                          do not autocommit, to give the user a chance to inspect and further tweak
                          the merge result before committing.



Description: The git pull command first runs git fetch which downloads 
             content from the specified remote repository. 
Note:	     This command must run under user work area 
             under folder \$PROJECT_HOME/workarea/\$USER/<user_work_area>/ 

script version : $iScrip_version
EOF
;
print $szUsage;
close(LOGFILE);
exit 0;
};# End sub at_git_pull
#--------------------------------------------------------------------------
# at_git_fetch
# ---------------
if ($sCommand eq "at_git_fetch") {
our $szUsage=<<EOF; 
usage: at_git_fetch [options] 

       -all
           Fetch all remotes.

       -no_tags
           By default, tags that point at objects that are downloaded from the remote repository are fetched and stored
           locally. This option disables this automatic tag following. The default behavior for a remote may be specified
           with the remote.<name>.tagopt setting. See git-config(1).

       -tags
           This is a short-hand for giving "refs/tags/:refs/tags/" refspec from the command line, to ask all tags to be
           fetched and stored locally. Because this acts as an explicit refspec, the default refspecs (configured with the
           remote.\$name.fetch variable) are overridden and not used.

       -force
           When git fetch is used with <rbranch>:<lbranch> refspec, it refuses to update the local branch <lbranch> unless
           the remote branch <rbranch> it fetches is a descendant of <lbranch>. This option overrides that check.

       -verbose
           Be verbose.

Description: git-fetch - Download objects and refs from another repository
             Fetches named heads or tags from one or more other repositories, 
             along with the objects necessary to complete them.
             The ref names and their object names of fetched refs are stored in 
             .git/FETCH_HEAD. This information is left for a
             later merge operation done by git merge.
 
Note:	     This command must run under user work area 
             under folder \$PROJECT_HOME/workarea/\$USER/<user_work_area>/ 

script version : $iScrip_version
EOF
;
print $szUsage;
close(LOGFILE);
exit 0;
};# End sub at_git_fetch
#--------------------------------------------------------------------------
# at_git_checkout
# ---------------
if ($sCommand eq "at_git_checkout") {
our $szUsage=<<EOF; 
usage: at_git_checkout [options] <relative_path> 

    -tag <tag_name>       checkout files in working tree from tag_name
    -force                When switching branches, proceed even if the index or the working
                          tree differs from HEAD. This is used to throw away local changes.
    -orig                 checkout from origin/master origin repository master
    <relative_path>       relative path to file or directory to checkout

Description: Updates files in the working tree to match
             the version in the index or the specified tree. If no
             paths are given, git checkout will also update HEAD 
             to set the specified branch as the current branch.
Note:	     This command must run under user work area 
             under folder \$PROJECT_HOME/workarea/\$USER/<user_work_area>/ 

Example:     checkout all files under common folder : 
             > at_git_checkout common/

             checkout all files under commom folder from tag common_ver_0002
             > at_git_checkout -tag common_ver_0002 common/

script version : $iScrip_version
EOF
;
print $szUsage;
close(LOGFILE);
exit 0;
};# End sub at_git_checkout
#--------------------------------------------------------------------------
# at_git_stash
# ---------------
if ($sCommand eq "at_git_stash") {
our $szUsage=<<EOF; 
usage: at_git_stash [options] 

       -op list 
       -op show [-st <stash>]
       -op drop [-q|-quiet] [-st <stash>]
       -op <pop | apply> [-index] [-q|-quiet] [-st <stash>]
       -op clear
       -op create

Description: Stash the changes in a dirty working directory away
             Use git stash when you want to record the current state 
             of the working directory and the index, but
             want to go back to a clean working directory. The command 
             saves your local modifications away and
             reverts the working directory to match the HEAD commit.

Note:	     This command must run under user work area 
             under folder \$PROJECT_HOME/workarea/\$USER/<user_work_area>/ 

Example:     >at_git_stash -op show
             >at_git_stash -op list
             >at_git_stash -op pop -st \"stash\@\{0\}\"       

script version : $iScrip_version
EOF
;
print $szUsage;
close(LOGFILE);
exit 0;
};# End sub at_git_stash
#--------------------------------------------------------------------------
# at_git_branch
# ---------------
if ($sCommand eq "at_git_branch") {
our $szUsage=<<EOF; 
usage: at_git_branch [options] 

	 -br <branch_name>      Create a new branch called <branch>. 
                                This does not check out the new branch.    
         -del <branch_name>     Delete the specified branch. This is a "safe" 
                                operation in that Git prevents you from deleting 
                                the branch if it has unmerged changes.
         -re <new_branch_name>  Rename the current branch to <branch>.
	 -all                   List all remote branches. 


Description: List, create, or delete branches in your repository.

Note:	     This command must run under user work area 
             under folder \$PROJECT_HOME/workarea/\$USER/<user_work_area>/ 

Example:  create new branch branch_v001:
           > at_git_branch -br branch_v001 
	  rename branch branch_v001 to branch_v002
           > at_git_branch -re branch_v002

script version : $iScrip_version
EOF
;
print $szUsage;
close(LOGFILE);
exit 0;
};# End sub at_git_branch
#--------------------------------------------------------------------------
# at_git_branch
# ---------------
if ($sCommand eq "at_git_branch") {
our $szUsage=<<EOF; 
usage: at_git_branch [options] 

	 -br <branch_name>      Create a new branch called <branch>. 
                                This does not check out the new branch.    
         -del <branch_name>     Delete the specified branch. This is a "safe" 
                                operation in that Git prevents you from deleting 
                                the branch if it has unmerged changes.
         -re <new_branch_name>  Rename the current branch to <branch>.
	 -all                   List all remote branches. 


Description: List, create, or delete branches in your repository.

Note:	     This command must run under user work area 
             under folder \$PROJECT_HOME/workarea/\$USER/<user_work_area>/ 

Example:  create new branch branch_v001:
           > at_git_branch -br branch_v001 
	  rename branch branch_v001 to branch_v002
           > at_git_branch -re branch_v002

script version : $iScrip_version
EOF
;
print $szUsage;
close(LOGFILE);
exit 0;
};# End sub at_git_branch
#--------------------------------------------------------------------------
# at_git_merge
# ---------------
if ($sCommand eq "at_git_merge") {
our $szUsage=<<EOF; 
usage: at_git_merge [options] 

      -orig        merge origin/master with repository master, this
                   option by deafult include commit option because of that reason
                   it must come with -m <commit_message> option
	           but if user run with option -no_commit than -m not necessary 
      [-commit]    This is the default option, Perform the merge and commit the result.
                   This option can be used to override --no-commit.
      -no_commit   With --no-commit perform the merge but pretend the merge failed 
                   and do not autocommit, to give the user a chance to inspect and further
                   tweak the merge result before committing.
      -m <message> commit message that stored in revison history 

Description: Join two or more development histories together,
             The target of this integration is always the currently 
             checked out HEAD branch.
             Git merge will combine multiple sequences of 
             commits into one unified history. 
             Git can automatically merge commits unless there
             are changes that conflict in both commit sequences.

Note:	     This command must run under user work area 
             under folder \$PROJECT_HOME/workarea/\$USER/<user_work_area>/ 

script version : $iScrip_version
EOF
;
print $szUsage;
close(LOGFILE);
exit 0;
};# End sub at_git_merge
#--------------------------------------------------------------------------
# at_git_merge
# ---------------
if ($sCommand eq "at_git_pre_merge") {
our $szUsage=<<EOF; 
usage: at_git_pre_merge 

Description: Generate report for all files that should be mereged 
	     This report comes by run commands :
		1) at_git_diff -orig -short	
		2) at_git_diff -short	

Note:	     This command must run under user work area 
             under folder \$PROJECT_HOME/workarea/\$USER/<user_work_area>/ 

script version : $iScrip_version
EOF
;
print $szUsage;
close(LOGFILE);
exit 0;
};# End sub at_git_pre_merge
#--------------------------------------------------------------------------
# at_git_reset
# ---------------
if ($sCommand eq "at_git_reset") {
our $szUsage=<<EOF; 
usage: at_git_reset [options] 

	-f <file>            Remove the specified file from the staging area, 
                             but leave the working directory unchanged. This 
                             unstages a file without overwriting any changes.
        -hard                Reset the staging area and the working directory 
                             to match the most recent commit. In addition to unstaging changes, 
                             the --hard flag tells Git to overwrite all changes in the 
                             working directory, too.  
        -commit <commit_idx> Move the current branch tip backward to commit, reset the staging 
                             area to match, but leave the working directory alone. All changes 
                             made since <commit> will reside in the working directory, 
                             which lets you re-commit the project history using cleaner, more 
                             atomic snapshots.		
        -hard -commit <commit_idx>   Move the current branch tip backward to <commit>  and reset both the
                             staging area and the working directory to match. This obliterates not 
                             only the uncommitted changes, but all commits after, as well. 

Description: Reset current HEAD to the specified state
             git reset is similar in behavior to git checkout.
             Where git checkout solely operates on the HEAD ref pointer, 
             git reset will move the HEAD ref pointer and the current 
             branch ref pointer. 

Note:	     This command must run under user work area 
             under folder \$PROJECT_HOME/workarea/\$USER/<user_work_area>/ 

Example:  
           

script version : $iScrip_version
EOF
;
print $szUsage;
close(LOGFILE);
exit 0;
};# End sub at_git_reset
#---------
#--------------------------------------------------------------------------
# at_git_rm
# ---------------
if ($sCommand eq "at_git_rm") {
our $szUsage=<<EOF; 
usage: at_git_rm  [-force] [-rec] -f <file> | <relative_path_dir>

DESCRIPTION
       Remove files from the index, or from the working tree and the index. git rm will not remove a file
       from just your working directory. (There is no option to remove a file only from the working tree and
       yet keep it in the index; use /bin/rm if you want to do that.) The files being removed have to be
       identical to the tip of the branch, and no updates to their contents can be staged in the index,
       though that default behavior can be overridden with the -f option. When --cached is given, the staged
       content has to match either the tip of the branch or the file on disk, allowing the file to be
       removed from just the index.

OPTIONS

       -force
           Override the up-to-date check.

       -rec
           Allow recursive removal when a leading directory name is given.

       -f <file> | <relative_path_dir>

           Files to remove. Fileglobs (e.g.  \*.c) can be given to remove all matching files. If you want Git
           to expand file glob characters, you may need to shell-escape them. A leading directory name (e.g.
           dir to remove dir/file1 and dir/file2) can be given to remove all files in the directory, and
           recursively all sub-directories, but this requires the -r option to be explicitly given.

Note:	   This command must run under user work area 
           under folder \$PROJECT_HOME/workarea/\$USER/<user_work_area>/ 

Example:  
           

script version : $iScrip_version
EOF
;
print $szUsage;
close(LOGFILE);
exit 0;
};# End sub at_git_rm
#---------

};# End sub ffnUsage 
#----------------------------------------------------------
# Procedure: fnHide_notStagedForCommit_message 
# Description: 
#-------------
sub fnHide_notStagedForCommit_message {

	  my $s_last_line = "";
	  my $i_changes_to_commit = 0;
	  my $s_last_use_inline = "";
	  my $s_last_not_staged_inline = "";
	  foreach my $s_line (@_) {
		chomp($s_line);
		#------------------------------
		# recognize the current section 
		if ($s_line =~ /Changes to be committed/) {
			$i_changes_to_commit = 1;
		} else {
			if (($s_line =~ /Changes not/) || ($s_line =~ /Untracked files/)) {
				$i_changes_to_commit = 0;
			}
		}
		#------------------------------
		if ($s_last_not_staged_inline =~ /Changes not staged for commit/) {
			if ($s_line =~ /\(use/) { 
				if ($s_last_use_inline eq "use passed") {;# new section after 'Changes not staged for commit'
					print STDOUT "$s_last_line\n";
					print STDOUT "$s_line\n";
					print LOGFILE "$s_last_line\n";
					print LOGFILE "$s_line\n";
					$s_last_line = $s_line;
					$s_last_use_inline = "";
				        $s_last_not_staged_inline = "";
				}	
				$s_last_use_inline = "use";
				if ($s_last_not_staged_inline =~ /Changes not staged for commit/)  {
					print STDOUT "$s_last_line\n";
					print LOGFILE "$s_last_line\n";
				}
			} else {
				if ($s_last_not_staged_inline =~ /Changes not staged for commit/) {
					if (!($s_last_line =~ /deleted:/) ) {
						print STDOUT "$s_last_line\n";
						print LOGFILE "$s_last_line\n";
					}
				}
				$s_last_use_inline = "use passed";
			}
			$s_last_line = $s_line ;next;
		}	
		if ($s_line =~ /Changes not staged for commit/) {$s_last_not_staged_inline = $s_line;$s_last_line = $s_line ;next;}	
		if (($i_changes_to_commit) && ($s_line =~ /deleted:/)) {
			print color("red")."$s_line\n";
			print color("reset")."";
			$i_red_color = 1;
		} else {
			print STDOUT "$s_line\n";
		}
		print LOGFILE "$s_line\n";
		$s_last_line = $s_line;
	  }

};# End sub fnHide_notStagedForCommit_message
#----------------------------------------------------------
# Procedure: fnPrintOut_notStagedForCommit_message 
# Description: 
#-------------
sub fnPrintOut_notStagedForCommit_messagefnPrintOut_notStagedForCommit_message {

	  my $s_last_line = "";
	  my $s_last_use_inline = "";
	  my $s_last_not_staged_inline = "";
	  foreach my $s_line (@_) {
		chomp($s_line);
		if ($s_last_not_staged_inline =~ /Changes not staged for commit/) {
			if ($s_line =~ /\(use/) { 
				if ($s_last_use_inline eq "use passed") {;# new section after 'Changes not staged for commit'
					$s_last_line = $s_line;
					$s_last_use_inline = "";
				        $s_last_not_staged_inline = "";
				}	
				$s_last_use_inline = "use";
			} else {
				$s_last_use_inline = "use passed";
				if (!($s_line =~ /deleted\:/)) {
					#print STDOUT "$s_line\n";
				}
			}
			if ($s_last_not_staged_inline ne "") {
				print STDOUT "$s_line\n";
				print LOGFILE "$s_line\n";
			}
			$s_last_line = $s_line 
		}	
		if ($s_line =~ /Changes not staged for commit/) {
			$s_last_not_staged_inline = $s_line;
			$s_last_line = $s_line ;
			print STDOUT "$s_line\n";
			print LOGFILE "$s_line\n";
		}	
		$s_last_line = $s_line;next;
	  }

};# End sub fnPrintOut_notStagedForCommit_message
#----------------------------------------------------------
# Procedure: 
# Description: 
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

};# End sub source
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
        print color("reset")."";
        print "\n\n\t* Info: you can find log file '$sLogFile' \n\n";
        close(LOGFILE);
        exit 1;
  }     
  if ( $message =~ /Warning:/ ) {
        print color("red")."$message";
        print color("reset")."";
        close(LOGFILE);
        exit 1;
  }     

};# End sub fnPrintMessageOut
#----------------------------------------------------------
# Procedure: 
# Description: 
#-------------
sub fnAnalyzeDiffResults {

	my ($s_orig_flag ,$s_report_flag,@l_cmd_results) = (@_);
     
        my $s_diff_files_idx     = 0;
	my $s_diff_section_start = 0;	
	my $s_diff_section_end   = 0;	
	my $s_dev_null           = 0;	
	my @l_last_diff_section  = ();
	my @l_short_line         = (); 
	my $s_short_line         = "";
	my $s_orig_str           = "";

	if (!($s_report_flag)) {
		print "\n#-------------- short diff report -------------------#\n";
		print LOGFILE "\n#-------------- short diff report -------------------#\n";
	}
	if ($s_orig_flag) { 
		$s_orig_str = "orig";
	} else {
		$s_orig_str = "master";
	}

	my $s_minus = 0;
	my $s_plus  = 0;
        my $s_merge_flag = 0; # 0- not manual  merge , 1- auto merge

	foreach my $s_curr_res_line (@l_cmd_results) {
		chomp($s_curr_res_line);
		if ($s_curr_res_line =~ /^diff \-\-git/) {
			if (scalar(@l_last_diff_section) > 0 ) {
				if ($s_dev_null == 0 ) {
					$s_short_line = $l_last_diff_section[0];
					@l_short_line = split(" ",$s_short_line); 	
					$s_short_line = $l_short_line[-1];	
					$s_short_line =~ s/^b\///;
					$s_short_line =~ s/^a\///;
					$s_diff_files_idx++;
					if (!($s_report_flag)) {
						print "$s_diff_files_idx) $s_short_line\n";
						print LOGFILE "$s_diff_files_idx) $s_short_line\n";
					} else {
						if ($s_orig_flag) { 
							$s_merge_flag = 0; # 0- not manual  merge , 1- auto merge
							$s_minus = 0;
							$s_plus  = 0;
							@_ = `git diff master origin/master -- $s_short_line`; 
							foreach my $s_res_diff (@_) {
								chomp($s_res_diff);
								next if ($s_res_diff =~ /^\-\-\-/);
								next if ($s_res_diff =~ /^\+\+\+/);
								next if ($s_res_diff eq "");
								if ( $s_res_diff =~ /^\+/ ) { $s_plus = 1 ;}
								if ( $s_res_diff =~ /^\-/ ) { $s_minus = 1 ;}
							}
							if (($s_plus == 1 ) && ($s_minus == 1)) { $s_merge_flag = 1 }; 
							if ($s_merge_flag) {
								printf $fh_merge_file "%-3s %-7s %-3s %-17s %-3s %-10s %-3s %-70s %-1s\n" ,"|","$s_orig_str" ,"|","manual merge","|","  +-" ,"|","$s_short_line","|";
							} else {
								printf $fh_merge_file "%-3s %-7s %-3s %-17s %-3s %-10s %-3s %-70s %-1s\n" ,"|","$s_orig_str" ,"|","auto merge", "|","  +/-" ,"|","$s_short_line","|";
							}
						} else {
							printf $fh_merge_file "%-3s %-7s %-3s %-17s %-3s %-10s %-3s %-70s %-1s\n" ,"|","$s_orig_str" ,"|","need to commit", "|","  ?  " ,"|","$s_short_line","|";
						}
					}
				}
			}
			$s_diff_section_start = 1;	
			$s_diff_section_end   = 0;	
			$s_dev_null           = 0;	
			@l_last_diff_section  = ();
			push(@l_last_diff_section,$s_curr_res_line);
		} else {
			push(@l_last_diff_section,$s_curr_res_line);
		}
	}
	if (scalar(@l_last_diff_section) > 0 ) {
		if ($s_dev_null == 0 ) {
			$s_short_line = $l_last_diff_section[0];
			@l_short_line = split(" ",$s_short_line); 	
			$s_short_line = $l_short_line[-1];	
			$s_short_line =~ s/^b\///;
			$s_short_line =~ s/^a\///;
			$s_diff_files_idx++;
			if (!($s_report_flag)) {
				print "$s_diff_files_idx) $s_short_line\n";
				print LOGFILE "$s_diff_files_idx) $s_short_line\n";
			} else {
				if ($s_orig_flag) { 
					$s_merge_flag = 0; # 0- not manual  merge , 1- auto merge
					$s_minus = 0;
					$s_plus  = 0;
					@_ = `git diff master origin/master -- $s_short_line`; 
					foreach my $s_res_diff (@_) {
						chomp($s_res_diff);
						next if ($s_res_diff =~ /^\-\-\-/);
						next if ($s_res_diff =~ /^\+\+\+/);
						if ( $s_res_diff =~ /^\+/ ) { $s_plus = 1 ;}
						if ( $s_res_diff =~ /^\-/ ) { $s_minus = 1 ;}
					}
					if (($s_plus == 1 ) && ($s_minus == 1)) { $s_merge_flag = 1 }; 
					if ($s_merge_flag) {
						printf $fh_merge_file "%-3s %-7s %-3s %-17s %-3s %-10s %-3s %-70s %-1s\n" ,"|","$s_orig_str" ,"|","manual merge","|","  +-" ,"|","$s_short_line","|";
					} else {
						printf $fh_merge_file "%-3s %-7s %-3s %-17s %-3s %-10s %-3s %-70s %-1s\n" ,"|","$s_orig_str" ,"|","auto merge", "|","  +/-" ,"|","$s_short_line","|";
					}
				} else {
					printf $fh_merge_file "%-3s %-7s %-3s %-17s %-3s %-10s %-3s %-70s %-1s\n" ,"|","$s_orig_str" ,"|","need to commit", "|","  ?  " ,"|","$s_short_line","|";
				}
			}
		}
	}
	if (!($s_report_flag)) {
		print "#----------------------------------------------------#\n";
		print LOGFILE "#----------------------------------------------------#\n";
	}
}
#----------------------------------------------------------
# Procedure: fnCheckIfWeUnderUWA
# Description: 
#-------------
sub fnCheckIfWeUnderUWA {

        # initalize 
	#if (defined $ENV{UWA_PROJECT_ROOT}) {$ENV{UWA_PROJECT_ROOT} = ""};
	if (defined $ENV{UWA_NAME}) {$ENV{UWA_NAME} = ""};

	#-----------------------------------
	# 1 - check if we are dircetly under space
	#     user work area
	# 2 - change dircetory to be under 
	#     $UWA_ROOT/$UWA_NAME/project/

	my $i_under_project_dir = 0;
	if (-d "project") {
		#chdir("project");
		#$i_under_project_dir = 1;
	}
	if ($i_under_project_dir == 0 ) {
		if (!($s_current_dir =~ /\/project\//)) {
			print "\nWarning: you must run this script under user 'project' work area folder \!\n\n"; 
			close(LOGFILE);
			exit 0;	
		}
		if (!(defined($ENV{PROJECT_HOME}))) {
			print "\nWarning: missing variable 'PROJECT_HOME' you must run setup_proj command before \!\n\n"; 
			close(LOGFILE);
			exit 0;	
		}
		my $s_project_dir = $ENV{PROJECT_HOME};
		$s_project_dir =~ s/\/project\///;
		$s_project_dir =~ s/\//_/;
		my $s_project_dir_keep = "/project/users/$ENV{USER}/$s_project_dir/";
		my $s_project_dir_tmp = "\/project\/users\/$ENV{USER}\/$s_project_dir\/";
		my $s_current_dir_tmp = $s_current_dir;
		$s_current_dir_tmp =~ s/$s_project_dir_tmp//;
		$s_current_dir_tmp =~ s/\// /g;
		my @l_uwa_name_tmp = split(" ",$s_current_dir_tmp);
		my $s_uwa_name_tmp = $l_uwa_name_tmp[0];
		if (!(-f "$s_project_dir_keep/$s_uwa_name_tmp/usr_setup_path")) {
			my $s_currPWD = `pwd`;
			chomp($s_currPWD);
			my $s_uwa_name_dir = basename($s_currPWD);	
			$s_project_dir_keep = "/space/users/$ENV{USER}/$s_project_dir/$s_uwa_name_tmp";
			$s_current_dir_tmp = $s_current_dir;
			@l_uwa_name_tmp = split(" ",$s_current_dir_tmp);
			if (-f "$s_project_dir_keep/usr_setup_path") {
				source "$s_project_dir_keep/usr_setup_path";
				print "Info: source '$s_project_dir_keep/usr_setup_path'\n";
			} else {
				print "\n\nWarning: missing file '$s_project_dir_keep/usr_setup_path' \!\!\!\n\n";
				close(LOGFILE);
				exit 0;	
			}
		} else {
			source "$s_project_dir_keep/$s_uwa_name_tmp/usr_setup_path";
			print "Info: source '$s_project_dir_keep/$s_uwa_name_tmp/usr_setup_path'\n";
		}
	}

	# check usr_setup_path is valid
	if ($ENV{UWA_SPACE_ROOT} eq "") {
		print "\nError: usr_setup_path file is not valid ,difenition is missing for '\$ENV{UWA_SPACE_ROOT}' \n\n";
		close(LOGFILE);
		exit 0;
	}
	if ($ENV{UWA_NAME} eq "") {
		print "\nError: usr_setup_path file is not valid ,difenition is missing for '\$ENV{UWA_NAME}' \n\n";
		close(LOGFILE);
		exit 0;
	}

};# End sub fnCheckIfWeUnderUWA
#----------------------------------------------------------
# Procedure: fnAtGitAdd
# Description: 
#-------------
sub fnAtGitAdd {

	if ($s_last_argv eq "-all") { 
		&ffnUsage;
	}

	if ($s_fileToAdd ne "") {
          my $s_file_path = "$s_current_dir/$s_fileToAdd";		
	  $cmd = "git add $s_file_path";
	  @_ = `$cmd 2>&1`;
	  if ("@_" =~ /Not a git repository/) {
		$msg = "\nError: you can run this command '$sCommand` only under '\$ENV{UWA_PROJECT_ROOT}/\$ENV{UWA_NAME}/<block_name>'";
		fnPrintMessageOut($msg);
	  }
	}

	if ($b_allFiles) {
          my $s_file_path = "$s_last_argv";		
          my $s_path_to_search = ".";
          if (($s_last_argv eq "" ) || ($s_last_argv eq ".")) {
		  $s_file_path = "$s_current_dir/";		
		  $s_path_to_search = "$s_current_dir/.";
	  }
	  #------------------------------------------------
          # remove all the file that should not be added
          # all file name that their prefix is started '#*'
          # all file name that their suffix is ended   '*~'
	  my $s_ignore1_add_files = `find $s_path_to_search -name \"\*\~\"`;
	  my @l_ignore1_add_files = split("\n",$s_ignore1_add_files);
	  my $s_ignore2_add_files = `find $s_path_to_search -name \"\#\*\"`;
	  my @l_ignore2_add_files = split("\n",$s_ignore2_add_files);
          if (scalar(@l_ignore1_add_files) > 0 ) {
		foreach my $s_ignore_file (@l_ignore1_add_files) {
			`rm -f $s_ignore_file`;
		}
	  }
          if (scalar(@l_ignore2_add_files) > 0 ) {
		foreach my $s_ignore_file (@l_ignore2_add_files) {
			`rm -f $s_ignore_file`;
		}
	  }
	  #--------------------------------------
          # check if folder exist files with deleted status 
          # that exist in git status result 
	  # section 'Changes not staged for commit' 		
	  $cmd = "git status $s_last_argv";
	  @_ = `$cmd`;
	  print "\n############## at_git_status #####################\n";
	  #fnPrintOut_notStagedForCommit_message(@_);
          print @_;		
	  print "##################################################\n";

	  print "\n";
	  print "You can see above all the files that should be added\n";
	  print "They are listed in section 'Changes not staged for commit' \n";
	  print "\n";
	  print "Do you want to continue with add process ?  \n";
	  print "yes/no :[no] ";
             my $sUserChoose = <STDIN>;
             chomp $sUserChoose;
             $sUserChoose=lc($sUserChoose);
             if ($sUserChoose eq "") {$sUserChoose = "no"; }
             while (($sUserChoose ne "no") && ($sUserChoose ne "yes")) {
		     print "Do you want to continue commit process ?  \n";
		     print "yes/no :[no] ";
                     $sUserChoose = <STDIN>;
                     chomp $sUserChoose;
                     $sUserChoose=lc($sUserChoose);
                     if ($sUserChoose eq "") {$sUserChoose = "no"; }
             }
             if ($sUserChoose eq "yes") {;# should continue
		  $cmd = "git add -A $s_file_path";
		  print "\n###################################\n";
		  fnRunSysCMD($cmd); 
		  print "cmd='$cmd'\n";
		  print "###################################\n";
	     } else {
		  print "\n##############################################\n";
		  print "# You choose to ignore this git add process.  ";
		  print "\n##############################################\n";
	     }
	};# all option with folder


};# sub fnAtGitAdd
#----------------------------------------------------------
# Procedure: fnAtGitClone
# Description: 
#-------------
sub fnAtGitClone {

	  my $s_cmd = "";
	  if ($s_repo_name eq "") { &ffnUsage; }
	  $s_cmd = $s_cmd . "$s_repo_name";

          if ($b_no_checkout) { $s_cmd = $s_cmd . " --no-checkout";}
          if ($s_depth ne "" ) { $s_cmd = $s_cmd . " --depth $s_depth";}
          if ($b_verbose) { $s_cmd = $s_cmd . " --verbose";}
          if ($s_dir_name ne "" ) { $s_cmd = $s_cmd . " $s_dir_name";}
	  
	  $cmd = "git clone $s_cmd";
	  print "\n###################################\n";
	  fnRunSysCMD($cmd); 
	  print "###################################\n";

};# End sub fnAtGitClone 
#----------------------------------------------------------
# Procedure: fnAtGitRevert
# Description: 
#-------------
sub fnAtGitRevert {

	  my $s_cmd = "";

	  if ($s_commit_ish eq "") {&ffnUsage; }

	  if (($b_quit) && ($b_continue)) {&ffnUsage; }
	  if (($b_quit) && ($b_abort)) {&ffnUsage; }
	  if (($b_continue) && ($b_abort)) {&ffnUsage; }

          if ($b_quit) { $s_cmd = $s_cmd . " --quit";}
          if ($b_continue) { $s_cmd = $s_cmd . " --continue";}
          if ($b_abort) { $s_cmd = $s_cmd . " --abort";}
	  
	  $cmd = "git revert $s_cmd $s_commit_ish";
	  print "\n###################################\n";
	  fnRunSysCMD($cmd); 
	  print "###################################\n";

};# End sub fnAtGitRevert 
#----------------------------------------------------------
# Procedure: fnAtGitRm
# Description: 
#-------------
sub fnAtGitRm { 

	  my $s_cmd = "";

	  if ($s_last_argv =~ /^\-/ ) { $s_last_argv = "";}
	  if ( $s_last_argv eq "" ) { &ffnUsage; } 
	  if ($s_fileToAdd ne "") {
		if (!(-f "$s_fileToAdd")) {
			print "\nWarning: no such file '$s_fileToAdd' \!\n\n"; 
			close(LOGFILE);
			exit 0;	
		}
		$s_last_argv = $s_fileToAdd;
	  }
          if ($b_force ) { $s_cmd = $s_cmd . " --force ";}
          if ($b_rec ) { $s_cmd = $s_cmd . " -r ";}

	  $cmd = "git rm $s_cmd $s_last_argv --dry-run";
	  #@_ = `$cmd`;
	  
	  print "\n############## at_git_rm #####################\n";
	  print "cmd='$cmd'\n";
	  @_ = `$cmd 2>&1`;
	  if ("@_" =~ /Not a git repository/) {
		$msg = "\nError: you can run this command '$sCommand` only under '\$ENV{UWA_PROJECT_ROOT}/\$ENV{UWA_NAME}/<block_name>'";
		fnPrintMessageOut($msg);
	  }
	  #fnRunSysCMD($cmd); 
	  #fnHide_notStagedForCommit_message(@_);
	  print "##################################################\n";
	  print "\n";
	  print "You can see above all the files that should be committed\n";
	  print "They are listed in section 'Changes to be committed' \n";
	  print "\n";
	  print "Do you want to continue remove process ?  \n";
	  print "yes/no :[no] ";
             my $sUserChoose = <STDIN>;
             chomp $sUserChoose;
             $sUserChoose=lc($sUserChoose);
             if ($sUserChoose eq "") {$sUserChoose = "no"; }
             while (($sUserChoose ne "no") && ($sUserChoose ne "yes")) {
		     print "Do you want to continue remove process ?  \n";
		     print "yes/no :[no] ";
                     $sUserChoose = <STDIN>;
                     chomp $sUserChoose;
                     $sUserChoose=lc($sUserChoose);
                     if ($sUserChoose eq "") {$sUserChoose = "no"; }
             }
             if ($sUserChoose eq "yes") {;# should continue
		  $cmd = "git rm $s_cmd $s_last_argv";
		  print "cmd='$cmd'\n";
		  print "\n###################################\n";
		  fnRunSysCMD($cmd); 
		  print "###################################\n";
	     } else {
		  print "\n##############################################\n";
		  print "# You choose to ignore this remove process.  ";
		  print "\n##############################################\n";
	     }

};# End sub fnAtGitRm
#----------------------------------------------------------
# Procedure: fnAtGitStatus
# Description: 
#-------------
sub fnAtGitStatus { 

	  $cmd = "git status";
	  @_ = `$cmd 2>&1`;
	  
	  print "\n############## at_git_status #####################\n";
	  print LOGFILE "\n############## at_git_status #####################\n";
	  #fnHide_notStagedForCommit_message(@_);
	  if ("@_" =~ /Not a git repository/) {
		$msg = "\nError: you can run this command '$sCommand` only under '\$ENV{UWA_PROJECT_ROOT}/\$ENV{UWA_NAME}/<block_name>'";
		fnPrintMessageOut($msg);
	  }
	  print @_;
	  print LOGFILE @_;
	  print "##################################################\n";
	  print LOGFILE "##################################################\n";

};# End sub fnAtGitStatus
#----------------------------------------------------------
# Procedure: fnAtGitStatus_rec
# Description: 
#-------------
sub fnAtGitStatus_rec { 

	  my ($s_WAproject_folder)  = (@_);

          my $s_currPWD = `pwd`;
	  chomp($s_currPWD);		

	   
	  chdir($s_WAproject_folder);
	  my $s_blocks_dir_list = `ls`;
          my @l_blocks_dir_list = ();
          my @l_blocks_dir_list_tmp = split(" ",$s_blocks_dir_list);
	  foreach my $s_one_dir (@l_blocks_dir_list_tmp) {
		if (-d "$s_one_dir") {
			push(@l_blocks_dir_list,$s_one_dir);
		}
	  }
	  if (scalar(@l_blocks_dir_list) > 0) {
		  print "\n############## at_git_status recursive #####################\n";
		  print LOGFILE "\n############## at_git_status recursive #####################\n";
		  foreach my $s_block_dir (@l_blocks_dir_list) {
			chdir($s_block_dir);
			$cmd = "git status";
			@_ = `$cmd 2>&1`;
			print "\n=========================================\n";
			print "----------- $s_block_dir --------- \n";
			print LOGFILE "\n=========================================\n";
			print LOGFILE "----------- $s_block_dir --------- \n";
			print @_;
			print LOGFILE @_;
			print "=========================================\n";
			print LOGFILE "=========================================\n";

			chdir($s_WAproject_folder);
		  }
	  }

	  print "##################################################\n";
	  print LOGFILE "##################################################\n";

 	  chdir($s_currPWD);

};# End sub fnAtGitStatus_rec
#----------------------------------------------------------
# Procedure: fnAtGitCommit
# Description: 
#-------------
sub fnAtGitCommit { 

	  if ((@s_commit_message eq "") ||  ($s_last_argv eq "@s_commit_message")) {
		print color("red")."\n*** Error: please follow the usage below \n\n";
		print color("reset")."";
		&ffnUsage; 
	  }

	  $i_red_color = 0;
	  $cmd = "git commit -m \"@s_commit_message\" $s_last_argv --dry-run";
	  @_ = `$cmd 2>&1`;
	  if ("@_" =~ /Not a git repository/) {
		$msg = "\nError: you can run this command '$sCommand` only under '\$ENV{UWA_PROJECT_ROOT}/\$ENV{UWA_NAME}/<block_name>'";
		fnPrintMessageOut($msg);
	  }
	  
	  print "\n############## at_git_commit #####################\n";
	  #fnHide_notStagedForCommit_message(@_);
	  print @_;
	  print "##################################################\n";
	  print "\n";
	  print "You can see above all the files that should be committed\n";
	  print "They are listed in section 'Changes to be committed' \n";
	  print "\n";
	  if ($i_red_color) {
		  print color("red")."Do you want to continue commit process ,even if you have files with 'deleted' status ?  \n";
		  print color("red")."yes/no :[no] ";
		  print color("reset")."";
	  } else {
		  print "Do you want to continue commit process ?  \n";
		  print "yes/no :[no] ";
	  }
             my $sUserChoose = <STDIN>;
             chomp $sUserChoose;
             $sUserChoose=lc($sUserChoose);
             if ($sUserChoose eq "") {$sUserChoose = "no"; }
             while (($sUserChoose ne "no") && ($sUserChoose ne "yes")) {
		     print "Do you want to continue commit process ?  \n";
		     print "yes/no :[no] ";
                     $sUserChoose = <STDIN>;
                     chomp $sUserChoose;
                     $sUserChoose=lc($sUserChoose);
                     if ($sUserChoose eq "") {$sUserChoose = "no"; }
             }
             if ($sUserChoose eq "yes") {;# should continue
		  $cmd = "git commit -m \"at_git_commit: @s_commit_message\" $s_last_argv";
		  print "cmd='$cmd'\n";
		  print "\n###################################\n";
		  fnRunSysCMD($cmd); 
		  print "###################################\n";
	     } else {
		  print "\n##############################################\n";
		  print "# You choose to ignore this commit process.  ";
		  print "\n##############################################\n";
	     }

};# End sub fnAtGitCommit
#----------------------------------------------------------
# Procedure: fnAtGitPush
# Description: 
#-------------
sub fnAtGitPush { 

	  my $s_cmd = "";

          if ($b_tag)     { 
		$s_cmd = $s_cmd . " origin --tags";
	  } else {
		$s_cmd = $s_cmd . " origin master";
	  }

	  $cmd = "git push $s_cmd --verbose --dry-run";
	  print "\n############## at_git_push #####################\n";
	  print "$cmd\n";
	  @_ = `$cmd 2>&1`;
	  if ("@_" =~ /Not a git repository/) {
		$msg = "\nError: you can run this command '$sCommand` only under '\$ENV{UWA_PROJECT_ROOT}/\$ENV{UWA_NAME}/<block_name>'";
		fnPrintMessageOut($msg);
	  }
	  print "##################################################\n";
	  print "\n";
	  print "Do you want to continue push process ?  \n";
	  print "yes/no :[no] ";
             my $sUserChoose = <STDIN>;
             chomp $sUserChoose;
             $sUserChoose=lc($sUserChoose);
             if ($sUserChoose eq "") {$sUserChoose = "no"; }
             while (($sUserChoose ne "no") && ($sUserChoose ne "yes")) {
		     print "Do you want to continue commit process ?  \n";
		     print "yes/no :[no] ";
                     $sUserChoose = <STDIN>;
                     chomp $sUserChoose;
                     $sUserChoose=lc($sUserChoose);
                     if ($sUserChoose eq "") {$sUserChoose = "no"; }
             }
             if ($sUserChoose eq "yes") {;# should continue
		  $cmd = "git push $s_cmd";
		  print "\n###################################\n";
		  print "# Running: '$cmd'\n";
		  fnRunSysCMD($cmd); 
		  print "###################################\n";
	     } else {
		  print "\n##############################################\n";
		  print "# You choose to ignore this push process.      ";
		  print "\n##############################################\n";
	     }





};# End sub fnAtGitPush
#----------------------------------------------------------
# Procedure: fnAtGitPull
# Description: 
#-------------
sub fnAtGitPull { 

	  my $s_cmd = "";

          if ($b_verbose) { $s_cmd = $s_cmd . " --verbose ";}
         if ($b_commit)  { 
		$s_cmd = $s_cmd . " --commit --verbose ";
          } else {
		$s_cmd = $s_cmd . " --no-commit --verbose ";
          }
          if ($b_force )    { $s_cmd = $s_cmd . " --force ";}

	  $cmd = "git pull $s_cmd";
	  print "\n###################################\n";
	  print "$cmd\n";
	  @_ = `$cmd 2>&1`;
	  if ("@_" =~ /Not a git repository/) {
		$msg = "\nError: you can run this command '$sCommand` only under '\$ENV{UWA_PROJECT_ROOT}/\$ENV{UWA_NAME}/<block_name>'";
		fnPrintMessageOut($msg);
	  }
	  print "###################################\n";

};# End sub fnAtGitPull
#----------------------------------------------------------
# Procedure: fnAtGitFetch
# Description: 
#-------------
sub fnAtGitFetch { 

	  my $s_cmd = "";

	  if ($s_last_argv =~ /^\-/ ) { $s_last_argv = "";}
          if ($b_verbose){ $s_cmd = $s_cmd . " --verbose"; }
          if ($b_force )    { $s_cmd = $s_cmd . " --force ";}
          if ($b_no_tags )  { $s_cmd = $s_cmd . " --no-tags ";}
          if ($b_tag )     { $s_cmd = $s_cmd . " --tags ";}
          if ($b_allFiles ) { $s_cmd = $s_cmd . " --all ";}

	  $cmd = "git fetch $s_cmd $s_last_argv --dry-run";
	  print "\n############## at_git_fetch #####################\n";
	  print "$cmd\n";
	  @_ = `$cmd 2>&1`;
	  if ("@_" =~ /Not a git repository/) {
		$msg = "\nError: you can run this command '$sCommand` only under '\$ENV{UWA_PROJECT_ROOT}/\$ENV{UWA_NAME}/<block_name>'";
		fnPrintMessageOut($msg);
	  }
	  print @_;
	  print LOGFILE @_;
	  print "##################################################\n";
	  print "\n";
	  print "You can see above all the commits IDs that should be fetched\n";
	  print "\n";
	  print "Do you want to continue fetch process ?  \n";
	  print "yes/no :[no] ";
             my $sUserChoose = <STDIN>;
             chomp $sUserChoose;
             $sUserChoose=lc($sUserChoose);
             if ($sUserChoose eq "") {$sUserChoose = "no"; }
             while (($sUserChoose ne "no") && ($sUserChoose ne "yes")) {
		     print "Do you want to continue fetch process ?  \n";
		     print "yes/no :[no] ";
                     $sUserChoose = <STDIN>;
                     chomp $sUserChoose;
                     $sUserChoose=lc($sUserChoose);
                     if ($sUserChoose eq "") {$sUserChoose = "no"; }
             }
             if ($sUserChoose eq "yes") {;# should continue
		  $cmd = "git fetch $s_cmd $s_last_argv";
		  print "\n###################################\n";
		  print "$cmd\n";
		  fnRunSysCMD($cmd); 
		  print "###################################\n";
	     } else {
		  print "\n##############################################\n";
		  print "# You choose to ignore this fetch process.  ";
		  print "\n##############################################\n";
	     }


};# End sub fnAtGitFetch
#----------------------------------------------------------
# Procedure:fnAtGitDiff 
# Description: 
#-------------
sub fnAtGitDiff { 

	  my $s_cmd = "";

	  if ($s_last_argv eq "-all" ) { &ffnUsage;}
          $s_last_argv =~ s/\-all/ /; 
          $s_last_argv =~ s/\-tkdiff/ /; 
          $s_last_argv =~ s/\-meld/ /; 
	  if ($s_last_argv =~ /^\-/ ) { $s_last_argv = "";}

          if ($b_meld)     { $s_cmd = $s_cmd . " difftool --dir-diff --tool=meld --gui "; }
          if ($b_tkdiff )  { $s_cmd = $s_cmd . " difftool --tool=tkdiff ";}
          if ($b_origin )  { 
		if (!(-e $s_last_argv)) {
			$s_cmd = $s_cmd . " master origin/master -- ";
		} else {
			$s_cmd = $s_cmd . " master origin/master ";
		}
	  } else {
		$s_cmd = $s_cmd . " HEAD ";
	  }
          if (!($b_meld) && !($b_tkdiff)) { $s_cmd =  " diff " . $s_cmd;} 
	  $cmd = "git $s_cmd $s_last_argv ";
	  print "\n############## at_git_diff #####################\n";
	  print LOGFILE "\n############## at_git_diff #####################\n";
	  if ($b_short == 0 ) {	
		  @_ = `$cmd`;
		  if (scalar(@_) == 0 ) {
			print "$cmd\n";
		  } else {	
			  print @_;	
			  print LOGFILE @_;	
		  }
	  } else {
		  print "$cmd\n";
		  @_ = `$cmd`;
		  fnAnalyzeDiffResults(0,0,@_);
	  }
	  print "##################################################\n";
	  print LOGFILE "##################################################\n";
	  print "\n";

};# End sub fnAtGitDiff
#----------------------------------------------------------
# Procedure: fnAtGitCheckout
# Description: 
#-------------
sub fnAtGitCheckout { 

	  my $s_cmd = "";
	  my $s_cmd_2 = "";

	  #-----------------------------------------
          # checkout for tag must be run 
          # directly under block's project folder
	  if ($s_tag_name ne "") {;
	      my $s_pwd_dir = `pwd`;
	      chomp($s_pwd_dir);	
	      if ($s_pwd_dir =~ /$ENV{UWA_PROJECT_ROOT}/) { 
		     $s_pwd_dir =~ s/$ENV{UWA_PROJECT_ROOT}//;
		     $s_pwd_dir =~ s/^\/+//;
		     my @l_tmp_dir = split("/",$s_pwd_dir);
		     if (scalar(@l_tmp_dir) != 2 ) {
				print "\nWarning: at_git_checkout with -tag option must be run only direct block's project folder \!\!\! \n\n";
				close(LOGFILE);
				exit 0;
	             } 
	      }
	  }
	  #-----------------------------------------
	  if ($s_last_argv =~ /^-/ ) {&ffnUsage; }
          if ($s_tag_name ne "") { 
		$s_cmd = $s_tag_name . $s_cmd ;
	  }
          if ($b_force )    { $s_cmd = $s_cmd . " --force ";}
          if ($b_origin )   { $s_cmd = " origin/master " . $s_cmd ;}
	  $cmd = "git checkout $s_cmd $s_last_argv";
	  @_ = `$cmd 2>&1`;
	  if ("@_" =~ /Not a git repository/) {
		$msg = "\nError: you can run this command '$sCommand` only under '\$ENV{UWA_PROJECT_ROOT}/\$ENV{UWA_NAME}/<block_name>'";
		fnPrintMessageOut($msg);
	  }
	  print "\n###################################\n";
	  print "$cmd\n";		
	  #print "@_\n";
	  print "###################################\n";

};# End sub fnAtGitCheckout
#----------------------------------------------------------
# Procedure: fnAtGitStash
# Description: 
#-------------
sub fnAtGitStash { 

	  if (($s_stash_option ne "list") &&
	      ($s_stash_option ne "show") &&
	      ($s_stash_option ne "drop") &&
	      ($s_stash_option ne "pop") &&
	      ($s_stash_option ne "apply") &&
	      ($s_stash_option ne "clear") &&
	      ($s_stash_option ne "create")) {
		 &ffnUsage; 
	  }

	  $s_stash_option =~ s/\-op//;
	  my $s_cmd = "";
	  $s_last_argv = "";
	  if ($s_stash_name ne "") { $s_last_argv = $s_stash_name;}
          if ($b_quit) { $s_cmd = $s_cmd . " --quiet " ;}
          if ($b_index) { $s_cmd = $s_cmd . " --index " ;}

	  $cmd = "git stash $s_stash_option $s_cmd $s_last_argv";
	  print "\n###################################\n";
	  print "$cmd\n";		
	  fnRunSysCMD($cmd); 
	  print "###################################\n";

};# End sub fnAtGitStash
#----------------------------------------------------------
# Procedure: fnAtGitBranch
# Description: 
#-------------
sub fnAtGitBranch { 

	  my $s_cmd = "";
	  if (($s_branch_name ne "") &&  ($s_del_name ne "")) { &ffnUsage;}
	  if (($s_branch_name ne "") &&  ($s_new_name ne "")) { &ffnUsage;}
	  if (($s_del_name ne "") &&  ($s_new_name ne "")) { &ffnUsage;}

          if ($s_branch_name ne "") { $s_cmd = $s_branch_name; goto LAUNCH_CMD;}
          if ($s_del_name ne "") { $s_cmd = " -d $s_del_name"; goto LAUNCH_CMD;}
          if ($s_new_name ne "") { $s_cmd = " -m $s_new_name"; goto LAUNCH_CMD;}
          if ($b_allFiles) { $s_cmd = " -A " ;}

	  LAUNCH_CMD:
	  $cmd = "git branch $s_cmd ";
	  print "\n###################################\n";
	  print "$cmd\n";		
	  fnRunSysCMD($cmd); 
	  print "###################################\n";

};# End sub fnAtGitBranch
#----------------------------------------------------------
# Procedure: fnAtGitMerge
# Description: 
#-------------
sub fnAtGitMerge { 

	  my $s_cmd = "";

          $s_cmd = $s_cmd . " --verbose ";
          if ($b_abort ) { $s_cmd = $s_cmd . " --abort ";}
          if ($b_fast_forward) { $s_cmd = $s_cmd . " --no-ff ";}
          if ($b_int_single_commit) { $s_cmd = $s_cmd . " --squash ";}
          if ($b_origin )  { 
		$s_cmd = $s_cmd . " origin/master ";
	  }
	  if ($b_no_commit == 0)  {;# merge and commit 
		if (scalar(@s_commit_message) == 0 ) {
			&ffnUsage;
		}
		$s_cmd = $s_cmd . " -m \"at_git_commit: comes from merge command, @s_commit_message\" ";
	  } else {
		$s_cmd = $s_cmd . " --no-commit ";
	  }
	  $cmd = "git merge $s_cmd ";
	  print "\n###################################\n";
	  print "$cmd\n";		
	  fnRunSysCMD($cmd); 
	  print "###################################\n";

};# End sub fnAtGitMerge
#----------------------------------------------------------
# Procedure: fnAtGitPreMerge
# Description: 
#-------------
sub fnAtGitPreMerge { 

	  $s_temp_merge_file_list = "/tmp/at_git_pre_merge_$$";
	  open $fh_merge_file, ">$s_temp_merge_file_list" or die "cannot open file $s_temp_merge_file_list : $!\n";
	  printf $fh_merge_file "+---------------------------------------------------------------------------------------------------------------------------+\n";
	  printf $fh_merge_file "%-3s %-7s %-3s %-17s %-3s %-10s %-3s %-70s %-1s\n" ,"|" ,"diff" ,"|","merge recommand" ,"|", "diff stat" ,"|","file place","|";
	  printf $fh_merge_file "%-1s %-7s %-3s %-17s %-3s %-10s %-3s %-70s %-1s\n" ,"|" ,"---------" ,"|","---------------" ,"|", "---------" ,"|","-------------------------","|";

	  $cmd = "git diff master origin/master | egrep -i '^(diff|deleted file mode)'";
	  print "\n############### at_git_pre_merge ####################\n";
	  print "$cmd\n";		
	  @_ = `$cmd`;
	  fnAnalyzeDiffResults(1,1,@_);
	  $cmd = "git diff HEAD | egrep -i '^(diff|deleted file mode)'";
	  print "$cmd\n";		
	  @_ = `$cmd`;
	  fnAnalyzeDiffResults(0,1,@_);
	  print "#####################################################\n";
	  printf $fh_merge_file "+---------------------------------------------------------------------------------------------------------------------------+\n";
	  close($fh_merge_file);
          @_ = `cat $s_temp_merge_file_list`;
	  foreach my $s_res_line (@_) {
		  print "$s_res_line";	
	  }
	  print "\nInfo: merge file list '$s_temp_merge_file_list`\n";

};# End sub fnAtGitPreMerge
#----------------------------------------------------------
# Procedure: fnAtGitReset
# Description: 
#-------------
sub fnAtGitReset { 

	  my $s_cmd = "";
	  $s_last_argv = "";

        
          if (($s_commit_ish ne "" ) && ($s_fileToAdd ne "")) {&ffnUsage;}

          if ($b_hard ) { $s_cmd = $s_cmd . " --hard ";}
          if ($s_commit_ish ne "" ) { $s_cmd = $s_cmd . " $s_commit_ish ";}
          if ($s_fileToAdd ne "") {
		if (!(-f "$s_fileToAdd")) {
			$s_fileToAdd =~ s/project\///;
			if (!(-f "$s_fileToAdd")) {
				print "\nWarning: no such file '$s_fileToAdd' \!\n\n"; 
				close(LOGFILE);
				exit 0;	
			}
		}
	        $s_last_argv = $s_fileToAdd;
	  }

	  $cmd = "git reset $s_cmd $s_last_argv";
	  print "\n###################################\n";
	  print "$cmd\n";		
	  fnRunSysCMD($cmd); 
	  print "###################################\n";

};# End sub fnAtGitReset
#---------------------------------------------------------------------------
#
#
#     ---------- MAIN   'git_wrapper_commands' -----------------------
#
#
#---------------------------------------------------------------------------
#

        if (not(&GetOptions('f=s'     => \$s_fileToAdd   ,
                            'all!'    => \$b_allFiles  ,
                            'repo=s'  => \$s_repo_name  ,
                            'tag=s'   => \$s_tag_name  ,
                            'dir=s'   => \$s_dir_name  ,
                            'noc!'    => \$b_no_checkout  ,
                            'dep=s'   => \$s_depth  ,
                            'verb!'   => \$b_verbose  ,
                            'mes=s'   => \@s_commit_message  ,
                            'm=s'     => \@s_commit_message  ,
                            'cid=s'   => \$s_commit_ish  ,
                            'op=s'    => \$s_stash_option  ,
                            'st=s'    => \$s_stash_name  ,
                            'br=s'    => \$s_branch_name  ,
                            're=s'    => \$s_new_name  ,
                            'del=s'   => \$s_del_name  ,
                            'quit!'   => \$b_quit  ,
                            'index!'  => \$b_index  ,
                            'cont!'   => \$b_continue  ,
                            'abort!'  => \$b_abort  ,
                            'tags!'   => \$b_tag  ,
                            'tkdiff!' => \$b_tkdiff  ,
                            'orig!'   => \$b_origin  ,
                            'meld!'   => \$b_meld  ,
                            'noff!'   => \$b_fast_forward  ,
                            'hard!'   => \$b_hard  ,
                            'force!'  => \$b_force  ,
                            'rec!'    => \$b_rec  ,
                            'commit!' => \$b_commit  ,
                            'short!'  => \$b_short  ,
                            'no_commit!' => \$b_no_commit  ,
                            'no_tags!'=> \$b_no_tags  ,
                            'squash!' => \$b_int_single_commit  ,
                            'help!'   => \$bHelp     )) || $bHelp ) {
          &ffnUsage;
        }
        #---------------------------
        # check args validation 
        #-----
        #if ($#ARGV==-1) { &szUsage; } 
        if ($bHelp) { &ffnUsage; }      

	$s_current_dir = `pwd`;
	chomp($s_current_dir);

	my $s_no_command = 1;

	switch ($sCommand) {
		case "at_git_add" {
			$s_no_command = 0;
			fnCheckIfWeUnderUWA();	
			if (($b_allFiles == 1) && ($s_fileToAdd ne "")) { &ffnUsage; }
			if ($s_fileToAdd ne "") {
				if (!(-f $s_fileToAdd)) {
					print "\nError: no such file '$s_fileToAdd' \!\!\! \n\n";
					close(LOGFILE);
					exit 0;
				}
			} else {  if ($b_allFiles == 0) {&ffnUsage;} }
			
			fnAtGitAdd();

		};# at_git_add
		case "at_git_clone" {
			$s_no_command = 0;
			fnAtGitClone();
		}
		case "at_git_status" {
			$s_no_command = 0;
			fnCheckIfWeUnderUWA();	
			if ($b_rec) {
				my $s_project_dir = "$ENV{UWA_PROJECT_ROOT}/$ENV{UWA_NAME}";
				if (!($s_current_dir =~ /$s_project_dir/)) {
					$msg = "\nError: you can run this command '$sCommand` only under '$s_project_dir'";
					fnPrintMessageOut($msg);
				} 
				fnAtGitStatus_rec($s_project_dir);
			} else {
				fnAtGitStatus();
			}
		}
		case "at_git_commit" {
			$s_no_command = 0;
			fnCheckIfWeUnderUWA();	
			fnAtGitCommit();
		}
		case "at_git_revert" {
			$s_no_command = 0;
			fnCheckIfWeUnderUWA();	
			fnAtGitRevert();
		}
		case "at_git_push" {
			$s_no_command = 0;
			fnCheckIfWeUnderUWA();	
			fnAtGitPush();
		}
		case "at_git_pull" {
			$s_no_command = 0;
			fnCheckIfWeUnderUWA();	
			fnAtGitPull();
		}
		case "at_git_fetch" {
			$s_no_command = 0;
			fnCheckIfWeUnderUWA();	
			fnAtGitFetch();
		}
		case "at_git_diff" {
			$s_no_command = 0;
			fnCheckIfWeUnderUWA();	
			fnAtGitDiff();
		}
		case "at_git_checkout" {
			$s_no_command = 0;
			fnCheckIfWeUnderUWA();	
			fnAtGitCheckout();
		}
		case "at_git_stash" {
			$s_no_command = 0;
			fnCheckIfWeUnderUWA();	
			fnAtGitStash();
		}
		case "at_git_branch" {
			$s_no_command = 0;
			fnCheckIfWeUnderUWA();	
			fnAtGitBranch();
		}
		case "at_git_merge" {
			$s_no_command = 0;
			fnCheckIfWeUnderUWA();	
			fnAtGitMerge();
		}
		case "at_git_pre_merge" {
			$s_no_command = 0;
			fnCheckIfWeUnderUWA();	
			my $s_project_dir = "$ENV{UWA_PROJECT_ROOT}/$ENV{UWA_NAME}";
			if (!($s_current_dir =~ /$s_project_dir/)) {
				$msg = "\nError: you can run this command '$sCommand` only under '$s_project_dir'";
				fnPrintMessageOut($msg);
			} 
			fnAtGitPreMerge();
		}
		case "at_git_reset" {
			$s_no_command = 0;
			fnCheckIfWeUnderUWA();	
			fnAtGitReset();
		}
		case "at_git_rm" {
			$s_no_command = 0;
			fnCheckIfWeUnderUWA();	
			fnAtGitRm();
		}


	};# switch
	if ($s_no_command) {
		$msg = "\nError: no such command '$sCommand` .\n\n";
		fnPrintMessageOut($msg);
	}
	#---------------------------

        print LOGFILE  "\n--------------------------------------------------------------\n";
        print LOGFILE  "  $sCommand finished successfully !!!\n";
        print LOGFILE  "--------------------------------------------------------------\n";
        print "\n--------------------------------------------------------------\n";
        print "  $sCommand finished successfully !!!\n";
        print "--------------------------------------------------------------\n";

        print "\n\t* Info: you can find log file '$sLogFile' \n\n";
        close(LOGFILE);
        exit 0;

#-------------------------------------------------------
#
#
# --------   END  git_wrapper_commands.pl -------------     
#
#
#-------------------------------------------------------

