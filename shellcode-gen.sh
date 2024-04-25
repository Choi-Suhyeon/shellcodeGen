#!/bin/bash

echoHelp() {
	echo "$0 -o FILE_NAME [-s -a -r -k]"
	echo "$0 -h"
	echo "<options>"
	echo "-o FILE_NAME : Essential. '*.s' file to create with shell code."
	echo "-s SYNTAX    : Optional. Specify syntax(att(default) or intel)." 
	echo "-a ARCH      : Optional. Specify architecture(64(default) or 32)"
	echo "-r           : Optional. Run shell code by making it an executable file."
	echo "-k           : Optional. Keep the intermediate files."
	echo "-h           : Print this message and then exit."
	echo "<exit code>"
	echo "0 : Success."
	echo "1 : Failure."
	exit 1
}

run() {
	IS_HELP=true
	SYNTAX="att"
	ARCHITECTURE="64"
	RUN=false
	KEEP=false

	while getopts o:s:a:hrk opts; do
		case $opts in
		h) 
			break
			;;
		o) 
			IS_HELP=false
			FILE_NAME=$OPTARG
			;;
		s)
			SYNTAX=$OPTARG
			;;
		a) 
			ARCHITECTURE=$OPTARG
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

	echo "$KEEP"

	if $IS_HELP; then
		echoHelp
	fi

	if [[ "$FILE_NAME" == *?.s ]]; then
		NAME_FORMAT=${FILE_NAME%*.s}
	else
		echo "$FILE_NAME"
		echo "ERROR: The file must have the extension 's'."
		exit 1
	fi

	if [ "$SYNTAX" != "att" ] && [ "$SYNTAX" != "intel" ]; then
		echo "ERROR: Unsupported assembly SYNTAX. Must be either 'att' or 'intel'."
		exit 1
	fi

	if [ "$ARCHITECTURE" != "64" ] && [ "$ARCHITECTURE" != "32" ]; then
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

	printf "Do you want to make it into SHELL CODE? [Y/n]: "
	read MAKE_IT

	case $MAKE_IT in
	y | Y)
		;;
	n | N) 
		if ! $KEEP; then
			rm "$NAME_FORMAT.o"

			if $RUN; then
				rm $NAME_FORMAT
			fi
		fi

		exit 0
		;;
	*) 
		echo "ERROR: The input is NOT 'y' or 'n'."
		exit 1
		;;
	esac

	objcopy --dump-section .text="$NAME_FORMAT.bin" "$NAME_FORMAT.o"
	ROUGH=$(hexdump -ve '/1 "%02X" " "' "$NAME_FORMAT.bin")

	python3 -c "split='${ROUGH}'.split();print(f'\nbytes length : {len(split)}({hex(len(split))})\n\n'+''.join(f'\\\\x{x}' for x in split))"

	if ! $KEEP; then
		rm "$NAME_FORMAT.o" "$NAME_FORMAT.bin"

		if $RUN; then
			rm $NAME_FORMAT
		fi
	fi
}

run "$@"
