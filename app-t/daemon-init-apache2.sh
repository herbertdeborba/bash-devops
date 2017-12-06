#!/bin/bash
# Author:
#  Herbert Mattei de Borba <herbert@tjsc.jus.br>
#
# /etc/init.d/daemon-init-${INSTANCE_NAME}
#
### BEGIN INIT INFO
# Provides: apache2
# Required-Start: $remote_fs
# Required-Stop:
# Default-Start: 2 3 4 5
# Default-Stop: 0 1 6
# Short-Description: Apache2 start, stop, restart.
# Description: Apache2 init script.
### END INIT INFO

COMMAND=$1

INSTANCE_NAME="apache2"

. /opt/scripts/custom/custom-setup-${INSTANCE_NAME}.sh

. /opt/scripts/daemon-init.sh ${INSTANCE_NAME} ${INSTANCE_PATH} ${COMMAND}