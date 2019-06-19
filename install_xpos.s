#!/bin/bash

ACCOUNT=$1
if [ "${ACCOUNT}" == "" ]
then
	echo "please follow the account id in commandline"
	echo "example: ./install_gmm.s z01"
	exit
fi

LOCAL=`pwd`
DATE=`date +%Y%m%d`
VER=`uname -r|awk -F- '{print $1}'|awk -F. '{print $3}'`
chmod 755 ${LOCAL}/bin/batch_tool

if [ ! -f /u/${ACCOUNT}/xpos_installed ]
then
echo "already installed xpos in ${DATE}" > /u/${ACCOUNT}/xpos_installed
#it will ask how many xpos station in current hotel,but it will only support 99 in maxiaum
echo "how many xpos station in your hotel?(1-99)"
read OLD_WS
while [[ "`echo $OLD_WS|sed -n '/^[1-9][0-9]*$/p'`" == "" || $OLD_WS -gt 99 ]]
do
	echo "please insert xpos station amount"
	read OLD_WS
done

START=1
WS=$(($OLD_WS+$START-1))

cd /u/${ACCOUNT}/data
if [ "`${LOCAL}/bin/batch_tool paytype.dbf /f:fpay_des1~alipay /s:fpay_des1`" == "" ]
then 
	for x in `awk '{for(i=1;i<=NF;i++){ if($i=="alipay"){printf("%s\n",substr($2,1))} } }' ${LOCAL}/conf/repl_list.txt`
	{
		cd /u/${ACCOUNT}/`echo $x|awk -F / '{print $1}'`/`echo $x|awk -F / '{print $2}'`/
#data paytype add three new method to support alipay wechat
		${LOCAL}/bin/batch_tool `echo $x|awk -F / '{print $3}'` "/FIELD:FPAY_DES1=alipay_coupon;FPAY_DES2=alipay_coupon;FPAY_DES3=alipay_coupon;FAUTHOR=F;FTYPE=1;FLIMIT=0.00;FPAYTYPE=98;FINPUT_TP=8;FPMS=0;FNOPREPOST=T;FNOASKACCT=T;FDEF_ACCT=T;FSEQ=98;FPAY_LEV=0" /append "/FIELD:FPAY_DES1=alipay;FPAY_DES2=alipay;FPAY_DES3=alipay;FAUTHOR=F;FTYPE=1;FLIMIT=0.00;FPAYTYPE=99;FINPUT_TP=0;FPMS=1;FNOPREPOST=T;FNOASKACCT=T;FDEF_ACCT=T;FSEQ=99;FPAY_LEV=0" /append "/FIELD:FPAY_DES1=wechat;FPAY_DES2=wechat;FPAY_DES3=wechat;FAUTHOR=F;FTYPE=1;FLIMIT=0.00;FPAYTYPE=97;FINPUT_TP=0;FPMS=1;FNOPREPOST=T;FNOASKACCT=T;FDEF_ACCT=T;FSEQ=97;FPAY_LEV=0" /append
		cd ${LOCAL}
	}
	for x in `awk '{for(i=1;i<=NF;i++){ if($i=="alipay_disc"){printf("%s\n",substr($2,1))} } }' ${LOCAL}/conf/repl_list.txt`
	{
	cd /u/${ACCOUNT}/`echo $x|awk -F / '{print $1}'`/`echo $x|awk -F / '{print $2}'`/
#data ckdistp add a new discount in check discount database
		${LOCAL}/bin/batch_tool `echo $x|awk -F / '{print $3}'` "/FIELD:FDIS_NUM=0099;FDIS_TYPE=2;FDIS_DESC1=alipay_disc;FDIS_DESC2=alipay_disc;FDIS_DESC3=alipay_disc;FDIS_AMT=0.00;FDIS_RANGE=0099;FSEQ=99;FDIS_LEV=0" /append
		cd ${LOCAL}
	}
fi
#adduser if not exist
if [ "`sed -n 's/^\(xpos\):.*/\1/p' /etc/passwd`" != "xpos" ]
then
	adduser xpos -d /u/xpos
else
	sed -i 's/\(^xpos:.*:.*:.*:.*:\).*\(:.*\)/\1\/u\/xpos\2/g' /etc/passwd
fi
#unzip programe
if [ ! -d /u/xpos_bak ]
then
	if [ -d /u/xpos ]
	then
		mv /u/xpos /u/xpos_bak
	else
		mkdir /u/xpos_bak
	fi
	unzip -o -d /u/ ${LOCAL}/xpos/xpos.zip	
fi

if [[ $VER == 21 ]]
then 
	unzip -o -d /u/xpos /u/xpos/xpos_rhel3.zip
else
	unzip -o -d /u/xpos /u/xpos/xpos_rhel5.zip
fi
#add startup script in rc.local
if [ "`sed -n '/^[^#].*paytbld\.s/p' /etc/rc.local`" == "" ]
then
	echo "/usr/gm/etc/paytbld.s" >> /etc/rc.local
fi
#compile and install json-c-0.8 and execute ldconfig
if [ ! -d ${LOCAL}/xpos/json-c-0.8 ]
then
	tar zxvf ${LOCAL}/xpos/json-c-0.8.tar.gz -C ${LOCAL}/xpos/
	cd ${LOCAL}/xpos/json-c-0.8
	./configure --prefix=/usr
	make
	make install
fi
if [ "`sed -n '/^\/usr\/local\/lib/p' /etc/ld.so.conf`" == "" ]
then
	echo "/usr/local/lib/" >> /etc/ld.so.conf
	ldconfig
else
	ldconfig
fi
#make temp dir for pgs_alipay
if [ ! -d /u/pgstmp ]
then
	mkdir /u/pgstmp
fi
chmod 777 /u/pgstmp
#add script info to crontab
if [ "`sed -n 's/.*\(paytbld\).*/\1/p' /var/spool/cron/root`" != "paytbld" ]
then
	echo "0 4 * * * /usr/gm/etc/paytbld.s >/dev/null 2>&1" >> /var/spool/cron/root
fi	
#unzip xpos programe
unzip -o -d /usr/ ${LOCAL}/xpos/gm_xpos.zip
if [[ $VER == 21 ]]
then
	unzip -o -d /usr/gm/bin /usr/gm/bin/paytbld_json_RHEL3*.zip
elif [[ $VER == 18 ]]
then
	unzip -o -d /usr/gm/bin /usr/gm/bin/paytbld_json_RHEL5*.zip
elif [[ $VER == 32 ]]
then 
	unzip -o -d /usr/gm/bin /usr/gm/bin/paytbld_json_RHEL6*.zip
else
	unzip -o -d /usr/gm/bin /usr/gm/bin/paytbld_json_RHEL7*.zip
fi
if [ ! -f /usr/gm/global/proc.dbf ]
then
	cd /usr/gm/global
	${LOCAL}/bin/batch_tool process.dbf /pack:dbf
fi

cp -p ${LOCAL}/conf/proc.dbf /usr/gm/global/proc.dbf
cd /usr/gm/global/
#batch_tool will undeleted amount of record that you inserted
${LOCAL}/bin/batch_tool proc.dbf /recall:${START}-${WS}
${LOCAL}/bin/batch_tool proc.dbf /pack:dbf
${LOCAL}/bin/batch_tool proc.dbf "/l:FUSER=${ACCOUNT}" /update
${LOCAL}/bin/batch_tool proc.dbf /delete:all
${LOCAL}/bin/batch_tool process.dbf +proc.dbf
#use echo and batch_tool to make a paytbld.s for your special configure
if [ ! -f /usr/gm/etc/paytbld.s.xpos ]
then
	if [ -f /usr/gm/etc/paytbld.s ]
	then
		mv /usr/gm/etc/paytbld.s /usr/gm/etc/paytbld.s.xpos
	else
		echo "no paytbld.s" > /usr/gm/etc/paytbld.s.xpos
	fi
fi

if [ ! -f /usr/gm/etc/paytbld.s ]
then 
	echo "PATH=/usr/java/jre1.7.0_72/bin:/usr/lib/qt-3.3/bin:/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:/root/bin:/usr/gm/etc:/usr/gm/global:/usr/gm/bin:/usr/gm/util" > /usr/gm/etc/paytbld.s
	echo "BASH_ENV=/etc/bashrc" >> /usr/gm/etc/paytbld.s
	echo "LD_LIBRARY_PATH=/usr/local/lib" >> /usr/gm/etc/paytbld.s
	echo "export PATH LD_LIBRARY_PATH BASH_ENV" >> /usr/gm/etc/paytbld.s
fi

if [ "`sed -n '/xpos/p' /usr/gm/etc/paytbld.s`" == "" ]
then
	${LOCAL}/bin/batch_tool proc.dbf /f:FPROCESS=pda /deleted+ /s:FUSER,FSTAT_ID|awk -F \| '{gsub(/ /,"",$1);print "cd /u/"$1"";print "su "$1" -c '\''/usr/gm/etc/pgs_json_start.s "$2"'\''"}' >> /usr/gm/etc/paytbld.s
	echo "cd /u/xpos" >> /usr/gm/etc/paytbld.s
	echo "su xpos -c '/u/xpos/shell/runs'" >> /usr/gm/etc/paytbld.s
else
	${LOCAL}/bin/batch_tool proc.dbf /f:FPROCESS=pda /deleted+ /s:FUSER,FSTAT_ID|awk -F \| '{gsub(/ /,"",$1);print "cd /u/"$1"";print "su "$1" -c '\''/usr/gm/etc/pgs_json_start.s "$2"'\''"}' > temp
	sed -i $'/cd \/u\/xpos/{e cat temp\n}' /usr/gm/etc/paytbld.s
	rm temp
fi

if [ "`sed -n '/mtime/p' /usr/gm/etc/paytbld.s`" == "" ]
then
	echo "sleep 3" >> /usr/gm/etc/paytbld.s
	echo "sync" >> /usr/gm/etc/paytbld.s
	echo "find /u/xpos/log/ -mtime +90 -exec rm -f {} +" >> /usr/gm/etc/paytbld.s
fi
chmod 755 /usr/gm/etc/paytbld.s

if [ ! -f /usr/gm/etc/paytbld_${ACCOUNT}.s ]
then
	echo "PATH=/usr/java/jre1.7.0_72/bin:/usr/lib/qt-3.3/bin:/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:/root/bin:/usr/gm/etc:/usr/gm/global:/usr/gm/bin:/usr/gm/util" > /usr/gm/etc/paytbld_${ACCOUNT}.s
	echo "BASH_ENV=/etc/bashrc" >> /usr/gm/etc/paytbld_${ACCOUNT}.s
	echo "LD_LIBRARY_PATH=/usr/local/lib" >> /usr/gm/etc/paytbld_${ACCOUNT}.s
	echo "export PATH LD_LIBRARY_PATH BASH_ENV" >> /usr/gm/etc/paytbld_${ACCOUNT}.s
	${LOCAL}/bin/batch_tool proc.dbf /f:FPROCESS=pda /deleted+ /s:FUSER,FSTAT_ID|awk -F \| '{gsub(/ /,"",$1);print "cd /u/"$1"";print "/usr/gm/etc/pgs_json_start.s "$2""}' >> /usr/gm/etc/paytbld_${ACCOUNT}.s	
fi
chmod 755 /usr/gm/etc/paytbld_${ACCOUNT}.s
#uncomment the amount of xpos station 's line in xpos/shell/runs ,in order to only start the correct qunanties daemon in background
#sed -i "5,+$amt {s/^#//;}" /u/xpos/shell/runs
if [ ! -f /u/xpos/etc/swt_agt.ini.xpos ]
then
	if [ -f /u/xpos/etc/swt_agt.ini ]
	then
		mv /u/xpos/etc/swt_agt.ini /u/xpos/etc/swt_agt.ini.xpos
	else
		echo "no swt_agt.ini" > swt_agt.ini.xpos
	fi
fi
for ((i=$((${START}-1));i<${WS};i++))
do
	cp /u/xpos/bin/swt_patt /u/xpos/bin/swt_patt$i
	sed -i "/.*ok.*/i /u/xpos/bin/swt_patt$i $i &" /u/xpos/shell/runs
	echo `awk '/\[pattern11\]/{while(getline)if($0!~/\[pattern11\]/)print;else exit}' ${LOCAL}/conf/setup.inf|awk "{if(NR==$((${i}+1))){print}}"` >> /u/xpos/etc/swt_agt.ini
	echo "L_NAME$i = SilverStone" >> /u/xpos/etc/swt_agt.ini
	echo "L_ADDR$i = 202.102.90.35" >> /u/xpos/etc/swt_agt.ini
	echo "L_PORT$i = 10102" >> /u/xpos/etc/swt_agt.ini
	echo "L_IDLE$i = 60" >> /u/xpos/etc/swt_agt.ini
	echo "L_LOG$i = 1" >> /u/xpos/etc/swt_agt.ini
	echo "S_NAME$i = Infrasys" >> /u/xpos/etc/swt_agt.ini
	echo "S_TIME$i = 50" >> /u/xpos/etc/swt_agt.ini
	echo "S_LOG$i = 1" >> /u/xpos/etc/swt_agt.ini
	echo "S_MODE$i = 1" >> /u/xpos/etc/swt_agt.ini
	echo "############" >> /u/xpos/etc/swt_agt.ini
done
#tty.inf
if [ ! -f /u/${ACCOUNT}/tty/tty.inf.xpos ]
then
	cp -p /u/${ACCOUNT}/tty/tty.inf /u/${ACCOUNT}/tty/tty.inf.xpos
	awk '/\[pattern6\]/{while(getline)if($0!~/\[pattern6\]/)print;else exit}' ${LOCAL}/conf/setup.inf|awk "{if(NR <= ${WS} && NR >= ${START}){print}}" > temp
	sed -i '/\[main\]/r temp' /u/${ACCOUNT}/tty/tty.inf
	rm temp
	OTHER=`sed -n '/^other/p' /u/${ACCOUNT}/tty/tty.inf|tail -1|awk -F= '{print $1}'|sed -n 's/other\(.*\)/\1/p'`
	sed -i "/^other${OTHER}.*/a other$(($OTHER+1))=98,1,0,0,0,1,0" /u/${ACCOUNT}/tty/tty.inf
	sed -i "s/other_xpos/other$(($OTHER+1))/g" /u/${ACCOUNT}/tty/tty.inf
fi
#tty.dbf gm_over.inf
cd /u/${ACCOUNT}/tty/
for ((i=${START};i<=${WS};i++))
do
	if [ $i -lt 10 ];then
		cp /u/${ACCOUNT}/tty/tty.dbf /u/${ACCOUNT}/tty/ttyk0$i.dbf
		st=`sed -n "/k0$i/p" /u/${ACCOUNT}/tty/tty.inf|awk -F= '{print $2}'|awk -F, '{print $3}'`
		${LOCAL}/bin/batch_tool ttyk0$i.dbf "/l:FCK_CUR=$(($st+1))" /update
		temp+="k0$i,"
	else
		cp /u/${ACCOUNT}/tty/tty.dbf /u/${ACCOUNT}/tty/ttyk$i.dbf
		st=`sed -n "/k$i/p" /u/${ACCOUNT}/tty/tty.inf|awk -F= '{print $2}'|awk -F, '{print $3}'`
		${LOCAL}/bin/batch_tool ttyk$i.dbf "/l:FCK_CUR=$(($st+1))" /update
		temp+="k$i,"
	fi
done
sed -i "/\[gmate\]/a $temp=gmate_pgs.inf" /u/${ACCOUNT}/data/gm_over.inf
sed -i 's/,=/=/g' /u/${ACCOUNT}/data/gm_over.inf
# gmate_pgs.inf
awk '/\[pattern3\]/{while(getline)if($0!~/\[pattern3\]/)print;else exit}' ${LOCAL}/conf/setup.inf|awk "{if(NR <= ${WS} && NR >= ${START}){print}}" > temp
sed -i '$i \[pay at table\]' /u/${ACCOUNT}/data/gmate_pgs.inf
sed -i '$e cat temp' /u/${ACCOUNT}/data/gmate_pgs.inf
rm temp
#echo a new swt_agt,ini in xpos program
#if [ ! -f /u/xpos/etc/swt_agt.ini.xpos ]
#then
#cp -p /u/xpos/etc/swt_agt.ini /u/xpos/etc/swt_agt.ini.xpos
#awk '{i=1}/\[pattern11\]/{while(getline a)if(i<=$amt){i++;print a}else{exit}}' ${LOCAL}/conf/setup.inf|sed -n 's/[[:space:]]//gp' > temp
#array1=($(cat temp|awk -F= '{print $1}'))
#array2=($(cat temp|awk -F= '{print $2}'))
#for (( i=0;i<$amt;i++ ))
#do
#sed -i "s/\(${array1[i]}\)[^0-9].*/\1 = ${array2[i]}/" /u/xpos/etc/swt_agt.ini
#done
#rm temp
#fi

#if [ ! -f /u/${ACCOUNT}/tty/tty.inf.xpos ]
#then
#cp -p /u/${ACCOUNT}/tty/tty.inf /u/${ACCOUNT}/tty/tty.inf.xpos
#awk '{i=1}/\[pattern6\]/{while(getline a)if(i<=$amt){i++;print a}else{exit}}' ${LOCAL}/conf/setup.inf > temp
#sed -i '/\[main\]/r temp' /u/${ACCOUNT}/tty/tty.inf
#rm temp
#fi

#if [ ! -f /u/{ACCOUNT}/data/gmate_pgs.inf.xpos ]
#then
#cp -p /u/${ACCOUNT}/data/gmate_pgs.inf /u/${ACCOUNT}/data/gmate_pgs.inf.xpos
#awk '{i=1}/\[pattern3\]/{while(getline a)if(i<=$amt){i++;print a}else{exit}}' ${LOCAL}/conf/setup.inf > temp
#sed -i '$r temp' /u/${ACCOUNT}/data/gmate_pgs.inf
#rm temp
#fi

chmod -R 777 /u/xpos
chown -R xpos:xpos /u/xpos
chmod -R 777 /u/${ACCOUNT}
chown -R ${ACCOUNT}:${ACCOUNT} /u/${ACCOUNT}
#if there is a new customer.inf,batch_tool will append proc.dbf to process.dbf,and execute paytbld.s script at last,if not you will do this procedure manually
if [[ -f ${LOCAL}/conf/customer.inf && ! -f /usr/gm/global/customer.inf.xpos ]]
then
	cd /usr/gm/global/
	cp -p /usr/gm/global/customer.inf /usr/gm/global/customer.inf.xpos
	cp -p ${LOCAL}/conf/customer.inf /usr/gm/global/customer.inf
	cp -p /usr/gm/global/process.dbf /usr/gm/global/process.dbf.xpos
	${LOCAL}/bin/batch_tool process.dbf /recall:all
else
	echo "lack of new customer.inf,you need update license and process.dbf manually"
fi

chmod -R 777 /usr/gm
chown -R bin:bin /usr/gm
#hardest part of this script,it will generate a selection in gmsys to execute paytbld.s automatically
#if [ -f /u/gmsys/sys_start.s ] && [ "`sed -n '/XPOS/p' /u/gmsys/sys_start.s`" == "" ] && [ ! -f /u/gmsys/sys_start.s.xpos ]
#then
#                1) exec sys_shutdown.s;;
#                2) sys_time.s;;
#                3) /usr/gm/etc/justboot.s;;
#	cp -p /u/gmsys/sys_start.s /u/gmsys/sys_start.s.xpos
#	array=($(sed -n 's/^[^#].*[^0-9]\(.*[^)"]\)).*/\1/p' /u/gmsys/sys_start.s))
#	length=${#array[@]}
#	temp=0
#	for ((i=0; i<$length; i++))
#	do
#		if [ $temp -lt ${array[$i]} ]
#		then
#			let "temp=${array[$i]}"
#		fi
#	done
#	let "temp+=1"
#        echo  " 8. Restart XPOS Service               "
#	sed -i "/^[^#].*[^0-9]0\./i \ \techo  \" $temp. Restart XPOS Service               \"" /u/gmsys/sys_start.s
#                8) /usr/gm/etc/paytbld.s;;
#	sed -i "/^[^#].*[^0-9]0).*;;/i \ \t\t$temp) /usr/gm/etc/paytbld.s\;\;" /u/gmsys/sys_start.s
#fi
STAT=`sed -n 's/^9.*stattype="\([0-9]\)".*/\1/p' /u/${ACCOUNT}/gm_user.s|awk '{if ( NR == 1 ){print $1}}'`
INF=`sed -n "s/.*${STAT}.*gm_select.*\/\(.*\);;.*/\1/p" /u/${ACCOUNT}/gm_user.s`

if [ ! -f /u/${ACCOUNT}/gm_user.s.xpos ]
then
	cp -p /u/${ACCOUNT}/gm_user.s /u/${ACCOUNT}/gm_user.s.xpos
	sed -i "/\[6\][)]/,/esac/{s/\(.*${STAT}[)] \).*\(;;.*\)/\1\/usr\/gm\/etc\/paytbld_${ACCOUNT}\.s \2/}" /u/${ACCOUNT}/gm_user.s
fi

array=($(LANG=en sed -n 's/^selection\([0-9]\).*/\1/p' /u/${ACCOUNT}/${INF}))
length=${#array[@]}
id=0
for ((i=0; i<$length; i++))
do
	if [ $id -lt ${array[$i]} ]
	then
		let "id=${array[$i]}"
	fi
done

if [ ! -f /u/${ACCOUNT}/${INF}.xpos ]
then
	cp -p /u/${ACCOUNT}/${INF} /u/${ACCOUNT}/${INF}.xpos
	sed -i "/^selection${id}.*/i selection${id} = 6,6,6\. Restart paytbld service" /u/${ACCOUNT}/${INF}
	let "id+=1"
	sed -i "s/.*\( = 0,0,0\..*\)/selection${id}\1/" /u/${ACCOUNT}/${INF}
fi

if [ -f ${LOCAL}/conf/customer.inf ]
then
	/usr/gm/etc/paytbld.s
fi
NEW_START=$(($START+$OLD_WS))
sed -i "s/^START.*/START=${NEW_START}/g" ${LOCAL}/install_xpos.s
else
cat /u/${ACCOUNT}/xpos_installed
fi
