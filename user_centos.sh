# Ipa-server

# kinit admin
# ipa dnsrecord-add tree.local client-1 --a-rec 10.133.11.1

# Cent_os_user


# update system
yum update -y


# static ip
nmcli con mod ens33 ipv4.address 10.133.11.1/24
nmcli con mod ens33 autoconnect yes
nmcli con down ens33
nmcli con up ens33


# open firewall for dns
firewall-cmd --add-service=dns --permanent
firewall-cmd --reload


# ask hostname
hostnamectl set-hostname client-1.tree.local


# add ip in hosts
echo "10.133.11.111  server.tree.local server" >> /etc/hosts
echo "10.133.11.1  client-1.tree.local client_1" >> /etc/hosts
# nano /etc/hosts
# {
# 	10.133.11.111  server.tree.local server
# 	10.133.11.1  client-1.tree.local client_1
# }


# install ipa-client and samba-client
yum -y install freeipa-client ipa-admintools samba-client


# add ip in order to search domain
sed -i -e '1 s/^/search tree.local\nnameserver 10.133.11.111\n/;' /etc/resolv.conf
# nano /etc/resolv.conf
# {
# 	search tree.local
# 	nameserver 10.133.11.111
# }


# add fs-server in domain
yes | ipa-client-install --mkhomedir --force-ntpd --no-ntp --principal='admin' --password='serveradmin'


# check fs-server
# smbclient -k //fs1.tree.local/FS_Share


# clear cache
# systemctl stop sssd
# rm -f /var/lib/sss/db/*
# rm -f /var/lib/sss/mc/*
# systemctl start sssd