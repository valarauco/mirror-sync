#!/bin/bash

#########################################################################
# Mirror Sync :: Script to sincronize repositories using Rsync					#
#																																				#
# This program is free software: you can redistribute it and/or modify	#
# it under the terms of the GNU General Public License as published by	#
# the Free Software Foundation, either version 3 of the License, or			#
# (at your option) any later version.																		#
#																																				#
# This program is distributed in the hope that it will be useful,				#
# but WITHOUT ANY WARRANTY; without even the implied warranty of				#
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the					#
# GNU General Public License for more details.													#
#																																				#
# You should have received a copy of the GNU General Public License			#
# along with this program. If not, see <http://www.gnu.org/licenses/>.	#
#																																				#
# 																																			#
# Universidad de Costa Rica @ 2012																			#
# Manuel Delgado Lopez - manuel.delgado@ucr.ac.cr												#
#########################################################################
# TODO
#		---
##

function printHelp() {
	echo "Mirror Sync ${VERSION} 
	USE: ${0} [options] mirror
		mirror is the name of the mirror configfile in the form <mirror.cnf> inside the configuration folder.
		Options:
			-l, --log LOGFILE				Define the path to general log file. (./log/mirror-sync.log)
			-c, --config CONFIGDIR	Define the path to general configuration directory. (./config/)
			"
}

function loadDefaults() {
	SYS_DIR=`pwd`
	CFG_DIR="${SYS_DIR}\config"
	LOG_FILE="${SYS_DIR}\log\mirror-sync.log"
	CFG_FILE="${CFG_DIR}m\mirror-sync.cfg"
}

