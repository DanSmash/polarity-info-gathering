#!/usr/bin/env bash
##########################################################################
# Copyright (c) 2016-2023. Polarity.io, Inc.
# All rights reserved
#
# UPDATED VERSION - Smaller, faster footprint, suitable for
#   login / MOTD execution.
#
##########################################################################


declare -a webarr=("nginx" "rh-nginx18-nginx" "rh-nginx110-nginx" "rh-nginx112-nginx" "rh-nginx114-nginx")

for i in "${webarr[@]}"
do
   rpm -q $i &>2
   if [ $? -eq 0 ]
   then
      version=$(rpm -q $i | head -1 | sed 's/\s\s*/ /g' | cut -d' ' -f2)
      webserver=$i
      break
   fi
done

PGVERSION=`rpm -qa postgresql*-server | cut -d"-" -f1|cut -d"l" -f2`			# smash - UPDATED QUERY

if [ "$PGVERSION" -eq "95" ]; then
        PGVERSION="9.5"
elif [ "$PGVERSION" -eq "96" ]; then
        PGVERSION="9.6"
fi

if [ "$PGVERSION" ]; then
        declare -a arr=("polarityd" $webserver "postgresql-$PGVERSION" "polarity-session-cache" "polarity-integration-cache" "polarity-metrics-cache" "polarity-pg-cache")
else
        declare -a arr=("polarityd" $webserver "polarity-session-cache" "polarity-integration-cache" "polarity-metrics-cache" "polarity-pg-cache")
fi

psver=$(rpm -q polarity-server | cut -d- -f3)			                     # smash - UPDATED QUERY

green=$'\033[32m'
red=$'\033[31m'
normal=$'\033[0m'

printf "%s ${green}%s\n\n" "Polarity Server" "$psver"
printf "${normal}%s\n" "Status         Service"
printf "${normal}%s\n" "=========      ================"
for i in "${arr[@]}"
do
   status=$(systemctl is-active $i)

   if [ $status = 'active' ]
   then
      printf "${green}%-15s${normal}%s\n" "active" "$i"
   else
      printf "${red}%-15s${normal}%s\n" "inactive" "$i"
   fi
done


printf "${normal}%s\n\n"
