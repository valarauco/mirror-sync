mirror-sync
===========

Bash script for Rsync based mirrors sync automatization

Inspired in debian's ftpsync, mirror-sync loads a configuration file with the 
parameters for rsync, logging and notification. 

Mirror-sync uses flock to ensure the sync process executes only once at the 
same time.

##Dependencies:

* rsync
* flock
* sendmail o similar if want to send email notifications

##Instructions:

* Download and unpack mirror-sync
* Create a mirror.cfg file in the config/ directory. See config/mirror.cfg.sample
* Edit config/mirror-sync.cfg to meet your system configuration
* run **./mirror-sync.sh mirror** to execute with mirror.cfg or **./mirror-sync.sh -h** for help
