#!/bin/bash

echoHelp() {
	echo "$0 -o FILE_NAME [-q -b -x -r]"
	echo "$0 -h"
	echo "<options>"
	echo "-o FILE_NAME : Essential. '*.asm' file to create with shell code."
	echo "-q           : Optional. 64bit mode."
	echo "-b           : Optional. Print Machine code."
	echo "-x           : Optional. Execute shell code by making it an executable file."
	echo "-r           : Optional. Remove all files created during execution."
	echo "-h           : Print this message and then exit."
	echo "<exit code>"
	echo "0 : Success."
	echo "1 : Failure."
	exit 1
}

while getopts o:hqbxr opts; do
	case $opts in
	h) echoHelp
		;;
	o) FILE_NAME=$OPTARG
		;;
	q) IS_64BIT="TRUE"
		;;
	b) ECHO_BIN="TRUE"
		;;
	x) EXECUTE="TRUE"
		;;
	r) RM_FILE="TRUE"
		;;
	esac
done

if [[ "$FILE_NAME" == *?.asm ]]; then
	NAME_FORMAT=${FILE_NAME%*.asm}
else
	echo "$FILE_NAME"
	echo "ERROR: This is not a file with an 'asm' extension."
	exit 1
fi

if [ "$IS_64BIT" == "TRUE" ]; then
	SUFFIX="64"
else
	SUFFIX=""
fi

nasm -felf$SUFFIX $FILE_NAME

unset FILE_NAME
unset IS_64BIT
unset SUFFIX

if [ "$ECHO_BIN" == "TRUE" ]; then
	echo "[----- ASSEMBLY CODE WITH MACHINE CODE -----]"
	objdump -d "$NAME_FORMAT.o"
	echo -e "[-------------------------------------------]\n"
fi

unset ECHO_BIN

if [ "$EXECUTE" == "TRUE" ]; then
	ld -o "./$NAME_FORMAT" "./$NAME_FORMAT.o"
	echo "[-------------- RUN YOUR CODE --------------]"
	$("./$NAME_FORMAT")
	echo -e "[-------------------------------------------]\n"
fi

printf "Do you want to make it into SHELL CODE? [y/n]: "
read MAKE_IT

case $MAKE_IT in
y | Y) unset MAKE_IT
	;;
n | N) 
	  unset MAKE_IT
    exit 0
  ;;
*) 
	  echo "ERROR: The input is NOT 'y' or 'n'."
	  unset MAKE_IT
	  exit 1
	;;
esac

objcopy --dump-section .text="$NAME_FORMAT.bin" "$NAME_FORMAT.o"
ROUGH=$(hexdump -ve '/1 "%#02x" " "' execve.bin)
python3 -c "for i in '${ROUGH}'.split(): print('\\\\' + (i[1:] if len(i) == 4 else f'x{i}' if len(i) == 2 else i.replace('x', 'x0')), end='')"
python3 -c "print()"

unset ROUGH

if [ "$RM_FILE" == "TRUE" ]; then
	rm "$NAME_FORMAT.o" "$NAME_FORMAT.bin"
    if [ "$EXECUTE" == "TRUE" ]; then
		rm $NAME_FORMAT
	fi
fi

unset EXECUTE
unset RM_FILE
unset NAME_FORMAT
