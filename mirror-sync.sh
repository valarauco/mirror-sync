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
#   Use FULLLOGS variable
#   Use HOOKS
#   Redirect logs of executables to logfile
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
  ERROR="Error :: $1"
  printLog "$ERROR"
  echo "${ERROR}" >&2
  if [ $2 ]; then
    exit $2
  fi
}

function printLog() {
  DATA="$1"
  if [ ! -f "$LOG_FILE" -a "$LOG_FILE" ]; then
    touch "$LOG_FILE"
  fi
  if [ -w "$LOG_FILE" ]; then
    DATE=`date -u` #TODO cambiar por una fecha más corta ISO  
    echo "[${DATE}] mirror-sync :: ${DATA}" >> "$LOG_FILE"
  else
    echo "Error :: Logfile not exist or is not writable" >&2
  fi
}

function loadOptions() {
  BASE_DIR=`pwd`
  CFG_DIR="${BASE_DIR}/config"
  LOG_FILE="${BASE_DIR}/log/mirror-sync.log"
  LST_MIRRORS=()
  
  if [ $# -lt 1 ];then
    printHelp "Must specify a mirror" 1
    exit 1
  fi
  
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
  CFG_FILE="${CFG_DIR}/mirror-sync.cfg"
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
    . "$CFG_FILE"
    if [ ! -x "$RSYNC_BIN" ]; then
      printError "Can not execute rsync from $RSYNC_BIN" 1
    fi
    if [ ! -x "$FLOCK_BIN" ]; then
      printError "Can not execute flock from $FLOCK_BIN" 1
    fi
  else
    printError "Configfile not readable" 1
  fi
}

function syncMirrors() {
  for (( i = 0 ; i < ${#LST_MIRRORS[@]} ; i++ )); do
    MIRROR_NAME=${LST_MIRRORS[$i]}
    MIRROR_FILE="${CFG_DIR}/${MIRROR_NAME}.cfg"
    if [ -r "$MIRROR_FILE" ]; then
      . "${CFG_DIR}/defaults"
      . "$MIRROR_FILE"
      (
         $FLOCK_BIN -n 9 || printError "El proceso ya esta en ejecución" $?
         runRsync
       ) 9>"$LOCK"
    else
      printError "$MIRROR_FILE is not a valid mirror configuration file"
    fi
    rm "$LOCK"
  done
}

function runRsync(){
  for (( i = 1 ; i <= ${RSYNC_PASS} ; i++ )); do
    if [ ! -f "$MIRROR_LOG" -a "$MIRROR_LOG" ]; then
      touch "$MIRROR_LOG"
    fi
    if [ ! -w "$MIRROR_LOG" ]; then
      printError "$MIRROR_LOG not exist or is not writable, using default logfile"
      MIRROR_LOG=$LOG_FILE
    fi
    
    RSYNC_OPTIONSN="RSYNC_OPTIONS${i}"
    RSYNC_ARGS="$RSYNC_EXTRA $EXCLUDE $RSYNC_OPTIONS ${!RSYNC_OPTIONSN}  --log-file="${MIRROR_LOG}""
    if [ "$RSYNC_BW" ]; then #TODO check if = 0
      RSYNC_ARGS+=" --bwlimit=${RSYNC_BW} "
    fi
    if [ $RSYNC_TIMEOUT -gt 0 ]; then 
      RSYNC_ARGS+=" --timeout=${RSYNC_TIMEOUT} "
    fi
    if [ "$RSYNC_USER" ]; then
      export RSYNC_USE
      export RSYNC_PASSWORD
    fi
    RSYNC_ARGS+=" ${RSYNC_HOST}::${RSYNC_PATH} $TO"
    printLog "Rsync command: $RSYNC_BIN $RSYNC_ARGS "
    $RSYNC_BIN $RSYNC_ARGS > /dev/null
    RSYNC_EXIT=$?
    if [ $RSYNC_EXIT -ne 0 ]; then
      printError "Exit code: ${RSYNC_EXIT}, check $MIRROR_LOG for details"
    fi
    if [ "$MAILTO" ]; then
      if [ $RSYNC_EXIT -ne 0 -a "$ERRORSONLY" = "true" ]; then 
        sendMailTo "$MAILTO" "$SUBJECT" << EOF
 An error occurred in $MIRROR_NAME with exit code ${RSYNC_EXIT}. 
 Check the logfile $MIRROR_LOG for details.
EOF
      elif [ "$ERRORSONLY" = "false"  ]; then
        sendMailTo "$MAILTO" "$SUBJECT" << EOF
 Sync executed: Mirror $MIRROR_NAME with exit code ${RSYNC_EXIT}. 
 Check the logfile $MIRROR_LOG for details.
EOF
      fi 
    fi
    if [ $RSYNC_EXIT -eq 0 ]; then
      $HOOKN="HOOK${i}"
      $HOOKN &> "$LOGFILE"
    fi
  done    
}

function sendMailTo() {
  if [ -x "$MAIL_BIN" ]; then
    $MAIL_BIN -s "$2" "$1" "$3" > /dev/null 
  else
    printError "Can not execute mail from ${MAIL_BIN}, mail not sent"
  fi
}

cd "`dirname \"$0\"`"

loadOptions $@
loadConfig
syncMirrors

#printHelp "People working... not finish yet"

