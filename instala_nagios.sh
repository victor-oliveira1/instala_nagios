#!/bin/bash
# Instalação automática do Nagios no Fedora
# victor.oliveira@gmx.com

clear
echo "Instalação automática - Nagios 4.2"
echo "A senha de root será solicitada para instalar alguns pacotes."
read -ep "Prosseguir com a instalação? (enter ou n): " teste

case $teste in
	[Nn])
	echo "Instalação cancelada. Saindo."
	exit
esac

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

echo "Baixando pacotes necessários para compilar o programa"
sudo dnf -y install autoconf automake gcc gcc-c++ gd-devel httpd php

echo "Criando usuário nagios"
sudo useradd -m nagios

echo "Configurando permissões do apache"
sudo usermod -aG nagios apache

echo "Criando pastas necessárias"
cd ~/
rm -rf nagios-install
mkdir nagios-install
cd nagios-install

echo "Baixando Nagios e plugins"
wget 'https://assets.nagios.com/downloads/nagioscore/releases/nagios-4.2.0.tar.gz#_ga=1.94145432.420122707.1469735867'

wget 'https://nagios-plugins.org/download/nagios-plugins-2.1.2.tar.gz#_ga=1.60581800.420122707.1469735867'

echo "Extraindo arquivos"
tar xvf nagios-4.2.0.tar.gz
tar xvf nagios-plugins-2.1.2.tar.gz

echo "Compilando"
cd nagios-4.2.0/
./configure
make all
sudo make install
sudo make install-init
sudo make install-commandmode
sudo make install-config
sudo make install-webconf
sudo make install-exfoliation

cd ../nagios-plugins-2.1.2/
./configure
make all
sudo make install

echo "Criando link simbólico"
cd ~/
ln -s /usr/local/nagios/

clear
echo "Digite a senha do usuário WEB nagiosadmin"
sudo htpasswd -c /usr/local/nagios/etc/htpasswd.users nagiosadmin

clear
echo "Digite a senha do usuário nagios"
sudo passwd nagios

echo "Configurando Selinux"
sudo setenforce 0
sudo sed -i s/SELINUX=enforcing/SELINUX=permissive/ /etc/selinux/config

echo "Configurando firewall"
sudo firewall-cmd --add-service=http
sudo firewall-cmd --add-service=http --permanent

echo "Configurando inicialização automática dos serviços"
sudo systemctl enable nagios httpd

echo "Iniciando serviços"
sudo systemctl start httpd nagios

clear
echo "Nagios 4.2 instalado!"
echo "Acesse o monitoramento através do link: http://<endereço ip>/nagios"
echo "Usuário: nagiosadmin e a senha configurada anteriormente"
