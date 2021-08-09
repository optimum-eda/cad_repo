#!/usr/bin/env python
# =====================================================================+
#                                                                     |
# Script : uws_create.py                                              |
#                                                                     |
# Description: this script creates new user work area under the        |
#  directory specified in the -wa parameter.                          |
#                                                                     |
#                                                                     |
# Written by: Ruby Cherry EDA  Ltd                                    |
# Date      : Mon Aug  9 22:51:18 IDT 2021                            |
#                                                                     |
# =====================================================================+
import sys
import os
import os.path
from os import path
import logging
import flow_utils
import argparse
global debug_flag 
global filelog_name 

from datetime import datetime
# current date and time
now = datetime.now()
dateTime = now.strftime("%d-%m-%Y_%H%M%S")

#--------- check setup_proj alreay ran -------
#flow_utils.fn_check_setup_proj_ran()

#----------- create log file -----------------
#UWA_PROJECT_ROOT = os.getenv('UWA_PROJECT_ROOT')
UWA_PROJECT_ROOT = os.getcwd()
global_log_file = 'logs/uws_create_logfile_' + dateTime + '.log'
global_command_log_file = 'logs/uws_commands.log'

#-------------- parse args --------
parser = argparse.ArgumentParser(description="Description: Create GIT user work area <work_area_name>")
requiredNamed = parser.add_argument_group('required named arguments')
requiredNamed.add_argument('-wa',default='',help = "work area name",required=True)
parser.add_argument('-debug',action='store_true')
requiredNamed.add_argument('-b',default='latest',help = "block name",required=True)
parser.add_argument('-ver',default='main',help = "block version")
args = parser.parse_args()

#-------- global var ---------------
script_version = "V000001.0"
home_dir = flow_utils.concat_workdir_path(os.getcwd() ,  args.wa)
flow_utils.home_dir = home_dir
#=============================================
#
#=============================================
#------------------------------------
# proc        : fn_check_args
# description : check script's inputs args
#------------------------------------
def fn_check_args():

    if (args.debug):
        flow_utils.logging_setLevel('DEBUG')
        flow_utils.debug_flag = True
    else :
        flow_utils.logging_setLevel('INFO')

    flow_utils.debug("Start fn_check_args")

    if (args.wa == ''):
        flow_utils.critical('You must give work area name , -wa <work_area_name>')
        usage()

    if (args.b == ''):
        flow_utils.critical('Tou must give work area name , -b <block_name>')
        usage()

    if not("GIT_PROJECT_ROOT" in os.environ):
        flow_utils.error("envirenment varable 'GIT_PROJECT_ROOT' not define !!! \n Please run setup_proj command")
    if not("GIT_CAD_REPO" in os.environ):
        flow_utils.error("envirenment varable 'GIT_CAD_REPO' not define !!! \n Please run setup_proj command")

    flow_utils.debug("Finish fn_check_args")

#------------------------------------
# proc        : fn_ignore_pull_merge
# description :
#------------------------------------
def fn_ignore_pull_merge ():

    cmd = 'echo "* merge=verify" > .git/info/attributes'
    os.system(cmd)
    cmd = 'git config merge.verify.name "NTIL manual merge"'
    flow_utils.info("run command : " + cmd)
    if not (flow_utils.git_cmd(cmd)):
         revert_and_exit()
    cmd = 'git config merge.verify.driver false'
    flow_utils.info("run command : " + cmd)
    if not (flow_utils.git_cmd(cmd)):
         revert_and_exit()

#------------------------------------
# proc        : fn_create_user_workspace
# description : create user work space
#               following top block's depends list file
#------------------------------------
def fn_create_user_workspace ():

    global filelog_name
    global home_dir

    flow_utils.debug("Start fn_create_user_workspace")

    UWA_PROJECT_ROOT   = os.getcwd()
    GIT_CAD_REPO       = os.getenv('GIT_CAD_REPO')
    GIT_PROJECT_ROOT   = os.getenv('GIT_PROJECT_ROOT')

    home_dir = UWA_PROJECT_ROOT + '/' + args.wa

    # check work area already exist
    if path.isdir(UWA_PROJECT_ROOT + '/' + args.wa):
        flow_utils.critical("work area '" + UWA_PROJECT_ROOT + '/' + args.wa + "' already exist ....")
        sys.exit(1)

    os.chdir(UWA_PROJECT_ROOT)
    os.mkdir(args.wa, 0o755 );
    os.chdir(args.wa)

    ## create logging directory only
    #  after we have a work area
    #os.system('mkdir -p logs')
    flow_utils.run_sys_cmd('mkdir -p logs')
    filelog_name = home_dir + '/' + global_log_file
    flow_utils.fn_init_logger(filelog_name)
    flow_utils.info("+======================================+")
    flow_utils.info("|             uws_create               |")
    flow_utils.info("+======================================+")

    #-----------------------------------
    # clone --- block -- git repo
    #
    os.chdir(home_dir)
    flow_utils.clone_block(args.b,args.ver,filelog_name)
    #--------
    # build hier design struct with all block's child and
    # their version following depends list file
    # and create user work area
    myHierDesignDict = {}
    myHierDesignDict = flow_utils.build_hier_design_struct(args.b,args.ver,filelog_name,myHierDesignDict,top_block=True)
    flow_utils.print_out_design_hier(myHierDesignDict)
    #--------
    flow_utils.debug("Finish fn_create_user_workspace")

#------------------------------------
# proc        : revert
# description : remove the working area in case of error
#------------------------------------
def revert_and_exit():

    global filelog_name

    sys.stdout.write("\033[1;31m")
    flow_utils.info("Reverting - removing work area " + args.wa)
    sys.stdout.write("\033[0;0m")
    home_dir = UWA_PROJECT_ROOT + '/' + args.wa
    os.chdir(UWA_PROJECT_ROOT)
    flow_utils.fn_close_logger(filelog_name)
    os.system("rm -rf " + home_dir)
    sys.stdout.flush()
    sys.exit(-1)

#------------------------------------
# proc        : main
# description :
#------------------------------------
def main ():

    fn_check_args()

    flow_utils.debug("Start uws_create")

    curr_pwd = os.getcwd()

    #-----------------------
    # create user work area
    fn_create_user_workspace()
    #-----------------------
    # store command line in logs/uws_commans.log
    local_uws_command_log_file = UWA_PROJECT_ROOT + "/" + args.wa + "/" + global_command_log_file
    flow_utils.write_command_line_to_log(sys.argv,local_uws_command_log_file)
    #-----------------------
    local_log_file = UWA_PROJECT_ROOT + "/" + args.wa + "/" + global_log_file
    if path.isfile(local_log_file):
        flow_utils.info("You can find log file under '" + local_log_file + "'")

    flow_utils.info("User work area is ready under: " + UWA_PROJECT_ROOT + '/' + args.wa)
    flow_utils.info("+======================================+")
    flow_utils.info("| uws_create finished successfully ... |")
    flow_utils.info("+======================================+")
    flow_utils.info("")
    flow_utils.info("")

    flow_utils.debug("Finish uws_create")
#------------------------------------
# proc        : uws_create usage
# description :
#------------------------------------
def usage():

    print(' -------------------------------------------------------------------------')
    print(' Usage: uws_create -wa <work_area_name> [-help]')
    print(' ')
    print(' description: create GIT user work area <work_area_name>')
    print('              work area should be created under \$UWA_PROJECT_ROOT ')
    print(' ')
    print(' options    :')
    print('              -wa   <work_area_name>       # work area folder name ')
    print('              -b    <block_name>           # top block name ')
    print('             [-ver  <block_version_name>  # top block version ,default is latest ]')
    print('              -help                        # print this usage')
    print(' ')
    print(' Script version:' + script_version)
    print(' -------------------------------------------------------------------------')
    sys.exit(' ')
#------------------------------------
#  ------------- END --------------
#------------------------------------
if __name__ == "__main__":
    main()
