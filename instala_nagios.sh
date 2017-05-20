#!/bin/bash
# Instalação automática do Nagios no Fedora
# Programas utilizados:
# curl, ifconfig, whereis, wget
# victor.oliveira@gmx.com

#TODO: Baixar sempre a versão atual
#curl 'https://www.nagios.org/checkforupdates/?product=nagioscore'| grep -Eo "Nagios Core is \w{1}\.\w{1}\.\w{1}"
url_nagios='https://assets.nagios.com/downloads/nagioscore/releases/nagios-4.3.2.tar.gz'
url_plugins='https://nagios-plugins.org/download/nagios-plugins-2.2.1.tar.gz'

clear
echo "Instalação automática - Nagios 4.3.2"

#Verifica se o usuário é root
id| grep root &> /dev/null
if [ $? != 0 ]; then
	echo "Para executar o script é necessário estar logado como root."
	exit
fi

read -ep "Prosseguir com a instalação? (enter ou n): " teste
case $teste in
	[Nn])
	echo "Instalação cancelada. Saindo."
	exit
esac

echo "Baixando pacotes necessários para compilar o programa"
dnf -y install autoconf automake gcc gcc-c++ gd-devel httpd php wget net-tools curl

clear
echo "Verificando conexão com a internet"
sleep 2

curl www.google.com &> /dev/null
if [ "$?" != "0" ]; then
	echo "Verifique sua conexão com a internet"
	echo "Saindo."
	exit
else
	echo "Conexão OK! Continuando..."
fi

sleep 2

echo "Criando usuário nagios"
useradd -m nagios

echo "Configurando permissões do apache"
usermod -aG nagios apache

echo "Criando pastas necessárias"
cd ~/
rm -rf nagios-install
mkdir nagios-install
cd nagios-install

echo "Baixando Nagios e plugins"
wget "${url_nagios}"

wget "${url_plugins}"

echo "Extraindo arquivos"
tar xvf nagios-4.3.2.tar.gz
tar xvf nagios-plugins-2.2.1.tar.gz

echo "Compilando"
cd nagios-4.3.2/
./configure
make all
make install
make install-init
make install-commandmode
make install-config
make install-webconf
make install-exfoliation

cd ../nagios-plugins-2.2.1/
./configure
make all
make install

echo "Criando link simbólico"
cd ~/
ln -s /usr/local/nagios/

clear
echo "Digite a senha do usuário WEB nagiosadmin"
htpasswd -c /usr/local/nagios/etc/htpasswd.users nagiosadmin

clear
echo "Digite a senha do usuário nagios"
passwd nagios

echo "Configurando Selinux"
setenforce 0
sed -i s/SELINUX=enforcing/SELINUX=permissive/ /etc/selinux/config

echo "Instalando script de checagem de serviço"
cd ~/
echo '#!/bin/bash
#
# Checa/reinicia Nagios
#

/usr/local/nagios/bin/nagios -v /usr/local/nagios/etc/nagios.cfg

if [ "$?" = "0" ]; then
	echo
	read -ep "Configuração OK! Reiniciar serviços? (n ou s): " questao
		case "$questao" in
			[Nn])
			exit
			;;
			[Ss])
			systemctl restart nagios
			;;
			*)
			echo "Opção inválida."
		esac
else
	echo "Verifique a configuração do Nagios."
fi' > nagios_check
mv ~/nagios_check /usr/bin/
chmod +x /usr/bin/nagios_check

echo "Configurando firewall"
firewall-cmd --add-service=http
firewall-cmd --add-service=http --permanent

echo "Configurando inicialização automática dos serviços"
systemctl enable nagios httpd

echo "Iniciando serviços"
systemctl start httpd nagios

clear
echo "Nagios 4.3.2 instalado!"
echo "Acesse o monitoramento através de um dos links:"
for ip in $(for name in $(ifconfig|grep UP|cut -d ':' -f1); do ifconfig $name|grep netmask|cut -d ' ' -f10; done); do
echo "http://$ip/nagios"
done
echo "Possíveis endereços IP:"
echo
echo "Usuário: nagiosadmin e a senha configurada anteriormente"
