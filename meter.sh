#!/bin/bash

# script voor het uitlezen van "ISK5ME162"
# met 300 Baud 7E1
# 1. meter voor verbruik en feedback
# 2. (optioneel) meter voor zonnecel installatie
# script moet elke minuut met cron aangeroepen worden
#
# berekening en overdracht van eingen verbruik en het totale verbruik
# waarde die nodig zijn om de vorige waardes te bereken
# waardes worden tijdelijk naar tmpfs geschreven

UUID_Z1="12345678-5af5-11e2-b07b-4719a189d23d"
# UUID_Z2="12345678-5b4b-11e2-80e1-470f08ca1a5d"
# UUID_Z3="12345678-5c12-11e2-bf45-d7ff2b4611b3"
# UUID_E="12345678-5b4b-11e2-9a36-95c59de08aa0"
# UUID_S="12345678-5b4b-11e2-8293-d3b227ca0237"

# echo "/?!<crlf>" naar y-poort node, grep de benodigde waardes er uit"
line=`echo -e "\x2f\x3f\x21\x0d\x0a" | nc -w2 192.168.178.5 7970 | grep "\."`
# filter correct lines
Z1_RAW=`echo "$line" | grep "1\.8\.0"`
# Z2_RAW etc...

# de juiste data in de juiste variable stoppen
[[ "$Z1_RAW" =~ "1.8.0" ]] && Z1=${Z1_RAW:6:9}	# Waarde hoofdmeter
# [[ "$Z2_RAW" =~ "2.8.0" ]] && Z2=${line:6:8}	# Waarde feedback

# Optioneel: Uitlezen 2e meter, hier via de seriele poort
# ( sleep 1 ; echo -e "\x2f\x3f\x21\x0d\x0a" > /dev/ttyUSB1 ) &
# while read -t8 line
# do
# #  [[ "$line" =~ "1.8.0" ]] && Z2_in=${line:6:8}                 # waarde niet nodig
#   [[ "$line" =~ "2.8.0" ]] && Z3=${line:6:8}                     # waarde productie
# done < /dev/ttyUSB1

# Eigenverbruik is verschil van productie - feedback
# aan gezien de meters niet syncroon lopen kan een waarde negatief worden
# dit veroorzaakt weergavefoute
# dus controleren of het verbruik niet minder is dan vorige waarde 

# eigen_old=$(cat /var/run/eigen_old)
# eigen=$(echo "scale=1; ($Z3 - $Z2)" | bc)                       # verbruik van de PV installatie
# [ -z "$eigen_old" ] && eigen_old=$eigen

# if [ $(echo "if ($eigen >= $eigen_old) 1 else 0" | bc) -eq 1 ] ; then  # als oud - nieuw negatief
#  echo $eigen > /var/run/eigen_old
# else
#   eigen=$eigen_old;                                             # dan oude waarde houden
# fi

# summe=$(echo "scale=1; ($Z1 + $eigen)" | bc)                    # Totaalverbruik

# Debug
datum=`date`
echo -n "$datum : from : $Z1" >> /var/log/meter.log
# , to:$Z2, pv:$Z3, mypv:$eigen, myall:$summe
# /Debug

# opslaan op het filesystem, om straks onnodige schrijfactie naar de db te vermijden

Z1_old=$(cat /var/run/Z1)
echo $Z1 > /var/run/Z1
# Z2_old=$(cat /var/run/Z2)
# echo $Z2 > /var/run/Z2
# Z3_old=$(cat /var/run/Z3)
# echo $Z3 > /var/run/Z3
# E_old=$(cat /var/run/Eigen)
# echo $eigen > /var/run/Eigen
# S_old=$(cat /var/run/Summe)
# echo $summe > /var/run/Summe

# checken of de waarde verandert is, zo niet dan ook niet daar de DB schrijven

[ "$Z1" == "$Z1_old" ] && Z1=""
# [ "$Z2" == "$Z2_old" ] && Z2=""
# [ "$Z3" == "$Z3_old" ] && Z3=""
# [ "$eigen" == "$E_old" ] && eigen=""
# [ "$summe" == "$S_old" ] && summe=""

# Debug , als er niet verandert is, dan markeren met *
[ -z "$Z1" ] && echo -n " *" >> /var/log/meter.log
# $Z2$Z3$eigen$summe
echo >> /var/log/meter.log
# /Debug

# versturen van de meterstanden naar de middleware wanneer nodig
# met vzclient, maar zou ook kunnen met wget of curl

# [ -z "$Z1" ] || /usr/local/bin/vzclient -u $UUID_Z1 add data value=$Z1 > /dev/null
# debug:
echo "$UUID_Z1: $Z1"
# [ -z "$Z2" ] || /usr/local/bin/vzclient -u $UUID_Z2 add data value=$Z2 > /dev/null
# [ -z "$Z3" ] || /usr/local/bin/vzclient -u $UUID_Z3 add data value=$Z3 > /dev/null
# [ -z "$eigen" ] || /usr/local/bin/vzclient -u $UUID_E add data value=$eigen > /dev/null
# [ -z "$summe" ] || /usr/local/bin/vzclient -u $UUID_S add data value=$summe > /dev/null
