#!/bin/bash

echoHelp() {
	echo "$0 -f TARGET_FILE_NAME [-o -a -s -r -k]"
	echo "$0 -h"
	echo "<options>"
	echo "-h                  : Print this message and then exit."
	echo "-f TARGET_FILE_NAME : Specify the file with the extension 's' for generating shellcode."
	echo "-o OUTPUT_FILE_NAME : (Optional) Save the completed shellcode to the specified file."
	echo "-a ARCHITECTURE     : (Optional) Specify architecture(64(default) or 32)."
	echo "-s SYNTAX           : (Optional) Specify syntax(att(default) or intel)." 
	echo "-r                  : (Optional) Run shell code by making it an executable file."
	echo "-k                  : (Optional) Keep the intermediate files."
	echo "<exit code>"
	echo "0 : Success."
	echo "1 : Failure."
	exit 1
}

run() {
	ARCHITECTURE="64"
	SYNTAX="att"
	OUTPUT=""

	IS_HELP=true
	KEEP=false
	RUN=false

	while getopts f:o:s:a:hrk opts; do
		case $opts in
		h) 
			break
			;;
		f) 
			IS_HELP=false
			FILE_NAME=$OPTARG
			;;
		o)
			OUTPUT=$OPTARG
			;;
		a) 
			ARCHITECTURE=$OPTARG
			;;
		s)
			SYNTAX=$OPTARG
			;;
		r) 
			RUN=true
			;;
		k)
			KEEP=true
			;;
		*)
			echo "ERROR: Illegal Option Found"
			exit 1
			;;
		esac
	done

	if $IS_HELP; then
		echoHelp
	fi

	if [[ ! "$FILE_NAME" =~ .+\.s ]]; then
		echo "ERROR: The file must have the extension 's'."
		exit 1
	fi

	if [ ! -f "$FILE_NAME" -o ! -r "$FILE_NAME" ]; then
		echo "ERROR: This is not a file or not readable."
		exit 1
	fi

	NAME_FORMAT=${FILE_NAME%*.s}

	if [ "$SYNTAX" != "att" -a "$SYNTAX" != "intel" ]; then
		echo "ERROR: Unsupported assembly SYNTAX. Must be either 'att' or 'intel'."
		exit 1
	fi

	if [ "$ARCHITECTURE" != "64" -a "$ARCHITECTURE" != "32" ]; then
		echo "ERROR: Unsupported ARCHITECTURE. Must be either '64' or '32'."
		exit 1
	fi

	as --$ARCHITECTURE -o "$NAME_FORMAT.o" $FILE_NAME

	echo "[------- ASSEMBLY WITH MACHINE CODE --------]"
	objdump -d "$NAME_FORMAT.o"
	echo -e "[-------------------------------------------]\n"

	if $RUN; then
		ld -o "./$NAME_FORMAT" "./$NAME_FORMAT.o"

		echo "[-------------- RUN YOUR CODE --------------]"
		chmod u+x "./$NAME_FORMAT"
		"./$NAME_FORMAT"
		echo -e "[-------------------------------------------]\n"
	fi

	echo -n "Do you want to make it into SHELLCODE? [Y/n]: "
	read -r  MAKE_IT

	case $MAKE_IT in
	[Yy]|[Yy][Ee][Ss])
		;;
	[Nn]|[Nn][Oo]) 
		if ! $KEEP; then
			rm "$NAME_FORMAT.o"

			if $RUN; then
				rm $NAME_FORMAT
			fi
		fi

		exit 0
		;;
	*) 
		echo "ERROR: The input must be one of 'y', 'n', 'yes', or 'no'."
		exit 1
		;;
	esac

	objcopy --dump-section .text="$NAME_FORMAT.bin" "$NAME_FORMAT.o"

	SPLIT=($(hexdump -ve '/1 "%02X" " "' "$NAME_FORMAT.bin"))
	LENGTH=${#SPLIT[@]}

	printf "\nbytes length : %d (%#X)\n\n" "$LENGTH" "$LENGTH"

	if [ -z "$OUTPUT" ]; then
		printf "\\\\x%s" "${SPLIT[@]}"
	else
		printf "\\\\x%s" "${SPLIT[@]}" | tee "$OUTPUT"
	fi

	echo

	if ! $KEEP; then
		rm "$NAME_FORMAT.o" "$NAME_FORMAT.bin"

		if $RUN; then
			rm $NAME_FORMAT
		fi
	fi
}

run "$@"
