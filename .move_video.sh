#!/bin/bash
# v1.0 vdrserver

#VDR Videos zusammenfuehren, in /nfs/videos verschiebe und ggf loeschenn

#nur einmal ausfuehren!
[ $(pidof -x $(basename $0) | wc -w) -gt 2 ] && exit 0

#logger -t MOVEVIDEO "Suche nach VDR Aufnahmen zum verschieben"
sourceDir=/vdrvideo00
destDir=/nfs/videos

sourceVideo="$(find $sourceDir -type f -name .move)"

for video in $(echo "$sourceVideo" | sed -e 's/[.]move//g' | tr '\n' ' '); do
	#videoname
	videoName=$(cat $video/info | grep ^"T" | sed -e 's/^T //' -e 's/://g' | tr ' ' '.')
	if [ "x$videoName" == "x" ]; then
		videoName=$(dirname $video)
		videoName=$(basename $videoName)
	fi

	if [ -e "$video/00001.ts" ]; then
		#ts File
		typ=$(ffmpeg -i "$video"/00001.ts 2>&1 | grep Stream | grep Video | sed -e 's/.*Video://' | awk '{ print $1 }')
		[ "x$typ" == "xh264" ] && container=avi
		[ "x$typ" == "xmpeg2video" ] && container=mpg
		[ "x$container" == "x" ] && exit 1
		catLine=$(ls $video/* | grep [0-9][0-9][0-9][0-9][0-9].ts | sort | tr '\n' ' ')
		logger -t MOVEVIDEO "kopiere VDR-Aufnahme nach '${videoName}.$container' ($(echo $catLine | wc -w) Files)"
		cat $catLine > $destDir/${videoName}.$container
		catResult=$?
		[ $catResult == "0" ] && logger -t MOVEVIDEO "${videoName}.$container kopiert"
	fi
	#erase
	if [[ "x$catResult" == "x0" && "x$(cat $video/.move)" == "xmv" ]]; then
		logger -t MOVEVIDEO "loesche: $video"
		rm -r $video
		rmdir --ignore-fail-on-non-empty -p $(dirname $video)
		touch $destDir/.update
	fi
	[[ "x$catResult" == "x0" && -e $video/.move ]] && rm $video/.move
	catResult=""
done
#logger -t MOVEVIDEO "Suche beendet"
exit 0
