mc2digital
==========

Bash script for recording audio from music cassettes to wav files

This script is intended to be used for digitizing a vast archive of old Dharma teachings recorded on music cassettes. Most recordings were done at Karma Tashi Ling buddhist center in Oslo, Norway. The oldest recordings date back to 1972.

Dates in filenames are stored in the ISO 8601 standard.

Dependencies: GNU bash 4.x, sox, KDE 4.5 or higher (for notify-send), ALSA (for aplay)

This script also notifies a pebble smart watch, through the use of the pushbullet service and the Pebble Notifier app for Android. The script searches for ~/.mc2digipush containing two lines: The device number and the api key. Both retrieved from the Pushbullet service.

Tested on: Slackware 14 x86_64, KDE 4.10.5, zsh 5.0.0 and GNU bash version 4.2.37(2)-release, alsa v.1.0.26
