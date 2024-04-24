#!/bin/bash

echoHelp() {
	echo "$0 -o FILE_NAME [-s -x -r]"
	echo "$0 -h"
	echo "<options>"
	echo "-o FILE_NAME : Essential. '*.s' file to create with shell code."
	echo "-s SYNTAX    : Optional. Specify syntax(att(default) or intel)." 
	echo "-x           : Optional. 64bit mode."
	echo "-r           : Optional. Run shell code by making it an executable file."
	echo "-h           : Print this message and then exit."
	echo "<exit code>"
	echo "0 : Success."
	echo "1 : Failure."
	exit 1
}

run() {
	IS_HELP="TRUE"
	SYNTAX="att"

	while getopts o:s:hxr opts; do
		case $opts in
		h) 
			break
			;;
		o) 
			IS_HELP="FALSE"
			FILE_NAME=$OPTARG
			;;
		s)
			SYNTAX=$OPTARG
			;;
		x) 
			IS_64BIT="TRUE"
			;;
		r) 
			RUN="TRUE"
			;;
		esac
	done

	if [ "$IS_HELP" == "TRUE" ]; then
		echoHelp
	fi

	if [[ "$FILE_NAME" == *?.s ]]; then
		NAME_FORMAT=${FILE_NAME%*.s}
	else
		echo "$FILE_NAME"
		echo "ERROR: This is not a file with an 's' extension."
		exit 1
	fi

	if [ "$IS_64BIT" == "TRUE" ]; then
		ARCHITECTURE="64"
	else
		ARCHITECTURE="32"
	fi

	as --$ARCHITECTURE -o "$NAME_FORMAT.o" $FILE_NAME

	echo "[------- ASSEMBLY WITH MACHINE CODE --------]"
	objdump -d "$NAME_FORMAT.o"
	echo -e "[-------------------------------------------]\n"

	if [ "$RUN" == "TRUE" ]; then
		ld -o "./$NAME_FORMAT" "./$NAME_FORMAT.o"

		echo "[-------------- RUN YOUR CODE --------------]"
		$("./$NAME_FORMAT")
		echo -e "[-------------------------------------------]\n"
	fi

	printf "Do you want to make it into SHELL CODE? [Y/n]: "
	read MAKE_IT

	case $MAKE_IT in
	y | Y)
		;;
	n | N) 
		exit 0
		;;
	*) 
		echo "ERROR: The input is NOT 'y' or 'n'."
		exit 1
		;;
	esac

	objcopy --dump-section .text="$NAME_FORMAT.bin" "$NAME_FORMAT.o"
	ROUGH=$(hexdump -ve '/1 "%02X" " "' "$NAME_FORMAT.bin")

	python3 -c "print('', ''.join(f'\\\\x{x}' for x in '${ROUGH}'.split()), sep='\n')"

	rm "$NAME_FORMAT.o" "$NAME_FORMAT.bin"
 	if [ "$RUN" == "TRUE" ]; then
 		rm $NAME_FORMAT
 	fi
}

run "$@"
