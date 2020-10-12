
#!/bin/bash
#
# FLits Masternode Setup Script V1.0 for Ubuntu 16/18 LTS
#by mrx0rhk
# Script will attempt to autodetect primary public IP address
# and generate masternode private key unless specified in command line
#
# Usage:
# bash fls-mn-install.sh
#


declare -r COIN_NAME='flits'
declare -r COIN_DAEMON="${COIN_NAME}d"
declare -r COIN_CLI="${COIN_NAME}-cli"
declare -r COIN_PATH='/usr/local/bin'
#declare -r BOOTSTRAP_LINK='###'
declare -r COIN_ARH='https://github.com/flitsnode/flits-core/releases/download/2.0.0/fls-2.0.0-x86_64-linux-gnu.tar.gz'
declare -r COIN_TGZ=$(echo ${COIN_ARH} | awk -F'/' '{print $NF}')
declare -r CONFIG_FILE="fls.conf"
declare -r CONFIG_FOLDER="${HOME}/.fls"

#Color codes
RED='\033[0;91m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

#TCP port
PORT=12270
RPC=12271

#Clear keyboard input buffer
function clear_stdin { while read -r -t 0; do read -r; done; }

#Delay script execution for N seconds
function delay { echo -e "${GREEN}Sleep for $1 seconds...${NC}"; sleep "$1"; }

#Stop daemon if it's already running
function stop_daemon {
    if pgrep -x 'flitsd' > /dev/null; then
        echo -e "${YELLOW}Attempting to stop flitsd${NC}"
        flits-cli stop
        sleep 30
        if pgrep -x 'flitsd' > /dev/null; then
            echo -e "${RED}flitsd daemon is still running!${NC} \a"
            echo -e "${RED}Attempting to kill...${NC}"
            sudo pkill -9 flitsd
            sleep 30
            if pgrep -x 'flitsd' > /dev/null; then
                echo -e "${RED}Can't stop flitsd! Reboot and try again...${NC} \a"
                exit 2
            fi
        fi
    fi
}

#Process command line parameters
genkey=$1
clear

echo -e "${GREEN}
  ---------- FLITS MASTERNODE INSTALLER -----------
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

clear

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
echo -e "${GREEN}Downloading and installing Flits deamon...${NC}"
cd ~
rm -rf /usr/local/bin/flits*
wget ${COIN_ARH}
tar xvzf "${COIN_TGZ}"
cd /root/fls-2.0.0/bin/  2>/dev/null  >/dev/null
sudo chmod -R 755 flits-cli  2>/dev/null  >/dev/null
sudo chmod -R 755 slitsd  2>/dev/null  >/dev/null
cp -p -r flitsd /usr/local/bin  2>/dev/null  >/dev/null
cp -p -r flits-cli /usr/local/bin  2>/dev/null  >/dev/null
flits-cli stop  2>/dev/null  >/dev/null
cd ~/
rm *gnu.tar.gz*  2>/dev/null  >/dev/null
 
sleep 5
 #Create datadir
 if [ ! -f ~/.fls/fls.conf ]; then 
 	sudo mkdir ~/.fls
 fi

cd ~
clear
echo -e "${YELLOW}Creating fls.conf...${NC}"

# If genkey was not supplied in command line, we will generate private key on the fly
if [ -z $genkey ]; then
    cat <<EOF > ~/.fls/fls.conf
rpcuser=$rpcuser
rpcpassword=$rpcpassword
EOF

    sudo chmod 755 -R ~/.fls/fls.conf

    #Starting daemon first time just to generate a Flits masternode private key
    flitsd -daemon > /dev/null
sleep 7
while true;do
    echo -e "${YELLOW}Generating masternode private key...${NC}"
    genkey=$(flits-cli createmasternodekey)
    if [ "$genkey" ]; then
        break
    fi
sleep 7
done
    fi
    
    #Stopping daemon to create fls.conf
    flits-cli stop
    sleep 5
    


# Create fls.conf
cat <<EOF > ~/.fls/fls.conf
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


addnode=[2001:41d0:303:3ea7::]:12270
addnode=[2a02:c205:2025:6626:db66::6]:12270
addnode=[2a02:c207:2033:7877::23]:12270
addnode=116.202.47.198:38208
addnode=144.91.106.92:47036
addnode=144.91.122.178:34270
addnode=149.56.30.241:35166
addnode=149.56.30.241:39586
addnode=149.56.30.241:43988
addnode=149.56.30.241:44956
addnode=149.56.30.241:51852
addnode=155.138.162.108:43240
addnode=161.97.129.125:12270
addnode=161.97.78.108:40150
addnode=161.97.78.108:53146
addnode=161.97.79.65:49592
addnode=161.97.85.149:32946
addnode=161.97.97.26:36958
addnode=161.97.97.27:37690
addnode=161.97.97.27:37716
addnode=161.97.97.40:55202
addnode=161.97.97.42:60156
addnode=164.68.127.109:12270
addnode=167.86.110.168:12270
addnode=167.86.126.67:57786
addnode=173.212.204.94:53620
addnode=173.249.21.162:51342
addnode=173.249.3.133:43146
addnode=173.249.4.190:12270
addnode=173.249.5.209:40154
addnode=173.249.5.209:52750
addnode=173.249.8.117:33960
addnode=173.249.8.117:40442
addnode=173.249.8.117:43232
addnode=173.249.8.117:47446
addnode=178.238.235.223:43496
addnode=207.180.193.2:33386
addnode=207.180.206.2:33210
addnode=207.180.206.2:51344
addnode=207.180.206.2:51584
addnode=207.180.252.140:52090
addnode=209.250.245.248:42022
addnode=213.136.71.178:12270
addnode=217.182.193.175:59756
addnode=37.187.146.100:53356
addnode=45.32.235.62:58576
addnode=45.63.70.158:59818
addnode=5.135.136.102:34594
addnode=5.135.136.102:42588
addnode=5.135.136.102:46298
addnode=5.189.180.171:12270
addnode=5.189.185.66:52346
addnode=5.189.185.66:56166
addnode=5.189.186.103:39610
addnode=5.189.186.103:42166
addnode=5.189.186.103:44800
addnode=5.189.186.103:47514
addnode=5.189.186.103:48006
addnode=5.189.186.103:50192
addnode=5.189.186.103:53420
addnode=5.189.186.103:53468
addnode=5.189.186.103:53494
addnode=5.189.186.103:56610
addnode=5.189.186.103:57332
addnode=51.178.241.90:12270
addnode=51.210.140.64:12270
addnode=51.254.198.64:37162
addnode=51.254.198.64:37280
addnode=51.254.198.64:38282
addnode=51.254.198.64:47314
addnode=51.254.198.64:48284
addnode=51.254.198.64:49428
addnode=51.254.198.64:52220
addnode=51.254.198.64:52824
addnode=51.254.198.64:56576
addnode=51.38.75.130:12270
addnode=51.38.90.6:12270
addnode=51.75.52.222:35450
addnode=51.83.191.129:12270
addnode=51.89.152.35:35364
addnode=51.89.152.35:38234
addnode=51.89.152.35:38252
addnode=51.89.152.35:40476
addnode=51.89.152.35:44506
addnode=51.89.152.35:44556
addnode=51.89.152.35:44930
addnode=51.89.152.35:51686
addnode=51.89.152.35:52208
addnode=51.89.152.35:54216
addnode=51.89.152.35:58500
addnode=51.89.152.35:58664
addnode=51.89.152.35:60980
addnode=51.89.251.96:12270
addnode=54.36.61.234:36524
addnode=54.36.61.234:53082
addnode=54.36.61.234:60590
addnode=54.36.62.167:12270
addnode=54.38.80.221:43546
addnode=54.38.80.221:48048
addnode=54.38.80.221:55334
addnode=54.38.94.142:34562
addnode=54.38.94.142:34624
addnode=54.38.94.142:54990
addnode=54.38.94.142:55788
addnode=54.38.94.142:56124
addnode=54.38.94.142:56768
addnode=54.38.94.142:57398
addnode=54.38.94.142:57828
addnode=54.38.94.142:58082
addnode=54.38.94.142:58172
addnode=62.171.144.144:42258
addnode=62.171.158.197:42788
addnode=62.171.162.106:39264
addnode=62.171.163.154:40624
addnode=62.171.163.154:51696
addnode=62.171.163.26:40524
addnode=62.171.190.142:12270
addnode=91.134.171.224:12270
addnode=95.111.229.120:52218
 
EOF

flitsd -daemon 2>/dev/null  >/dev/null
	
#Finally, starting daemon with new fls.conf

printf '#!/bin/bash\nif [ ! -f "~/.fls/flits.pid" ]; then /usr/local/bin/flitsd -daemon ; fi' > /root/flitsautostart.sh

cd /root

sudo chmod 755 flitsautostart.sh

#Setting auto start cron job for flits
if ! crontab -l | grep "flitsautostart.sh"; then
    (crontab -l ; echo "*/5 * * * * /root/flitsautostart.sh")| crontab -
fi


echo -e "========================================================================
${GREEN}Flits Masternode setup is complete!${NC}
========================================================================
Masternode was installed with VPS IP Address: ${GREEN}$publicip${NC}
Masternode Private Key: ${GREEN}$genkey${NC}
Now you can add the following string to the masternode.conf file 
======================================================================== \a"
echo -e "${GREEN}flits_mn1 $publicip:$PORT $genkey TxId TxIdx${NC}"
echo -e "========================================================================
Use your mouse to copy the whole string above into the clipboard by
tripple-click + single-click (Dont use Ctrl-C) and then paste it 
into your ${GREEN}masternode.conf${NC} file and replace:
    ${GREEN}flits_mn1${NC} - with your desired masternode name (alias)
    ${GREEN}TxId${NC} - with Transaction Id from masternode outputs
    ${GREEN}TxIdx${NC} - with Transaction Index (0 or 1)
     Remember to save the masternode.conf and restart the wallet!
To introduce your new masternode to the Flits network, you need to
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
To view masternode configuration produced by this script in fls.conf:
${GREEN}cat ~/.fls/fls.conf${NC}
Here is your fls.conf generated by this script:
-------------------------------------------------${GREEN}"
echo -e "${GREEN}flits_mn1 $publicip:$PORT $genkey TxId TxIdx${NC}"
cat ~/.fls/fls.conf
echo -e "${NC}-------------------------------------------------
NOTE: To edit fls.conf, first stop the flitsd daemon,
then edit the fls.conf file and save it in nano: (Ctrl-X + Y + Enter),
then start the flitsd daemon back up:
to stop:                   ${GREEN}flits-cli stop${NC}
to start:                  ${GREEN}flitsd${NC}
to edit:                   ${GREEN}nano ~/.fls/fls.conf ${NC}
to check mn status:        ${GREEN}flits-cli getmasternodestatus${NC}
ti check wallet status:    ${GREEN}flits-cli getinfo${NC}
========================================================================
To monitor system resource utilization and running processes:
                   ${GREEN}htop${NC}
========================================================================

${GREEN}Have fun with your Flits Masternode!${NC}


"
rm ~/fls-mn-install.sh
