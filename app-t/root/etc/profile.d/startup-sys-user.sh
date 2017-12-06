if id -nG "$USER" | grep -qw -E "sysadm|devadm" ; then
		/usr/bin/sudo /opt/devops/common-permissions.sh

		echo "Definindo comandos de administração."

		alias apache-status="sudo /opt/devops/daemon-status.sh -i apache2 -m"
		alias apache-logs="/opt/devops/util-log-reader.sh -l \"/usr/local/apache2/logs/access_log /usr/local/apache2/logs/error_log\" -c -f"
		alias apache-logs-access="/opt/devops/util-log-reader.sh -l \"/usr/local/apache2/logs/access_log\" -c -f"
		alias apache-logs-error="/opt/devops/util-log-reader.sh -l \"/usr/local/apache2/logs/error_log\" -c -f"
fi

if id -nG "$USER" | grep -qw "sysadm" ; then
		echo "Definindo comandos exclusivos para usuario administrador do sistema."
		
		alias apache-start="sudo /opt/devops/daemon-start.sh -i apache2"
		alias apache-stop="sudo /opt/devops/daemon-stop.sh -i apache2"
		alias apache-restart="sudo /opt/devops/daemon-restart.sh -i apache2"
		alias apache-reload="sudo /opt/devops/daemon-restart.sh -i apache2 -r"
		alias sync-me="/opt/devops/sync-me.sh"

fi
#if id -nG "$USER" | grep -qw "devadm" ; then
		#echo "Definindo comandos específicos para usuario administrador de aplicacao."
#fi

