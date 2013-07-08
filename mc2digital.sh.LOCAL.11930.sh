#!/bin/bash

target="/home/$USER/m/audio/ktl_arkiv/"
audiodev="hw:2,0"
codefile=${target}lama_codes.txt

place="KTL"
correct="y"
newentry="y"
allsides="y"
cassette=1

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
		


	read -p "Enter subject and press [ENTER]: " -ei "$subject" subject

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

	echo "Place:                $place"
	echo "Name of Lama:         $name (${fullName})"
	echo "Subject:              $subject"
	echo "Number of cassettes:  $cassCnt"
	echo "Sides to be recorded: $sideCnt"
	echo "Year:                 $year"
	echo "Month:                $month"
	echo "Day:                  $day"
	read -p "Are values correct? [y/N]: " final
	final=${final:-n}
	if [ "$final" == "y" ] || [ "$final" == "Y" ]; then
		break
	fi
done

cd $target
dir="${name}_${place}_${year}-${month}-${day}_${subject}"

if [[ ! -d $dir ]]; then
	mkdir $dir
fi

cd $dir

echo "Rewind the cassette tape!"
read -p "Press [ENTER] when ready .."

for (( i=1; i<=$sideCnt; i++ ))
do
	filename="${name}_${place}_${year}-${month}-${day}_${subject}-${i}of${sideCnt}.wav"

	#AUDIODEV=$audiodev rec "$filename" silence 1 0.1 1% 1 10.0 1%
	AUDIODEV=$audiodev rec -r 44100 "$filename" silence 1 0.1 0.1% 1 3.0 0.1%
	#ffmpeg -loglevel panic -y -i "$filename" -metadata title="$subject" \
		#-metadata artist="$fullName" \
		#-metadata creation_time="${year}-${month}-${day}" \
		#-metadata track="${i}/${sideCnt}" \
		#-metadata genre="Dharma" \
		#-codec copy "$filename"

		if [[ $((i % 2)) == 0 ]]; then
			msg="Change cassette, !!!### REWIND ###!!! and press [ENTER] when ready"
			side="B"
			let cassette++
		else
			msg="Turn side and press [ENTER] when ready"
			side="A"
		fi

		echo "Done with cassette ${cassette}, side $side"
		notify-send "Done with cassette ${cassette}, side $side"

		if [ $i -ne $sideCnt ]; then
			read -p "$msg"
		fi
done

cd ..
