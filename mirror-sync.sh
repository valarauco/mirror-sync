#!/bin/bash

#########################################################################
# Mirror Sync :: Script to sincronize repositories using Rsync          #
#                                                                       #
# This program is free software: you can redistribute it and/or modify  #
# it under the terms of the GNU General Public License as published by  #
# the Free Software Foundation, either version 3 of the License, or     #
# (at your option) any later version.                                   #
#                                                                       #
# This program is distributed in the hope that it will be useful,       #
# but WITHOUT ANY WARRANTY; without even the implied warranty of        #
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the          #
# GNU General Public License for more details.                          #
#                                                                       #
# You should have received a copy of the GNU General Public License     #
# along with this program. If not, see <http://www.gnu.org/licenses/>.  #
#                                                                       #
#                                                                       #
# Universidad de Costa Rica @ 2012                                      #
# Manuel Delgado Lopez - manuel.delgado@ucr.ac.cr                       #
#########################################################################
# TODO
#   ---
##
VERSION="v0.1"

function printHelp() {
  echo -e "\nMirror Sync ${VERSION} - Manuel Delgado <manuel.delgado at ucr.ac.cr>"
  if [ "$1" ]; then
    printError "$1"
  fi
  echo -e "\nUSE: ${0} [options] mirror mirror2 ...
  Parameter <mirror> is the name of the mirror configfile in the form 
    <mirror.cnf> inside the configuration folder.
  
  Options:
    -c, --config CONFIGDIR  
      Define the path to general configuration directory. (./config/)
    
    -h, --help
      Print this text
      
    -l, --log LOGFILE        
      Define the path to general log file. (./log/mirror-sync.log)

    "
}

function printError() {
  ERROR="$1"
  printLog "$ERROR"
  echo "Error :: ${ERROR}" >&2
}

function printLog() {
  DATA="$1"
  if [ -w "$LOG_FILE" ]; then
    DATE=`date -u` #TODO cambiar por una fecha más corta  
    echo "[${DATE}] mirror-sync :: ${DATA}" >> $LOG_FILE
  else
    echo "Error :: Logfile not exist or is not writable" >&2
  fi
}

function loadOptions() {
  SYS_DIR=`pwd`
  CFG_DIR="${SYS_DIR}\config"
  LOG_FILE="${SYS_DIR}\log\mirror-sync.log"
  
  while [ $# -gt 0 ]; do
    case "${1:0:1}" in
      "-")
        argOption "$1" "$2"
        shift; shift;
        ;;
      *)
        LST_MIRRORS=( ${LST_MIRRORS[@]} "$1")
        shift
        ;;
    esac
  done
  
  CFG_FILE="${CFG_DIR}\mirror-sync.cfg"
}

function argOption() {
  case "$1" in
    "-l" | "--log")
      if [ ! -e "$2" ]; then
        printHelp "$2 is not a file"
        exit 1
      fi
      LOG_FILE=$2
      shift; shift;
      ;;
    "-c" | "--config")
      if [ ! -d "$2" ]; then
        printHelp "$2 is not a directory"
        exit 1
      fi
      CFG_DIR=$2
      shift; shift;
      ;;
    "-h" | "--help")
      printHelp
      exit 0
      ;;
    *)
      printHelp "$1 is not a valid option"
      exit 1
      ;;
  esac
}

function loadConfig() {
  if [ -r "$CFG_FILE" ]; then
    . $CFG_FILE
  else
    printError "Configfile not readable"
  fi
}

function syncMirrors() {
  for (( i = 0 ; i < ${#LST_MIRRORS[@]} ; i++ )); do
    MIRROR_FILE="${CFG_DIR}/${LST_MIRRORS[$i]}.cfg"
    if [ -r $MIRROR_FILE ]; then
      echo "--"
    else
      printError "$MIRROR_FILE is not a valid mirror configuration file"
    fi
  done
}

printHelp "People working... not finish yet"

