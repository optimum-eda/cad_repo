#!/bin/csh
#-------------------------------------
# ruby_cherry_proj rev_a environment variable
#
setenv REV rev_a
setenv PROJECT_NAME ruby_cherry_proj
setenv PROJECT_HOME /Users/aduvdevani/my_github/project_home/$PROJECT_NAME/$REV
setenv GIT_PROJECT_ROOT "git@github.com:optimum-eda"
set GIT_PROJECT_ROOT=/Users/aduvdevani/GIT/RUBY_CHERRY_REV_A
setenv UWA_PROJECT_ROOT $PROJECT_HOME/workarea/$USER
setenv UWA_SPACE_ROOT   $PROJECT_HOME/space/$USER
setenv RUBY_CHERRY_PROJ_RELEASE_AREA $PROJECT_HOME/release
if (!(-d $UWA_PROJECT_ROOT)) then
  mkdir $UWA_PROJECT_ROOT
endif
echo "----$UWA_PROJECT_ROOT-----"
cd "$UWA_PROJECT_ROOT/"
echo "+---------------------------------------------+"
echo "| set project  : ruby_cherry_proj             |"
echo "|     revision : rev_a                        |"
echo "|     git rep  : git@github.com:optimum-eda   |"
echo "+---------------------------------------------+"
echo ""

