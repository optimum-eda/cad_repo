#!/bin/csh 
#
#  setup_project  
#
set NAME="`basename $0`"
set project_name = $1 
set project_rev  = $2 
set test_env     = $3 
if ( ($#argv == 3) && ($test_env == "test" )) then

else
  if ( $#argv != 2 ) then
   echo "-----------------------------------------------------"
   echo "Usage: setup_proj <project_name> <project_version>"
   echo "e.g. : setup_proj craton3 rev_a"
   goto END_SET 
  endif
endif

# set project home dir
set PROJECT_HOME_DIR = "/project/$project_name/$project_rev"
#------------------------------------
# check if project test_env required 
if ($test_env != "test") then
  set PROJECT_CSHRC = "$PROJECT_HOME_DIR/.$project_name.$project_rev.cshrc" 
else
  set PROJECT_CSHRC = "$PROJECT_HOME_DIR/.$project_name.$project_rev.test_env.cshrc" 
endif
#------------------------------------

if ( -d "$PROJECT_HOME_DIR" ) then
  if ( -f "$PROJECT_CSHRC" ) then
    echo $PROJECT_CSHRC
  else
    echo "------------" 
    echo "Warning: cannot find project .cshrc revision file \!\!\!"  
    echo "         no such project cshrc file : '$PROJECT_CSHRC'" 
  endif
else
  echo "------------" 
  echo "Warning: cannot find project directory : '$PROJECT_HOME_DIR' \!\!\!"  
  echo " "  
endif

END_SET:


