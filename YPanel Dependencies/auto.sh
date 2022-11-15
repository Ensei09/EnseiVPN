#!/bin/bash
nc -zv 127.0.0.1 8060 && sudo kill $( sudo lsof -i:8060 -t )
if nc -z localhost 8060; then
    echo "stunnel running"
else
    echo "Starting Port 8060"
    screen -dmS proxy2 python /bin/proxy2.py 8060
fi
if nc -z localhost 8010; then
    echo "stunnel running"
else
    echo "Starting Port 8010"
    screen -dmS proxy python /bin/proxy.py 8010
fi

if nc -z localhost 8070; then
    echo "Port 8070 running"
else
    echo "Starting Port 8070"
    screen -dmS proxy3 python /bin/proxy3.py 8070
fi


if nc -z localhost 443; then
    echo "stunnel running"
else
    echo "stunnel not running"
    service stunnel4 restart
fi
if nc -z localhost 7300; then
    echo "badvpn running"
else
    echo "Starting Badvpn"
    screen -dmS udpvpn /bin/badvpn-udpgw --listen-addr 127.0.0.1:7300 --max-clients 1000 --max-connections-for-client 3
fi
if nc -z localhost 80; then
    echo "Apache is running"
else
    echo "Starting Apache"
    service apache2 restart
fi

sudo sync; echo 3 > /proc/sys/vm/drop_caches
swapoff -a && swapon -a
echo "Ram Cleaned!"
