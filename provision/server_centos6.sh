#!/bin/bash
#####################################################################################
# Copyright 2013 Normation SAS
#####################################################################################
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, Version 3.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
#####################################################################################

## Config stage

# Rudder version
RUDDER_VERSION="2.6"
RUDDER_VERSION27="2.7"

YUM_ARGS="-y --nogpgcheck"

# Rudder related parameters
SERVER_INSTANCE_HOST="server.rudder.local"
DEMOSAMPLE="no"
LDAPRESET="yes"
INITPRORESET="yes"
ALLOWEDNETWORK[0]='192.168.42.0/24'

# Showtime
# Editing anything below might create a time paradox which would
# destroy the very fabric of our reality and maybe hurt kittens.
# Be responsible, please think of the kittens.

# Host preparation:
# This machine is "server", with the FQDN "server.rudder.local".
# It has this IP : 192.168.42.10 (See the Vagrantfile)

sed -i "s%^127\.0\.0\.1.*%127\.0\.0\.1\tlocalhost localhost.localdomain server\.rudder\.local\tserver%" /etc/hosts
echo -e "\n192.168.42.11	node.rudder.local" >> /etc/hosts
echo -e "\n192.168.42.12	node2.rudder.local" >> /etc/hosts
echo -e "\n192.168.42.13	node3.rudder.local" >> /etc/hosts
echo -e "\n192.168.42.14	node4.rudder.local" >> /etc/hosts
echo -e "\n192.168.42.15	node5.rudder.local" >> /etc/hosts
echo -e "\n192.168.42.16	node6.rudder.local" >> /etc/hosts
echo -e "\n192.168.42.17	node7.rudder.local" >> /etc/hosts
echo -e "\n192.168.42.18	node8.rudder.local" >> /etc/hosts
echo -e "\n192.168.42.19	node9.rudder.local" >> /etc/hosts
echo -e "\n192.168.42.20	node10.rudder.local" >> /etc/hosts
sed -ri 's#^HOSTNAME=.*#HOSTNAME=server#' /etc/sysconfig/network
hostname server

# Add Rudder repository
echo "[Rudder_${RUDDER_VERSION}]
name=Rudder ${RUDDER_VERSION} Repository
baseurl=http://www.rudder-project.org/rpm-${RUDDER_VERSION}/RHEL_6/
enabled=1
gpgcheck=0
" > /etc/yum.repos.d/rudder.repo

# Add Rudder 2.7 repository
echo "[Rudder_${RUDDER_VERSION26_NIGHTLY}]
name=Rudder ${RUDDER_VERSION26_NIGHTLY} Repository
baseurl=http://www.rudder-project.org/rpm-${RUDDER_VERSION27}/RHEL_6/
enabled=0
gpgcheck=0
" > /etc/yum.repos.d/rudder2.7.repo


# Set SElinux as permissive
setenforce 0
service iptables stop

# Refresh zypper
yum ${YUM_ARGS} check-update

# Install Rudder
yum ${YUM_ARGS} install rudder-server-root

# Initialize Rudder
/opt/rudder/bin/rudder-init.sh $SERVER_INSTANCE_HOST $DEMOSAMPLE $LDAPRESET $INITPRORESET ${ALLOWEDNETWORK[0]} < /dev/null > /dev/null 2>&1

# Edit the base url parameter of Rudder to this Vagrant machine fully qualified name no need for 2.5
sed -i s%^base\.url\=.*%base\.url\=http\:\/\/server\.rudder\.local\:8080\/rudder% /opt/rudder/etc/rudder-web.properties

# Add licenses (don't think it's needed anymore)
# cp licenses.xml /opt/rudder/etc/licenses/

# Start the rudder web service
/etc/init.d/jetty restart < /dev/null > /dev/null 2>&1

# Start the CFEngine backend
/etc/init.d/rudder-agent restart

echo "Rudder server install: FINISHED" |tee /tmp/rudder.log
