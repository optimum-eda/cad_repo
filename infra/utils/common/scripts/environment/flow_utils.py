#!/usr/bin/env python
#==============================================================+
#                                                              |
# Script : flow_utils.py                                       |
#                                                              |
# Description : all central/public procedure written here      |
#                                                              |
#                                                              |
# Written by: Ruby Cherry EDA  Ltd                             |
# Date      : Tue Jul 21 19:05:55 IDT 2020                     |
#                                                              |
#==============================================================+
import getopt, sys, urllib, time, os , re
import os.path
import logging ,datetime
import subprocess
import getpass
from os import path

#### permissions to change latest_stable tag
################# who is allwed to change the latest_stabe tag
global alowed_to_change_latest_stabe_list
alowed_to_change_latest_stabe_list = {"amird" ,"ezrac"}


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
#-------------- logger -----------
# Gets or creates a logger
logging.basicConfig()
logger = logging.getLogger("__")  
global debug_flag 
debug_flag = False
global home_dir

#------------------------------------
# proc        :system_call
# description :
#------------------------------------
def system_call(command):
	p = subprocess.Popen([command], stdout=subprocess.PIPE, shell=True)
	return p.stdout.read()

#------------------------------------
# proc        : fn_init_logger
# description :
#------------------------------------
def fn_init_logger(filelog_name):

	file_handler = logging.FileHandler(filelog_name)
	formatter    = logging.Formatter('%(message)s')
	# define file handler and set formatter
	file_handler.setFormatter(formatter)
	# add file handler to logger
	logger.addHandler(file_handler)

#------------------------------------
# proc        : fn_close_logger
# description :
#------------------------------------
def fn_close_logger(filelog_name):
	logging.shutdown()

#------------------------------------
# proc        : fn_check_setup_proj_ran
# description :
#------------------------------------
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

#------------------------------------
# proc        : get_head_tag_or_sha
# description : return  tag if exists or the sha if no tag
# inputs      :
#------------------------------------
def get_head_tag_or_sha():

	debug("Start - get_head_tag_or_sha")
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
#------------------------------------
# proc        : revert
# description : remove the working area in case of error
#------------------------------------
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
#------------------------------------
# proc        : build_hier_design_struct
# description : build hier design data structure
#
# inputs      :
#------------------------------------
def build_hier_design_struct(block_name,block_version,filelog_name,myHierDesignDict,top_block=False):

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
				clone_block(child_name,child_version, filelog_name)
				myHierDesignDict = build_hier_design_struct(child_name,child_version,filelog_name, myHierDesignDict, top_block=False)
	else:
		if block_name in myHierDesignDict.keys():
			info("Need to Contradiction !!!! ")
		else:
			myHierDesignDict[block_name] = [parent_name,parent_version,force , child_name ,child_version]
			os.chdir(home_dir)
			clone_block(child_name, child_version, filelog_name)
		myHierDesignDict=build_hier_design_struct(child_name,child_version,filelog_name,myHierDesignDict,top_block=False)

	os.chdir(home_dir)

	debug("Finish build_hier_design_struct")
	return myHierDesignDict
#------------------------------------
# proc        : get_branch_name
# description : get current branch name if exist
# inputs      :
#------------------------------------
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
#------------------------------------
# proc        : get_branch_name
# description : get current branch name if exist
# inputs      :
#------------------------------------
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

#------------------------------------
# proc        : get_master
# description : get head sha of current work area
# inputs      :
#------------------------------------
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
#------------------------------------
# proc concat_workdir path path : concat two paths (relative or ablolut to find the workdir)
# description : store script command line
#               in logs/uws_commands.log
#------------------------------------
def concat_workdir_path (working_dir , wa_path) :
        if (len(wa_path) == 0):
                return ""
        return os.path.abspath(wa_path)
        # if (wa_path[0] == '/'):
        #     return wa_path
        # if (wa_path[0] == '~'):
        #     return wa_path
        # if (working_dir[-1] == '/'):
        #     return working_dir + wa_path
        # return working_dir + "/" + wa_path

#------------------------------------
# proc        : print_out_design_hier
# description : print out myHierDesignDict design hier struct
#------------------------------------
def print_out_design_hier(myHierDesignDict):

	print('_______________________________________________________________________________________________________________')
	print("| {:<20}| {:<20}| {:<20}| {:<20}| {:<20}|".format('', '', '', '',
															 ''))
	print("| {:<20}| {:<20}| {:<20}| {:<20}| {:<20}|".format('Parent_name', 'Parent_version', 'Force', 'Child_name',
													  'Child_version'))
	print("| {:<20}| {:<20}| {:<20}| {:<20}| {:<20}|".format('___________________', '___________________', '___________________', '___________________',
													  '___________________'))

	for key in myHierDesignDict.keys():
		parent_name    = myHierDesignDict[key][0]
		parent_version = myHierDesignDict[key][1]
		force          = myHierDesignDict[key][2]
		child_name     = myHierDesignDict[key][3]
		child_version  = myHierDesignDict[key][4]
		print("| {:<20}| {:<20}| {:<20}| {:<20}| {:<20}|".format(parent_name, parent_version, force, child_name,
															  child_version))
	#print('_______________________________________________________________________________________________________________')
	print("| {:<20}| {:<20}| {:<20}| {:<20}| {:<20}|\n".format('___________________', '___________________', '___________________', '___________________',
													  '___________________'))


#------------------------------------
# proc        : now
# description :
#------------------------------------
def now():
	return str(datetime.datetime.now().strftime("%H:%M:%S"))

#------------------------------------
# proc        : logging_setLevel
# description :
#------------------------------------
def logging_setLevel(level):
	if (level == 'DEBUG'):
		logger.setLevel(logging.DEBUG)
	else :
		logger.setLevel(logging.INFO)
#--------------------------
#------ logger info -------
#--------------------------
def info(msg):
	logger.info(msg)
	sys.stdout.flush()

#--------------------------
#------ logger debug -------
#--------------------------
def debug(msg):
	if (debug_flag) :
		logger.debug(msg)
		sys.stdout.flush()

#--------------------------
#------ logger warning -------
#--------------------------
def warning(msg):
	logger.warning(msg)
	sys.stdout.flush()

#--------------------------
#------ logger error -------
#--------------------------
def error(msg):
	logger.error(bcolors.WARNING2 + msg + bcolors.ENDC)
	sys.stdout.flush()
	sys.exit(1);

#--------------------------
#------ logger critical -------
#--------------------------
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


#------------------------------------
# proc        : git_cmd
# description : will un a git command
#    it will check that the return value is 0 (sucssess) 
#       if not will pring an error message and exit
#------------------------------------
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
#------------------------------------
# proc        : write_command_line_to_log
# description : store script command line 
#               in logs/uws_commands.log 
#------------------------------------
def write_command_line_to_log(input_cmd,local_uws_command_log_file):

	cmd_line = input_cmd[0]
	# total arguments
	n = len(input_cmd)
	for i in range(1, n):
		cmd_line = cmd_line + " " + input_cmd[i]
	cmd = 'echo ' + cmd_line + ' >> ' + local_uws_command_log_file
	os.system(cmd)

#------------------------------------
# proc        : get_conflict_list
# description : get a list of files that 
#               conflict by "git pull --no-commit origin master"
#------------------------------------
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
#------------------------------------
# proc        : switch_refrence
# description : will go to the corresponding subtree (dv or des)
#               and checkout the "sha" only on this subtree
#            it will update the curr_sha file as well
#------------------------------------
def switch_refrence(tree_type, sha, calling_function="default_behavior"):

	debug("Start - switch_refrence")
	#
	update_master = False
	ok1 = ok2 = ok3 = ok4 = ok5 = ok6 = ok7 = ok8 = True
	ok1 = git_cmd("git config advice.detachedHead false")
	swithch_path = get_forward_path(tree_type)
	if (sha == 'latest') and (tree_type != "cad"):
		if (calling_function == "uws_create"):
			write_current_sha(tree_type, "latest")
			debug("switch refrence in uws_create for latest on tree " + tree_type + " does nothing - assume clone brings master")
			return True
			# update_master = True
		if (calling_function == "uws_update"):
			debug("switch refrence in uws_update for latest on tree " + tree_type + " we call \"git checkout master\"")
			#ok6 = git_cmd("git checkout --force master")
			ok6 = git_cmd("git checkout --force -B master origin/master")
			#ok6 = git_cmd("git checkout --force  master origin/master")

			curr_tag = get_head_tag_or_sha()
			write_current_sha(tree_type, curr_tag)
			return ok6
		## this is default behaviour, we search for origing master and do "normal" checkout to it
	latest_sha = get_latest_origin_master()
	info('+--------------------------------------+')
	info('Sync path: \'' + os.getcwd() + '\'')
	info('     area: \'' + tree_type + '\'' )
	if (sha == 'latest') :
		info('     sha : \'' + sha + '\' = \'' + latest_sha + '\'')
	else:
		info('     sha : \'' + sha + '\'' )
	info('+-------------')
	if (tree_type != "cad"):
		if (sha == 'latest') :
			if (calling_function == "uws_create"):
				update_master = True
			sha = get_latest_origin_master()
			debug("switshing \"latest\" to sha:" + sha)
		if  (swithch_path != "."):
			ok2 = git_cmd("git reset " + sha + " -- " + swithch_path)
			ok3 = git_cmd("git checkout " + " -- " + swithch_path)
			ok4 = git_cmd("git clean -fd " + swithch_path)
		else:
			if (sha.startswith("imp_") and tree_type =="top" and "uws_create" in os.path.abspath(sys.argv[0])):
				#file_content = "\"/*\n!*/results"
				#if ("-top_res" in sys.argv):
				#	included_res_folder_string =  sys.argv[sys.argv.index("-top_res")+1]
				#	included_res_folder_list = list(included_res_folder_string.split(","))
				#	for folder in included_res_folder_list:
				#		file_content += "\n"+folder+"/results"
				#file_content += "\""
				#git_cmd("git config core.sparseCheckout true")
				##git_cmd("echo -e \"/*\\n!*/results\" >> .git/info/sparse-checkout")
				##print(file_content)
				#git_cmd("echo -e "+file_content+" >> .git/info/sparse-checkout")				
				write_current_sha(tree_type,sha)
				ok2 = git_cmd("git checkout " + sha)
			else:
				ok2 = git_cmd("git checkout --force " + sha)
			if not ok2:
				critical("Can't find tag " + sha + " on " + tree_type)

	else:
		if (sha == 'latest') :
			#sha = get_latest_origin_master()
			sha = "master"
			debug("switshing \"latest\" to sha:" + sha)

		ok2 = git_cmd("git checkout " + sha + ' -- infra/tools/wrapper')
		ok3 = git_cmd("git checkout " + sha + ' -- infra/environment/wrapper')
		ok4 = git_cmd("git checkout " + sha + ' -- infra/scripts/wrapper')
		ok7 = git_cmd("git checkout " + sha + ' -- infra/utils/common/scripts/tools/')
		ok8 = git_cmd("git checkout " + sha + ' -- infra/utils/common/scripts/git_hooks/')


	# update the current sha in the central location
	if (tree_type != "sha_list_to_sync_wa"):
		#git_cuur_sha_file = swithch_path + "/.git_curr_sha"
		if (len(sha) == 0):
			error("Noting to write in current sha for section " + tree_type + " " + os.getcwd())
		write_current_sha(tree_type, sha)
		#cmd = "echo " + sha + " > " + swithch_path + "/.git_curr_sha"
		#debug(cmd)
		#os.system(cmd)
	if update_master:
		#ok6 = git_cmd("git checkout master")
		ok6 = git_cmd("git checkout --force -B master origin/master")
		#ok6 = git_cmd("git checkout --force master origin/master")

	ok5 = git_cmd("git config advice.detachedHead true")

	debug("Finish - switch_refrence")
	return ok1 and ok2 and ok3 and ok4 and ok5 and ok6 and ok7 and ok8


#------------------------------------
# proc        : get_git_status_porcelain_file_status
# description : will return a nice word for the user 
#               to explain the code given in "git status --porcelain"
#------------------------------------
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
#------------------------------------
# proc        : get_tags_on_same_sha
# description : get a list of all tags that sit  "parallel" on the same tag with "sha"
#------------------------------------
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

#------------------------------------
# proc        : is_brother_tag
# description : see if tag1 is on the same sha as tag2
#------------------------------------
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





#-----------------------------------------------
# ---------- End flow_utils.py ----------------- 
#-----------------------------------------------
