#!/bin/bash

echoHelp() {
	echo "$0 -f TARGET_FILE_NAME [-o -a -t -s -r -k]"
	echo "$0 -h"
	echo "<options>"
	echo "-h                  : Print this message and then exit."
	echo "-f TARGET_FILE_NAME : Specify the file with the extension 's' for generating shellcode."
	echo "-o OUTPUT_FILE_NAME : (Optional) Save the completed shellcode to the specified file."
	echo "-a ARCHITECTURE     : (Optional) Specify architecture(x86_64(default) or i386)."
	echo "-t LITERAL_TYPE     : (Optional) Specify the literal type(str(default), arr, or all) of bytes of shellcode to output."
	echo "-s SYNTAX           : (Optional) Specify syntax(att(default) or intel)." 
	echo "-r                  : (Optional) Run shell code by making it an executable file."
	echo "-k                  : (Optional) Keep the intermediate files."
	echo "<exit code>"
	echo "0 : Success."
	echo "1 : Failure."
	exit 1
}

echo_with_highlight() {
	SEARCH_ARR=("${@:2}")
	SEARCH_STRS=$(IFS="|"; echo "${SEARCH_ARR[*]}")

	echo "$(echo "$1" | sed -E "s/${SEARCH_STRS:0:$((${#SEARCH_STRS}-1))}/$(tput setaf 1)&$(tput sgr0)/g")"
}

run() {
	ARCHITECTURE="x86_64"
	LITERAL_TYPE="str"
	SYNTAX="att"
	OUTPUT=""

	IS_HELP=true
	KEEP=false
	RUN=false

	while getopts f:o:a:t:s:hrk opts; do
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
		t)
			LITERAL_TYPE=$OPTARG
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

	case $ARCHITECTURE in
	"x86_64")
		ARCH_NUM="64"
		;;
	"i386")
		ARCH_NUM="32"
		;;
	*)
		echo "ERROR: Unsupported ARCHITECTURE. Must be either 'x86_64' or 'i386'."
		exit 1
		;;
	esac

	if [ "$LITERAL_TYPE" != "str" -a "$LITERAL_TYPE" != "arr" -a "$LITERAL_TYPE" != "all" ]; then
		echo "ERROR: Unsupported LITERAL_TYPE. Must be among 'str', 'arr', or 'all'."
		exit 1
	fi

	as --$ARCH_NUM -o "$NAME_FORMAT.o" $FILE_NAME

	echo "[-------------------- ASSEMBLY WITH MACHINE CODE --------------------]"
	WHITESPACE=("09 " "0a " "0b " "0c " "0d " "20 ")

	echo_with_highlight "$(objdump -d "$NAME_FORMAT.o")" "${WHITESPACE[@]}"

	echo
	echo "NOTE : Whitespace in C : "
	echo "  0x09(Horizontal Tab), 0x0A(Line Feed),       0x0B(Vertical Tab),"
	echo "  0x0C(Form Feed),      0x0D(Carriage Return), 0x20(Space)"
	echo
	echo -e "[-------------------------------------------------------------------]\n"

	if $RUN; then
		ld -m "elf_$ARCHITECTURE" -o "./$NAME_FORMAT" "./$NAME_FORMAT.o"

		echo "[-------------------------- RUN YOUR CODE --------------------------]"
		"./$NAME_FORMAT"
		echo -e "[-------------------------------------------------------------------]\n"
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

	printf "\nbytes length : %d (0x%X)\n\n" "$LENGTH" "$LENGTH"

	if [ $LITERAL_TYPE != "arr" ]; then
		STR_LITERAL=$(printf "\\\\x%s" "${SPLIT[@]}")

		echo "String Literal: "

		if [ -z "$OUTPUT" ]; then
			echo "$STR_LITERAL"
		else
			echo "$STR_LITERAL" | tee -a "$OUTPUT"
		fi

		echo
	fi

	if [ $LITERAL_TYPE != "str" ]; then
		ARR_LITERAL=$(printf "0x%s, " "${SPLIT[@]:0:$(($LENGTH - 1))}" && printf "0x${SPLIT[-1]}")

		echo "Array Literal: "

		if [ -z "$OUTPUT" ]; then
			echo "$ARR_LITERAL"
		else
			echo "$ARR_LITERAL" | tee -a "$OUTPUT"
		fi

		echo
	fi

	if ! $KEEP; then
		rm "$NAME_FORMAT.o" "$NAME_FORMAT.bin"

		if $RUN; then
			rm $NAME_FORMAT
		fi
	fi
}

run "$@"
