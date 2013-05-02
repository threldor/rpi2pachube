#!/bin/bash

#    This file is part of rpi2pachube (formerly rpi2cosm).
#    Copyright (c) 2012, Ricardo Cabral <ricardo.arturo.cabral@gmail.com>
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.

. utils/utils.sh

cat <<EOF
==================================================================
=               rpi2pachube configuration utility                =
==================================================================

EOF

which realpath &> /dev/null
if [ $? -eq 0 ]; then
  realpath=$(realpath $0 2>/dev/null)
else
  echo "Command 'realpath' is missing." 1>&2
  echo "Install 'realpath' before running this utility." 1>&2
  exit 1
fi

if [[ -f "$HOME/.rpi2pachube.conf" ]]; then
  . $HOME/.rpi2pachube.conf
  cat <<EOF
Current configuration:
  -API Key: $api_key
  -Feed: $feed
  -Monitor load avg: $(bool2str "$monitor_load_avg")
  -Monitor free memory: $(bool2str "$monitor_mem_free")
  -Monitor used memory: $(bool2str "$monitor_mem_used")
  -Monitor cached memory: $(bool2str "$monitor_mem_cached")
  -Monitor temperature: $(bool2str "$monitor_temp")
  -Monitor indoor temperature: $(bool2str "$monitor_temp_in")
  -Monitor outdoor temperature: $(bool2str "$monitor_temp_out")
  -Monitor temp. in Fahrenheit: $(bool2str "$monitor_temp_f")
  -Monitor number of processes: $(bool2str "$monitor_pid_count")
  -Monitor number of connections: $(bool2str "$monitor_connections")
  -Monitor no. of users logged in: $(bool2str "$monitor_users")
  -Monitor uptime: $(bool2str "$monitor_uptime")
  -Monitor network interfaces: $(bool2str "$monitor_network_interfaces")
    -Network interfaces: $network_interfaces
EOF
  read_yn "Would you like to keep your current configuration? (y/n)"
  if [ $? -eq 1 ]; then
    echo "Nothing to do."
    exit 0
  fi

fi

read_s "Enter your API Key:" result "$api_key"
api_key=$result

read_s "Enter the Feed ID for this device:" result "$feed"
feed=$result

read_yn "Would you like to monitor the load average over 5 minutes? (y/n)" "$monitor_load_avg"
monitor_load_avg=$?

read_yn "Would you like to monitor free RAM memory? (y/n)" "$monitor_mem_free"
monitor_mem_free=$?

read_yn "Would you like to monitor used RAM memory? (y/n)" "$monitor_mem_used"
monitor_mem_used=$?

read_yn "Would you like to monitor cached RAM memory? (y/n)" "$monitor_mem_cached"
monitor_mem_cached=$?

read_yn "Would you like to monitor the temperature? (y/n)" "$monitor_temp"
monitor_temp=$?

read_yn "Would you like the temperature to be converted to Fahrenheit? (y/n)" "$monitor_temp_f"
monitor_temp_f=$?

read_yn "Would you like to monitor the number of processes? (y/n)" "$monitor_pid_count"
monitor_pid_count=$?

read_yn "Would you like to monitor the number of active TCP/UDP connections? (y/n)" "$monitor_connections"
monitor_connections=$?

read_yn "Would you like to monitor the number of users logged in? (y/n)" "$monitor_users"
monitor_users=$?

read_yn "Would you like to monitor the uptime? (y/n)" "$monitor_uptime"
monitor_uptime=$?

read_yn "Would you like to monitor indoor temperature with a 1-wire sensor? (y/n)" "$monitor_temp_in"
monitor_temp_in=$?
if [ "${monitor_temp_in:-0}" -eq 1 ]; then
  echo "Please select the 1-wire device:"
  monitor_temp_in_dev=`read_w1_dev`
fi

read_yn "Would you like to monitor the outdoor temperature with a 1-wire sensor? (y/n)" "$monitor_temp_out"
monitor_temp_out=$?
if [ "${monitor_temp_out:-0}" -eq 1 ]; then
  echo "Please select the 1-wire device:"
  monitor_temp_out_dev=`read_w1_dev`
fi

# Check that ifstat command is installed
which ifstat &>/dev/null
if [ $? -eq 0 ]; then
  read_yn "Would you like to monitor any network interfaces? (y/n)" "$monitor_network_interfaces"
  monitor_network_interfaces=$?
  if [ $monitor_network_interfaces -eq 1 ]; then
    avail_ifaces=$(get_interfaces);
    read_s "Enter a comma-separated list of network interfaces ($avail_ifaces):" result "$network_interfaces"
    network_interfaces=$result
  fi
else
  monitor_network_interfaces=0
  echo "WARNING: ifstat command not found. Unable to monitor network 
interfaces. Press Enter to continue."  
  read
fi

# Prompt user to back up existing configuration, if any
if [[ -f "$HOME/.rpi2pachube.conf" ]]; then
  read_yn "Configuration file already exists. Would you like to make a back up first? (y/n)"
  if [ $? -eq 1 ]; then
    echo "Moved old configuration to $HOME/.rpi2pachube.conf.backup"
    cp $HOME/.rpi2pachube.conf $HOME/.rpi2pachube.conf.backup
  fi
fi

cat <<EOF > /tmp/rpi2pachube.conf
# Generated by rpi2pachube configuration utility
# from $realpath
# on `date` by `id -un`
# Feel free to modify this file or use the configuration utility.

# API Key
api_key=$api_key

# Feed ID
feed=$feed

# Monitor load average
monitor_load_avg=$monitor_load_avg

# Monitor free RAM memory
monitor_mem_free=$monitor_mem_free

# Monitor used RAM memory
monitor_mem_used=$monitor_mem_used

# Monitor cached RAM memory
monitor_mem_cached=$monitor_mem_cached

# Monitor the temperature
monitor_temp=$monitor_temp
monitor_temp_f=$monitor_temp_f

# Monitor the 1-wire sensors
monitor_temp_in=$monitor_temp_in
monitor_temp_in_dev=$monitor_temp_in_dev
monitor_temp_out=$monitor_temp_out
monitor_temp_out_dev=$monitor_temp_out_dev

# Monitor the number of processes
monitor_pid_count=$monitor_pid_count

# Monitor the number of active TCP/UDP connections
monitor_connections=$monitor_connections

# Monitor the number of users logged in
monitor_users=$monitor_users

# Monitor the uptime
monitor_uptime=$monitor_uptime

# Monitor monitor_network_interfaces
monitor_network_interfaces=$monitor_network_interfaces

# Network Interfaces
network_interfaces=$network_interfaces
EOF

# Back up old configuration
if [ -f "$HOME/.rpi2pachube.conf" ]; then
  mv "$HOME/.rpi2pachube.conf" "$HOME/.rpi2pachube.conf.backup"
fi

# Write new configuration
echo "Writing new configuration to $HOME/.rpi2pachube.conf..."
mv /tmp/rpi2pachube.conf $HOME/.rpi2pachube.conf
if [[ $? -eq 0 ]]; then
  echo "Configuration file saved to $HOME/.rpi2pachube.conf"
else
  echo "Unable to save configuration file to $HOME/.rpi2pachube.conf" 1>&2
  exit 1
fi

echo "Updating crontab..."
# Get crontab without any entries to rpi2pachube and save to temporary file
crontab -l 2>/dev/null | grep -v rpi2pachube > /tmp/crontab
# Get the directory where setup utility is; assuming rpi2pachube.sh is there too
dirname=`dirname $realpath`
# Add a new entry to our crontab
echo "*/5 * * * * ${dirname}/rpi2pachube.sh" >> /tmp/crontab
# Replace current crontab with our version
crontab /tmp/crontab
# Show it to the user
#env EDITOR=nano crontab -e
echo "Displaying `id -un`'s crontab:"
crontab -l
echo "Run 'crontab -e' if you see any problem with your crontab."
echo "Done."
# Exit
exit 0
