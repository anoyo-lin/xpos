#!/bin/bash
ACCOUNT=$1
LOCAL=`pwd`
DATE=`/usr/gm/util/gmdate`

if [ "${ACCOUNT}" = "" ]
then
        echo "Please input the account name"
        echo "For example, /root/repl_gep.s z01"
        exit
fi

#if [ ! -f /u/${ACCOUNT}/xpos_installed ]
#then
#echo "already installed xpos environment in ${DATE}" >> /u/${ACCOUNT}/xpos_installed

#let program can execute
chmod 755 ${LOCAL}/bin/batch_tool
chmod 755 ${LOCAL}/bin/reindex
chmod 755 ${LOCAL}/gm_script/*.s

#kill all process of gmate
${LOCAL}/gm_script/kill_all.s
${LOCAL}/gm_script/disable_prog.s

#backup the defined account
if [ ! -f /u/${ACCOUNT}/sales_xpos_${DATE}.zip ]
then
	zip -r /u/${ACCOUNT}/data_xpos_${DATE}.zip /u/${ACCOUNT}/data
	zip -r /u/${ACCOUNT}/mttpl_xpos_${DATE}.zip /u/${ACCOUNT}/mttpl
	zip -r /u/${ACCOUNT}/sales_xpos_${DATE}.zip /u/${ACCOUNT}/sales
	zip -r /u/${ACCOUNT}/tty_xpos_${DATE}.zip /u/${ACCOUNT}/tty
fi
if [ ! -f /usr/gm/global_xpos_${DATE}.zip ]
then
	zip -r /usr/gm/global_xpos_${DATE}.zip /usr/gm/global
fi

#dos format inf file to unix format
#dos2unix -k -q -o /u/${ACCOUNT}/data/*.inf
#dos2unix -k -q -o /u/${ACCOUNT}/tty/*.inf
#dos2unix -k -q -o /u/${ACCOUNT}/mttpl/*.mdf
#dos2unix -k -q -o /u/${ACCOUNT}/mttpl/*.gep
#dos2unix -k -q -o /usr/gm/global/reindex.inf

#make the temporary directory
if [ -d /u/${ACCOUNT}/mttpl/xpos ]
then
	rm -fr /u/${ACCOUNT}/mttpl/xpos/*
else
	mkdir /u/${ACCOUNT}/mttpl/xpos
fi
	chmod 755 /u/${ACCOUNT}/mttpl/xpos

if [ -d /u/${ACCOUNT}/data/xpos ]
then
	rm -fr /u/${ACCOUNT}/data/xpos/*
else
	mkdir /u/${ACCOUNT}/data/xpos
fi
	chmod 755 /u/${ACCOUNT}/data/xpos

if [ -d /u/${ACCOUNT}/sales/xpos ]
then
	rm -fr /u/${ACCOUNT}/sales/xpos/*
else
	mkdir /u/${ACCOUNT}/sales/xpos
fi
chmod 755 /u/${ACCOUNT}/sales/xpos

#cp -p ./xpos/data/template/* /u/${ACCOUNT}/data/xpos/
#rm -rf ${DBE}
#echo "cd /u/${ACCOUNT}/data/xpos/" >> ${DBE}
#for x in /u/${ACCOUNT}/data/xpos/*.dbf
#{
#echo "use `echo $x|awk '{split($0,b,"/");print b[6]}'`" >> ${DBE}
#echo "appfile from ../`echo $x|awk '{split($0,b,"/");print b[6]}'`" >> ${DBE}
#echo "use" >> ${DBE}
#}
#echo "quit" >> ${DBE}
#/usr/gm/util/dbe ${DBE}
#rm -f ${DBE}
#copy the update file to temp dir
#cp -p ${LOCAL}/xpos/data/* /u/${ACCOUNT}/data/xpos/

sed -n '/^[^#].*lev2_payment.*/p' /u/${ACCOUNT}/data/gmate.inf > tmp
sed -i 's/[[:space:]]*//g' tmp
if [ "`sed -n '/^support_lev2_payment=1/p' tmp`" == "" ]
then
	cp -p ${LOCAL}/xpos/data/pay_grp.* /u/${ACCOUNT}/data/xpos/
	cp -p ${LOCAL}/xpos/data/pay_seq.* /u/${ACCOUNT}/data/xpos/
fi
rm tmp

sed -n '/^[^#].*lev2_discount.*/p' /u/${ACCOUNT}/data/gmate.inf > tmp
sed -i 's/[[:space:]]*//g' tmp
if [ "`sed -n '/^support_lev2_discount=1/p' tmp`" == "" ]
then
	cp -p ${LOCAL}/xpos/data/disc_grp.* /u/${ACCOUNT}/data/xpos/
	cp -p ${LOCAL}/xpos/data/disc_seq.* /u/${ACCOUNT}/data/xpos/
fi
rm tmp


#if [ ! -f /u/${ACCOUNT}/data/disc_grp.dbf ]
#then
#cp -p ${LOCAL}/xpos/data/disc_grp.* /u/${ACCOUNT}/data/xpos/
#fi
#if [ ! -f /u/${ACCOUNT}/data/disc_seq.dbf ]
#then
#cp -p ${LOCAL}/xpos/data/disc_seq.* /u/${ACCOUNT}/data/xpos/
#fi
#if [ ! -f /u/${ACCOUNT}/data/pay_grp.dbf ]
#then
#cp -p ${LOCAL}/xpos/data/pay_grp.* /u/${ACCOUNT}/data/xpos/
#fi
#if [ ! -f /u/${ACCOUNT}/data/pay_seq.dbf ]
#then
#cp -p ${LOCAL}/xpos/data/pay_seq.* /u/${ACCOUNT}/data/xpos/
#fi

cp -p ${LOCAL}/xpos/data/taxtable.dbf /u/${ACCOUNT}/data/xpos/
#cp -p ${LOCAL}/xpos/data/gmate_pgs.inf /u/${ACCOUNT}/data/xpos/

#cp -p ${LOCAL}/xpos/tty/* /u/${ACCOUNT}/tty/

#use a matrix to indentify the different kind file should be updated later,the matrix file just locates in local/conf
#data files first column named "repl_data" file name is just following latter
#substr($2,1) means get second element and start from offset 1
#%s\n means output result and follow a \n
for x in `awk '{for(i=1;i<=NF;i++){ if($i=="repl_data"){printf("%s\n",substr($2,1))} } }' ${LOCAL}/conf/repl_list.txt`
{
	cp -p /u/${ACCOUNT}/data/$x /u/${ACCOUNT}/data/xpos/
}
#sales files named "repl_sales" in firstt column,second column contains files' name
for x in `awk '{for(i=1;i<=NF;i++){ if($i=="repl_sales"){printf("%s\n",substr($2,1))} } }' ${LOCAL}/conf/repl_list.txt`
{
	cp -p /u/${ACCOUNT}/sales/$x /u/${ACCOUNT}/sales/xpos/
}
#report column named "repl_gep",2nd column contains files name
for x in `awk '{for(i=1;i<=NF;i++){ if($i=="repl_gep"){printf("%s\n",substr($2,1))} } }' ${LOCAL}/conf/repl_list.txt`
{
	if [ -f /u/${ACCOUNT}/mttpl/$x ]
	then
	cp -p /u/${ACCOUNT}/mttpl/$x /u/${ACCOUNT}/mttpl/xpos/
fi
}
#copy lack file to temp dir
cp -p ${LOCAL}/xpos/mttpl/* /u/${ACCOUNT}/mttpl/xpos/
#grep -rl will list files contain the pattern word in cli,and use pipe incoporate with sed to replace the 
#destination pattern words,because of sed can not support pipe method,so execute xargs before sed
#sed -i 's/dest/changed/g' will help you change all pattern word in evert file contains original word you want to replace
#in gep
grep -rl "FPAYTYPE, N, 2" /u/${ACCOUNT}/mttpl/xpos/|xargs sed -i "s/FPAYTYPE, N, 2/FPAYTYPE, N, 4/g" >/dev/null 2>&1
grep -rl "FPAYTYPE,	N,	2" /u/${ACCOUNT}/mttpl/xpos/|xargs sed -i "s/FPAYTYPE,	N,	2/FPAYTYPE,	N,	4/g" >/dev/null 2>&1
grep -rl "FPAYTYPE, C, 2" /u/${ACCOUNT}/mttpl/xpos/|xargs sed -i "s/FPAYTYPE, C, 2/FPAYTYPE, C, 4/g" >/dev/null 2>&1
grep -rl "FPAYTYPE,C,2" /u/${ACCOUNT}/mttpl/xpos/|xargs sed -i "s/FPAYTYPE,C,2/FPAYTYPE,C,4/g" >/dev/null 2>&1
grep -rl "FPAYTYPE,N,2" /u/${ACCOUNT}/mttpl/xpos/|xargs sed -i "s/FPAYTYPE,N,2/FPAYTYPE,N,4/g" >/dev/null 2>&1
grep -rl "FPAYMENT,N,2" /u/${ACCOUNT}/mttpl/xpos/|xargs sed -i "s/FPAYMENT,N,2/FPAYMENT,N,4/g" >/dev/null 2>&1
grep -rl "FDIS_NUM,C,2" /u/${ACCOUNT}/mttpl/xpos/|xargs sed -i "s/FDIS_NUM,C,2/FDIS_NUM,C,4/g" >/dev/null 2>&1
#in mdf
grep -rl "\`FDIS_NUM\`2\`C" /u/${ACCOUNT}/mttpl/xpos/|xargs sed -i "s/\`FDIS_NUM\`2\`C/\`FDIS_NUM\`4\`C/g" >/dev/null 2>&1
grep -rl "\`FITEM_DIS\`2\`C" /u/${ACCOUNT}/mttpl/xpos/|xargs sed -i "s/\`FITEM_DIS\`2\`C/\`FITEM_DIS\`4\`C/g" >/dev/null 2>&1
grep -rl "\`FCHK_DIS\`2\`C" /u/${ACCOUNT}/mttpl/xpos/|xargs sed -i "s/\`FCHK_DIS\`2\`C/\`FCHK_DIS\`4\`C/g" >/dev/null 2>&1
grep -rl "\`FPAYTYPE\`2\`N" /u/${ACCOUNT}/mttpl/xpos/|xargs sed -i "s/\`FPAYTYPE\`2\`N/\`FPAYTYPE\`4\`N/g" >/dev/null 2>&1
#if first column is fdis_num ,it will insert full path of pre-defined file in stdout
for x in `awk '{for(i=1;i<=NF;i++){ if($i=="fdis_num"){printf("%s\n",substr($2,1))} } }' ${LOCAL}/conf/repl_list.txt`
{
#use awk to separate every element in full path by separator defined is "/"
	cd /u/${ACCOUNT}/`echo $x|awk -F / '{print $1}'`/`echo $x|awk -F / '{print $2}'`/
# $3 is  file name in full path
#batch_tool is useful tool to process some dbf task but it only can execute dbf files in current directory,so you need to cd to directory,that the file exsits
	${LOCAL}/bin/batch_tool `echo $x|awk -F / '{print $3}'` /MODIFY:${LOCAL}/bin/fdis_num.txt
#modify will add some column in dbf defined in a txt
#filter will select record that FDIS_NUM is not empty ,in batch_tool comparison symbol <> is changed to {} ,if you want to know more info ,just google batch_tool commandline in serach engine
#FDIS_NUM~<space><space> means the programe will only select record include <space><space> in latter,cuz FDIS_NUM extend to C 4,the original record will
#change to [digit][digit]<space><space> format or [digit]<point><zero> format so if you want the record to be compromised with new standard, you need add two <zero>
#in the head of field,once you change the record in buffer stream.dont forget update it to the dbf file.
#data ckdistp itdistp hmc_disc covdisc2 sales chkdisc itemtrs itemdisc 
	${LOCAL}/bin/batch_tool `echo $x|awk -F / '{print $3}'` /filter:FDIS_NUM{}' ' "/filter:FDIS_NUM~  ;FDIS_NUM~.0" "/field:FDIS_NUM=\"00\"FDIS_NUM" /update
	cd ${LOCAL}
}
for x in `awk '{for(i=1;i<=NF;i++){ if($i=="fchk_dis"){printf("%s\n",substr($2,1))} } }' ${LOCAL}/conf/repl_list.txt`
{
	cd /u/${ACCOUNT}/`echo $x|awk -F / '{print $1}'`/`echo $x|awk -F / '{print $2}'`/
#date member roompkg
	${LOCAL}/bin/batch_tool `echo $x|awk -F / '{print $3}'` /MODIFY:${LOCAL}/bin/fchk_dis.txt
	${LOCAL}/bin/batch_tool `echo $x|awk -F / '{print $3}'` /filter:FCHK_DIS{}' ' "/filter:FCHK_DIS~  ;FCHK_DIS~.0" "/field:FCHK_DIS=\"00\"FCHK_DIS" /update
	${LOCAL}/bin/batch_tool `echo $x|awk -F / '{print $3}'` /filter:FITEM_DIS{}' ' "/filter:FITEM_DIS~  ;FITEM_DIS~.0" "/field:FITEM_DIS=\"00\"FITEM_DIS" /update
	cd ${LOCAL}
}
for x in `awk '{for(i=1;i<=NF;i++){ if($i=="fdis_type"){printf("%s\n",substr($2,1))} } }' ${LOCAL}/conf/repl_list.txt`
{
	cd /u/${ACCOUNT}/`echo $x|awk -F / '{print $1}'`/`echo $x|awk -F / '{print $2}'`/
#sales ckheader
	${LOCAL}/bin/batch_tool `echo $x|awk -F / '{print $3}'` /MODIFY:${LOCAL}/bin/fdis_type.txt
	cd ${LOCAL}
}
for x in `awk '{for(i=1;i<=NF;i++){ if($i=="fpayment"){printf("%s\n",substr($2,1))} } }' ${LOCAL}/conf/repl_list.txt`
{
	cd /u/${ACCOUNT}/`echo $x|awk -F / '{print $1}'`/`echo $x|awk -F / '{print $2}'`/
#sales payment
	${LOCAL}/bin/batch_tool `echo $x|awk -F / '{print $3}'` /MODIFY:${LOCAL}/bin/fpayment.txt
	cd ${LOCAL}
}
for x in `awk '{for(i=1;i<=NF;i++){ if($i=="fpaytype"){printf("%s\n",substr($2,1))} } }' ${LOCAL}/conf/repl_list.txt`
{
	cd /u/${ACCOUNT}/`echo $x|awk -F / '{print $1}'`/`echo $x|awk -F / '{print $2}'`/
# date creditrul sales pay_mon payhist
	${LOCAL}/bin/batch_tool `echo $x|awk -F / '{print $3}'` /MODIFY:${LOCAL}/bin/fpaytype.txt
	cd ${LOCAL}
}
for x in `awk '{for(i=1;i<=NF;i++){ if($i=="fpos_ptype"){printf("%s\n",substr($2,1))} } }' ${LOCAL}/conf/repl_list.txt`
{
	cd /u/${ACCOUNT}/`echo $x|awk -F / '{print $1}'`/`echo $x|awk -F / '{print $2}'`/
#data spcclose
	${LOCAL}/bin/batch_tool `echo $x|awk -F / '{print $3}'` /MODIFY:${LOCAL}/bin/fpos_ptype.txt
	${LOCAL}/bin/batch_tool `echo $x|awk -F / '{print $3}'` /filter:FPOS_PTYPE{}' ' "/filter:FPOS_PTYPE~  ;FPOS_PTYPE~.0" "/field:FPOS_PTYPE=\"00\"FPOS_PTYPE" /update
	cd ${LOCAL}
}
for x in `awk '{for(i=1;i<=NF;i++){ if($i=="paytype"){printf("%s\n",substr($2,1))} } }' ${LOCAL}/conf/repl_list.txt`
{
	cd /u/${ACCOUNT}/`echo $x|awk -F / '{print $1}'`/`echo $x|awk -F / '{print $2}'`/
#data paytype
	${LOCAL}/bin/batch_tool `echo $x|awk -F / '{print $3}'` /MODIFY:${LOCAL}/bin/paytype.txt
	cd ${LOCAL}
}
cd /u/${ACCOUNT}/sales
#this command will separate displayed table to a matrix and only grasp the month info and remove duplicate month directory such like 201508back
#use batch_tool to execute history sales data,will cost a lot of time,3.3GB sales will costs six minutes at least,so cordinate your update procedure according ot
#the sales size.
#you dont want to concern about if there is one or two database is already support 4 digits ,the programme will pass the 4 digits database automatically
MONTH_LIST=`lsdir | awk '{printf("%s\n",substr($9,1,6))}' | sort -u`
for MONTH in ${MONTH_LIST}
do
	cd /u/${ACCOUNT}/sales/${MONTH}
	if [ -f /u/"${ACCOUNT}"/sales/"${MONTH}"/chkdisc.dbf ]
	then
		${LOCAL}/bin/batch_tool chkdisc.dbf /MODIFY:${LOCAL}/bin/fdis_num.txt
		${LOCAL}/bin/batch_tool chkdisc.dbf /filter:FDIS_NUM{}' ' "/filter:FDIS_NUM~  ;FDIS_NUM~.0" "/field:FDIS_NUM=\"00\"FDIS_NUM" /update
	else
		cp -p /u/${ACCOUNT}/sales/xpos/chkdisc.dbf /u/${ACCOUNT}/sales/${MONTH}/
	fi
	${LOCAL}/bin/batch_tool itemdisc.dbf /MODIFY:${LOCAL}/bin/fdis_num.txt
	${LOCAL}/bin/batch_tool itemtrs.dbf /MODIFY:${LOCAL}/bin/fdis_num.txt
	${LOCAL}/bin/batch_tool ckheader.dbf /MODIFY:${LOCAL}/bin/fdis_type.txt
	${LOCAL}/bin/batch_tool payment.dbf /MODIFY:${LOCAL}/bin/fpayment.txt
	${LOCAL}/bin/batch_tool itemdisc.dbf /filter:FDIS_NUM{}' ' "/filter:FDIS_NUM~  ;FDIS_NUM~.0" "/field:FDIS_NUM=\"00\"FDIS_NUM" /update
	${LOCAL}/bin/batch_tool itemtrs.dbf /filter:FDIS_NUM{}' ' "/filter:FDIS_NUM~  ;FDIS_NUM~.0" "/field:FDIS_NUM=\"00\"FDIS_NUM" /update
	${LOCAL}/bin/batch_tool ckheader.dbf /filter:FDIS_TYPE{}' ' "/filter:FDIS_TYPE~  ;FDIS_TYPE~.0" "/field:FDIS_TYPE=\"00\"FDIS_TYPE" /update
done
#execute daily
cd /u/${ACCOUNT}/daily
if [[ -f /u/${ACCOUNT}/daily/ck_hd00.dbf && ! -f /u/${ACCOUNT}/daily_xpos_${DATE}.zip ]]
then
	zip -r /u/${ACCOUNT}/daily_xpos_${DATE}.zip /u/${ACCOUNT}/daily/
	${LOCAL}/bin/batch_tool itmdis00.dbf /MODIFY:${LOCAL}/bin/fdis_num.txt
	${LOCAL}/bin/batch_tool itmtrs00.dbf /MODIFY:${LOCAL}/bin/fdis_num.txt
	${LOCAL}/bin/batch_tool ck_hd00.dbf /MODIFY:${LOCAL}/bin/fdis_type.txt
	${LOCAL}/bin/batch_tool pay00.dbf /MODIFY:${LOCAL}/bin/fpayment.txt
	${LOCAL}/bin/batch_tool itmdis00.dbf /filter:FDIS_NUM{}' ' "/filter:FDIS_NUM~  ;FDIS_NUM~.0" "/field:FDIS_NUM=\"00\"FDIS_NUM" /update
	${LOCAL}/bin/batch_tool itmtrs00.dbf /filter:FDIS_NUM{}' ' "/filter:FDIS_NUM~  ;FDIS_NUM~.0" "/field:FDIS_NUM=\"00\"FDIS_NUM" /update
	${LOCAL}/bin/batch_tool ck_hd00.dbf /filter:FDIS_TYPE{}' ' "/filter:FDIS_TYPE~  ;FDIS_TYPE~.0" "/field:FDIS_TYPE=\"00\"FDIS_TYPE" /update
	if [ -f /u/"${ACCOUNT}"/daily/chkdis00.dbf ]
	then
		${LOCAL}/bin/batch_tool chkdis00.dbf /MODIFY:${LOCAL}/bin/fdis_num.txt
		${LOCAL}/bin/batch_tool chkdis00.dbf /filter:FDIS_NUM{}' ' "/filter:FDIS_NUM~  ;FDIS_NUM~.0" "/field:FDIS_NUM=\"00\"FDIS_NUM" /update
	else
		cp -p /u/${ACCOUNT}/sales/xpos/chkdisc.dbf /u/${ACCOUNT}/daily/chkdis00.dbf
		cp -p /u/${ACCOUNT}/daily/itmdis00.cdx /u/${ACCOUNT}/daily/chkdis00.cdx
	fi
fi
#will read gm_over.inf to collect info about how many inf file used by current account,and copy files to tempdir
cd ${LOCAL}
sed -n '/^[^#].*/p' /u/${ACCOUNT}/data/gm_over.inf > tmp
sed -i 's/[[:space:]]//g' tmp
sed -i 's/^[^#].*gmate.inf.*/#&/g' tmp
for x in `sed -n '/\[gmate\]/,/\[ckperiod\]/{/^[^#].*inf/p}' tmp|awk -F = '{print $2}'|sort -u` gmate.inf back_detail.inf back_summary.inf
do
	cp -p /u/${ACCOUNT}/data/$x /u/${ACCOUNT}/data/xpos/$x
	
#	sed -i 's/^support_lev2.*/#&/g' /u/${ACCOUNT}/data/xpos/$x
#	sed -i 's/^support_multi_chkdisc.*/#&/g' /u/${ACCOUNT}/data/xpos/$x
#	sed -i 's/^ckfmt_section_type.*/#&/g' /u/${ACCOUNT}/data/xpos/$x
#	sed -i 's/^support_10_othref.*/#&/g' /u/${ACCOUNT}/data/xpos/$x
#	sed -i 's/^void_code_for_void_payment.*/#&/g' /u/${ACCOUNT}/data/xpos/$x
#	sed -i 's/^support_kill_station_by_unlock_table_option.*/#&/g' /u/${ACCOUNT}/data/xpos/$x
	for i in `awk '/\[pattern1\]/{while(getline)if($0!~/\[pattern1\]/)print;else exit}' ${LOCAL}/conf/setup.inf|awk -F= '{print $1}'|sed 's/^#//g'`
	do
		sed -i "/${i}/d" /u/${ACCOUNT}/data/xpos/$x
	done
	for j in `awk '/\[pattern2\]/{while(getline)if($0!~/\[pattern2\]/)print;else exit}' ${LOCAL}/conf/setup.inf|awk -F= '{print $1}'`
	do
		sed -i "/${j}/d" /u/${ACCOUNT}/data/xpos/$x
	done
	awk '/\[pattern1\]/{while(getline)if($0!~/\[pattern1\]/)print;else exit}' ${LOCAL}/conf/setup.inf > temp
	sed -i '/\[gmate\]/r temp' /u/${ACCOUNT}/data/xpos/$x
	rm temp
done
rm tmp
#already copy gmate.inf to xpos directory,avoid gmate.inf occur in gm_over.inf leads append pattern1 twice
#cp -p /u/${ACCOUNT}/data/gmate.inf /u/${ACCOUNT}/data/xpos/gmate.inf
#insert diffrent pattern to specified files ,the insert place is just some special point that is unique,such as [gmate],[pda],[setup1],etc.
#awk '/\[pattern1\]/{while(getline)if($0!~/\[pattern1\]/)print;else exit}' ${LOCAL}/conf/setup.inf > temp
#sed -i '/\[gmate\]/r temp' /u/${ACCOUNT}/data/xpos/gmate.inf

cp -p /u/${ACCOUNT}/data/xpos/gmate.inf /u/${ACCOUNT}/data/xpos/gmate_pgs.inf
#sed -i '/\[gmate\]/r temp' /u/${ACCOUNT}/data/xpos/gmate.inf
awk '/\[pattern2\]/{while(getline)if($0!~/\[pattern2\]/)print;else exit}' ${LOCAL}/conf/setup.inf > temp
sed -i '/\[pda\]/r temp' /u/${ACCOUNT}/data/xpos/gmate_pgs.inf

#sed -n '/^\[rounding\]/,/^$/{p}' /u/${ACCOUNT}/data/xpos/gmate.inf > temp
#sed -i '$r temp' /u/${ACCOUNT}/data/xpos/gmate_pgs.inf
#awk '/\[pattern3\]/{while(getline)if($0!~/\[pattern3\]/)print;else exit}' ${LOCAL}/conf/setup.inf|awk "{if(NR <= ${WS} && NR >= $((${START}+1))){print}}" > temp
#sed -i '$r temp' /u/${ACCOUNT}/data/xpos/gmate_pgs.inf

awk '/\[pattern4\]/{while(getline)if($0!~/\[pattern4\]/)print;else exit}' ${LOCAL}/conf/setup.inf > temp
sed -i $'/\[setup1\]/{e cat temp\n}' /u/${ACCOUNT}/data/xpos/ckfmt.inf
awk '/\[pattern5\]/{while(getline)if($0!~/\[pattern5\]/)print;else exit}' ${LOCAL}/conf/setup.inf > temp
sed -i '$e cat temp' /u/${ACCOUNT}/data/xpos/ckfmt.inf
sed -i 's/% */ге/g' /u/${ACCOUNT}/data/xpos/ckfmt.inf

#awk '/\[pattern7\]/{while(getline)if($0!~/\[pattern7\]/)print;else exit}' ${LOCAL}/conf/setup.inf > temp
#sed -i '/\[gmate\]/r temp' /u/${ACCOUNT}/data/xpos/gm_over.inf

#if [ ! -f /u/${ACCOUNT}/tty/tty.inf.xpos ]
#then
#cp -p /u/${ACCOUNT}/tty/tty.inf /u/${ACCOUNT}/tty/tty.inf.xpos
#awk '/\[pattern6\]/{while(getline)if($0!~/\[pattern6\]/)print;else exit}' ${LOCAL}/conf/setup.inf > temp
#sed -i '/\[main\]/r temp' /u/${ACCOUNT}/tty/tty.inf
#fi
if [ "`sed -n '/disc_grp/p' /u/${ACCOUNT}/data/mntain.inf`" == "" ] && [ "`sed -n '/pay_grp/p' /u/${ACCOUNT}/data/mntain.inf`" == "" ]
then
	awk '/\[pattern8\]/{while(getline)if($0!~/\[pattern8\]/)print;else exit}' ${LOCAL}/conf/setup.inf > temp
	sed -i $'/\[menu maintenance\]/{e cat temp\n}' /u/${ACCOUNT}/data/xpos/mntain.inf
fi
#this is hardest part in this script sed will look for crossout.inf to search some cross account configuration
#and comments every line read data in differnt account .in crossout.inf,and recalculate the outlet = current outlet in same account

sed -i ':n;/\nacc.*[^'${ACCOUNT}']$/,/^$/{s/.*/#&/;s/.*\n/&#/;tm;};/.*\n.*/!{N;bn};P;D;:m;p;d' /u/${ACCOUNT}/data/xpos/crossout.inf

#:n
#/\nacc.*[^'${ACCOUNT}']$/,/^$/ when met first expression excute every line till the end and add # before first character per line
#{
#s/.*/#&/
#s/.*\n/&#/
#tm t short for test if true jump to m
#}
#/.*\n.*/
#! if false execute command in bracket
#{
#N append a new line to buffer ${line1}\n${line2}\n
#bn b short for branch to n
#}
#P print first line till \n
#D delete from starting character to first \n and jump to first line to execute
#:m
#p print whole buffer
#d delete all

#get every available outlet number from [] bracket and replace old parameter "outlet = outletid1,outletid2,outletid3"
for x in `sed -n 's/^\[\([^a-zA-Z].*\)\]/\1/p' /u/${ACCOUNT}/data/xpos/crossout.inf`
do
	str+="$x,"
done
sed -i "/^outlet/c outlet = $str" /u/${ACCOUNT}/data/xpos/crossout.inf
sed -i 's/\(^outlet.*\),$/\1/' /u/${ACCOUNT}/data/xpos/crossout.inf

#echo "[name_list]" > ${LOCAL}/bin/reindex.inf
#awk '/\[pattern10\]/{while(getline)if($0!~/\[pattern10\]/)print;else exit}' ${LOCAL}/conf/setup.inf > temp
#n=`grep -n "name_list" ${LOCAL}/bin/reindex.inf|awk -F: '{if(NR==1){print $1}}'`
#sed -i ''$n' r temp' ${LOCAL}/bin/reindex.inf
#awk '/\[pattern9\]/{while(getline)if($0!~/\[pattern9\]/)print;else exit}' ${LOCAL}/conf/setup.inf > temp
#sed -i ''$n' r temp' ${LOCAL}/bin/reindex.inf
##sed -i '$e cat temp' ${LOCAL}/bin/reindex.inf
#${LOCAL}/bin/reindex -s ${LOCAL}/bin/reindex.inf
#rm ${LOCAL}/bin/reindex.inf
#rm temp

#this will add pay_seq pay_grp disc_seq disc_grp reindex info to /usr/gm/global/reindex.inf,and execute reindex to reindex the updated account
if [ ! -f /usr/gm/global/reindex.inf.xpos ] && [ "`sed -n '/pseq_info/p' /usr/gm/global/reindex.inf`" == "" ]
then
	cp -p /usr/gm/global/reindex.inf /usr/gm/global/reindex.inf.xpos
	awk '/\[pattern9\]/{while(getline)if($0!~/\[pattern9\]/)print;else exit}' ${LOCAL}/conf/setup.inf > temp
	n=`grep -n "name_list" /usr/gm/global/reindex.inf|awk -F: '{if(NR==1){print $1}}'`
	sed -i ''$n' r temp' /usr/gm/global/reindex.inf
	awk '/\[pattern10\]/{while(getline)if($0!~/\[pattern10\]/)print;else exit}' ${LOCAL}/conf/setup.inf > temp
	sed -i '$e cat temp' /usr/gm/global/reindex.inf
fi
rm temp

cp -p /u/${ACCOUNT}/data/xpos/* /u/${ACCOUNT}/data/
cp -p /u/${ACCOUNT}/mttpl/xpos/* /u/${ACCOUNT}/mttpl/
cp -p /u/${ACCOUNT}/sales/xpos/* /u/${ACCOUNT}/sales/

cd /u/${ACCOUNT}
${LOCAL}/bin/reindex -s /usr/gm/global/reindex.inf -e
chmod -R 777 /u/${ACCOUNT}
chown -R ${ACCOUNT}:${ACCOUNT} /u/${ACCOUNT}
cd ${LOCAL}
${LOCAL}/gm_script/activate_prog.s
#all right copy the updated files to the live account,and reindex,then,the system will reuse after that.
echo "Job Done! there is nothing you can do for now,feel free to have a coffee!"
echo "using this script at your own risk,i cant promise if it can work in any situation"
echo "Linyishuai wrote in 12252015"

#else
#cat /u/${ACCOUNT}/xpos_installed
#fi
