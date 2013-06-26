#!/bin/bash
# Runs modelsim to compile and simulate provided sources and toplevel.
# Call e.g. ./msim-sim.sh $TOP_LEVEL -s $SRC_LIST -g $GEN_LIST

ROOT=../../..
DOFILE=$ROOT/common/util/do/sim.do
TOP_LEVEL=$1
VHDL_STD="-93"
READ_MODE=
NO_RUN=
SRC_LIST=
GEN_LIST=
OUT_DIR=_out_$TOP_LEVEL

echo
echo "#### $TOP_LEVEL ####"

rm work -rf
vlib work

for i in $*
do
    if [ "$i" == "-s" ]; then
        READ_MODE="SRC"
    elif [ "$i" == "-g" ]; then
        READ_MODE="GEN"
    elif [ "$i" == "--no-run" ]; then
        READ_MODE=
        NO_RUN=1
    elif [ "$READ_MODE" == "SRC" ]; then
        SRC_LIST+="$ROOT/$i "
    elif [ "$READ_MODE" == "GEN" ]; then
        GEN_LIST+="-g$i "
    fi
done

#compile source files
vcom $VHDL_STD -work work $SRC_LIST
if test $? -ne 0
then
    exit 1
fi

#exit if --no-run
if [ -n "$NO_RUN" ]; then
    exit 0
fi

#simulate design
vsim $TOP_LEVEL -c -do $DOFILE -lib work $GEN_LIST

#catch simulation return
RET=$?

#create output dir
mkdir $OUT_DIR -p
#copy work into
cp work $OUT_DIR/work -r
#copy waves and transcript into
cp transcript $OUT_DIR -r
cp *.wlf $OUT_DIR -r

#exit with simulation return
exit $RET