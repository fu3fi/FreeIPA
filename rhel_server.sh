admin
serveradmin

# Rhel
# su -p ipaserver


# static ip
nmcli con mod ens160 ipv4.address 10.133.11.111/24
nmcli con mod ens160 autoconnect yes
nmcli con down ens160
nmcli con up ens160

# registration
subscription-manager register --username='fumakit' --password='VQxG^F39t9#cb$r' --auto-attach
#-- subscription-manager attach --auto


# update system
yum update -y


# ask time
\cp /usr/share/zoneinfo/Europe/Moscow /etc/localtime


# install synctime
yum install -y chrony
systemctl enable chronyd
systemctl start chronyd


# ask hostname
hostnamectl set-hostname server.tree.local


# open firewall
firewall-cmd --permanent --add-port=53/{tcp,udp} --add-port=80/tcp --add-port=88/{tcp,udp} --add-port=123/udp --add-port=389/tcp --add-port=443/tcp --add-port=464/{tcp,udp} --add-port=636/tcp
firewall-cmd --reload


# install freeipa
yum -y install @idm:DL1
yum install -y ipa-server ipa-server-dns


# ipa-server-install
# {
# 	Do you want to configure integrated DNS (BIND)? [no]: yes
# 	Server host name [server.tree.local]: server.tree.local
# 	Please confirm the domain name [tree.local]: tree.local
# 	Please provide a realm name [TREE.LOCAL]: TREE.LOCAL
# 	Directory Manager password: ipaserveradmin
# 	Password (confirm): ipaserveradmin
# 	IPA admin password: serveradmin
# 	Password (confirm): serveradmin
# 	Do you want to configure DNS forwarders? [yes]: yes
# 	Do you want to configure these servers as DNS forwarders? [yes]: yes
# 	Enter an IP address for a DNS forwarder, or press Enter to skip: 8.8.8.8
# 	Enter an IP address for a DNS forwarder, or press Enter to skip:
# 	Do you want to search for missing reverse zones? [yes]:
# 	Do you want to create reverse zone for IP 10.133.11.111 [yes]:
# 	Please specify the reverse zone name [11.133.10.in-addr.arpa.]:
# 	Do you want to create reverse zone for IP 192.168.122.1 [yes]: 
# 	Please specify the reverse zone name [122.168.192.in-addr.arpa.]:
# 	Do you want to create reverse zone for IP 172.16.189.142 [yes]:
# 	Please specify the reverse zone name [189.16.172.in-addr.arpa.]:
# 	Do you want to configure chrony with NTP server or pool address? [no]:
# 	Continue to configure the system with these values? [no]: 
# 	(https://linux.die.net/man/1/ipa-server-install)

# 	The IPA Master Server will be configured with:
# 	Hostname:       server.tree.local
# 	IP address(es): 10.133.11.111, 192.168.122.1, 172.16.189.142
# 	Domain name:    tree.local
# 	Realm name:     TREE.LOCAL

# 	The CA will be configured with:
# 	Subject DN:   CN=Certificate Authority,O=TREE.LOCAL
# 	Subject base: O=TREE.LOCAL
# 	Chaining:     self-signed

# 	BIND DNS server will be configured to serve IPA domain with:
# 	Forwarders:       172.16.189.2, 8.8.8.8
# 	Forward policy:   only
# 	Reverse zone(s):  11.133.10.in-addr.arpa., 122.168.192.in-addr.arpa., 189.16.172.in-addr.arpa.
# }


# install freeipa
yes | ipa-server-install --setup-dns --hostname='server.tree.local' --domain='tree.local' --realm='TREE.LOCAL' --ds-password='ipaserveradmin' --admin-password='serveradmin' --no-forwarders --ip-address='10.133.11.111' --no-ntp --reverse-zone='11.133.10.in-addr.arpa.'
# --no-reverse 



#reboot
# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!




# login for admin
echo 'serveradmin' | kinit admin


# add fs-server for ipa-server
ipa dnsrecord-add tree.local fs1 --a-rec 10.133.11.99


# settings fs1.tree.local
################################################################################################################################################################################################################################################################################


# login for admin
echo 'serveradmin' | kinit admin


# add service
ipa service-add cifs/fs1.tree.local@TREE.LOCAL


# settings service
ipa permission-add "CIFS server can read user passwords" --attrs={ipaNTHash,ipaNTSecurityIdentifier} --type=user --right={read,search,compare} --bindtype=permission
ipa privilege-add "CIFS server privilege"
ipa privilege-add-permission "CIFS server privilege" --permission="CIFS server can read user passwords"
ipa role-add "CIFS server"
ipa role-add-privilege "CIFS server" --privilege="CIFS server privilege"
ipa role-add-member "CIFS server" --services=cifs/fs1.tree.local


# open firewall for samba
firewall-cmd --permanent --add-port=445/{tcp,udp} --add-port=139/{tcp,udp}
firewall-cmd --reload


# add user
# ipa user-add fuma --first=Fuma --last=Min --password