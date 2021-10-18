#!/usr/bin/env bash

source common/setenv.sh

SEVERITY=warning
ARGS_ALL_0="--session default --shm-segment-id $NUMAID --shm-segment-size $SHMSIZE"
ARGS_ALL="${ARGS_ALL_0} --infologger-severity $SEVERITY --severity $SEVERITY"

#ARGS_ALL+=" --monitoring-backend influxdb-unix:///tmp/telegraf.sock"
ARGS_ALL_CONFIG="NameConf.mDirGRP=$FILEWORKDIR;NameConf.mDirGeom=$FILEWORKDIR;NameConf.mDirCollContext=$FILEWORKDIR;NameConf.mDirMatLUT=$FILEWORKDIR;keyval.input_dir=$FILEWORKDIR;keyval.output_dir=/dev/null"
ARGS_ALL_CONFIG="${ARGS_ALL_CONFIG};MCHCoDecParam.sampaBcOffset=913000"

DATASAMPLING_JSON="$HOME/O2DataProcessing/testing/detectors/MCH/mch-datasampling.json"
PROXY_INSPEC="A:MCH/RAWDATA;dd:FLP/DISTSUBTIMEFRAME/0;eos:***/INFORMATION"
DECOD_INSPEC="TF:MCH/RAWDATA_SAMPLED"

# Receive raw data
WORKFLOW="o2-dpl-raw-proxy $ARGS_ALL \
  --dataspec \"$PROXY_INSPEC\" \
  --readout-proxy \"--channel-config 'name=readout-proxy,type=pull,method=connect,address=ipc://@$INRAWCHANNAME,transport=shmem,rateLogging=1'\" |"

# Sample raw data
WORKFLOW+="o2-datasampling-standalone $ARGS_ALL --config json:/${DATASAMPLING_JSON} |" 

# Decode raw data
#WORKFLOW+="o2-mch-raw-to-digits-workflow $ARGS_ALL_0 --infologger-severity error --severity error --configKeyValues \"$ARGS_ALL_CONFIG\" --dataspec ${DECOD_INSPEC} --ignore-dist-stf |" 
WORKFLOW+="o2-mch-raw-to-digits-workflow $ARGS_ALL_0 --infologger-severity error --severity error --error-log-frequency 3000 --configKeyValues \"$ARGS_ALL_CONFIG\" --dataspec ${DECOD_INSPEC}  |" 
    
if [ -n "$QCJSON" ]; then
  # Perform quality control
  WORKFLOW+="o2-qc -b --local --host epn ${ARGS_ALL} --config json:/$QCJSON  | "
  # WORKFLOW+="o2-qc -b ${ARGS_ALL} --config json:/$QCJSON  | "
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
