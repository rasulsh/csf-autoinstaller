#!/bin/bash
rpm -qa | grep dialog;
if [ $? -ne 0 ]; then
	yum install dialog -y ;
fi
##Global varibales
CSF="/usr/sbin/csf";
CDF="/etc/csf/csf.deny";
CONFIG="/etc/csf/csf.conf";
IGNORE="/etc/csf/csf.pignore";
TO="yourmail\@domain.com";
FROM="hostname\@domain.com";
MYSSH="";
RESET='\033[0m'
GREEN='\033[01;32m'
INPUT=/tmp/menu.sh.$$
OUTPUT=/tmp/output.sh.$$


if [ -d "/usr/local/cpanel" ]; then
	NPO_IN='TCP_IN = \"20,21,22,25,53,80,110,143,443,465,587,993,995,2789,27635,1443,9085,9086,2077,2078,2082,2083,2095,2096,2086,2087,7080,11211,${MYSSH}\"';
	NPO_OUT='TCP_OUT = \"20,21,22,25,53,80,110,113,443,465,587,993,995,2789,27635,1443,9085,9086,2077,2078,2082,2083,2095,2096,2086,2087,7080,11211,${MYSSH}\"'
elif [ -d "/usr/local/directadmin" ]; then
	NPO_IN='TCP_IN = \"20,21,22,25,53,80,110,143,443,465,587,993,995,2222,2789,27635,1443,9085,9086,7080,11211,${MYSSH}\"';
	NPO_OUT='TCP_OUT = \"20,21,22,25,53,80,110,113,443,465,587,993,995,2222,2789,27635,1443,9085,9086,7080,11211,${MYSSH}\"'
elif [ -d "/usr/local/cwp" ]; then
	NPO_IN='TCP_IN = \"20,21,22,25,53,80,110,143,443,465,587,993,995,2789,27635,1443,9085,9086,7080,11211,2030,2031,${MYSSH}\"';
	NPO_OUT='TCP_OUT = \"20,21,22,25,53,80,110,113,443,465,587,993,995,2789,27635,1443,9085,9086,7080,11211,2030,2031,${MYSSH}\"'
fi

function  do_config()
{
	clear;
	echo -e "$GREEN [NOTICE] CSF configuraing... $RESET";
	
	rpm -qa | grep ipset;
	if [ $? -ne 0 ]; then
		yum install ipset -y >/dev/null 2>&1;
	fi
	csf -x >/dev/null 2>&1 ;
	echo "$GREEN[NOTICE] Configure Process is runnig...$RESET";
	perl -pi -e 's/TESTING = "1"/TESTING = "0"/g' "${CONFIG}"
	perl -pi -e 's/RESTRICT_SYSLOG = "0"/RESTRICT_SYSLOG = "3"/g' "${CONFIG}"
	perl -pi -e 's/SYSLOG_CHECK = "0"/SYSLOG_CHECK = "300"/g' "${CONFIG}"
	perl -pi -e 's/DENY_TEMP_IP_LIMIT = "100"/DENY_TEMP_IP_LIMIT = "200"/g' "${CONFIG}"
	perl -pi -e 's/LF_IPSET = "0"/LF_IPSET = "1"/g' "${CONFIG}"
	perl -pi -e 's/LF_SELECT = "0"/LF_SELECT = "1"/g' "${CONFIG}"
	perl -pi -e 's/CT_LIMIT = "0"/CT_LIMIT = "200"/g' "${CONFIG}"
	
	OE=$(cat "${CONFIG}" | grep "LF_ALERT_TO = " )
	NE="LF_ALERT_TO = \"${TO}\""
	perl -pi  -e "s/${OE}/${NE}/g"  "${CONFIG}"
	
	OF=$(cat "${CONFIG}" | grep "LF_ALERT_FROM = " )
	NF="LF_ALERT_FROM = \"${FROM}\""
	perl -pi  -e "s/${OF}/${NF}/g"  "${CONFIG}"
	
	PO_IN=$(cat "${CONFIG}" | grep "TCP_IN = " )
	
	perl -pi  -e "s/${PO_IN}/${NPO_IN}/g"  "${CONFIG}"

	PO_OUT=$(cat "${CONFIG}" | grep "TCP_OUT =" )
	perl -pi  -e "s/${PO_OUT}/${NPO_OUT}/g"  "${CONFIG}"
	
	USERMEM=$(cat "${CONFIG}" | grep "PT_USERMEM = ")
	perl -pi  -e "s/${USERMEM}/PT_USERMEM = \"0\"/g"  "${CONFIG}"
	
	perl -pi -e 's/PT_LIMIT = "60"/PT_LIMIT = "0"/g' "${CONFIG}"
	perl -pi -e 's/PT_SKIP_HTTP = "0"/PT_SKIP_HTTP = "1"/g' "${CONFIG}"
	perl -pi -e 's/LF_EMAIL_ALERT = "1"/LF_EMAIL_ALERT = "0"/g' "${CONFIG}"
	perl -pi -e 's/LF_PERMBLOCK_ALERT = "1"/LF_PERMBLOCK_ALERT = "0"/g' "${CONFIG}"
	
	echo "exe:/usr/bin/memcached" >> "${IGNORE}"
	echo "exe:/sbin/rpcbind" >> "${IGNORE}"
	
	service rpc stop  >/dev/null 2>&1 ;
	service xfs stop  >/dev/null 2>&1 ;
	service portmap stop  >/dev/null 2>&1;
	chkconfig cfx off  >/dev/null 2>&1 ;
	service portreserve stop >/dev/null 2>&1 ;
	chkconfig portreserve off >/dev/null 2>&1 ;

	csf -e >/dev/null 2>&1 ;
	csf -r >/dev/null 2>&1 ; 
	echo -e "$GREEN [OK] finish configure $RESET";
	echo -e "$GREEN";
	read -p "Press any key to continue..." -n1 -s ;
	echo -e "$RESET";
}
function do_install()
{
	clear;
	cd /tmp;
	echo -e "$GREEN [NOTICE] CSF Instaling... $RESET";
	wget https://download.configserver.com/csf.tgz >/dev/null 2>&1 ;
	tar -xzf csf.tgz >/dev/null 2>&1 ;
	cd csf ;
	sh install.sh >/dev/null 2>&1 ;
	cd .. ;
	rm -f csf.tgz ;
	rm -rf csf/ ;
	echo -e "$GREEN [OK] CSF installed! $RESET";
	echo -e "$GREEN";
	read -p "Press any key to continue... " -n1 -s ;
	echo -e "$RESET";
}


function do_extra() {
	clear;
	echo -e "$GREEN [Notice] CSF Extra packages installing...! $RESET";
	
	rpm -qa | grep perl-libwww-perl;
	if [ $? -ne 0 ]; then
		yum install perl-libwww-perl -y  >/dev/null 2>&1;
	fi
	
	rpm -qa | grep perl-Crypt-SSLeay;
	if [ $? -ne 0 ]; then
		yum install perl-Crypt-SSLeay -y  >/dev/null 2>&1 ;
	fi
	rpm -qa | grep perl-Time-HiRes;
	if [ $? -ne 0 ]; then
		yum install  perl-Time-HiRes -y  >/dev/null 2>&1;
	fi
	yum install 'perl (IO::Socket:SSL)'  >/dev/null 2>&1;
	echo -e "$GREEN [OK] Extra packages installed! $RESET";
	echo -e "$GREEN";
	read -p "Press any key to continue... " -n1 -s ;
	echo -e "$RESET";echo -e "$RESET";
}

################################################################################
while true
do

### display main menu ###
dialog --clear  --help-button --backtitle "Asanwebhost Company" \
--title "[ M A I N - M E N U ]" \
--menu "You can use the UP/DOWN arrow keys, the first \n\
letter of the choice as a hot key, or the \n\
number keys 1-9 to choose an option.\n\
Choose the TASK" 15 60 6 \
Install "install CSF" \
config "only config csf" \
Extra "install extra package" \
Full "install & configure all needed options" \
Exit "Exit to the shell" 2>"${INPUT}"

menuitem=$(<"${INPUT}")


# make decsion 
case $menuitem in
	Install) do_install;;
	config) do_config;;
	Extra) do_extra;;
	Full) do_install;do_config;do_extra;;
	Exit) clear;echo "Bye"; break;;
esac

done