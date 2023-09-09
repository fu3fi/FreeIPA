# Fs-server
# sf -p fsserver


# mkdir fs
mkdir -p /opt/share


# static ip
nmcli con mod ens33 ipv4.address 10.133.11.99/24
nmcli con mod ens33 autoconnect yes
nmcli con down ens33
nmcli con up ens33


# update system and kdestroy
yum update -y
yum install -y openldap-clients $


# open firewall for dns
firewall-cmd --add-service=dns --permanent
firewall-cmd --reload


# ask hostname
hostnamectl set-hostname fs1.tree.local


# add ip in hosts
echo "10.133.11.111  server.tree.local server" >> /etc/hosts
echo "10.133.11.99  fs1.tree.local fs1" >> /etc/hosts
# nano /etc/hosts
# {
#   10.133.11.111  server.tree.local server
#   10.133.11.99  fs1.tree.local fs1
# }


# install ipa-client and samba
yum -y install freeipa-client ipa-admintools sssd-libwbclient samba samba-client


# add ip in order to search domain
sed -i -e '1 s/^/search tree.local\nnameserver 10.133.11.111\n/;' /etc/resolv.conf
# nano /etc/resolv.conf
# {
#   search tree.local
#   nameserver 10.133.11.111
# }


# add fs-server in domain
yes | ipa-client-install --mkhomedir --force-ntpd --no-ntp --principal='admin' --password='serveradmin'


# settings server
########################################################################################################################################################################

# login for admin
echo 'serveradmin' | kinit admin


# load keytab
kinit -kt /etc/krb5.keytab
ipa-getkeytab -s server.tree.local -p cifs/fs1.tree.local -k /etc/samba/samba.keytab


# read ipaNTHash
kdestroy -A
kinit -kt /etc/samba/samba.keytab cifs/fs1.tree.local
ldapsearch -Y gssapi "(ipaNTHash=*)" ipaNTHash &> /dev/null


# config samba
echo '[global]
    workgroup = TREE
    realm = TREE.LOCAL

    log file = /var/log/samba/log.%m

    dedicated keytab file = FILE:/etc/samba/samba.keytab
    kerberos method = dedicated keytab


[homes]
    comment = Home Directories
    valid users = %S, %D%w%S
    browseable = No
    read only = No
    inherit acls = Yes


[FS_Share]
    comment = Test share on FS server
    path = /opt/share
    writeable = yes
    browseable = yes
     valid users = @admins # access
     write list = @admins # write
     guest ok = No
     inherit acls = Yes
     create mask = 0660
     directory mask = 0770' > /etc/samba/smb.conf
# nano /etc/samba/smb.conf
# {
#     [global]
#         workgroup = TREE
#         realm = TREE.LOCAL

#         log file = /var/log/samba/log.%m

#         dedicated keytab file = FILE:/etc/samba/samba.keytab
#         kerberos method = dedicated keytab


#     [homes]
#         comment = Home Directories
#         valid users = %S, %D%w%S
#         browseable = No
#         read only = No
#         inherit acls = Yes

#     [FS_Share]
#             comment = Test share on FS server
#             path = /opt/share
#             writeable = yes
#             browseable = yes
#             valid users = @admins # access
#             write list = @admins # write
#             guest ok = No
#             inherit acls = Yes
#             create mask = 0660
#             directory mask = 0770
# }


# start fs-server(smb)
systemctl start smb
systemctl enable smb


# open firewall for samba
firewall-cmd --permanent --add-port=445/{tcp,udp} --add-port=139/{tcp,udp}
firewall-cmd --reload