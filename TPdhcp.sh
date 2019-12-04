#!/bin/bash

ipProxy=$1
senha=$2
nome=$3
dns="8.8.8.8,\ 8.8.4.4"
tempo1="default-lease-time 300;"
tempo2="max-lease-time 1800;"
ipCliente="192.168.10.2"
ipServidor="192.168.10.10"
rede="subnet 192.168.10.0 netmask 255.255.255.240"
range="range 192.168.10.101 192.168.10.199;"
routers="option routers 192.168.10.200"

sshpass -p "123456" ssh -o StrictHostKeyChecking=no root@$ipProxy 'systemctl status dhcpd | grep "active (running)"'

if [ $? -eq 0 ]
then
    echo "O DHCP está executando."
    sshpass -p "$senha" ssh -o StrictHostKeyChecking=no root@$ipProxy ping -c 2 $ipServidor
    sshpass -p "123456" ssh -o StrictHostKeyChecking=no root@$ipProxy ping -c 2 $ipCliente

    cliente=$(sshpass -p "123456" ssh -o StrictHostKeyChecking=no root@$ipProxy ip neighbour show | grep $ipCliente | awk '{ print $5 }')

    servidor=$(sshpass -p "123456" ssh -o StrictHostKeyChecking=no root@$ipProxy ip neighbour show | grep $ipServidor | awk '{ print $5 }')

    sshpass -p "123456" scp -o StrictHostKeyChecking=no root@$ipProxy:/etc/dhcp/dhcpd.conf ./
 
    while read linha
    do
        grep -v "^#" $linha 2> /dev/null | sed /^$/d > correcao.txt
    done < ./dhcpd.conf
    
    grep -q "authoritative" correcao.txt 2> /dev/null -a grep -q "log-facility local7" 2> /dev/null
    if [ $? -eq 0 ]
    then
        echo "As configurações de log e de rede local principal estão corretas"
    else
        echo "As configurações de log e de rede local principal estão incorretas"
    fi

    grep -q $nome correcao.txt 2> /dev/null -a grep -q $dns correcao.txt 2> /dev/null
    if [ $? -eq 0 ]
    then
        echo "As configurações de nome e DNS estão corretas"
        pontos=`expr $pontos + 2`
    else
        echo "As configurações de nome e DNS estão incorretas"
    fi
    
    grep -q $tempo1 correcao.txt 2> /dev/null
    if [ $? -eq 0 ]
    then
        echo "A configuração de tempo default está correta"
        pontos=`expr $pontos + 1`
    else
        echo "A configuração de tempo default está incorreta"
    fi

    grep -q $tempo2 correcao.txt 2> /dev/null
    if [ $? -eq 0 ]
    then
        echo "A configuração de tempo máximo está correta"
        pontos=`expr $pontos + 1`
    else
        echo "A configuração de tempo máximo está incorreta"
    fi
    
    grep -q $cliente correcao.txt 2> /dev/null -a grep -q $ip1 correcao.txt 2> /dev/null
    if [ $? -eq 0 ]
    then
        echo "A configuração de IP do host cliente está correta"
        pontos=`expr $pontos + 2`
    else
        echo "A configuração de IP do host cliente  está incorreta"
    fi

    grep -q $servidor correcao.txt 2> /dev/null -a grep -q $ip2 correcao.txt 2> /dev/null
    if [ $? -eq 0 ]
    then
        echo "A configuração de IP do host servidor está correta"
        pontos=`expr $pontos + 2`
    else
        echo "A configuração de IP do host servidor  está incorreta"
    fi

    egrep -q $rede correcao.txt 2> /dev/null -a egrep -q $range correcao.txt 2> /dev/null -a egrep -q $routers correcao.txt 2> /dev/null
    if [ $? -eq 0 ]
    then
        echo "A configuração de rede está correta"
        pontos=`expr $pontos + 2`
    else
        echo "A configuração de rede está incorreta"
    fi
    
    echo "Sua pontuação nessa questão é: $pontos"

    #apaga o arquivo auxiliar usado na correção
    rm -rf correcao.txt
    rm -rf ./dhcpd.conf

else
    echo "O DHCP não está executando. Você não irá pontuar nessa questão."
fi

