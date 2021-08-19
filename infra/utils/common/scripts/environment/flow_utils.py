#!/usr/bin/env python

#=============================================================================+
#                                                                             |
# Script : flow_utils.py                                                      |
#                                                                             |
# Description : all central/public procedure written here                     |
#                                                                             |
#                                                                             |
# Written by: Ruby Cherry EDA  Ltd                                            |
# Date      : Tue Jul 21 19:05:55 IDT 2020                                    |
#                                                                             |
#=============================================================================+
#------------------------------------------------------------------------------
import getopt, sys, urllib, time, os , re
import os.path
import logging ,datetime
import subprocess
import shutil
import getpass
from os import path

class bcolors:
	HEADER = '\033[95m'
	OKBLUE = '\033[94m'
	OKGREEN = '\033[92m'
	WARNING = '\033[93m'
	WARNING2 = '\033[1;31m'
	FAIL = '\033[91m'
	ENDC = '\033[0m'
	BOLD = '\033[1m'
	UNDERLINE = '\033[4m'

# ------------------------------------------------------------------------------
#-------------- logger -----------
# Gets or creates a logger
logging.basicConfig()
logger = logging.getLogger("__")  
global debug_flag 
debug_flag = False
global home_dir
#------------------------------------------------------------------------------
# proc        :system_call
# description :
#------------------------------------------------------------------------------
def system_call(command):
	p = subprocess.Popen([command], stdout=subprocess.PIPE, shell=True)
	return p.stdout.read()
#------------------------------------------------------------------------------
# proc        :run_sys_cmd
# description :
#------------------------------------------------------------------------------
def run_sys_cmd(cmd):

	debug('Info : run cmd: ' + str(cmd))
	cmd_l = cmd.split(' ')
	cmd = []
	for one_ele in cmd_l:
		cmd.append(one_ele)

	proc = (subprocess.Popen(cmd, stdout=subprocess.PIPE, universal_newlines=True))
	outs, errs = proc.communicate()

	if proc.returncode != 0:
		error('Error: cmd failed , ' + outs + '\n\t' + errs)
		sys.exit(1)

	# return_code = proc.poll()
	# print('result: outs "' + str(outs) + '"')
	# print('result: errs "' + str(errs) + '"')

	return outs
#------------------------------------------------------------------------------
# proc        : fn_init_logger
# description :
#------------------------------------------------------------------------------
def fn_init_logger(filelog_name):

	file_handler = logging.FileHandler(filelog_name)
	formatter    = logging.Formatter('%(message)s')
	# define file handler and set formatter
	file_handler.setFormatter(formatter)
	# add file handler to logger
	logger.addHandler(file_handler)

#------------------------------------------------------------------------------
# proc        : fn_close_logger
# description :
#------------------------------------------------------------------------------
def fn_close_logger(filelog_name):
	logging.shutdown()

#------------------------------------------------------------------------------
# proc        : fn_check_setup_proj_ran
# description :
#------------------------------------------------------------------------------
def fn_check_setup_proj_ran():

	debug("Start fn_check_setup_proj_ran")

	if "UWA_PROJECT_ROOT" not in os.environ:
		print ("Envirenment variable 'UWA_PROJECT_ROOT' is not defined , please run setup_proj command")
		sys.exit(1)

	if "GIT_PROJECT_ROOT" not in os.environ:
		print ("Envirenment variable 'GIT_PROJECT_ROOT' is not defined , please run setup_proj command")
		sys.exit(1)

	if "GIT_CAD_REPO" not in os.environ:
		print ("Envirenment variable 'GIT_CAD_REPO' is not defined , please run setup_proj command")
		sys.exit(1)

	debug("Finish fn_check_setup_proj_ran")

#------------------------------------------------------------------------------
# proc        : get_head_tag_or_sha
# description : return  tag if exists or the sha if no tag
# inputs      :
#------------------------------------------------------------------------------
def get_head_tag_or_sha():

	debug("Start - get_head_tag_or_sha")
	# -----------------------------
	#---- check if branch -------
	head_branch = get_branch_name()
	if (head_branch != ""):
		return head_branch
	#-----------------------------
	the_tag = get_head_tag()
	if (len(the_tag) >0 ):
		debug("head tag =" + the_tag)
		return the_tag
	else:
		hed_sha = get_head_sha()
		debug("head sha =" + hed_sha)
		return hed_sha
#------------------------------------------------------------------------------
# proc        : revert
# description : remove the working area in case of error
#------------------------------------------------------------------------------
def revert_and_exit(filelog_name):

    sys.stdout.write("\033[1;31m")
    info("Reverting - removing work area " + os.getcwd())
    sys.stdout.write("\033[0;0m")

    home_dir = os.getcwd()
    os.chdir(home_dir)
    fn_close_logger(filelog_name)
    os.system("rm -rf " + home_dir)
    sys.stdout.flush()
    sys.exit(-1)

#------------------------------------------------------------------------------
# proc        : build_hier_design_struct
# description : build hier design data structure
#
# inputs      :
#------------------------------------------------------------------------------
def build_hier_design_struct(block_name,block_version,filelog_name,myHierDesignDict,action,top_block=False):

	debug("Start build_hier_design_struct")
	home_dir = os.getcwd()
	if not path.isdir(block_name):
		error('folder name ' + str(block_name) + ', doesnt exist under work ares :' + block_name)
	os.chdir(block_name)
	depends_file = 'info/depends.list'
	parent_name    = block_name
	parent_version = block_version
	force          = 'none'
	child_name     = 'none'
	child_version  = 'none'
	if os.path.isfile(depends_file):
		with open(depends_file, 'r') as reader:
			for line in reader:
				line = line.strip()
				if re.search(r'^#', line):
					continue
				line_l = line.split(' ')
				if (len(line_l) < 2):
					error('Wrong format line ' + str(line) + ', in depend.list for block :' + block_name)
				if (len(line_l) == 2):
					child_name    = line_l[0]
					child_version = line_l[1]
				if (len(line_l) == 3):
					force         = line_l[0]
					child_name    = line_l[1]
					child_version = line_l[2]
				debug('----------------------------------------')
				debug('parent_name    =' + parent_name)
				debug('parent_version =' + parent_version)
				debug('force          =' + force)
				debug('child_name     =' + child_name)
				debug('child_version  =' + child_version)
				if block_name in myHierDesignDict.keys():
					info("Need to Contradiction !!!! ")
				else:
					myHierDesignDict[block_name] = [parent_name,parent_version,force, child_name, child_version]
				os.chdir(home_dir)
				if action == 'build':
					clone_block(child_name,child_version, filelog_name)
				myHierDesignDict = build_hier_design_struct(child_name,child_version,filelog_name, myHierDesignDict,action, top_block=False)
	else:
		if block_name in myHierDesignDict.keys():
			info("Need to Contradiction !!!! ")
		else:
			myHierDesignDict[block_name] = [parent_name,parent_version,force , child_name ,child_version]
			os.chdir(home_dir)
			if action == 'build':
				clone_block(child_name, child_version, filelog_name)
		myHierDesignDict=build_hier_design_struct(child_name,child_version,filelog_name,myHierDesignDict,action,top_block=False)

	os.chdir(home_dir)

	debug("Finish build_hier_design_struct")
	return myHierDesignDict

#------------------------------------------------------------------------------
# proc        : get_branch_name
# description : get current branch name if exist
# inputs      :
#------------------------------------------------------------------------------
def clone_block (block_name,block_version,filelog_name):

	home_dir = os.getcwd()

	if "GIT_PROJECT_ROOT" not in os.environ:
		print ("Envirenment variable 'GIT_PROJECT_ROOT' is not defined , please run setup_proj command")
		sys.exit(1)

	GIT_PROJECT_ROOT = os.getenv('GIT_PROJECT_ROOT')
	cmd = 'git clone ' + GIT_PROJECT_ROOT + '/' + block_name + '.git' + ' ' + block_name
	info("run command : " + cmd)
	if not (git_cmd(cmd)):
		revert_and_exit(filelog_name)
	if block_version != 'latest':
		os.chdir(block_name)
		cmd = 'git checkout ' + str(block_version)
		info("run command : " + cmd)
		if not (git_cmd(cmd)):
			error('Failed on git checkout ' + str(block_version) + ', on block :' + block_name)

	os.chdir(home_dir)
#------------------------------------------------------------------------------
# proc        : get_branch_name
# description : get current branch name if exist
# inputs      :
#------------------------------------------------------------------------------
def get_branch_name():

	debug("Start - get_branch_name")
	#---- check if branch -------
	head_branch = ""
	tmp_top_branch_file = "get_top_branch_file.txt"
	cmd = "git branch >& " + tmp_top_branch_file
	git_cmd(cmd)
	if not os.path.isfile(tmp_top_branch_file):
		head_branch = ""
	else:
		with open(tmp_top_branch_file, 'r') as reader:
			for line in reader:
				if re.search('\*' ,line):
					head_branch = line.split()[1]
					if (re.search("detached",line)):
						os.remove(tmp_top_branch_file)
						return ""
					else:
						head_branch = line.split()[1]
						if (re.search("master",head_branch)):
							os.remove(tmp_top_branch_file)
							return ""
	os.remove(tmp_top_branch_file)
	debug("Finish - get_branch_name")
	debug("head_branch = \"" + head_branch + '\"')
	return head_branch

#------------------------------------------------------------------------------
# proc        : get_master
# description : get head sha of current work area
# inputs      :
#------------------------------------------------------------------------------
def get_master():

		debug("Start - get_master")
		pid = str(os.getpid())
		head_sha_file = "/tmp/head_sha.tmp." + pid + ".txt"
		cmd = "git rev-parse --short master > " + head_sha_file
		git_cmd(cmd)
		#head_sha = system_call(cmd).rstrip("\n")
		with open(head_sha_file, 'r') as reader:
			for line in reader:
				debug('line :' + line)
				head_sha = line.split()[0]
		if (len(head_sha) == 0):
			error("Can't get master SHA at: " + os.getcwd())
		os.remove(head_sha_file)
		debug("Finish get_master")
		return head_sha

#------------------------------------------------------------------------------
# proc concat_workdir path path : concat two paths (relative or ablolut to find the workdir)
# description : store script command line
#               in logs/uws_commands.log
#------------------------------------------------------------------------------
def concat_workdir_path (working_dir , wa_path) :
        if (len(wa_path) == 0):
                return ""
        return os.path.abspath(wa_path)
#------------------------------------------------------------------------------
# proc        : get_workarea
# description :
#------------------------------------------------------------------------------
def get_workarea():

	location = os.getcwd()
	UWA_PROJECT_ROOT = os.getenv('UWA_PROJECT_ROOT')
	if UWA_PROJECT_ROOT in location:
		location = location.replace(UWA_PROJECT_ROOT,'')
		location_l = location.split('/')
		if len(location_l) > 1:
			return location_l[1]

	return 'None'

#------------------------------------------------------------------------------
# proc        : print_out_design_hier
# description : print out myHierDesignDict design hier struct
#------------------------------------------------------------------------------
def print_out_design_hier(myHierDesignDict):

	print("+{:<20}+{:<20}+{:<20}+{:<20}+{:<20}+".format('---------------------', '---------------------',
														'---------------------', '---------------------',
														'---------------------'))

	print("| {:<20}| {:<20}| {:<20}| {:<20}| {:<20}|".format('Parent_name', 'Parent_version', 'Force', 'Child_name',
													  'Child_version'))
	print("+{:<20}+{:<20}+{:<20}+{:<20}+{:<20}+".format('---------------------', '---------------------', '---------------------', '---------------------',
													  '---------------------'))

	for key in myHierDesignDict.keys():
		parent_name    = myHierDesignDict[key][0]
		parent_version = myHierDesignDict[key][1]
		force          = myHierDesignDict[key][2]
		child_name     = myHierDesignDict[key][3]
		child_version  = myHierDesignDict[key][4]
		print("| {:<20}| {:<20}| {:<20}| {:<20}| {:<20}|".format(parent_name, parent_version, force, child_name,
															  child_version))
	print("+{:<20}+{:<20}+{:<20}+{:<20}+{:<20}+\n".format('---------------------', '---------------------', '---------------------', '---------------------',
													  '---------------------'))
#------------------------------------------------------------------------------
# proc        : now
# description :
#------------------------------------------------------------------------------
def now():
	return str(datetime.datetime.now().strftime("%H:%M:%S"))

#------------------------------------------------------------------------------
# proc        : logging_setLevel
# description :
#------------------------------------------------------------------------------
def logging_setLevel(level):
	if (level == 'DEBUG'):
		logger.setLevel(logging.DEBUG)
	else :
		logger.setLevel(logging.INFO)
#------------------------------------------------------------------------------
#------ logger info -------
#------------------------------------------------------------------------------
def info(msg):
	logger.info(msg)
	sys.stdout.flush()

#------------------------------------------------------------------------------
#------ logger debug -------
#------------------------------------------------------------------------------
def debug(msg):
	if (debug_flag) :
		logger.debug(msg)
		sys.stdout.flush()

#------------------------------------------------------------------------------
#------ logger warning -------
#------------------------------------------------------------------------------
def warning(msg):
	logger.warning(msg)
	sys.stdout.flush()

#------------------------------------------------------------------------------
#------ logger error -------
#------------------------------------------------------------------------------
def error(msg):
	logger.error(bcolors.WARNING2 + msg + bcolors.ENDC)
	sys.stdout.flush()
	sys.exit(1);

#------------------------------------------------------------------------------
#------ logger critical -------
#------------------------------------------------------------------------------
def critical(msg):
	logger.critical(bcolors.WARNING2 + msg + bcolors.ENDC)

def find_in_file(keystr, file_name):
	if not os.path.isfile(file_name):
		return False
	with open(file_name, 'r') as reader:
		for line in reader:
			if (line.find(keystr) >= 0):
				return True
	return False
#------------------------------------------------------------------------------
# proc        : git_cmd
# description : will un a git command
#    it will check that the return value is 0 (sucssess) 
#       if not will pring an error message and exit
#------------------------------------------------------------------------------
def git_cmd(cmd, allow_failure=False):

	location = os.getcwd()
	debug("Start - git_cmd " + "(at: " + location + ")")

	debug(cmd)
	return_value = os.system(cmd)
	if ((return_value != 0) and (not allow_failure)):
		critical("git command: " + cmd + " FAILED")
		return False
	debug("Finish - git_cmd")
	return True

#------------------------------------------------------------------------------
# proc        : write_command_line_to_log
# description : store script command line 
#               in logs/uws_commands.log 
#------------------------------------------------------------------------------
def write_command_line_to_log(input_cmd,local_uws_command_log_file):

	cmd_line = input_cmd[0]
	# total arguments
	n = len(input_cmd)
	for i in range(1, n):
		cmd_line = cmd_line + " " + input_cmd[i]
	cmd = 'echo ' + cmd_line + ' >> ' + local_uws_command_log_file
	os.system(cmd)

#------------------------------------------------------------------------------
# proc        : get_conflict_list
# description : get a list of files that 
#               conflict by "git pull --no-commit origin master"
#------------------------------------------------------------------------------
def get_conflict_list(section):

	debug("Start - get_conflict_list")

	retur_list = []

	#proc = subprocess.Popen(["git stash push"], stdout=subprocess.PIPE, shell=True)
	#(out, err) = proc.communicate()
	#info("git stash output: '" + out + '\'')
	#curr_sha = get_head_sha()
	pid = str(os.getpid())
	comment_file = "/tmp/origin_mater_report.tmp." + pid + ".txt"

	git_cmd("git pull --no-commit origin master > " + comment_file)
	with open(comment_file, 'r') as reader:
		for line in reader:
			if (line.find("CONFLICT") >= 0 ):
				filename = line.split()[-1]
				retur_list.append(filename)
	if (os.path.isfile(comment_file)):
		os.remove(comment_file)

	#if (re.search("No local changes to save",out)):
	#    git_cmd('git checkout ' + curr_sha)
	#else:
	#    git_cmd('git stash pop "stash@{0}"')

	debug("Finish - get_conflict_list")
	return(retur_list)
#------------------------------------------------------------------------------
# proc        : get_work_in_progress_list
# description : get a list of files that changed
#               under a development area (can be des / dv / top)
#------------------------------------------------------------------------------
def get_work_in_progress_list(area, reverse=False):

	debug("Start - get_work_in_progress_list")
	retur_list = []
	full_area_name = area
	pid = str(os.getpid())
	comment_file = "/tmp/git_status.tmp." + pid + ".txt"

	git_cmd("git status --porcelain > " + comment_file)
	with open(comment_file, 'r') as reader:
		for line in reader:
			if (line.find(comment_file) >= 0) :
				## git_status.txt is tivially not under source control and will be removed shortly
				continue
			if ((line.find(".gitignore") >= 0) and (area == "ot")):
				## .gitignore is changed in ot by external users and some old stuff might still be there
				continue
			filename = line.split()[1]
			git_status_code = line.split()[0]
			if ((filename.find(full_area_name) >= 0) or (full_area_name == "." )):
				if not reverse:
					cause = get_git_status_porcelain_file_status(git_status_code)
					retur_list.append(cause + " " + filename)
			else:
				if (reverse):
					cause = get_git_status_porcelain_file_status(git_status_code)
					retur_list.append(cause + " " + filename)

	if (os.path.isfile(comment_file)):
		os.remove(comment_file)

	debug("Finish - get_work_in_progress_list")

	return(retur_list)
#------------------------------------------------------------------------------
# proc        : get_git_status_porcelain_file_status
# description : will return a nice word for the user 
#               to explain the code given in "git status --porcelain"
#------------------------------------------------------------------------------
def get_git_status_porcelain_file_status(porcelain_code):

	debug("Start - get_git_status_porcelain_file_status")
	status_code_dict = {
		"??": "Not under source control",
		"M":  "Modified                ",
		"A": "Added                    ",
		"D": "Deleted                  ",
		"R": "Renamed                  ",
		"C": "Copied                   ",
		"U": "Updated but unmerged     "
	}

	debug("Finish - get_git_status_porcelain_file_status")
	if porcelain_code in status_code_dict:
		return status_code_dict.get(porcelain_code)
	else:
		return "Unknon Staus (" + porcelain_code + ")"
#------------------------------------------------------------------------------
# proc        : get_tags_on_same_sha
# description : get a list of all tags that sit  "parallel" on the same tag with "sha"
#------------------------------------------------------------------------------
def get_tags_on_same_sha (tag):

	taglist = []
	if (tag == ""):
		return taglist
	pid = str(os.getpid())
	gitlogall_file_name = "/tmp/gitlogall." + pid + ".txt"
	partallel_tags_file_name = "/tmp/partallel_tags" + pid + ".txt"
	git_cmd("git log --graph --oneline --decorate --all > " + gitlogall_file_name)
	if not os.path.isfile(gitlogall_file_name):
		return taglist
	cmd = "grep " + tag + " " +  gitlogall_file_name + " > " + partallel_tags_file_name
	os.system(cmd)
	if not os.path.isfile(partallel_tags_file_name):
		return taglist
	with open(partallel_tags_file_name, 'r') as reader:
		found = False
		for line in reader:
			line_list = line.split()
			next_idx = 0
			for wrd in line_list:
				next_idx = next_idx + 1
				if wrd == "tag:" :
					tag_cand = line_list[next_idx]
					if (tag_cand[-1]== ',') or (tag_cand[-1]== '}'):
						tag_cand = tag_cand[:-1]
					taglist.append(tag_cand)
	os.remove(gitlogall_file_name)
	os.remove(partallel_tags_file_name)
	return taglist

#------------------------------------------------------------------------------
# proc        : is_brother_tag
# description : see if tag1 is on the same sha as tag2
#------------------------------------------------------------------------------
def is_brother_tag(tag1, tag2):

	if tag1 == tag2:
		return True
	if tag1 == "":
		return False
	ll = get_tags_on_same_sha(tag1)
	if (tag2 in ll):
		return True
	else:
		return False

#------------------------------------------------------------------------------
# ---------------------------- End flow_utils.py ------------------------------
#------------------------------------------------------------------------------
