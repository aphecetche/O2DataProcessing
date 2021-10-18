#!/usr/bin/env bash

source common/setenv.sh

SEVERITY=warning
ARGS_ALL_0="--session default --shm-segment-id $NUMAID --shm-segment-size $SHMSIZE"
ARGS_ALL="${ARGS_ALL_0} --infologger-severity $SEVERITY --severity $SEVERITY"

ARGS_ALL_CONFIG="NameConf.mDirGRP=$FILEWORKDIR;NameConf.mDirGeom=$FILEWORKDIR;NameConf.mDirCollContext=$FILEWORKDIR;NameConf.mDirMatLUT=$FILEWORKDIR;keyval.input_dir=$FILEWORKDIR;keyval.output_dir=/dev/null"
ARGS_ALL_CONFIG="${ARGS_ALL_CONFIG};MCHCoDecParam.sampaBcOffset=0"

PROXY_INSPEC="A:MCH/RAWDATA;dd:FLP/DISTSUBTIMEFRAME/0;eos:***/INFORMATION"

# Receive raw data
WORKFLOW="o2-dpl-raw-proxy $ARGS_ALL \
  --dataspec \"$PROXY_INSPEC\" \
  --readout-proxy \"--channel-config 'name=readout-proxy,type=pull,method=connect,address=ipc://@$INRAWCHANNAME,transport=shmem,rateLogging=1'\" |"

# Decode raw data
WORKFLOW+="o2-mch-raw-to-digits-workflow $ARGS_ALL_0 --infologger-severity error --severity warning --error-log-frequency 1000 --pipeline mch-data-decoder:8 --configKeyValues \"$ARGS_ALL_CONFIG\" |" 
#WORKFLOW+="o2-mch-raw-to-digits-workflow $ARGS_ALL_0 --infologger-severity error --severity warning  3000 --configKeyValues \"$ARGS_ALL_CONFIG\" |" 

if [ -n "$WRITE_CTF" ]; then
# Encode for CTF
WORKFLOW+="o2-mch-entropy-encoder-workflow --ctf-dict \"$HOME/ctf_dictionary.root\" $ARGS_ALL --configKeyValues \"$ARGS_ALL_CONFIG\" |" 
# Write CTF
#WORKFLOW+="o2-ctf-writer-workflow $ARGS_ALL_0 --severity info --infologger-severity warning --onlyDet MCH --configKeyValues \"$ARGS_ALL_CONFIG\" --output-dir /tmp/eosbuffer | "
fi

if [ -n "$QCJSON" ]; then
  # Perform quality control
  WORKFLOW+="o2-qc -b --local --host epn ${ARGS_ALL} --config json:/$QCJSON  | "
fi

WORKFLOW+=" o2-dpl-run ${ARGS_ALL} ${GLOBALDPLOPT}"

if [ $WORKFLOWMODE == "print" ]; then
  echo Workflow command:
  echo $WORKFLOW | sed "s/| */|\n/g"
else
  # Execute the command we have assembled
  WORKFLOW+=" --$WORKFLOWMODE"
  eval $WORKFLOW
fi
