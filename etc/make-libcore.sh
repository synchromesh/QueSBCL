#!/bin/bash
# QueSBCL/etc/make-libcore.sh - generate plugin/lib/libcore.so from ../../../repos/sbcl
# File Created: 24 September 2025
# Author: John Pallister <john@synchromesh.com>
# Based on: hello-alien/build-scripts/make-core.sh etc.
# Ref: https://github.com/Gleefre/hello-alien
#
# Having built SBCL for Android via sbcl/make-android.sh, there's a copy of SBCL
# on the attached Android device in /data/local/tmp/sbcl. The core is at
# /data/local/tmp/sbcl/output/sbcl.core. So we use that.
#
# "SBCL will search for ["alien-callable"] function in main program by default
# Main program is Java program, so we need to load the [wrapper] library at the
# startup." - Gleefre
#
# "SBCL enables float traps at startup, but doesn't disable them when
# initalize_lisp returns. So we do it in our INIT-HOOK ourselves. Note: It might
# be better to use SB-INT:SET-FLOATING-POINT-MODES." - Gleefre
#
# This script should be executed from e.g. ~/src/ngake/QueSBCL/etc/, so that the
# default relative paths are correct.

function msg () {
		echo "make-libcore.sh: $*"
}

function fatal () {
		local ERRCODE=$1 ; shift

		msg $*
		exit $ERRCODE
}

if [ "$1" = "--verbose" ] || [ "$1" = "-v" ]
then
		shift
		VERBOSE_P=1
		#set -x
fi

if [ "$1" = "--help" ] || [ "$1" = "-h" ]
then
		shift
		echo "Usage: make-libcore.sh [-v|--verbose]"
		echo " "
		echo "This script should be executed from e.g. ~/src/ngake/QueSBCL/etc/, so that the"
		echo "default relative paths are correct."
		exit 0
fi

if ! which adb > /dev/null
then
		fatal 2 "Error - no ADB executable found."
fi

# Make sure an Android device is connected.
if ! adb devices | grep -q "[[:space:]]device$"
then
		fatal 3 "Error - no connected Android device found."
fi

# Check that the Android device architecture is arm64-v8a.
UNAME_ARCH="$(adb shell uname -m)"
case $UNAME_ARCH in
    aarch64) ABI=arm64-v8a ;;
    *)       fatal 4 "Error - architecture $UNAME_ARCH is not supported." ;;
esac

# Local copy of the SBCL repo (git://git.code.sf.net/p/sbcl/sbcl)
: "${SBCL_DIR:=../../../repos/sbcl}"

# Default installation on the Android device
: "${DEVICE_SBCL_DIR:=/data/local/tmp/sbcl}"

# The SBCL core must load this library to find the C FFI entry points.
: "${LIBQUESBCL_SO:=libQueSBCL.so}"

# Name of the saved Lisp core.
: "${LIBCORE_SO:=libcore.so}"
: "${LIBCORE_SO_DEST_DIR:=../plugin/lib/${ABI}}"

# The Lisp file that defines the interface and sets *CALLABLE-EXPORTS*.
: "${INTERFACE_LISP_PATH:=../lisp/interface.lisp}"

: "${HERE_LISP_PATH:=./make-libcore.lisp}"
: "${DEVTMPDIR:=/data/local/tmp/tmp-make-libcore}"

cat <<EOF > "${HERE_LISP_PATH}"
(push (lambda ()
        (sb-alien:load-shared-object "${LIBQUESBCL_SO}" :dont-save t)
        (setf (sb-vm:floating-point-modes) (dpb 0 sb-vm:float-traps-byte (sb-vm:floating-point-modes))))
        *init-hooks*)

(save-lisp-and-die "${DEVTMPDIR}/${LIBCORE_SO}"
                   :callable-exports *callable-exports*
                   #+sb-core-compression :compression
                   #+sb-core-compression t)
EOF

if [ "${VERBOSE_P}" ]
then
		msg "UNAME_ARCH          ${UNAME_ARCH}"
		msg "SBCL_DIR            ${SBCL_DIR}"
		msg "DEVICE_SBCL_DIR     ${DEVICE_SBCL_DIR}"
		msg "LIBQUESBCL_SO       ${LIBQUESBCL_SO}"
		msg "LIBCORE_SO          ${LIBCORE_SO}"
		msg "LIBCORE_SO_DEST_DIR ${LIBCORE_SO_DEST_DIR}"
		msg "INTERFACE_LISP_PATH ${INTERFACE_LISP_PATH}"
		msg "HERE_LISP_PATH      ${HERE_LISP_PATH}"
		msg "DEVTMPDIR           ${DEVTMPDIR}"
fi

rm -f "./${LIBCORE_SO}"

function exec-adb () {
		adb shell rm -rf "${DEVTMPDIR}"
		adb shell mkdir -p "${DEVTMPDIR}"
		adb push "${INTERFACE_LISP_PATH}" "${DEVTMPDIR}/interface.lisp"
		adb push "${HERE_LISP_PATH}" "${DEVTMPDIR}/make-libcore.lisp"
		adb shell "$(cat <<EOF
cd "${DEVICE_SBCL_DIR}"
HOME="${DEVICE_SBCL_DIR}" sh ./run-sbcl.sh --load "${DEVTMPDIR}/interface.lisp" --load "${DEVTMPDIR}/make-libcore.lisp"
EOF
)"
		adb pull "${DEVTMPDIR}/${LIBCORE_SO}" ./
}

if [ "${VERBOSE_P}" ]
then
		exec-adb
else
		exec-adb &> /dev/null
fi

if [ -f "./${LIBCORE_SO}" ]
then
		msg "${LIBCORE_SO} built successfully."
		mv "${LIBCORE_SO}" "${LIBCORE_SO_DEST_DIR}/"
		RESULT=0
else
		msg "${LIBCORE_SO} build failed."
		RESULT=${?}
fi

# Check for newer ARM libsbcl.so, libzstd.so.
function maybe-copy () {
		local DIR=$1 ; shift
		local FILE=$1 ; shift
		local DEST=$1 ; shift
		local FILEPATH="${DIR}/${FILE}"

		if [ -f "${FILEPATH}" ] && [ "${FILEPATH}" -nt "${DEST}/${FILE}" ]
		then
				local ARCH="$(file "${FILEPATH}" | grep "${UNAME_ARCH}")"

				if [ "${ARCH}" ]
				then
						msg "Copying newer ${FILE} to ${DEST}"
						cp -a "${FILEPATH}" "${DEST}/"
				fi
		fi
}

maybe-copy "${SBCL_DIR}/src/runtime"  "libsbcl.so" "${LIBCORE_SO_DEST_DIR}"
maybe-copy "${SBCL_DIR}/android-libs" "libzstd.so" "${LIBCORE_SO_DEST_DIR}"

# Cleanup.
adb shell rm -rf "${DEVTMPDIR}"
[ -z "${VERBOSE_P}" ] && rm -f "${HERE_LISP_PATH}"

exit ${RESULT}

# End of make-libcore.sh
