
#!/bin/bash
#
# Vitae Masternode Setup Script V1.0 for Ubuntu 16/18 LTS
#by mrx0rhk
# Script will attempt to autodetect primary public IP address
# and generate masternode private key unless specified in command line
#
# Usage:
# bash vitae-mn-install.sh
#


declare -r COIN_NAME='vitae'
declare -r COIN_DAEMON="${COIN_NAME}d"
declare -r COIN_CLI="${COIN_NAME}-cli"
declare -r COIN_PATH='/usr/local/bin/'
declare -r BOOTSTRAP_LINK='https://gir.sqdmc.net/dev/vitae/snapshot.zip'
declare -r COIN_ARH='https://github.com/VitaeTeam/Vitae/releases/download/v4.6.3/vitae-4.6.3-x86_64-linux-gnu.tar.gz'
declare -r COIN_TGZ=$(echo ${COIN_ARH} | awk -F'/' '{print $NF}')
declare -r CONFIG_FILE="${COIN_NAME}.conf"
declare -r CONFIG_FOLDER="${HOME}/.${COIN_NAME}"

#Color codes
RED='\033[0;91m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

#TCP port
PORT=8765
RPC=8766

#Clear keyboard input buffer
function clear_stdin { while read -r -t 0; do read -r; done; }

#Delay script execution for N seconds
function delay { echo -e "${GREEN}Sleep for $1 seconds...${NC}"; sleep "$1"; }

#Stop daemon if it's already running
function stop_daemon {
    if pgrep -x 'vitaed' > /dev/null; then
        echo -e "${YELLOW}Attempting to stop vitaed${NC}"
        vitae-cli stop
        sleep 30
        if pgrep -x 'vitaed' > /dev/null; then
            echo -e "${RED}vitaed daemon is still running!${NC} \a"
            echo -e "${RED}Attempting to kill...${NC}"
            sudo pkill -9 vitaed
            sleep 30
            if pgrep -x 'vitaed' > /dev/null; then
                echo -e "${RED}Can't stop vitaed! Reboot and try again...${NC} \a"
                exit 2
            fi
        fi
    fi
}

#Process command line parameters
genkey=$1
clear

echo -e "${GREEN}
  ---------- VITAE MASTERNODE INSTALLER -----------
 |                                                  |
 |                                                  |
 |       The installation will install and run      |
 |        the masternode under the user root.       |
 |                                                  |
 |        This version of installer will setup      |
 |           fail2ban and ufw for your safety.      |
 |                                                  |
 +--------------------------------------------------+
   ::::::::::::::::::::::::::::::::::::::::::::::::${NC}"
echo "Do you want me to generate a masternode private key for you? [y/n]"
read DOSETUP

if [[ $DOSETUP =~ "n" ]] ; then
          read -e -p "Enter your private key:" genkey;
              read -e -p "Confirm your private key: " genkey2;
    fi

#Confirming match
  if [ $genkey = $genkey2 ]; then
     echo -e "${GREEN}MATCH! ${NC} \a" 
else 
     echo -e "${RED} Error: Private keys do not match. Try again or let me generate one for you...${NC} \a";exit 1
fi
sleep .5
clear

# Determine primary public IP address
dpkg -s dnsutils 2>/dev/null >/dev/null || sudo apt-get -y install dnsutils
publicip=$(dig +short myip.opendns.com @resolver1.opendns.com)

if [ -n "$publicip" ]; then
    echo -e "${YELLOW}IP Address detected:" $publicip ${NC}
else
    echo -e "${RED}ERROR: Public IP Address was not detected!${NC} \a"
    clear_stdin
    read -e -p "Enter VPS Public IP Address: " publicip
    if [ -z "$publicip" ]; then
        echo -e "${RED}ERROR: Public IP Address must be provided. Try again...${NC} \a"
        exit 1
    fi
fi
if [ -d "/var/lib/fail2ban/" ]; 
then
    echo -e "${GREEN}Packages already installed...${NC}"
else
   echo -e "${GREEN}Updating system and installing required packages. This can take a few minutes...${NC}"

sudo DEBIAN_FRONTEND=noninteractive apt-get update -y #2>/dev/null  >/dev/null 
sudo apt-get -y upgrade #2>/dev/null  >/dev/null 
sudo apt-get -y dist-upgrade #2>/dev/null  >/dev/null
sudo apt-get -y autoremove #2>/dev/null  >/dev/null
sudo apt-get -y install wget nano htop jq #2>/dev/null  >/dev/null
sudo apt-get -y install libzmq3-dev #2>/dev/null  >/dev/null
sudo apt-get -y install libevent-dev -y #2>/dev/null  >/dev/null
sudo apt-get install unzip #2>/dev/null  >/dev/null
sudo apt install unzip #2>/dev/null  >/dev/null
sudo apt -y install software-properties-common #2>/dev/null  >/dev/null
sudo add-apt-repository ppa:bitcoin/bitcoin -y #2>/dev/null  >/dev/null
sudo apt-get -y update #2>/dev/null  >/dev/null
sudo apt-get -y install libdb4.8-dev libdb4.8++-dev -y #2>/dev/null  >/dev/null
sudo apt-get -y install libminiupnpc-dev #2>/dev/null  >/dev/null
sudo apt-get install -y unzip libzmq3-dev build-essential libssl-dev libboost-all-dev libqrencode-dev libminiupnpc-dev libboost-system1.58.0 libboost1.58-all-dev libdb4.8++ libdb4.8 libdb4.8-dev libdb4.8++-dev libevent-pthreads-2.0-5 -y #2>/dev/null  >/dev/null 
   fi
   
    # only for 18.04 // openssl
if [[ "${VERSION_ID}" == "18.04" ]] ; then
       apt-get -qqy -o=Dpkg::Use-Pty=0 -o=Acquire::ForceIPv4=true install libssl1.0-dev 
fi

#Network Settings
echo -e "${GREEN}Installing Network Settings...${NC}"
{
sudo apt-get install ufw -y
} &> /dev/null
echo -ne '[##                 ]  (10%)\r'
{
sudo apt-get update -y
} &> /dev/null
echo -ne '[######             ] (30%)\r'
{
sudo ufw default deny incoming
} &> /dev/null
echo -ne '[#########          ] (50%)\r'
{
sudo ufw default allow outgoing
sudo ufw allow ssh
} &> /dev/null
echo -ne '[###########        ] (60%)\r'
{
sudo ufw allow $PORT/tcp
} &> /dev/null
echo -ne '[###############    ] (80%)\r'
{
sudo ufw allow 22/tcp
sudo ufw limit 22/tcp
} &> /dev/null
echo -ne '[#################  ] (90%)\r'
{
echo -e "${YELLOW}"
sudo ufw --force enable
echo -e "${NC}"
} &> /dev/null
echo -ne '[###################] (100%)\n'

#Generating Random Password for  JSON RPC
rpcuser=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
rpcpassword=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)

#Create 4GB swap file

    echo -e "* Check if swap is available"
if [[  $(( $(wc -l < /proc/swaps) - 1 )) > 0 ]] ; then
    echo -e "All good, you have a swap"
else
    echo -e "No proper swap, creating it"
    rm -f /var/swapfile.img
    dd if=/dev/zero of=/var/swapfile.img bs=1024k count=4000 
    chmod 0600 /var/swapfile.img
    mkswap /var/swapfile.img 
    swapon /var/swapfile.img 
    echo '/var/swapfile.img none swap sw 0 0' | tee -a /etc/fstab   
    echo 'vm.swappiness=20' | tee -a /etc/sysctl.conf               
    echo 'vm.vfs_cache_pressure=50' | tee -a /etc/sysctl.conf		
fi
 
#Installing Daemon
echo -e "${GREEN}Downloading and installing Vitae deamon...${NC}"
cd ~
rm -rf /usr/local/bin/vitae*
wget ${COIN_ARH}
tar xvzf "${COIN_TGZ}"
cd /root/vitae-4.6.3/bin/  2>/dev/null  >/dev/null
sudo chmod -R 755 vitae-cli  2>/dev/null  >/dev/null
sudo chmod -R 755 vitaed  2>/dev/null  >/dev/null
cp -p -r vitaed /usr/local/bin  2>/dev/null  >/dev/null
cp -p -r vitae-cli /usr/local/bin  2>/dev/null  >/dev/null
vitae-cli stop  2>/dev/null  >/dev/null
cd ~/
rm *gnu.tar.gz*  2>/dev/null  >/dev/null
 
sleep 5
 #Create datadir
 if [ ! -f ~/.vitae/vitae.conf ]; then 
 	sudo mkdir ~/.vitae
 fi

cd ~
clear
echo -e "${YELLOW}Creating vitae.conf...${NC}"

# If genkey was not supplied in command line, we will generate private key on the fly
if [ -z $genkey ]; then
    cat <<EOF > ~/.vitae/vitae.conf
rpcuser=$rpcuser
rpcpassword=$rpcpassword
EOF

    sudo chmod 755 -R ~/.vitae/vitae.conf

    #Starting daemon first time just to generate a Vitae masternode private key
    vitaed -daemon > /dev/null
sleep 7
while true;do
    echo -e "${YELLOW}Generating masternode private key...${NC}"
    genkey=$(vitae-cli masternode genkey)
    if [ "$genkey" ]; then
        break
    fi
sleep 7
done
    fi
    
    #Stopping daemon to create vitae.conf
    vitae-cli stop
    sleep 5
    
#Adding bootstrap files 

cd ~/.vitae/ && rm -rf banlist.dat  blocks  chainstate  database  db.log  debug.log  fundamentalnode.conf  .lock   mncache.dat  peers.dat  sporks vitaed.pid  VitaeSnapshot-latest.zip snapshot.zip
cd ~/.vitae/ && wget ${BOOTSTRAP_LINK}
cd ~/.vitae/ && unzip snapshot.zip

#sleep 5 

#cd ~/.vitae/ && rm -rf VitaeSnapshot-latest.zip*


# Create vitae.conf
cat <<EOF > ~/.vitae/vitae.conf
rpcuser=$rpcuser
rpcpassword=$rpcpassword
rpcallowip=127.0.0.1
rpcport=$RPC
port=$PORT
listen=1
server=1
daemon=1
logtimestamps=1
maxconnections=256
masternode=1
externalip=$publicip
bind=$publicip
masternodeaddr=$publicip
masternodeprivkey=$genkey


addnode=109.86.81.235:8765
addnode=116.202.28.235:8765
addnode=116.203.203.246:8765
addnode=116.203.76.96:55352
addnode=135.181.47.128:8765
addnode=148.71.213.240:3123
addnode=148.71.213.240:63330
addnode=148.71.213.240:8584
addnode=168.119.6.101:8765
addnode=185.117.74.45:8765
addnode=195.201.100.107:8765
addnode=195.26.2.113:59977
addnode=199.247.22.228:8765
addnode=207.148.73.40:8765
addnode=45.63.41.113:8765
addnode=49.12.15.168:8765
addnode=78.47.225.228:8765
addnode=82.161.212.157:53333
addnode=94.130.179.131:8765
addnode=94.177.254.33:8765
addnode=95.216.154.57:8765
addnode=95.216.200.97:37598
addnode=95.217.212.54:8765
 
EOF

sleep 3
 
#config systemd & service

 cat << EOF > /etc/systemd/system/$COIN_NAME.service
[Unit]
Description=$COIN_NAME service
After=network.target
[Service]
User=root
Group=root
Type=forking
#PIDFile=$CONFIG_FOLDER/$COIN_NAME.pid
ExecStart=$COIN_PATH$COIN_DAEMON -daemon -conf=$CONFIG_FOLDER/$CONFIG_FILE -datadir=$CONFIG_FOLDER
ExecStop=-$COIN_PATH$COIN_CLI -conf=$CONFIG_FOLDER/$CONFIG_FILE -datadir=$CONFIG_FOLDER stop
Restart=always
PrivateTmp=true
TimeoutStopSec=60s
TimeoutStartSec=10s
StartLimitInterval=120s
StartLimitBurst=5

[Install]
WantedBy=multi-user.target
EOF

  systemctl daemon-reload
  sleep 3
  systemctl enable $COIN_NAME.service
  systemctl start $COIN_NAME.service >/dev/null 2>&1

  if [[ -z "$(ps axo cmd:100 | egrep $COIN_DAEMON)" ]]; then
    echo -e "${RED}$COIN_NAME is not running${NC}, please investigate. You should start by running the following commands as root:"
    echo -e "${GREEN}systemctl start $COIN_NAME.service"
    echo -e "systemctl status $COIN_NAME.service"
    echo -e "less /var/log/syslog${NC}"
    exit 1
  fi

  
sleep 5

systemctl start $vitae.service

echo -e "========================================================================
${GREEN}Vitae Masternode setup is complete!${NC}
========================================================================
Masternode was installed with VPS IP Address: ${GREEN}$publicip${NC}
Masternode Private Key: ${GREEN}$genkey${NC}
Now you can add the following string to the masternode.conf file 
======================================================================== \a"
echo -e "${GREEN}vitae_mn1 $publicip:$PORT $genkey TxId TxIdx${NC}"
echo -e "========================================================================
Use your mouse to copy the whole string above into the clipboard by
tripple-click + single-click (Dont use Ctrl-C) and then paste it 
into your ${GREEN}masternode.conf${NC} file and replace:
    ${GREEN}vitae_mn1${NC} - with your desired masternode name (alias)
    ${GREEN}TxId${NC} - with Transaction Id from masternode outputs
    ${GREEN}TxIdx${NC} - with Transaction Index (0 or 1)
     Remember to save the masternode.conf and restart the wallet!
To introduce your new masternode to the Vitae network, you need to
issue a masternode start command from your wallet, which proves that
the collateral for this node is secured."

clear_stdin
read -p "*** Press any key to continue ***" -n1 -s

echo -e "Wait for the node wallet on this VPS to sync with the other nodes
on the network. Eventually the 'Is Synced' status will change
to 'true', which will indicate a complete sync, although it may take
from several minutes to several hours depending on the network state.
Your initial Masternode Status may read:
    ${GREEN}Node just started, not yet activated${NC} or
    ${GREEN}Node  is not in masternode list${NC}, which is normal and expected.
"
clear_stdin
read -p "*** Press any key to continue ***" -n1 -s

echo -e "
${GREEN}...scroll up to see previous screens...${NC}
Here are some useful commands and tools for masternode troubleshooting:
========================================================================
To view masternode configuration produced by this script in vitae.conf:
${GREEN}cat ~/.vitae/vitae.conf${NC}
Here is your vitae.conf generated by this script:
-------------------------------------------------${GREEN}"
echo -e "${GREEN}vitae_mn1 $publicip:$PORT $genkey TxId TxIdx${NC}"
cat ~/.vitae/vitae.conf
echo -e "${NC}-------------------------------------------------
NOTE: To edit vitae.conf, first stop the vitaed daemon,
then edit the vitae.conf file and save it in nano: (Ctrl-X + Y + Enter),
then start the vitaed daemon back up:
to stop:                   ${GREEN}vitae-cli stop${NC}
to start:                  ${GREEN}vitaed${NC}
to edit:                   ${GREEN}nano ~/.vitae/vitae.conf ${NC}
to check mn status:        ${GREEN}vitae-cli getmasternodestatus${NC}
ti check wallet status:    ${GREEN}vitae-cli getinfo${NC}
========================================================================
To monitor system resource utilization and running processes:
                   ${GREEN}htop${NC}
========================================================================

${GREEN}Have fun with your Vitae Masternode!${NC}


"
rm ~/vitae-mn-install.sh
