#!/bin/bash

ERROR_LABEL="\e[41;1m ERROR \e[0m"
INFO_LABEL="\e[42;1m INFO \e[0m"
AXB_REGEX="^([0-9]+)x([0-9]+)$"

OUT_DIR=converted
OUT_EXT=png
PALETTE=palette/modified/all_saturated.png
W=29
H=29
X=1
Y=1
SCALE=40

################################################################################

if [[ ${1,,} =~ ^--?h(elp)?$ ]]; then
	echo -e "$INFO_LABEL Please provide at least first of four arguments in the following order:"
	echo "  1. processed image relative path (required),"
	echo "  2. palette relative path         (default $PALETTE),"
	echo "  3. tile size in format WxH       (default ${W}x${H}),"
	echo "  4. tiling in format XxY          (default ${X}x${Y})."
	exit 1
fi

if [[ $# -ge 1 ]]; then
	IMG=$1
	if [[ ! -f $IMG ]]; then
		echo -e "$ERROR_LABEL Image file $IMG does not exist"
		exit 1
	fi
	echo -e "$INFO_LABEL Processing image $IMG"
else
	echo -e "$ERROR_LABEL Missing argument. Type \"${0##*/} --help\" for more info"
	exit 1
fi

if [[ $# -ge 2 ]]; then
	PALETTE=$2
	if [[ ! -f $PALETTE ]]; then
		echo -e "$ERROR_LABEL Palette file $PALETTE not found"
		exit 1
	fi
	echo -e "$INFO_LABEL Using palette from file $PALETTE"
else
	echo -e "$INFO_LABEL Using default palette from file $PALETTE"
	if [[ ! -f $PALETTE ]]; then
		echo -e "$ERROR_LABEL Default palette file $PALETTE not found"
		exit 1
	fi
fi

if [[ $# -ge 3 ]]; then
	if [[ ! $3 =~ $AXB_REGEX ]]; then
		echo -e "$ERROR_LABEL Please provide tile size in format WxH, where W is width and H is height"
		exit 1
	fi
	W=${BASH_REMATCH[1]}
	H=${BASH_REMATCH[2]}
fi
echo -e "$INFO_LABEL Output tile will be $W pixels wide and $H pixels high"

if [[ $# -ge 4 ]]; then
	if [[ ! $4 =~ $AXB_REGEX ]]; then
		echo -e "$ERROR_LABEL Please provide tiling information in format XxY, where X is a number of tiles horizontally and Y is a number of tiles vertically"
		exit 1
	fi
	X=${BASH_REMATCH[1]}
	Y=${BASH_REMATCH[2]}
fi
totalW=$(($X*$W))
totalH=$(($Y*$H))
if [[ $X -ne 1 || $Y -ne 1 ]]; then
	echo -e "$INFO_LABEL Output image will have $X tiles horizontally and $Y tiles vertically"
	echo -e "$INFO_LABEL Total image size will be ${totalW}x${totalH}"
else
	echo -e "$INFO_LABEL Output image will have only one tile"
fi

#echo -e "\e[1;46m DEBUG \e[0m ($W)($H)($X)($Y)($totalW)($totalH)($PALETTE)($IMG)"

################################################################################

imgNoExt="${IMG%.*}"
outputFile="$OUT_DIR/$imgNoExt.$OUT_EXT"
outputPath="${outputFile%/*}"
mkdir -p "$outputPath" &>/dev/null
if [[ $? -ne 0 ]]; then
	echo -e "$ERROR_LABEL Directory $outputPath creation failed"
	exit 1
fi

convert "$IMG" \
	-resize ${totalW}x${totalH}^ \
	-gravity center \
	-extent ${totalW}x${totalH} \
	+repage \
	-dither Riemersma \
	-remap "$PALETTE" \
	-scale $((100*SCALE))% \
	"$outputFile"

if [[ $? -ne 0 || ! -f $outputFile ]]; then
	echo -e "$ERROR_LABEL There was a problem while converting the image"
	exit 1
fi
echo -e "$INFO_LABEL Image converted successfully to $outputFile"

if [[ $X -ne 1 || $Y -ne 1 ]]; then
	outputTiles="${outputFile}_TILES"
	mkdir -p "$outputTiles"
	if [[ $? -ne 0 ]]; then
		echo -e "$ERROR_LABEL Directory $outputTiles creation failed"
		exit 1
	fi

	convert "$outputFile" \
		-crop ${X}x${Y}@ \
		+repage \
		+adjoin \
		"$outputTiles/%d.$OUT_EXT"
	if [[ $? -ne 0 ]]; then
		echo -e "$ERROR_LABEL There was a problem while generating tiles"
		exit 1
	fi
	echo -e "$INFO_LABEL Tiles created successfully in $outputTiles"
fi

