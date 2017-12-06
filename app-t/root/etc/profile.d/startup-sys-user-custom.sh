#if id -nG "$USER" | grep -qw -E "sysadm|devadm" ; then
#        echo "Definindo comandos customizados de administração."
#        alias apache-stop="sudo /opt/scripts/daemon-stop.sh -i apache2"
#	alias apache-alterna-estado="sudo /opt/scripts/custom/custom-portal-alterna-estado.sh"
#fi

#if id -nG "$USER" | grep -qw "sysadm" ; then
#	
#fi

