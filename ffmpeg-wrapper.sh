#!/bin/bash

rev="12.1"

_log() {
	echo "$(date '+%Y-%m-%d %H:%M:%S') - ${streamid} - $1" >> /tmp/ffmpeg.log
}

_log_para() {
	echo "$1" | fold -w 120 | sed "s/^.*$/$(date '+%Y-%m-%d %H:%M:%S') - ${streamid} -          = &/" >> /tmp/ffmpeg.log
}

_term() {
	rm /tmp/ffmpeg-${streamid}.stderr
	_log "*** KILLCHILD ***"
	kill -TERM "$childpid" 2>/dev/null
}

trap _term SIGTERM

arch=`uname -a | sed 's/.*synology_//' | cut -d '_' -f 1`
nas=`uname -a | sed 's/.*synology_//' | cut -d '_' -f 2`
pid=$$
paramvs=$@
stream="${@: -1}"
streamid="FFM$pid"
bin1=/var/packages/VideoStation/target/bin/ffmpeg.orig
bin2=/var/packages/ffmpeg/target/bin/ffmpeg
args=()

vcodec="KO"

while [[ $# -gt 0 ]]
do
case "$1" in
	-i)
		shift
		movie="$1"
		args+=("-i" "$1")
	;;
	-hwaccel)
		shift
		hwaccel="$1"
		args+=("-hwaccel" "$1")
	;;
	-scodec)
		shift
		scodec="$1"
		args+=("-scodec" "$1")
	;;
	-f)
		shift
		fcodec="$1"
		args+=("-f" "$1")
	;;
	-map)
		shift
		args+=("-map" "$1")
		idmap=`echo $1 | cut -d : -f 2`
		if [ "$vcodec" = "KO" ]; then
			vcodec=`/var/packages/ffmpeg/target/bin/ffprobe -v error -select_streams $idmap -show_entries stream=codec_name -of default=noprint_wrappers=1:nokey=1 "$movie" | head -n 1`
			vcodecprofile=`/var/packages/ffmpeg/target/bin/ffprobe -v error -select_streams $idmap -show_entries stream=profile -of default=noprint_wrappers=1:nokey=1 "$movie" | head -n 1`
		else
			acodec=`/var/packages/ffmpeg/target/bin/ffprobe -v error -select_streams $idmap -show_entries stream=codec_name -of default=noprint_wrappers=1:nokey=1 "$movie" | head -n 1`
		fi
	;;
	*)
		args+=("$1")
	;;
esac
shift
done

_log "*** PROCESS START REV $rev DS$nas ($arch) PID $pid ***"

_log "MOVIE    = $movie"

set -- "${args[@]}"

argsnew=()
args1sv=()
args2sv=()
args1vs=()
args2vs=()

while [[ $# -gt 0 ]]
do
case "$1" in
	-ss)
		shift
		argsnew+=("-ss" "$1")
		args1sv+=("-ss" "$1")
		args1sv+=("-noaccurate_seek")
		args1vs+=("-ss" "$1")
		args1vs+=("-noaccurate_seek")
		args2sv+=("-analyzeduration" "10000000")
		args2vs+=("-analyzeduration" "10000000")
	;;
	-i)
		shift
		argsnew+=("-i" "$1")
		args1sv+=("-i" "$1")
		args2sv+=("-i" "pipe:0" "-map" "0")
		args1vs+=("-i" "$1")
		args2vs+=("-i" "pipe:0" "-map" "0")
	;;
	-vf)
		shift
		if [ "$hwaccel" = "vaapi" ] && [ "$vcodecprofile" = "Main 10" ]; then
			scale_w=`echo "${1}" | sed -e 's/.*=w=//g' | sed -e 's/:h=.*//g'`
			scale_h=`echo "${1}" | sed -e 's/.*:h=//g'`
			if let ${scale_w} AND let ${scale_h}; then
				argsnew+=("-vf" "scale_vaapi=w=${scale_w}:h=${scale_h}:format=nv12,hwupload,setsar=sar=1")
			else
				argsnew+=("-vf" "scale_vaapi=format=nv12,hwupload,setsar=sar=1")
			fi
		else
			argsnew+=("-vf" "$1")
		fi
		args2sv+=("-vf" "$1")
		args1vs+=("-vf" "$1")
	;;
	-vb)
    		shift
		argsnew+=("-vb" "$1")
		args1sv+=("-vb" "$1")
		args2sv+=("-vb" "$1")
		args1vs+=("-vb" "$1")
		args2vs+=("-vb" "$1")
	;;
	-vcodec)
		shift
		argsnew+=("-vcodec" "$1")
		args1sv+=("-vcodec" "copy")
		args2sv+=("-vcodec" "$1")
		args1vs+=("-vcodec" "$1")
		args2vs+=("-vcodec" "copy")
	;;
	-acodec)
		shift
		if [ "$1" = "libfaac" ]; then
			argsnew+=("-acodec" "aac")
			args1sv+=("-acodec" "aac")
			args2vs+=("-acodec" "aac")
		else
			argsnew+=("-acodec" "$1")
			args1sv+=("-acodec" "$1")
			args2vs+=("-acodec" "$1")
		fi
		args2sv+=("-acodec" "copy")
		args1vs+=("-acodec" "copy")
	;;
	-ab)
		shift
		argsnew+=("-ab" "$1")
		args1sv+=("-ab" "$1")
		args2vs+=("-ab" "$1")
	;;
	-ac)
		shift
		argsnew+=("-ac" "$1")
		args1sv+=("-ac" "$1")
		args2vs+=("-ac" "$1")
	;;
	-f)
		shift
		argsnew+=("-f" "$1")
		args1sv+=("-f" "mpegts")
		args2sv+=("-f" "$1")
		args1vs+=("-f" "mpegts")
		args2vs+=("-f" "$1")
	;;
	-segment_format)
		shift
		argsnew+=("-segment_format" "$1")
		args2vs+=("-segment_format" "$1")
		args2sv+=("-segment_format" "$1")
	;;
	-segment_list_type)
		shift
		argsnew+=("-segment_list_type" "$1")
		args2vs+=("-segment_list_type" "$1")
		args2sv+=("-segment_list_type" "$1")
	;;
	-hls_seek_time)
		shift
		argsnew+=("-hls_seek_time" "$1")
		args2vs+=("-hls_seek_time" "$1")
		args2sv+=("-hls_seek_time" "$1")
	;;
	-segment_time)
		shift
		argsnew+=("-segment_time" "$1")
		args2vs+=("-segment_time" "$1")
		args2sv+=("-segment_time" "$1")
	;;
	-segment_time_delta)
		shift
		argsnew+=("-segment_time_delta" "$1")
		args2vs+=("-segment_time_delta" "$1")
		args2sv+=("-segment_time_delta" "$1")
	;;
	-segment_start_number)
		shift
		argsnew+=("-segment_start_number" "$1")
		args2vs+=("-segment_start_number" "$1")
		args2sv+=("-segment_start_number" "$1")
	;;
	-individual_header_trailer)
		shift
		argsnew+=("-individual_header_trailer" "$1")
		args2vs+=("-individual_header_trailer" "$1")
		args2sv+=("-individual_header_trailer" "$1")
	;;
	-avoid_negative_ts)
		shift
		argsnew+=("-avoid_negative_ts" "$1")
		args2vs+=("-avoid_negative_ts" "$1")
		args2sv+=("-avoid_negative_ts" "$1")
	;;
	-break_non_keyframes)
		shift
		argsnew+=("-break_non_keyframes" "$1")
		args2vs+=("-break_non_keyframes" "$1")
		args2sv+=("-break_non_keyframes" "$1")
	;;
	-max_muxing_queue_size)
		shift
		args2vs+=("-max_muxing_queue_size" "$1")
		args2sv+=("-max_muxing_queue_size" "$1")
	;;
	-map)
		shift
		argsnew+=("-map" "$1")
		args1sv+=("-map" "$1")
		args1vs+=("-map" "$1")
	;;
	*)
		argsnew+=("$1")
		if [ "$stream" = "$1" ]; then
			args1sv+=("-bufsize" "1024k" "pipe:1")
			args2sv+=("$1")
			args1vs+=("-bufsize" "1024k" "pipe:1")
			args2vs+=("$1")
		else
			args2sv+=("$1")
			args1vs+=("$1")
		fi
	;;
esac
shift
done

sed -i -e "s/{\"PID\":${pid},\"hardware_transcode\":true,/{\"PID\":${pid},\"hardware_transcode\":false,/" /tmp/VideoStation/enabled

startexectime=`date +%s`

if [ "$scodec" = "subrip" ]; then

	_log "FFMPEG   = $bin1"
	_log "CODEC    = $scodec"
	_log "PARAMVS  ="
	_log_para "$paramvs"

	$bin1 "${args[@]}" 2> /tmp/ffmpeg-${streamid}.stderr &

elif [ "$fcodec" = "mjpeg" ]; then

	_log "FFMPEG   = $bin1"
	_log "CODEC    = $fcodec"
	_log "PARAMVS  ="
	_log_para "$paramvs"

	$bin1 "${args[@]}" 2> /tmp/ffmpeg-${streamid}.stderr &

else

	_log "VCODEC   = $vcodec ($vcodecprofile)"
	_log "ACODEC   = $acodec"
	_log "PARAMVS  ="
	_log_para "$paramvs"
	_log "MODE     = ORIG"
	_log "FFMPEG   = $bin1"
	_log "PARAMWP  ="
	param1=${argsnew[@]}
	_log_para "$param1"

	$bin1 "${argsnew[@]}" 2> /tmp/ffmpeg-${streamid}.stderr &

fi

childpid=$!
_log "CHILDPID = $childpid"
wait $childpid

if grep "Conversion failed!" /tmp/ffmpeg-${streamid}.stderr || grep "not found for input stream" /tmp/ffmpeg-${streamid}.stderr || grep "Error opening filters!" /tmp/ffmpeg-${streamid}.stderr || grep "Unrecognized option" /tmp/ffmpeg-${streamid}.stderr || grep "Invalid data found when processing input" /tmp/ffmpeg-${streamid}.stderr; then

	_log "*** CHILD END ***"
	startexectime=`date +%s`
	_log "STDOUT   ="
	_log_para "`tail -n 15 /tmp/ffmpeg-${streamid}.stderr`"
	_log "MODE     = PIPE V_ORIG-A_WRAP"
	_log "FFMPEG1  = $bin1"
	_log "FFMPEG2  = $bin2"
	_log "PARAM1   ="
	param1=${args1vs[@]}
	_log_para "$param1"
	_log "PARAM2   ="
	param2=${args2vs[@]}
	_log_para "$param2"

	$bin1 "${args1vs[@]}" | $bin2 "${args2vs[@]}" 2> /tmp/ffmpeg-${streamid}.stderr &

	childpid=$!
	_log "CHILDPID = $childpid"
	wait $childpid

fi

if grep "Conversion failed!" /tmp/ffmpeg-${streamid}.stderr || grep "not found for input stream" /tmp/ffmpeg-${streamid}.stderr || grep "Error opening filters!" /tmp/ffmpeg-${streamid}.stderr || grep "Unrecognized option" /tmp/ffmpeg-${streamid}.stderr || grep "Invalid data found when processing input" /tmp/ffmpeg-${streamid}.stderr; then

	_log "*** CHILD END ***"
	startexectime=`date +%s`
	_log "STDOUT   ="
	_log_para "`tail -n 15 /tmp/ffmpeg-${streamid}.stderr`"
	_log "MODE     = PIPE V_WRAP-A_ORIG"
	_log "FFMPEG1  = $bin2"
	_log "FFMPEG2  = $bin1"
	_log "PARAM1   ="
	param1=${args1sv[@]}
	_log_para "$param1"
	_log "PARAM2   ="
	param2=${args2sv[@]}
	_log_para "$param2"

	$bin2 "${args1sv[@]}" | $bin1 "${args2sv[@]}" 2> /tmp/ffmpeg-${streamid}.stderr &

	childpid=$!
	_log "CHILDPID = $childpid"
	wait $childpid

fi

if grep "Conversion failed!" /tmp/ffmpeg-${streamid}.stderr || grep "not found for input stream" /tmp/ffmpeg-${streamid}.stderr || grep "Error opening filters!" /tmp/ffmpeg-${streamid}.stderr || grep "Unrecognized option" /tmp/ffmpeg-${streamid}.stderr || grep "Invalid data found when processing input" /tmp/ffmpeg-${streamid}.stderr; then

	_log "*** CHILD END ***"
	startexectime=`date +%s`
	_log "STDOUT   ="
	_log_para "`tail -n 15 /tmp/ffmpeg-${streamid}.stderr`"
	_log "MODE     = WRAPPER"
	_log "FFMPEG   = $bin2"

	$bin2 "${args[@]}" 2> /tmp/ffmpeg-${streamid}.stderr &

	childpid=$!
	_log "CHILDPID = $childpid"
	wait $childpid

fi

stopexectime=`date +%s`
if test $((stopexectime-startexectime)) -lt 10; then
	_log "STDOUT   ="
	_log_para "`tail -n 22 /tmp/ffmpeg-${streamid}.stderr`"
fi

_log "*** CHILD END ***"
_log "*** PROCESS END ***"

rm /tmp/ffmpeg-*.stderr
