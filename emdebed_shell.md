
```c
#!/bin/sh

dir_name=$1
echo $dir_name

duration=$2

total_frames=`expr $2 \* 10` 

echo $total_frames

cd  $dir_name

image_sum=`find . -type f  -name 'img*' | grep -E '.jpg|.bmp|.png' | wc -l`
echo $image_sum

cycle_num=`expr $total_frames / $image_sum + 1`
echo $cycle_num

echo "start !!!"	
image_cnt=0
while [  $image_cnt -lt $image_sum ]; do 

	echo $image_cnt	
	count=$(printf %03d $image_cnt)
	echo  $count

	image_name=img"$count".jpg
	#find . -type f  -name "$image_name"
	echo $image_name
	ls -alh "$image_name"
	if [ $? -eq 0 ]; then
		cnt=0
		while [  $cnt -lt $cycle_num ]; do 	
			echo "cycle_num $cycle_num"
			
			cnt=`expr $cnt + 1 `
		done
		#echo $image_name
	fi
	image_cnt=`expr $image_cnt + 1 `

done

echo "end !!!"	
		
```

```c
# check disk partition 
for dev_name  in ` ls  /dev/sd* | cut -d / -f 3 | grep sd[a-z]$ `
do
cnt=0;
 ls  /dev/sd* | cut -d / -f 3 | grep ${dev_name}[1-9] > /dev/null
 if [  $? -eq 0 ]; then
	let "cnt=$cnt + 1"
	#echo -e $dev_name is ok  $cnt  "\r\n"
else
	echo $dev_name is not ok !!!
	cd /opt/app
	./format_disk.sh ${dev_name} "ntfs"  &
	cd -
 fi

done

```



