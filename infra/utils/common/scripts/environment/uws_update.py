#!/usr/bin/env python
#=======================================================================+
#                                                                       |
#  Script : uws_update.py                                               |
#                                                                       |
# Description: this script update an existing  work area                |
#              for $PROJECT_NAME under $UWA_PROJECT_ROOT                |
#              workarea will be updated by the following options:       |
#       1) -wa        <work_area_name>  # work area folder name         |
#       6) -freeze    <sha/tag/latest>       # sha_list_to_sync_wa file |
#       7) -latest  this option cannot comes with -freeze option        |  
#                   this option overwrite on all sha's values that comes|
#                   from file sha_list_to_sync_wa with value 'latest'   |
#                   that is the origin/master latest sha.               |#                                                                       |
#               The script will update the update the work area to      |
#               the tag/sha sepcified for each section.                 |
#                                                                       |
# Written by: Ruby Cherry EDA  Ltd                                      |
# Date      : Fri July  2020                                            |
#                                                                       |
#=======================================================================+
import getopt, sys, urllib, time, os
import os.path
import re
from os import path
import logging
import flow_utils
import argparse
import shutil
global debug_flag 

from datetime import datetime
from sys import stdin,stdout

# current date and time
now = datetime.now()
dateTime = now.strftime("%d-%m-%Y_%H%M%S")

#--------- check setup_proj alreay ran -------
flow_utils.fn_check_setup_proj_ran()

#----------- create log file -----------------
#UWA_PROJECT_ROOT = os.getenv('UWA_PROJECT_ROOT')
UWA_PROJECT_ROOT         = os.getcwd()
#os.system('mkdir -p ' + UWA_PROJECT_ROOT + '/logs')
filelog_name = UWA_PROJECT_ROOT + '/logs/uws_update_logfile_' + dateTime + '.log'
global_command_log_file = 'logs/uws_commands.log'

#flow_utils.fn_init_logger(filelog_name)
#-------------- parse args -------- 
parser = argparse.ArgumentParser(description="Description: Update GIT user work area <work_area_name>." )
parser.add_argument('-debug',action='store_true')
requiredNamed = parser.add_argument_group('required named arguments')
#requiredNamed.add_argument('-wa',default='',help = "work area name",required=True)
parser.add_argument('-wa',default='',help = "work area name")
parser.add_argument('-here',action='store_true',help = "that relates to the current working dir if we are inside")
parser.add_argument('-freeze',default='',help = "version of the sha_list_to_sync_wa file , default is 'latest_stable' tag ")
parser.add_argument('-latest',action='store_true',help = "this option cannot comes with -freeze option ,this option overwrite on all sha's values that comes from file sha_list_to_sync_wa with value 'latest' that is the origin/master latest sha ")

args = parser.parse_args()

global update_all
#we update all if the -all flag is on or we are at -latest or we work on the -freeze
update_all =  args.latest or (args.freeze != '')


#----------- create log file -----------------
UWA_PROJECT_ROOT = os.getenv('UWA_PROJECT_ROOT')
## check if work area for update exist
#home_dir = UWA_PROJECT_ROOT + "/" +  args.wa
if ((args.wa == '') and (args.here)):
     args.wa = flow_utils.get_workarea()
     if args.wa == 'None':
         flow_utils.error("You are not exist under work area folder,\n\t -here option avalible only under user work area folder !!!")
     os.chdir(UWA_PROJECT_ROOT)

home_dir = flow_utils.concat_workdir_path(os.getcwd() ,  args.wa)
if not os.path.isdir(home_dir):
    flow_utils.error("Work area \'" + home_dir + "\' does not exists")
## check we have a log area (made by uws_create)
logs_dir = home_dir + "/logs"

if not os.path.isdir(logs_dir):
    flow_utils.error("Expecting a log directory at: " + logs_dir)

filelog_name = logs_dir + '/uws_update_logfile_' + dateTime + '.log'
flow_utils.fn_init_logger(filelog_name)
## command file log
local_uws_command_log_file = home_dir + "/" + global_command_log_file
flow_utils.write_command_line_to_log(sys.argv,local_uws_command_log_file)
flow_utils.home_dir = home_dir

#-------- global var ---------------
script_version = "V000001.0"

#=============================================
#   
#=============================================
#------------------------------------
# proc        : fn_check_args
# description :
#------------------------------------
def fn_check_args():

    if (args.debug):
        flow_utils.logging_setLevel('DEBUG')
        flow_utils.debug_flag = True
    else :
        flow_utils.logging_setLevel('INFO')

    flow_utils.debug("Start fn_check_args")

    if (args.wa == ''):
        flow_utils.error('You must give work area name , -wa <work_area_name>')
        usage()
        return False

    if (args.latest and args.freeze != ''):
        flow_utils.critical('The option -latest cannot come together with -freeze option !!!')
        usage()

    flow_utils.debug("Finish fn_check_args")
    return True

#------------------------------------
# proc        : fn_update_user_workspace
# description :
#------------------------------------
def fn_update_user_workspace ():

    flow_utils.debug("Start fn_update_user_workspace")

    ### check that it exists
    if not(os.path.isdir(args.wa)):
        flow_utils.error("Work area does not exists")

    os.chdir(args.wa)
    home_dir = os.getcwd()
    #flow_utils.fetch_all()

        #    proceed = is_working_area_clean(section, args.force, args.strict)
        #if (proceed):
         #   ok = flow_utils.switch_refrence(section, target_sha_dict[section], calling_function="uws_update")
         #   if not ok:
         #       revert_and_exit()
        #else:
         #   flow_utils.critical("Could not update " + section + " untill work area is clean")
         #   revert_and_exit()
        #os.chdir(home_dir)


    os.chdir(home_dir)
            
    flow_utils.debug("Finish fn_update_user_workspace")

#------------------------------------
# proc        : is_working_area_clean
# description : check if we have new / unchecked out files
#------------------------------------
def is_working_area_clean(section,force=False, strict=False):

    changed_table = flow_utils.get_work_in_progress_list(section)
    if (len(changed_table)):
        ## some file changed - print the list, notify the user and prompt
        print("uws_update: some files are not commited into git. updating \'" + section + "\' might overwrite changes done in these files")
        #print(*changed_table, sep = "\n")
        for i in range(len(changed_table)):
            print(changed_table[i])
        if (strict==True):
            print("Aborting")
            return False
        if (force==True):
            print("Overwriting")
            return True
        #answer = str(input("Proceed? y/n "))
        print('Proceed? [y|n] ' )
        answer = stdin.readline().strip("\n").split()[0]
        if ((answer == 'y') or (answer == 'Y') or (answer == 'yes')  or (answer == 'Yes')  or (answer == 'YES') ):
            flow_utils.debug("is_working_area_clean - user confirmed changes")
            return True
        else:
            flow_utils.debug("is_working_area_clean - user aborted because of changes")
            return False
    else:
        return True

#------------------------------------
# proc        : revert_and_exit
# description :  remove the working area in case of error
#------------------------------------
def revert_and_exit():
    sys.stdout.write("\033[1;31m")
    flow_utils.info("Reverting - we keep fetched files to " + args.wa + " but no change to SHA")
    sys.stdout.write("\033[0;0m")
    sys.stdout.flush()
    sys.exit(-1)

#------------------------------------
# proc        : main
# description :
#------------------------------------
def main ():

    if not fn_check_args() :
        return -1
    
    flow_utils.info("+======================================+")
    flow_utils.info("|              uws_update              |")
    flow_utils.info("+======================================+")
    flow_utils.debug("Start uws_update")
    
    curr_pwd = os.getcwd()

    fn_update_user_workspace()

    # -----------------------

    if path.isfile(filelog_name):
        flow_utils.info("You can find log file under '" + filelog_name + "'")

    flow_utils.info("User work area is ready under: " + UWA_PROJECT_ROOT + '/' + args.wa)
    flow_utils.info("+======================================+")
    flow_utils.info("| uws_update finished successfully ... |")
    flow_utils.info("+======================================+")
    flow_utils.debug("Finish uws_uptate")

#------------------------------------
# proc        : usage
# description :
#------------------------------------

def usage():

    print (' -------------------------------------------------------------------------')
    print (' Usage: uws_update -wa <work_area_name> [-des <version> ] [-dv <version> ] [-top <version> [-help]')
    print (' ')
    print (' description: update GIT user work area <work_area_name>')
    print ('              work area should exists under \$UWA_PROJECT_ROOT ')
    print (' ')
    print (' options    :')
    print ('              -wa        <work_area_name>  # work area folder name ')
    print('              -here                         # that relates to the current working dir if we are inside')
    print ('             -freeze    <sha/tag/latest>           # sha_list_to_sync_wa file')
    print ('             -latest                               # this option cannot comes with -freeze option ')
    print ('              -help      # print this usage')
    print (' ')
    print (' Script version:' + script_version)
    print (' -------------------------------------------------------------------------')
    sys.exit(' ')

#------------------------------------
#  ------------- END --------------
#------------------------------------
if __name__ == "__main__":
    main()
