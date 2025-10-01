#!/bin/bash
# QueSBCL/etc/show-log.sh
# File Created: 1 October 2025
# Author: John Pallister <john@synchromesh.com>
#

VERBOSE_P=0
if [ "$1" = "--verbose" ] || [ "$1" = "-v" ]
then
		shift
		VERBOSE_P=1
fi

: "${LOGFILE:=godot.log}"
: "${HERE_AWK:=godot-log.awk}"

cat <<EOF > "${HERE_AWK}"
/main.gd:_ready()/                    { p=1; } # Sometimes this is skipped/dropped?
/lisp_worker: Thread starting/        { p=1; }
/Orphan StringName/                   { p=0; }
(\$6 ~ /godot|QueSBCL/ || ${VERBOSE_P}) && p
EOF

adb logcat -d /data/data/net.ngake.quesbcl/files/logs/godot.log > "${LOGFILE}" # && adb logcat -c

awk -f "${HERE_AWK}" godot.log

rm -f "${HERE_AWK}"

# End of show-log.sh
