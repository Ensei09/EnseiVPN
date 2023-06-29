#!/bin/bash
rm -rf debian*
fun_bar () {
comando[0]="$1"
comando[1]="$2"
 (
[[ -e $HOME/fim ]] && rm $HOME/fim
${comando[0]} -y > /dev/null 2>&1
${comando[1]} -y > /dev/null 2>&1
touch $HOME/fim
 ) > /dev/null 2>&1 &
 tput civis
echo -ne "\033[1;33m["
while true; do
   for((i=0; i<18; i++)); do
   echo -ne "\033[1;31m#"
   sleep 0.1s
   done
   [[ -e $HOME/fim ]] && rm $HOME/fim && break
   echo -e "\033[1;33m]"
   sleep 1s
   tput cuu1
   tput dl1
   echo -ne "\033[1;33m["
done
echo -e "\033[1;33m]\033[1;37m -\033[1;32m OK !\033[1;37m"
tput cnorm
}

RED='\033[01;31m';
RESET='\033[0m';
GREEN='\033[01;32m';
WHITE='\033[01;37m';
YELLOW='\033[00;33m';

# Server local time
MyVPS_Time='Asia/Manila'

timedatectl set-timezone Asia/Manila

systemupdate () {
#Disable ipv6
sudo sysctl -w net.ipv6.conf.all.disable_ipv6=1
sudo sysctl -w net.ipv6.conf.default.disable_ipv6=1
sudo sysctl -w net.ipv6.conf.lo.disable_ipv6=1
apt-get update
apt-get upgrade -y
apt-get -y install dropbear
wget -qO /etc/banner "https://raw.githubusercontent.com/Ensei09/EnseiVPN/main/NatureVPN%20Files/SSHBanner"

 # Removing some duplicate config file
 rm -rf /etc/default/dropbear*

  # creating dropbear config using cat eof tricks
 cat <<'MyDropbear' > /etc/default/dropbear
# My Dropbear Config
NO_START=0
DROPBEAR_PORT=550
DROPBEAR_EXTRA_ARGS=""
DROPBEAR_BANNER="/etc/banner"
DROPBEAR_RSAKEY="/etc/dropbear/dropbear_rsa_host_key"
DROPBEAR_DSSKEY="/etc/dropbear/dropbear_dss_host_key"
DROPBEAR_ECDSAKEY="/etc/dropbear/dropbear_ecdsa_host_key"
DROPBEAR_RECEIVE_WINDOW=65536
MyDropbear

echo "/bin/false" >> /etc/shells
echo "/usr/sbin/nologin" >> /etc/shells
systemctl restart dropbear

# sed -i 's/NO_START=1/NO_START=0/g' /etc/default/dropbear
# sed -i 's/DROPBEAR_PORT=22/DROPBEAR_PORT=550/g' /etc/default/dropbear
# sed -i 's/DROPBEAR_BANNER=""/DROPBEAR_BANNER="/etc/banner/"g' /etc/default/dropbear

}

systempackages () {
apt-get install mysql-client openvpn unzip build-essential curl privoxy stunnel4 net-tools screen -y
apt-get install php php-mysqli php-mysql php-gd php-mbstring -y
apt-get install php-ldap php-odbc php-pear php-xml php-xmlrpc php-mbstring php-snmp php-soap -y
}

filesfolders () {
mkdir /etc/openvpn/script
mkdir /var/www/html/stat
touch /var/www/html/stat/status.txt
touch /var/www/html/stat/udpstatus.txt
touch /var/www/html/stat/udpstatus2.txt
chmod 755 /var/www/html/stat/*

cat <<\EOM >/etc/openvpn/server.conf
port 442
sndbuf 0
rcvbuf 0
push "sndbuf 393216"
push "rcvbuf 393216"
reneg-sec 432000
push "persist-key"
push "persist-tun"
proto tcp
dev tun
ca ca.crt
cert server.crt
key server.key
dh dh2048.pem
server 10.8.0.0 255.255.0.0
user nobody
username-as-common-name
client-cert-not-required
auth-user-pass-verify /etc/openvpn/script/authvpn.sh via-env
push "redirect-gateway def1 bypass-dhcp"
push "dhcp-option DNS 8.8.4.4"
push "dhcp-option DNS 8.8.8.8"
client-to-client
keepalive 5 30
max-clients 4080
script-security 3
status /var/www/html/stat/status.txt
persist-key
persist-tun
verb 3
EOM

cat <<\EOM1 >/etc/openvpn/server2.conf
port 110
sndbuf 0
rcvbuf 0
push "sndbuf 393216"
push "rcvbuf 393216"
reneg-sec 432000
push "persist-key"
push "persist-tun"
proto tcp
dev tun
ca ca.crt
cert server.crt
key server.key
dh dh2048.pem
server 172.20.0.0 255.255.255.0
user nobody
username-as-common-name
client-cert-not-required
auth-user-pass-verify /etc/openvpn/script/authvpn.sh via-env
push "redirect-gateway def1 bypass-dhcp"
push "dhcp-option DNS 8.8.4.4"
push "dhcp-option DNS 8.8.8.8"
client-to-client
keepalive 5 30
max-clients 4080
script-security 3
status /var/www/html/stat/udpstatus2.txt
persist-key
persist-tun
verb 3
EOM1

cat <<\EOM2 >/etc/openvpn/server3.conf
port 110
sndbuf 0
rcvbuf 0
push "sndbuf 393216"
push "rcvbuf 393216"
reneg-sec 432000
push "persist-key"
push "persist-tun"
proto udp
dev tun
ca ca.crt
cert server.crt
key server.key
dh dh2048.pem
server 10.9.0.0 255.255.255.0
user nobody
username-as-common-name
client-cert-not-required
auth-user-pass-verify /etc/openvpn/script/authvpn.sh via-env
push "redirect-gateway def1 bypass-dhcp"
push "dhcp-option DNS 8.8.4.4"
push "dhcp-option DNS 8.8.8.8"
client-to-client
keepalive 5 30
max-clients 4080
script-security 3
status /var/www/html/stat/udpstatus.txt
persist-key
persist-tun
verb 3
EOM2


cat <<\EOM3 >/etc/openvpn/ca.crt
-----BEGIN CERTIFICATE-----
MIID1zCCA0CgAwIBAgIJAIf0ZhcijVyOMA0GCSqGSIb3DQEBBQUAMIGkMQswCQYD
VQQGEwJVUzELMAkGA1UECBMCQ0ExEDAOBgNVBAcTB2J1ZmZhbG8xFTATBgNVBAoT
DEZvcnQtRnVuc3RvbjESMBAGA1UECxMJZ2FtaW5ndnBuMRIwEAYDVQQDEwlnYW1p
bmd2cG4xEjAQBgNVBCkTCWdhbWluZ3ZwbjEjMCEGCSqGSIb3DQEJARYUY2Fydmlj
MTk5OEBnbWFpbC5jb20wHhcNMTYwNDEyMDQxNzE3WhcNMjYwNDEwMDQxNzE3WjCB
pDELMAkGA1UEBhMCVVMxCzAJBgNVBAgTAkNBMRAwDgYDVQQHEwdidWZmYWxvMRUw
EwYDVQQKEwxGb3J0LUZ1bnN0b24xEjAQBgNVBAsTCWdhbWluZ3ZwbjESMBAGA1UE
AxMJZ2FtaW5ndnBuMRIwEAYDVQQpEwlnYW1pbmd2cG4xIzAhBgkqhkiG9w0BCQEW
FGNhcnZpYzE5OThAZ21haWwuY29tMIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKB
gQC6woe2R8MjAdN5KT+ccmhmDTjXIzQVNWSL+q7VRgqB7pmVgtoCE1Ti2l60jGzN
OGU7WeT43+nOa9iKBag5KvLOLzFpVnKFPXgrG0GUyGPHEf11jqreYBq7T3kFwGYM
WnKKiCG2FyWlZc/Fe2iQwEFyQ1o2uQaf/iP+gIdjk8Z6owIDAQABo4IBDTCCAQkw
HQYDVR0OBBYEFDNbVb2UowyA/pYt+MaCGZLZ2ehHMIHZBgNVHSMEgdEwgc6AFDNb
Vb2UowyA/pYt+MaCGZLZ2ehHoYGqpIGnMIGkMQswCQYDVQQGEwJVUzELMAkGA1UE
CBMCQ0ExEDAOBgNVBAcTB2J1ZmZhbG8xFTATBgNVBAoTDEZvcnQtRnVuc3RvbjES
MBAGA1UECxMJZ2FtaW5ndnBuMRIwEAYDVQQDEwlnYW1pbmd2cG4xEjAQBgNVBCkT
CWdhbWluZ3ZwbjEjMCEGCSqGSIb3DQEJARYUY2FydmljMTk5OEBnbWFpbC5jb22C
CQCH9GYXIo1cjjAMBgNVHRMEBTADAQH/MA0GCSqGSIb3DQEBBQUAA4GBAF+A6zox
senbKlz8OlzINM4CHFknHHbCXAfIsVgLA+Dsau40PB3TsHmLiWtEnzVKQ91VAMXU
z89ilB4pPYP6RijHyCAbtWyWxHSdxFTOzjVQyYpvNHSAXd+0ntaNhpSrv3toMedh
i8VauAMaG2SWG2hGCxEjHKH7qXrs1s2NKihO
-----END CERTIFICATE-----
EOM3

cat <<\EOM4 >/etc/openvpn/dh2048.pem
-----BEGIN DH PARAMETERS-----
MIIBCAKCAQEAohzwXz9fsjw+G9Q14qINNOhZnTt/b30zzJYm4o2NIzAngM6E6GPm
N5USUt0grZw6h3VP9LyqQoGi/bHFz33YFG5lgDF8FAASEh07/leF7s0ohhK8pspC
JVD+mRatwBrIImXUpJvYI2pXKxtCOnDa2FFjAOHKixiAXqVcmJRwNaSklQcrpXdn
/09cr0rbFoovn+f1agly4FxYYs7P0XkvSHm3gVW/mhAUr1hvZlbBaWFSVUdgcVOi
FXQ/AVkvxYaO8pFI2Vh+CNMk7Vvi8d3DTayvoL2HTgFi+OIEbiiE/Nzryu+jDGc7
79FkBHWOa/7eD2nFrHScUJcwWiSevPQjQwIBAg==
-----END DH PARAMETERS-----
EOM4

cat <<\EOM5 >/etc/openvpn/server.crt
Certificate:
    Data:
        Version: 3 (0x2)
        Serial Number: 1 (0x1)
    Signature Algorithm: sha1WithRSAEncryption
        Issuer: C=US, ST=CA, L=buffalo, O=Fort-Funston, OU=OragonVPN, CN=OragonVPN/name=OragonVPN/emailAddress=carvic1998@gmail.com
        Validity
            Not Before: Apr 12 04:17:47 2016 GMT
            Not After : Apr 10 04:17:47 2026 GMT
        Subject: C=US, ST=CA, L=buffalo, O=Fort-Funston, OU=OragonVPN, CN=OragonVPN/name=OragonVPN/emailAddress=carvic1998@gmail.com
        Subject Public Key Info:
            Public Key Algorithm: rsaEncryption
                Public-Key: (1024 bit)
                Modulus:
                    00:c5:fd:a6:d6:bf:4d:6b:b0:a9:fc:db:97:02:d3:
                    9b:ab:a8:7e:44:95:4d:fb:d8:55:ad:c0:99:78:21:
                    bb:a9:fa:78:36:96:2e:c5:f0:c3:57:ca:40:30:c4:
                    24:4a:3d:25:91:0c:93:52:c2:a7:ab:f8:90:40:bb:
                    60:f5:1d:15:e7:96:cc:8a:ca:fe:41:69:e2:85:cd:
                    e4:e0:99:66:cf:86:52:84:ae:ed:56:25:1e:f4:46:
                    b2:08:db:29:c0:f5:61:aa:0e:c8:fb:99:4c:0b:8d:
                    bb:3e:8a:03:de:25:c0:ac:0c:8d:06:1e:fa:e0:a7:
                    e6:82:50:49:93:e4:f2:e2:7f
                Exponent: 65537 (0x10001)
        X509v3 extensions:
            X509v3 Basic Constraints: 
                CA:FALSE
            Netscape Cert Type: 
                SSL Server
            Netscape Comment: 
                Easy-RSA Generated Server Certificate
            X509v3 Subject Key Identifier: 
                11:39:E8:C7:D4:76:29:1F:5E:76:E0:82:6E:93:5E:3F:93:B2:51:06
            X509v3 Authority Key Identifier: 
                keyid:33:5B:55:BD:94:A3:0C:80:FE:96:2D:F8:C6:82:19:92:D9:D9:E8:47
                DirName:/C=US/ST=CA/L=buffalo/O=Fort-Funston/OU=OragonVPN/CN=OragonVPN/name=OragonVPN/emailAddress=carvic1998@gmail.com
                serial:87:F4:66:17:22:8D:5C:8E

            X509v3 Extended Key Usage: 
                TLS Web Server Authentication
            X509v3 Key Usage: 
                Digital Signature, Key Encipherment
    Signature Algorithm: sha1WithRSAEncryption
         32:fa:26:e4:38:d4:8f:85:75:d3:fa:d4:ca:9d:d5:27:78:99:
         c5:fc:bd:5f:6a:b0:65:56:8d:69:5a:8f:41:e3:d1:55:02:3d:
         82:bd:4e:d6:3d:a5:fc:45:ce:8a:bd:ba:bc:9a:02:ea:37:64:
         64:54:d4:ff:f8:c9:d1:05:6e:b7:76:88:de:96:d3:dd:70:08:
         a5:1f:28:71:a4:e8:ab:95:d6:e9:98:10:1c:6d:62:4a:6a:32:
         25:c1:50:36:05:4a:6f:15:84:cf:9a:6a:0e:79:d5:46:37:ba:
         0c:65:17:f9:0a:58:46:e6:a2:f1:61:f6:36:38:f6:95:ff:3e:
         47:ec
-----BEGIN CERTIFICATE-----
MIIENzCCA6CgAwIBAgIBATANBgkqhkiG9w0BAQUFADCBpDELMAkGA1UEBhMCVVMx
CzAJBgNVBAgTAkNBMRAwDgYDVQQHEwdidWZmYWxvMRUwEwYDVQQKEwxGb3J0LUZ1
bnN0b24xEjAQBgNVBAsTCWdhbWluZ3ZwbjESMBAGA1UEAxMJZ2FtaW5ndnBuMRIw
EAYDVQQpEwlnYW1pbmd2cG4xIzAhBgkqhkiG9w0BCQEWFGNhcnZpYzE5OThAZ21h
aWwuY29tMB4XDTE2MDQxMjA0MTc0N1oXDTI2MDQxMDA0MTc0N1owgaQxCzAJBgNV
BAYTAlVTMQswCQYDVQQIEwJDQTEQMA4GA1UEBxMHYnVmZmFsbzEVMBMGA1UEChMM
Rm9ydC1GdW5zdG9uMRIwEAYDVQQLEwlnYW1pbmd2cG4xEjAQBgNVBAMTCWdhbWlu
Z3ZwbjESMBAGA1UEKRMJZ2FtaW5ndnBuMSMwIQYJKoZIhvcNAQkBFhRjYXJ2aWMx
OTk4QGdtYWlsLmNvbTCBnzANBgkqhkiG9w0BAQEFAAOBjQAwgYkCgYEAxf2m1r9N
a7Cp/NuXAtObq6h+RJVN+9hVrcCZeCG7qfp4NpYuxfDDV8pAMMQkSj0lkQyTUsKn
q/iQQLtg9R0V55bMisr+QWnihc3k4Jlmz4ZShK7tViUe9EayCNspwPVhqg7I+5lM
C427PooD3iXArAyNBh764KfmglBJk+Ty4n8CAwEAAaOCAXUwggFxMAkGA1UdEwQC
MAAwEQYJYIZIAYb4QgEBBAQDAgZAMDQGCWCGSAGG+EIBDQQnFiVFYXN5LVJTQSBH
ZW5lcmF0ZWQgU2VydmVyIENlcnRpZmljYXRlMB0GA1UdDgQWBBQROejH1HYpH152
4IJuk14/k7JRBjCB2QYDVR0jBIHRMIHOgBQzW1W9lKMMgP6WLfjGghmS2dnoR6GB
qqSBpzCBpDELMAkGA1UEBhMCVVMxCzAJBgNVBAgTAkNBMRAwDgYDVQQHEwdidWZm
YWxvMRUwEwYDVQQKEwxGb3J0LUZ1bnN0b24xEjAQBgNVBAsTCWdhbWluZ3ZwbjES
MBAGA1UEAxMJZ2FtaW5ndnBuMRIwEAYDVQQpEwlnYW1pbmd2cG4xIzAhBgkqhkiG
9w0BCQEWFGNhcnZpYzE5OThAZ21haWwuY29tggkAh/RmFyKNXI4wEwYDVR0lBAww
CgYIKwYBBQUHAwEwCwYDVR0PBAQDAgWgMA0GCSqGSIb3DQEBBQUAA4GBADL6JuQ4
1I+FddP61Mqd1Sd4mcX8vV9qsGVWjWlaj0Hj0VUCPYK9TtY9pfxFzoq9uryaAuo3
ZGRU1P/4ydEFbrd2iN6W091wCKUfKHGk6KuV1umYEBxtYkpqMiXBUDYFSm8VhM+a
ag551UY3ugxlF/kKWEbmovFh9jY49pX/Pkfs
-----END CERTIFICATE-----
EOM5

cat <<\EOM6 >/etc/openvpn/server.key
-----BEGIN PRIVATE KEY-----
MIICeQIBADANBgkqhkiG9w0BAQEFAASCAmMwggJfAgEAAoGBAMX9pta/TWuwqfzb
lwLTm6uofkSVTfvYVa3AmXghu6n6eDaWLsXww1fKQDDEJEo9JZEMk1LCp6v4kEC7
YPUdFeeWzIrK/kFp4oXN5OCZZs+GUoSu7VYlHvRGsgjbKcD1YaoOyPuZTAuNuz6K
A94lwKwMjQYe+uCn5oJQSZPk8uJ/AgMBAAECgYEAl4GAd/gv4GZxzeKjbjBLgVIQ
PZ8a68sh1TH6vmjh2DKoZu0JocKZWMaV1DtjocOkyZgb7Eq0T+6HRGGe0jKNnS/C
4VfA04dlYI3/vQQjuTKzexc8V9/VdxG+gISN/jOIS9nIchL/ea4SuubcX//Cmj5m
PlaoG6j9Ea1OXyGjJJECQQDhhluhJjIjNd1YmHMyPlOFvNdkpj/ayeFILPGO98Bp
K+qzrMjOZXYkds4ry2VRl+BfCFKQwtlVPuEx0JD+pV/dAkEA4L7NZTCw3m6gSzwE
Bb8q+oGyv53sHVKUGIPf7+ErseaBZ6/D8SrxL4AopjiExeTPtzHBthrG8nqSb6By
qVyUCwJBAKLtH/FR2NLbLSe+KyrXIBv0C1/pQyRayGgOIAz7K4RPd+WKJCAH6Mv7
EINPE8lYgX3mU0/FlKEjJimI1ddBvfkCQQDbfdzQ97W09qu77lgrWKFb2DE/bLc9
h/m0245oEyv+aZV2MzWVIhA9CNgqRkZ9ktK+Im0CMbKc+9JqDHQPLagzAkEA32ZL
sWWrJCTXItLxqREf2VTozxezL+Kn8W2c+X7YZT6tjcmPbbMbq0XaC4eRT4a5I7y4
MhZ/R1wSBx9xz+14PQ==
-----END PRIVATE KEY-----
EOM6

cat <<\EOM7 >/etc/openvpn/script/config.sh
#!/bin/bash
HOST='178.128.216.244'
USER='sql_panel_nature'
PASS='sRFzNwXpw5Drwm7F'
DB='sql_panel_nature'
EOM7

cat <<\EOM8 >/etc/openvpn/script/connect.sh
#!/bin/bash
. /etc/openvpn/script/config.sh
##tm="$(date +%s)"
##dt="$(date +'%Y-%m-%d %H:%M:%S')"
##timestamp="$(date +'%FT%TZ')"
##set status online to user connected
mysql -u $USER -p$PASS -D $DB -h $HOST -e "UPDATE users SET is_connected=1 WHERE user_name='$common_name' "
EOM8

cat <<\EOM9 >/etc/openvpn/script/disconnect.sh
#!/bin/bash
. /etc/openvpn/script/config.sh
tm="$(date +%s)"
dt="$(date +'%Y-%m-%d %H:%M:%S')"
timestamp="$(date +'%FT%TZ')"

##mysql -u $USER -p$PASS -D $DB -h $HOST -sN -e "UPDATE bandwidth_logs SET bytes_received='$bytes_received',bytes_sent='$bytes_sent',time_out='$dt', status='offline' WHERE username='$common_name' AND status='online' AND category='vip' "

mysql -u $USER -p$PASS -D $DB -h $HOST -sN -e "UPDATE users SET is_connected=0 WHERE user_name='$common_name' ";
mysql -u $USER -p$PASS -D $DB -h $HOST -sN -e "UPDATE users SET bandwidth_premium=bandwidth_premium +'$bytes_received' WHERE user_name='$common_name'";
EOM9

cat <<EOF >/etc/privoxy/config
user-manual /usr/share/doc/privoxy/user-manual
confdir /etc/privoxy
logdir /var/log/privoxy
filterfile default.filter
logfile logfile
listen-address  0.0.0.0:8118
listen-address  0.0.0.0:8000
listen-address  0.0.0.0:8080
listen-address  0.0.0.0:8888
listen-address  0.0.0.0:3128
toggle 1
enable-remote-toggle  0
enable-remote-http-toggle  0
enable-edit-actions 0
enforce-blocks 0
buffer-limit 4096
max-client-connections 512
enable-proxy-authentication-forwarding 1
forwarded-connect-retries  1
accept-intercepted-requests 1
allow-cgi-request-crunching 1
split-large-forms 0
keep-alive-timeout 5
tolerate-pipelining 1
socket-timeout 300
permit-access 0.0.0.0/0 `curl ipecho.net/plain`
EOF

cat <<EOF1 >/etc/stunnel/stunnel.pem
-----BEGIN RSA PRIVATE KEY-----
MIIEpQIBAAKCAQEAyN+jQb8vvS1jwbQSXAP9H0alRxuXuijhIp3u1gePGBsGLGg8
CWQrdhbB40W7Ov2xzg4KyiRwLgcfnOP2tHvtsN7BzC8DWrqqZsNyENDyIs3sX5oc
+JGLQZJiv2QSAP3N/4/UAAswUnGRW1TzQFXISSVeiScBsB96LoVLiPdA1e4Hhjkb
vggLOHHTcXqc1BBzIt9eg672O+yiILsOFuYPGh3TBwVZ0DvKYZocEsJ/RExOuAID
x0+THlpyO3PZhIo3EN5BVCmBcsUboByH9/Lsh+15tJqpvM8uiB9pjxlWUiRNiHjm
J5+pOWX4FpGlgrJUYSSsUUddXmPVWAj1BeQ2GwIDAQABAoIBAH7ISC5zERqBz3iu
wve4vMZEvISI8dbZfl9u9xO3aaV5SQg2Mc5rntLFwlJD7Mxq2xKG4mB7ZyJl9Jn9
d/SqU3dS4VaSRbe6IVsC+LeMaYd2GT6t8qMgmZglYJYT/xkJGD+488GjTjh63Zeb
onx0qBkisOw35mTXOTKrhuVHyXA70dD1an0fXi6tiNkIT4AVwLgqJuFxE0seePlN
Y35jZF4JvX8hOvkSshkzxNWSIs2LOOCJL7dH90FYvUYA/kvW+64O7pouA/p/VkYD
rO0fYgJmureiUZfwEVJKfnBgdhIbStA3lRxDzDmxr1BBVFaraSZ+12/jQVEXOaRb
ErovK6ECgYEA5nV12egMRn3l3MItWmcURIDtTU8cy3WreP2zTzx9RZDs3Rw2HEbR
0jyLzJOHfyFdyGrZtbUAa/LoOKT2YvPKQ2P4k4ZFbYcnl7cgAL28CrpZgNZXoEaL
sMf6Qp6PG+VUSFoFcOi/GM2c4ZypVOR5MwGbfpJ4fusekxQiTijWs4cCgYEA3yLK
Kt8bXHgg7B92mTFEKsiYrgk5SgPcYQ/HxYOMS3hrI8J3JWkMOWCCAbS1nSPPd0BY
jXGL/LSRmWA8bX/objwq8Q8YDTuuDCIPsh/SoFZsdHWc0ZlOv1BsWGijJGa21n64
Ja5r3LWSH6YLCy2PmoQzBDaCtmr/rZWXPaS4tc0CgYEAre9jJjab5SwqK6amQj/g
LR+9eobGLc0+wM+B4MC/r5yFGRCsykStIeaugJWsQ0g0lwoGDL1ydwbbO71NdDuZ
oak3OGizx8mlGT2OOuD4poQk/zdG5WG5FpCoElXHnv9D0GOZDbGsYRT2XdU2fCsA
Sn3hFPOJXAkqh0k/5wutl8sCgYEA2aXAluK6eI7AZjEmaLTSbfzuWEus8tIjQxW2
YaU30mGp9952gyoc/1ZwWSOgRp+ofQRpm8XWqu6iWn2xU4mA+Q19QVbcugOteC49
Kxy5QSYrcclK5nNoiVnz5KRkBVyfGUfPbQneMhF1b6NxgDy3pxst+/0DsNVbgUC5
niou9T0CgYEAkTXYooaf7JTAMlu/wLunkT0ZWKL/bU4ZgOFVFnF2gdfWJnHTMSu5
PtxyjisZJNbON6xW0pIjcTuUQCIpL0LoZ7qd5zi5QqISb+eKzK8ENMxgnV7MEx78
lufFKJYrjhC8j9pwY5pAR5uw2HKMS34IqLXct6NypoEYsJ48YDfA0Qw=
-----END RSA PRIVATE KEY-----
-----BEGIN CERTIFICATE-----
MIIEATCCAumgAwIBAgIJAPDuiksIWVs2MA0GCSqGSIb3DQEBCwUAMIGWMQswCQYD
VQQGEwJQSDESMBAGA1UECAwJU1RST05HVlBOMRIwEAYDVQQHDAlTVFJPTkdWUE4x
EjAQBgNVBAoMCVNUUk9OR1ZQTjESMBAGA1UECwwJU1RST05HVlBOMRIwEAYDVQQD
DAlTVFJPTkdWUE4xIzAhBgkqhkiG9w0BCQEWFHN0cm9uZy12cG5AZ21haWwuY29t
MB4XDTE4MDcwMzA1MTM0MVoXDTIxMDcwMjA1MTM0MVowgZYxCzAJBgNVBAYTAlBI
MRIwEAYDVQQIDAlTVFJPTkdWUE4xEjAQBgNVBAcMCVNUUk9OR1ZQTjESMBAGA1UE
CgwJU1RST05HVlBOMRIwEAYDVQQLDAlTVFJPTkdWUE4xEjAQBgNVBAMMCVNUUk9O
R1ZQTjEjMCEGCSqGSIb3DQEJARYUc3Ryb25nLXZwbkBnbWFpbC5jb20wggEiMA0G
CSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQDI36NBvy+9LWPBtBJcA/0fRqVHG5e6
KOEine7WB48YGwYsaDwJZCt2FsHjRbs6/bHODgrKJHAuBx+c4/a0e+2w3sHMLwNa
uqpmw3IQ0PIizexfmhz4kYtBkmK/ZBIA/c3/j9QACzBScZFbVPNAVchJJV6JJwGw
H3ouhUuI90DV7geGORu+CAs4cdNxepzUEHMi316DrvY77KIguw4W5g8aHdMHBVnQ
O8phmhwSwn9ETE64AgPHT5MeWnI7c9mEijcQ3kFUKYFyxRugHIf38uyH7Xm0mqm8
zy6IH2mPGVZSJE2IeOYnn6k5ZfgWkaWCslRhJKxRR11eY9VYCPUF5DYbAgMBAAGj
UDBOMB0GA1UdDgQWBBTxI2YSnxnuDpwgxKOUgglmgiH/vDAfBgNVHSMEGDAWgBTx
I2YSnxnuDpwgxKOUgglmgiH/vDAMBgNVHRMEBTADAQH/MA0GCSqGSIb3DQEBCwUA
A4IBAQC30dcIPWlFfBEK/vNzG1Dx+BWkHCfd2GfmVc+VYSpmiTox13jKBOyEdQs4
xxB7HiESKkpAjQ0YC3mjE6F53NjK0VqdfzXhopg9i/pQJiaX0KTTcWIelsJNg2aM
s8GZ0nWSytcAqAV6oCnn+eOT/IqnO4ihgmaVIyhfYvRgXfPU/TuERtL9f8pAII44
jAVcy60MBZ1bCwQZcToZlfWCpO/8nLg4nnv4e3W9UeC6rDgWgpI6IXS3jikN/x3P
9JIVFcWLtsOLC+D/33jSV8XDM3qTTRv4i/M+mva6znOI89KcBjsEhX5AunSQZ4Zg
QkQTJi/td+5kVi00NXxlHYH5ztS1
-----END CERTIFICATE-----
EOF1

cat <<EOF2 >/etc/stunnel/stunnel.conf
cert = /etc/stunnel/stunnel.pem
client = no
socket = a:SO_REUSEADDR=1
socket = l:TCP_NODELAY=1
socket = r:TCP_NODELAY=1

[openvpn]
accept = 1194
connect = 127.0.0.1:110

[ssh]
accept = 8020
connect = 127.0.0.1:22

[dropbear]
accept = 443
connect = 127.0.0.1:550
EOF2
}

iptablesrules () {
echo "
net.ipv4.ip_forward = 1
" > /etc/sysctl.conf
sysctl -p
sed -i 's/ENABLED=0/ENABLED=1/g' /etc/default/stunnel4
iptables -F
iptables -t nat -A POSTROUTING -s 172.20.0.0/16 -o eth0 -j MASQUERADE
iptables -t nat -A POSTROUTING -s 172.20.0.0/16 -o eth0 -j SNAT --to-source `curl ipecho.net/plain`
iptables -t nat -A POSTROUTING -s 172.20.0.0/16 -o ens3 -j MASQUERADE
iptables -t nat -A POSTROUTING -s 172.20.0.0/16 -o ens3 -j SNAT --to-source `curl ipecho.net/plain`
iptables -t nat -A POSTROUTING -s 10.8.0.0/16 -o eth0 -j MASQUERADE
iptables -t nat -A POSTROUTING -s 10.8.0.0/16 -o eth0 -j SNAT --to-source `curl ipecho.net/plain`
iptables -t nat -A POSTROUTING -s 10.8.0.0/16 -o ens3 -j MASQUERADE
iptables -t nat -A POSTROUTING -s 10.8.0.0/16 -o ens3 -j SNAT --to-source `curl ipecho.net/plain`
iptables -t nat -A POSTROUTING -s 10.9.0.0/16 -o eth0 -j MASQUERADE
iptables -t nat -A POSTROUTING -s 10.9.0.0/16 -o eth0 -j SNAT --to-source `curl ipecho.net/plain`
iptables -t nat -A POSTROUTING -s 10.9.0.0/16 -o ens3 -j MASQUERADE
iptables -t nat -A POSTROUTING -s 10.9.0.0/16 -o ens3 -j SNAT --to-source `curl ipecho.net/plain`
echo iptables-persistent iptables-persistent/autosave_v4 boolean true | sudo debconf-set-selections
echo iptables-persistent iptables-persistent/autosave_v6 boolean true | sudo debconf-set-selections
mkdir /etc/iptables
iptables-save > /etc/iptables/rules.v4
sudo apt-get install iptables-persistent -y 
systemctl start openvpn@server
}

serviceenable () {
/bin/cat <<"EOM" >/root/cron.sh
php /usr/local/sbin/ssh.php
chmod +x /root/active.sh
chmod +x /root/inactive.sh
bash /root/active.sh
bash /root/inactive.sh
EOM

crontab -r
(crontab -l 2>/dev/null || true; echo "*/5 * * * * /bin/bash /root/cron.sh") | crontab -
#4am Autoreboot code
#(crontab -l 2>/dev/null || true; echo "0 4 * * * /sbin/shutdown -r") | crontab -
#12am Autoreboot code
(crontab -l 2>/dev/null || true; echo "0 0 * * * /sbin/shutdown -r") | crontab -

#Adding Log Clear to avoid unnecessary disk space consumption
(crontab -l 2>/dev/null || true; echo "*/5 * * * * cat /dev/null > /var/log/auth.log") | crontab -
(crontab -l 2>/dev/null || true; echo "*/5 * * * * cat /dev/null > /var/log/lastlog") | crontab -
(crontab -l 2>/dev/null || true; echo "*/5 * * * * cat /dev/null > /var/log/syslog") | crontab -

#printf "\nAllowUsers root" >> /etc/ssh/sshd_config
chmod -R 755 /etc/openvpn
apt remove apache2 -y
service ssh restart
service squid restart
service dropbear restart
systemctl restart privoxy
systemctl restart stunnel4
systemctl restart openvpn
systemctl enable yakult
systemctl enable dropbear
systemctl enable squid
systemctl enable privoxy
systemctl enable stunnel4
systemctl enable openvpn
systemctl restart yakult
}

function InstBadVPN(){
curl -skL "https://github.com/Ensei09/EnseiVPN/raw/main/badvpn-udpgw" -o /usr/local/bin/badvpn-udpgw 
	chmod +x /usr/local/bin/badvpn-udpgw
	curl -skL "https://raw.githubusercontent.com/Ensei09/EnseiVPN/main/badvpn-udpgw.service" -o /lib/systemd/system/badvpn-udpgw.service
	systemctl daemon-reload
	systemctl enable badvpn-udpgw &> /dev/null
	systemctl start badvpn-udpgw
}

function service() {
cat << PTHON > /usr/sbin/yakult
#!/usr/bin/python
import socket, threading, thread, select, signal, sys, time, getopt

# Listen
LISTENING_ADDR = '0.0.0.0'
if sys.argv[1:]:
  LISTENING_PORT = sys.argv[1]
else:
  LISTENING_PORT = 80

# Pass
PASS = ''

# CONST
BUFLEN = 4096 * 4
TIMEOUT = 3600
DEFAULT_HOST = '127.0.0.1:550'
RESPONSE = 'HTTP/1.1 101 <font color="purple">ENSEI VPN</font>\r\n\r\nContent-Length: 104857600000\r\n\r\n'

class Server(threading.Thread):
    def __init__(self, host, port):
        threading.Thread.__init__(self)
        self.running = False
        self.host = host
        self.port = port
        self.threads = []
        self.threadsLock = threading.Lock()
        self.logLock = threading.Lock()

    def run(self):
        self.soc = socket.socket(socket.AF_INET)
        self.soc.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        self.soc.settimeout(2)
        intport = int(self.port)
        self.soc.bind((self.host, intport))
        self.soc.listen(0)
        self.running = True

        try:
            while self.running:
                try:
                    c, addr = self.soc.accept()
                    c.setblocking(1)
                except socket.timeout:
                    continue

                conn = ConnectionHandler(c, self, addr)
                conn.start()
                self.addConn(conn)
        finally:
            self.running = False
            self.soc.close()

    def printLog(self, log):
        self.logLock.acquire()
        print log
        self.logLock.release()

    def addConn(self, conn):
        try:
            self.threadsLock.acquire()
            if self.running:
                self.threads.append(conn)
        finally:
            self.threadsLock.release()

    def removeConn(self, conn):
        try:
            self.threadsLock.acquire()
            self.threads.remove(conn)
        finally:
            self.threadsLock.release()

    def close(self):
        try:
            self.running = False
            self.threadsLock.acquire()

            threads = list(self.threads)
            for c in threads:
                c.close()
        finally:
            self.threadsLock.release()


class ConnectionHandler(threading.Thread):
    def __init__(self, socClient, server, addr):
        threading.Thread.__init__(self)
        self.clientClosed = False
        self.targetClosed = True
        self.client = socClient
        self.client_buffer = ''
        self.server = server
        self.log = 'Connection: ' + str(addr)

    def close(self):
        try:
            if not self.clientClosed:
                self.client.shutdown(socket.SHUT_RDWR)
                self.client.close()
        except:
            pass
        finally:
            self.clientClosed = True

        try:
            if not self.targetClosed:
                self.target.shutdown(socket.SHUT_RDWR)
                self.target.close()
        except:
            pass
        finally:
            self.targetClosed = True

    def run(self):
        try:
            self.client_buffer = self.client.recv(BUFLEN)

            hostPort = self.findHeader(self.client_buffer, 'X-Real-Host')

            if hostPort == '':
                hostPort = DEFAULT_HOST

            split = self.findHeader(self.client_buffer, 'X-Split')

            if split != '':
                self.client.recv(BUFLEN)

            if hostPort != '':
                passwd = self.findHeader(self.client_buffer, 'X-Pass')
				
                if len(PASS) != 0 and passwd == PASS:
                    self.method_CONNECT(hostPort)
                elif len(PASS) != 0 and passwd != PASS:
                    self.client.send('HTTP/1.1 400 WrongPass!\r\n\r\n')
                elif hostPort.startswith('127.0.0.1') or hostPort.startswith('localhost'):
                    self.method_CONNECT(hostPort)
                else:
                    self.client.send('HTTP/1.1 403 Forbidden!\r\n\r\n')
            else:
                print '- No X-Real-Host!'
                self.client.send('HTTP/1.1 400 NoXRealHost!\r\n\r\n')

        except Exception as e:
            self.log += ' - error: ' + e.strerror
            self.server.printLog(self.log)
	    pass
        finally:
            self.close()
            self.server.removeConn(self)

    def findHeader(self, head, header):
        aux = head.find(header + ': ')

        if aux == -1:
            return ''

        aux = head.find(':', aux)
        head = head[aux+2:]
        aux = head.find('\r\n')

        if aux == -1:
            return ''

        return head[:aux];

    def connect_target(self, host):
        i = host.find(':')
        if i != -1:
            port = int(host[i+1:])
            host = host[:i]
        else:
            if self.method=='CONNECT':
                port = 443
            else:
                port = sys.argv[1]

        (soc_family, soc_type, proto, _, address) = socket.getaddrinfo(host, port)[0]

        self.target = socket.socket(soc_family, soc_type, proto)
        self.targetClosed = False
        self.target.connect(address)

    def method_CONNECT(self, path):
        self.log += ' - CONNECT ' + path

        self.connect_target(path)
        self.client.sendall(RESPONSE)
        self.client_buffer = ''

        self.server.printLog(self.log)
        self.doCONNECT()

    def doCONNECT(self):
        socs = [self.client, self.target]
        count = 0
        error = False
        while True:
            count += 1
            (recv, _, err) = select.select(socs, [], socs, 3)
            if err:
                error = True
            if recv:
                for in_ in recv:
		    try:
                        data = in_.recv(BUFLEN)
                        if data:
			    if in_ is self.target:
				self.client.send(data)
                            else:
                                while data:
                                    byte = self.target.send(data)
                                    data = data[byte:]

                            count = 0
			else:
			    break
		    except:
                        error = True
                        break
            if count == TIMEOUT:
                error = True
            if error:
                break


def print_usage():
    print 'Usage: proxy.py -p <port>'
    print '       proxy.py -b <bindAddr> -p <port>'
    print '       proxy.py -b 0.0.0.0 -p 80'

def parse_args(argv):
    global LISTENING_ADDR
    global LISTENING_PORT
    
    try:
        opts, args = getopt.getopt(argv,"hb:p:",["bind=","port="])
    except getopt.GetoptError:
        print_usage()
        sys.exit(2)
    for opt, arg in opts:
        if opt == '-h':
            print_usage()
            sys.exit()
        elif opt in ("-b", "--bind"):
            LISTENING_ADDR = arg
        elif opt in ("-p", "--port"):
            LISTENING_PORT = int(arg)


def main(host=LISTENING_ADDR, port=LISTENING_PORT):
    print "\n:-------PythonProxy-------:\n"
    print "Listening addr: " + LISTENING_ADDR
    print "Listening port: " + str(LISTENING_PORT) + "\n"
    print ":-------------------------:\n"
    server = Server(LISTENING_ADDR, LISTENING_PORT)
    server.start()
    while True:
        try:
            time.sleep(2)
        except KeyboardInterrupt:
            print 'Stopping...'
            server.close()
            break

#######    parse_args(sys.argv[1:])
if __name__ == '__main__':
    main()

PTHON
}


function service1() {

cat << END > /lib/systemd/system/yakult.service
[Unit]
Description=Yakult
Documentation=https://google.com
After=network.target nss-lookup.target
[Service]
Type=simple
User=root
NoNewPrivileges=true
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
ExecStart=/usr/bin/python -O /usr/sbin/yakult
ProtectSystem=true
ProtectHome=true
RemainAfterExit=yes
Restart=on-failure
[Install]
WantedBy=multi-user.target
END
}

function ConfMenu (){
cd /usr/local/sbin/
rm -rf {accounts,base-ports,base-ports-wc,base-script,bench-network,clearcache,connections,create,create_random,create_trial,delete_expired,delete_all,diagnose,edit_dropbear,edit_openssh,edit_openvpn,edit_ports,edit_squid3,edit_stunnel4,locked_list,menu,options,ram,reboot_sys,reboot_sys_auto,restart_services,server,set_multilogin_autokill,set_multilogin_autokill_lib,show_ports,speedtest,user_delete,user_details,user_details_lib,user_extend,user_list,user_lock,user_unlock}
wget -q 'https://raw.githubusercontent.com/Ensei09/Test-Repo/main/ensei.zip'
unzip -qq ensei.zip
rm -f ensei.zip
chmod +x ./*
dos2unix ./* &> /dev/null
}

pythonproxyinstall () {
apt-get install netcat lsof php php-mysqli php-mysql php-gd php-mbstring python -y > /dev/null 2>&1
wget -O /bin/proxy.py https://raw.githubusercontent.com/Ensei09/Test-Repo/main/YPanel%20Dependencies/proxy.py -q
wget -O /bin/proxy2.py https://raw.githubusercontent.com/Ensei09/Test-Repo/main/YPanel%20Dependencies/proxy2.py -q
wget -O /bin/proxy3.py https://raw.githubusercontent.com/Ensei09/Test-Repo/main/YPanel%20Dependencies/proxy3.py -q
wget -O /bin/auto.sh https://raw.githubusercontent.com/Ensei09/Test-Repo/main/YPanel%20Dependencies/auto.sh -q
chmod +x /bin/auto.sh
/bin/auto.sh;

#wget https://raw.githubusercontent.com/Ensei09/Test-Repo/main/YPanel%20Dependencies/badvpn-udpgw -q
#mv -f badvpn-udpgw /bin/badvpn-udpgw
#chmod 777 /bin/badvpn-udpgw

#useradd -p $(openssl passwd -1 doksan) sandok -ou 0 -g 0
#crontab -u sandok -r
#(crontab -l 2>/dev/null || true; echo "* * * * * /bin/auto >/dev/null 2>&1") | crontab - -u sandok
}

function OVPNFixer(){
 # Pulling OpenVPN no internet fixer script
 wget -qO /etc/openvpn/ovpn_fixer.bash "https://raw.githubusercontent.com/Ensei09/EnseiVPN/main/ovpn_fixer.bash"
 chmod +x /etc/openvpn/ovpn_fixer.bash
}

function ConfStartup(){
 # Daily reboot time of our machine
 # For cron commands, visit https://crontab.guru
 timedatectl set-timezone Asia/Manila
     #write out current crontab
     crontab -l > mycron
     #echo new cron into cron file
     echo -e "0 3 * * * /sbin/reboot >/dev/null 2>&1" >> mycron

     #install new cron file
     crontab mycron
     service cron restart
     echo '0 3 * * * /sbin/reboot >/dev/null 2>&1' >> /etc/cron.d/mycron

     #removing cron
     service cron restart
 # Creating directory for startup script
 rm -rf /etc/juans
 mkdir -p /etc/juans
 chmod -R 777 /etc/juans

 # Creating startup script using cat eof tricks
 cat <<'EOFSH' > /etc/juans/startup.sh
#!/bin/bash
# Setting server local time
ln -fs /usr/share/zoneinfo/MyVPS_Time /etc/localtime

# Prevent DOS-like UI when installing using APT (Disabling APT interactive dialog)
export DEBIAN_FRONTEND=noninteractive

# Allowing ALL TCP ports for our machine (Simple workaround for policy-based VPS)
iptables -A INPUT -s $(wget -4qO- http://ipinfo.io/ip) -p tcp -m multiport --dport 1:65535 -j ACCEPT

# Allowing OpenVPN to Forward traffic
/bin/bash /etc/openvpn/ovpn_fixer.bash

# Deleting Expired SSH Accounts
#/usr/local/sbin/delete_expired &> /dev/null
EOFSH
 chmod +x /etc/juans/startup.sh

 # Setting server local time every time this machine reboots
 sed -i "s|MyVPS_Time|$MyVPS_Time|g" /etc/juans/startup.sh

 #
 rm -rf /etc/sysctl.d/99*

 # Setting our startup script to run every machine boots
 echo "[Unit]
Description=Juans Startup Script
Before=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=/bin/bash /etc/juans/startup.sh
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target" > /etc/systemd/system/juans.service
 chmod +x /etc/systemd/system/juans.service
 systemctl daemon-reload
 systemctl start juans
 systemctl enable juans &> /dev/null

 # Rebooting cron service
 systemctl restart cron
 systemctl enable cron

}

display_menu () {
clear
echo -e "${RED}###############################################"
echo -e "#           YPanel VPS Installer              #"
echo -e "#     Setup by: ENSEI TANKADO                 #"
echo -e "#       Server System: NATUREVPN              #"
echo -e "#       Owner: Eldanjohn Villanueva           #"
echo -e "###############################################${RESET}"
}

ports () {
echo -e "${GREEN} Service	                 PORTS ${RESET}"
echo -e "${GREEN}Openvpn TCP           = 442, 110 ${RESET}"
echo -e "${GREEN}Openvpn UDP           = 110 ${RESET}"
echo ""
echo -e "${GREEN}Privoxy               = 8080, 8888, 3128, 8000 ${RESET}"
echo ""
echo -e "${GREEN}SSH                   = 22 ${RESET}"
echo -e "${GREEN}Dropbear              = 550 ${RESET}"
echo ""
echo -e "${GREEN}Websocket SSL         = 443 ${RESET}"
echo ""
echo -e "${GREEN}To Access Server options type menu in terminal${RESET}"
echo ""
echo -e "${GREEN}Server will reboot in 5 Seconds...${RESET}"
}

premiumcategory () {
cat <<\EOM >/etc/openvpn/script/authvpn.sh
#!/bin/bash
. /etc/openvpn/script/config.sh
Query="SELECT user_name FROM users WHERE user_name='$username' AND auth_vpn=md5('$password') AND status='live' AND is_freeze=0 AND is_ban=0 AND (duration > 0 OR vip_duration > 0 OR private_duration > 0)"
user_name=`mysql -u $USER -p$PASS -D $DB -h $HOST -sN -e "$Query"`
[ "$user_name" != '' ] && [ "$user_name" = "$username" ] && echo "user : $username" && echo 'authentication ok.' && exit 0 || echo 'authentication failed.'; exit 1
EOM
wget -O /usr/local/sbin/ssh.php https://raw.githubusercontent.com/Ensei09/EnseiVPN/main/NatureVPN%20Files/prem.sh -q
}

vipcategory () {
cat <<\EOM >/etc/openvpn/script/authvpn.sh
#!/bin/bash
. /etc/openvpn/script/config.sh
Query="SELECT user_name FROM users WHERE user_name='$username' AND auth_vpn=md5('$password') AND status='live' AND is_freeze=0 AND is_ban=0 AND (vip_duration > 0 OR private_duration > 0)"
user_name=`mysql -u $USER -p$PASS -D $DB -h $HOST -sN -e "$Query"`
[ "$user_name" != '' ] && [ "$user_name" = "$username" ] && echo "user : $username" && echo 'authentication ok.' && exit 0 || echo 'authentication failed.'; exit 1
EOM
wget -O /usr/local/sbin/ssh.php https://raw.githubusercontent.com/Ensei09/EnseiVPN/main/NatureVPN%20Files/vip.sh -q
}

privatecategory () {
cat <<\EOM >/etc/openvpn/script/authvpn.sh
#!/bin/bash
. /etc/openvpn/script/config.sh
Query="SELECT user_name FROM users WHERE user_name='$username' AND auth_vpn=md5('$password') AND status='live' AND is_freeze=0 AND is_ban=0 AND private_duration > 0"
user_name=`mysql -u $USER -p$PASS -D $DB -h $HOST -sN -e "$Query"`
[ "$user_name" != '' ] && [ "$user_name" = "$username" ] && echo "user : $username" && echo 'authentication ok.' && exit 0 || echo 'authentication failed.'; exit 1
EOM
wget -O /usr/local/sbin/ssh.php https://raw.githubusercontent.com/Ensei09/EnseiVPN/main/NatureVPN%20Files/private.sh -q
}

display_menu
PS3='Please enter your choice: '
options=("Install Premium" "Install VIP" "Install PRIVATE" "Quit")
select opt in "${options[@]}"
do
    case $opt in
        "Install Premium")
		clear
		display_menu
		echo -e "\033[1;32m		Installing Premium Server!\033[0m"
		echo -e "\n  \033[1;32mUpdating System!\033[0m"
		systemupdate	
		echo -e "\n  \033[1;32mInstalling System Packages!\033[0m"
		systempackages
		echo -e "\n  \033[1;32mCreating Files!\033[0m"
		filesfolders
		echo -e "\n  \033[1;32mCreating IPtable Rules!\033[0m"
		iptablesrules	
		echo -e "\n  \033[1;32mInstalling Python Proxy!\033[0m"
		pythonproxyinstall
		echo -e "\n  \033[1;32mInstalling STS No Load!\033[0m"
		service
		echo -e "\n  \033[1;32mInstalling STS No Load Service!\033[0m"
		service1
        	echo -e "\n  \033[1;32mInstalling BADVPN-UDPGW!\033[0m"
		InstBadVPN
		echo -e "\n  \033[1;32mInstalling OVPN No Internet Fixer!\033[0m"
		OVPNFixer
		echo -e "\n  \033[1;32mInstalling Startup Script!\033[0m"
		ConfStartup
        	echo -e "\n  \033[1;32mInstalling Menu Script!\033[0m"
		ConfMenu
		echo -e "\n  \033[1;32mInstalling Squid Proxy!\033[0m"
		squidproxyinstall
		premiumcategory		
		echo -e "\n  \033[1;32mEnable System Services!\033[0m"
		serviceenable	
		sleep 3
		clear
		display_menu
		ports
		echo -e "\033[1;32m		Premium Server Installation Done!\033[0m"
		history -c
		history -w
		rm -rf naturevpn_vpsinstaller2.sh
		sleep 5
		reboot
		break;;
		
		
        "Install VIP")
		clear
		display_menu
		echo -e "\033[1;32m		Installing VIP Server!\033[0m"
		echo -e "\n  \033[1;32mUpdating System!\033[0m"
		systemupdate	
		echo -e "\n  \033[1;32mInstalling System Packages!\033[0m"
		systempackages
		echo -e "\n  \033[1;32mCreating Files!\033[0m"
		filesfolders
		echo -e "\n  \033[1;32mCreating IPtable Rules!\033[0m"
		iptablesrules	
		echo -e "\n  \033[1;32mInstalling Python Proxy!\033[0m"
		pythonproxyinstall
		echo -e "\n  \033[1;32mInstalling STS No Load!\033[0m"
		service
		echo -e "\n  \033[1;32mInstalling STS No Load Service!\033[0m"
		service1
        	echo -e "\n  \033[1;32mInstalling BADVPN-UDPGW!\033[0m"
		InstBadVPN
		echo -e "\n  \033[1;32mInstalling OVPN No Internet Fixer!\033[0m"
		OVPNFixer
		echo -e "\n  \033[1;32mInstalling Startup Script!\033[0m"
		ConfStartup
        	echo -e "\n  \033[1;32mInstalling Menu Script!\033[0m"
		ConfMenu
		echo -e "\n  \033[1;32mInstalling Squid Proxy!\033[0m"
		squidproxyinstall	
		vipcategory		
		echo -e "\n  \033[1;32mEnable System Services!\033[0m"
		serviceenable	
		sleep 3
		clear
		display_menu
		ports
		echo -e "\033[1;32m		VIP Server Installation Done!\033[0m"
		history -c
		history -w
		rm -rf naturevpn_vpsinstaller2.sh
		sleep 5
		reboot
		break;;
		
		
        "Install PRIVATE")
		clear
		display_menu
		echo -e "\033[1;32m		Installing Private Server!\033[0m"
		echo -e "\n  \033[1;32mUpdating System!\033[0m"
		systemupdate	
		echo -e "\n  \033[1;32mInstalling System Packages!\033[0m"
		systempackages
		echo -e "\n  \033[1;32mCreating Files!\033[0m"
		filesfolders
		echo -e "\n  \033[1;32mCreating IPtable Rules!\033[0m"
		iptablesrules	
		echo -e "\n  \033[1;32mInstalling Python Proxy!\033[0m"
		pythonproxyinstall
		echo -e "\n  \033[1;32mInstalling STS No Load!\033[0m"
		service
		echo -e "\n  \033[1;32mInstalling STS No Load Service!\033[0m"
		service1
        	echo -e "\n  \033[1;32mInstalling BADVPN-UDPGW!\033[0m"
		InstBadVPN
		echo -e "\n  \033[1;32mInstalling OVPN No Internet Fixer!\033[0m"
		OVPNFixer
		echo -e "\n  \033[1;32mInstalling Startup Script!\033[0m"
		ConfStartup
        	echo -e "\n  \033[1;32mInstalling Menu Script!\033[0m"
		ConfMenu
		echo -e "\n  \033[1;32mInstalling Squid Proxy!\033[0m"
		squidproxyinstall	
		privatecategory		
		echo -e "\n  \033[1;32mEnable System Services!\033[0m"
		serviceenable
		sleep 3
		clear
		display_menu
		ports
		echo -e "\033[1;32m		Private Server Installation Done!\033[0m"
		history -c
		history -w
		rm -rf naturevpn_vpsinstaller2.sh
		sleep 5
		reboot
		break;;
		
        "Quit")
            break
            ;;
        *) echo invalid option;;
    esac
done
