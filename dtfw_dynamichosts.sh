#!/bin/bash -
#===============================================================================
#
#          FILE: dtfw_dynamichosts.sh
#
#         USAGE: ./dtfw_dynamichosts.sh
#
#   DESCRIPTION: Dumb Terminals plug-in script to help handle Dynamic DNS, to ease
#                  remote access for ever changing IP's with the firewall.
#       OPTIONS: ---
#  REQUIREMENTS: IPTables and DTfw script.
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: Mike Redd (MikereDD), mredd@0tue0.com
#  ORGANIZATION: the Spork, Inc.
#       CREATED: 04/28/2012 10:21:44 AM PDT
#      REVISION:  ---
#===============================================================================

#set -o nounset                              # Treat unset variables as an error

VER="0.1b"

# create the chain in iptables.
# /sbin/iptables -N dtfwdynamichosts
# insert the chain into the input chain @ the head of the list.
# /sbin/iptables -I INPUT 1 -j dtfwdynamichosts
# flush all the rules in the chain
# /sbin/iptables -F dtfwdynamichosts


HOST=$1
HOSTFILE="/usr/local/etc/DTfw/dtfw_dynamichosts/host-$HOST"
CHAIN="dtfwdynamichosts"  # change this to whatever chain you want.
IPTABLES='/usr/sbin/iptables'
DYNAMICDNSLIST="/usr/local/etc/DTfw/dtfw_dynamiclists/dtfw_dynamichosts.lst"
DYNAMICDNSLISTTMP="/usr/local/etc/DTfw/dtfw_dynamiclists/dtfw_dynamichoststmp.lst"

if [ -f "$DYNAMICDNSLIST" ];then
    echo "############################################"
    echo -e " DTfw Dynamic Hosts ver.$VER"
    echo -e " running on server: $HOSTNAME"
    echo -e " Date/Time: $(date)"
    echo " Found dtfw_dynamichosts list... using list"
    echo "############################################"
    HOST=$(cat $DYNAMICDNSLIST)
# check to make sure we have enough args passed.
elif [ "${#@}" -ne "1" ]; then
    echo "$0 hostname"
    echo " You must supply a hostname to update in iptables."
    exit
fi

# lookup host name from dns tables
IP=`/usr/bin/dig +short $HOST | /usr/bin/tail -n 1`
if [ "${#IP}" = "0" ]; then
    echo " Couldn't lookup hostname for $HOST, failed."
    exit
fi

OLDIP=""
if [ -a $HOSTFILE ]; then
    OLDIP=`cat $HOSTFILE`
    # echo "CAT returned: $?"
fi
 
# has address changed?
if [ "$OLDIP" == "$IP" ]; then
    echo "############################################"
    echo " Old and new IP addresses match."
    echo -e " DTfw Dynamic Hosts ver.$VER"
    echo -e " $HOST - $OLDIP"
    echo "############################################"
    exit
fi
 
# save of new ip.
echo $IP>$HOSTFILE
echo "############################################"
echo -e " DTfw Dynamic Hosts ver.$VER"
echo " Updating $HOST in iptables."
echo -e " $HOST - $IP"
echo "############################################"
if [ "${#OLDIP}" != "0" ]; then
    echo "Removing old rule ($OLDIP)"
    `$IPTABLES -D $CHAIN -s $OLDIP/32 -j ACCEPT`
fi
echo "Inserting new rule ($IP)"
`$IPTABLES -A $CHAIN -s $IP/32 -j ACCEPT`

#   if [ ! -r "$DYNAMICDNSLIST" ]; then
#     echo -e "${ReD}cannot read DynamicHostlist at \"${DYNAMICDNSLIST}\", allowing ALL traffic!${DeF}"
#     $IPTABLES -I INPUT 1 -j ACCEPT     -m comment --comment "dynamicdnslist error, allowing all"
#     $IPTABLES -I FORWARD 1 -j ACCEPT   -m comment --comment "dynamicdnslist error, allowing all"
#     $IPTABLES -I OUTPUT 1 -j ACCEPT    -m comment --comment "dynamicdnslist error, allowing all"
#   else
#       wl=1;
#       whiteSpace="         "
#       echo -e "/usr/bin/dig -f $DYNAMICDNSLIST +short" > $DYNAMICDNSLISTTMP
#       grep -v "^#" $DYNAMICDNSLISTTMP | grep -v "^$" | while read a; do
#           if [ "$wl" == "1" ]; then  echo " Permitting DynamicDNSlisted IPs:"; fi
#           sz=${#a}
#           wip=`echo $a | awk '{print $1}'`
#           szip=${#wip}
#           comment=`echo ${a:szip} | sed 's/ *$//g'`
#           ws=${whiteSpace:0:20-szip}
#           echo "    $wl: ${wip}${ws}$comment"
#           $IPTABLES -I ${WLchain} ${wl} -t filter -s $wip -j ACCEPT   -m comment --comment "dynamicdnslist ${wl} ${comment}"
#           wl=$((wl+1));
#       rm -f $DYNAMICDNSTMP
#       done
#
#   fi
#   InsertLayerRule "102" # input  dynamicdnslist
#   InsertLayerRule "162" # output dynamicdnslist

