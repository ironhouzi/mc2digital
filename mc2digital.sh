#############################################################
# Depends on the file .mc2digipush in ~/ which contains:    #
# <device id>                                               #
# <api key>                                                 #
#############################################################
#!/bin/bash

#################
### Declare paths
#################
target="/home/$USER/m/audio/ktl_arkiv"
sshbckp="ktlmedia:/media/raid/audio/"
codefile=/home/$USER/.lama_codes.txt
persistfile=/home/$USER/.mc2digitalval
apifile=/home/$USER/.mc2digipush
url="https://www.pushbullet.com/api/pushes"

#####################
### Declare variables
#####################
noapi=0

if [[ -f $apifile ]];then
    device=`head -1 $apifile`
    api=`tail -1 $apifile`
else
    noapi=1
fi

place="KTL"
correct="y"
newentry="y"
allsides="y"
sideStart="A"
sideEnd="A"
samesubj="y"
range=0
cassette=1
newsubj="and enter subject for next cassette"
dirTitle=""

###############################
### Configure alsa sound source
###############################
IFS=$'\n' hwlines=($(aplay -l | grep "^card*"))
init=0

if [[ -f $persistfile ]];then
    line=`head -1 $persistfile`
    nr=`tail -1 $persistfile`
    if [[ "${hwlines[$nr]}" == "$line" ]]; then
        hwdev=`echo "$line" | grep -o "device [0-9]" | grep -o "[0-9]"`
        hwcard=`echo "$line" | cut -d' ' -f2 | cut -d':' -f1`
        audiodev="hw:${hwcard},${hwdev}"
        init=1
    fi
fi
if [[ $init == 0 || ! -f $persistfile ]];then
    echo "Here are your audio devices:"
    i=0
    for l in ${!hwlines[*]}; do
        txt=`echo "${hwlines[$l]}" | cut -d' ' -f3-`
        printf "(%s) -> %s\n" $i $txt
        i=$(( i+1 ))
    done
    printf "\n"
    read -p "Select device used for the recording: " -ei "$seldev" seldev

    echo "${hwlines[${seldev}]}" > $persistfile
    echo "$seldev" >> $persistfile
    hwdev=`echo "${hwlines[${seldev}]}" | grep -o "device [0-9]" | grep -o "[0-9]"`
    hwcard=`echo "${hwlines[${seldev}]}" | cut -d' ' -f2 | cut -d':' -f1`
    audiodev="hw:${hwcard},${hwdev}"
fi

################################
### Gather recording information
################################
while true; do
	read -p "Enter place of recording and press [ENTER]: " -ei "$place" place

	echo -n "Enter three letter lama code and press [ENTER] (? for help):"

	while true; do
		read -p " " -ei "$name" name

		if [ ${#name} -eq 3 ]; then
			break
		elif [ "$name" == "?" ]; then
			echo "Examples:"
			cat $codefile
		else
			echo "Input must be a three letter code. Hit '?' for help"
		fi
	done

	result=`grep "$name" $codefile`

	if [ ${#result} != 0 ]; then
		fullName=`echo "$result" | cut -c 6-`
	else
		while true; do
			read -p "Code not found. Make new entry? [Y/n] ('n' will exit)" -ei "$newentry" newentry

			if [ "$newentry" == "n" ]; then
				exit
			elif [ "$newentry" == "y" ]; then
				while true; do
					read -p "Enter Full three word name of lama mapped to code: " -ei "$fullName" fullName
					read -p "Is $fullName correct? [Y/n] " -ei $correct correct

					if [ "$correct" == "y" ]; then
						echo "${name}. $fullName" >> $codefile
						break
					fi
				done
				break
			fi
		done
	fi

	read -p "All tapes have same subject? [Y/n]: " -ei "$samesubj" samesubj

	if [ "$samesubj" == "n" ];then
        read -p "Enter title for entire recording and press [ENTER]: " -ei "$dirTitle" dirTitle 
        read -p "Enter subject for first recording and press [ENTER]: " -ei "$subject" subject
    else
        read -p "Enter subject and press [ENTER]: " -ei "$subject" subject
        dirTitle="$subject"
	fi

	read -p "Enter number of cassettes for the recording session and press [ENTER]: " -ei "$cassCnt" cassCnt 

	sideCnt=$(( cassCnt * 2 ))

	read -p "All $sideCnt sides contain recordings? [Y/n]: " -ei "$allsides" allsides

	if [ "$allsides" == "y" ]; then
		subtract=0
	else
		subtract=1
		allsides="n"
	fi

	sideCnt=$(( sideCnt - subtract ))

	read -p "Record all tapes, or specific range? [0 means all tapes] " -ei "$range" range
	if [ $range -ne 0 ]; then
        while true; do
            read -p "First tape to record? [1 - ${cassCnt}]" -ei "$cassStart" cassStart

            if [[ $cassStart -lt 1 || $cassStart -gt cassCnt ]];then
                continue
            fi

            read -p "What side on tape $cassStart to record? [A/b] " -ei "$sideStart" sideStart

            if [[ $sideStart -eq "a" || $sideStart -eq "b" ]]; then
                break
            fi
        done

		if [ $sideStart == 'A' ]; then
			subtract=1
		else
			subtract=0
		fi
		startNr=$(( cassStart * 2 - subtract ))
		cassette=$cassStart

		read -p "Last tape to record? [press '0' = to record to the very end " -ei "$cassEnd" cassEnd
		if [ $cassEnd -eq 0 ]; then
			endNr=$sideCnt
		else
			read -p "What is the last side on tape $cassEnd to record? [A/b] " -ei "$sideEnd" sideStart
			if [ $sideEnd == 'A']; then
				subtract=1
			else
				subtract=0
			fi
			endNr=$(( cassEnd * 2 - subtract ))
		fi
	else
		startNr=1
		endNr=$sideCnt
	fi

	while true; do
		read -p "Enter year of recording and press [ENTER]: " -ei "$year" year

		if [ ${#year} -eq 4 ]; then
			break
		fi
		echo "Format of year must be _FOUR_ digits! Eg: 1972'"
	done

	read -p "Enter month of recording and press [ENTER]: " -ei "$month" month
	if [ ${#month} -eq 1 ]; then
		month="0"$month
	fi

	read -p "Enter day of recording and press [ENTER]: " -ei "$day" day
	if [ ${#day} -eq 1 ]; then
		day="0"$day
	fi

    ############################
    ### Verify data or try agian
    ############################

	echo "Place:                $place"
	echo "Name of Lama:         $name (${fullName})"
	echo "Subject:              $subject"
	echo "Title:                $dirTitle"
	echo "All tapes same subj.: $samesubj"
	echo "Number of cassettes:  $cassCnt"
	echo "Sides to be recorded: $sideCnt"
	echo "Year:                 $year"
	echo "Month:                $month"
	echo "Day:                  $day"
	echo "Range:                ${startNr}-${endNr}"
	read -p "Are values correct? [y/N]: " final
	final=${final:-n}
	if [ "$final" == "y" ] || [ "$final" == "Y" ]; then
		break
	fi
done


############################
### Create and move into dir
############################

cd "$target"
dirTitle=${dirTitle// /_}
dir="${name}_${place}_${year}-${month}-${day}_${dirTitle}"

if [[ ! -d "$dir" ]]; then
    echo "making dir: $dir"
	mkdir "$dir"
fi

cd "$dir"

echo "Rewind the cassette tape!"
read -p "Press [ENTER] when ready .."


########################
### Start recording loop
########################

for (( i=$startNr; i<=$endNr; i++ ))
do
    subject=${subject// /_}
	filename="${name}_${place}_${year}-${month}-${day}_`printf "%02d" ${i}`x`printf "%02d" ${sideCnt}`_${subject}.wav"

	AUDIODEV=$audiodev rec -r 44100 "$filename" silence 1 0.1 0.1% 1 3.0 0.1%

	if [[ $((i % 2)) == 0 ]]; then
		msg="Change cassette, !!!### REWIND ###!!! and press [ENTER] when ready"
		side="B"
	else
		msg="Turn side and press [ENTER] when ready"
		side="A"
	fi

    if [[ -f $apifile ]]; then
        curl --data "device_id=${device}&type=note&title=Recording done&body=Finished cassette ${cassette}, side ${side}" ${url} -u ${api}: &> /dev/null
    fi

	echo "Done with cassette ${cassette}, side $side"
	notify-send "Done with cassette ${cassette}, side $side"

	if [ "$side" == "B" ]; then
		let cassette++
	fi

	if [ $i -ne $sideCnt ]; then

		if [ "$samesubj" == "n" ]; then
			read -p "$msg ${newsubj}: " -ei "$subject" subject
		else
			read -p "$msg"
		fi

    elif [[ -f $apifile ]]; then
		curl --data "device_id=${device}&type=note&title=All done&body=Finished recording ${dir}" "$url" -u "${api}": &> /dev/null
	fi
done

cd ..

rsync -a "$target" "$sshbckp" &
