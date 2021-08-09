#!/usr/bin/env python3
#--------------------------------------------
# Script : gen_changelog.py
#   
# Description : 
#
# Wiritten by : Amir Duvdevani
# Date        : un Aug  8 09:27:26 IDT 2021
#--------------------------------------------
import os, time,datetime
import getopt, sys, urllib
import os.path
import re
from os import path
import subprocess
import logging
import argparse
import shutil
import getpass
global debug_flag 
global home_dir
home_dir = os.getcwd() 
results_line = ''
g_gitLab_versionDict = {}
g_gitLab_versionDict['Major'] = []
g_gitLab_versionDict['Minor'] = []
g_gitLab_versionDict['Fix']   = []

parser = argparse.ArgumentParser(description="Description: generate changelog.md file ") 
requiredNamed = parser.add_argument_group('required named arguments')
requiredNamed.add_argument('-o',default='changelog.md',help = "name of output file , default is changelog.md",required=False)
parser.add_argument('-debug',action='store_true',help = "debug option verbose = True")
args = parser.parse_args()
#------------------------------------------------------
def run_sys_cmd2(cmd):

	return_value = os.system(cmd)
	if (return_value !=0):
		print('Error: command "' + cmd + '" failed') 
		return False
	return True

#------------------------------------------------------
def run_sys_cmd(cmd):

	if args.debug:
		print('Info : run cmd: ' + str(cmd)) 
	cmd_l = cmd.split(' ') 
	cmd = []
	for one_ele in cmd_l:
		cmd.append(one_ele)
	
	proc = (subprocess.Popen(cmd, stdout=subprocess.PIPE,universal_newlines=True))
	try:
		outs, errs = proc.communicate(timeout=15)

	except TimeoutExpired:
		proc.kill()
		outs, errs = proc.communicate()
		return_code = proc.poll()
		print('Error: cmd failed , ' + outs)   
		print('                    ' + errs)   
		sys.exit(1)
			
	if proc.returncode != 0:
		outs, errs = proc.communicate()
		return_code = proc.poll()
		print('Error: cmd failed , ' + outs)   
		print('                    ' + errs)   
		sys.exit(1)

	
	#return_code = proc.poll()
	#print('result: outs "' + str(outs) + '"')
	#print('result: errs "' + str(errs) + '"')

	return outs
#------------------------------------------------------
def get_last_tag():

	global results_line

	if args.debug:
		print('Debug: start    get_last_tag')

	cmd = "git log --oneline --decorate --all"
	results = run_sys_cmd(cmd)
	results_line = results.split('\n')
	for one_res_line in results_line:
		if args.debug:
			print('Debug: result line :' + one_res_line)
		if 'tag: v' in one_res_line: 
			tag_commitID_l = one_res_line.split(' ')		
			tag_commitID = tag_commitID_l[0]
			tag_name_l = one_res_line.replace('tag: ','tag:').split('tag:')		
			tag_name_l = tag_name_l[1].split(' ')
			tag_name   = tag_name_l[0].replace(',','').replace(')','').replace('(','')
			if args.debug:
				print('Debug: tag_name    ="' + tag_name + '"')
				print('Debug: tag_commitID="' + tag_commitID + '"')
				print('Debug: finished get_last_tag')
			return tag_name,tag_commitID
			
	# if tag not found
	if args.debug:
		print('Debug: finished get_last_tag')
	return 'v0.0.0','None'
#------------------------------------------------------
def collect_all_gitLab_version_until_lastTag(tag_commitID):

	global g_gitLab_versionDict 
	global results_line

	if args.debug:
		print('Debug: start    collect_all_gitLab_version_until_lastTag')

	fix_version_done   = False
	minor_version_done = False
	major_version_done = False

	for one_res_line in results_line:
		if tag_commitID in one_res_line:
			if args.debug:
				print('Debug: finished collect_all_gitLab_version_until_lastTag')
			return fix_version_done,minor_version_done,major_version_done
		if 'Fix:' in one_res_line:
			g_gitLab_versionDict['Fix'].append(one_res_line)
			fix_version_done   = True
		if 'Minor:' in one_res_line:
			g_gitLab_versionDict['Minor'].append(one_res_line)
			minor_version_done   = True
		if 'Major:' in one_res_line:
			g_gitLab_versionDict['Major'].append(one_res_line)
			major_version_done   = True

	if args.debug:
		print('Debug: finished collect_all_gitLab_version_until_lastTag')

	return fix_version_done,minor_version_done,major_version_done

#------------------------------------------------------
def split_last_version_type(tag_name):

	tag_name_l = tag_name.replace('v','')
	tag_name_l = tag_name_l.split('.')

	last_major_ver = tag_name_l[0]
	last_minor_ver = tag_name_l[1]
	last_fix_ver   = tag_name_l[2]

	return last_fix_ver ,last_minor_ver ,last_major_ver
#------------------------------------------------------
def print_out_changeLog(fix_version_done,minor_version_done,major_version_done,tag_name):

	global g_gitLab_versionDict 
	global results_line

	for Fix_commit in g_gitLab_versionDict['Fix']:
		print('Info : Fix_commit ="' + Fix_commit + '"')
	for Minor_commit in g_gitLab_versionDict['Minor']:
		print('Info : Minor_commit ="' + Minor_commit + '"')
	for Major_commit in g_gitLab_versionDict['Major']:
		print('Info : Major_commit ="' + Major_commit + '"')

	last_fix_ver ,last_minor_ver ,last_major_ver = split_last_version_type(tag_name)

	if args.debug:
		print('Debug: fix_version_done   = ' + str(fix_version_done))
		print('Debug: minor_version_done = ' + str(minor_version_done))
		print('Debug: major_version_done = ' + str(major_version_done))
		print('Debug: tag_name           = ' + str(tag_name))
		print('Debug: last_major_ver     = ' + str(last_major_ver))
		print('Debug: last_minor_ver     = ' + str(last_minor_ver))
		print('Debug: last_fix_ver       = ' + str(last_fix_ver))

	if fix_version_done:
		last_fix_ver = str(int(last_fix_ver) + 1)
	if minor_version_done:
		last_minor_ver = str(int(last_minor_ver) + 1)
	if major_version_done:
		last_major_ver = str(int(last_major_ver) + 1)
	
	new_tag_name = 'v' + str(last_major_ver) + '.' + str(last_minor_ver) + '.' + str(last_fix_ver) 
	print('Info : new tag_name should be "' + new_tag_name + '"')
	#if not os.path.isfile(args.o):
		
#------------------------------------------------------
def check_tag_name_is_valid(tag_name):

	if not tag_name.startswith('v'):
		print('______________________________________________________________')
		print('*** Error: wrong tag format !!! ')
		print('***        tag name is "' + tag_name + '"')   
		print('***        the tag format should be like "v<major_num>.<minor_num>.<fix_num>"      ')
		print('______________________________________________________________')
		sys.exit(1)
	tag_name_l = tag_name.replace('v','')
	tag_name_l = tag_name_l.split('.')
	if (len(tag_name_l) != 3):
		print('______________________________________________________________')
		print('*** Error: wrong tag format !!! ')
		print('***        tag name is "' + tag_name + '"')   
		print('***        should be with 3 digits <major>.<minor>.<fix>      ')
		print('______________________________________________________________')
		sys.exit(1)

#------------------------------------------------------
def main():

	global g_gitLab_versionDict 
	global results_line

	if args.debug:
		print('Debug: start    main')

	tag_name,tag_commitID = get_last_tag()
	check_tag_name_is_valid(tag_name)

	print('Info : tag_name     : "' + tag_name + '"')
	print('Info : tag_commitID : "' + tag_commitID + '"')
	
	fix_version_done,minor_version_done,major_version_done = collect_all_gitLab_version_until_lastTag(tag_commitID)

	print_out_changeLog(fix_version_done,minor_version_done,major_version_done,tag_name)

	if args.debug:
		print('Debug: finished main')

	print('***********************************************')
	print('Info : gen_changelog.py finished successfully')
	print('***********************************************')
	print('Info : result file created "' + args.o + '"')
#------------------------------------------------------
if __name__ == "__main__":
    main()
