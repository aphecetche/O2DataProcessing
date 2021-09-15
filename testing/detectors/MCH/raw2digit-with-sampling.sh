#!/usr/bin/env bash

source common/setenv.sh

SEVERITY=warning
ARGS_ALL="--session default --severity $SEVERITY --shm-segment-id $NUMAID --shm-segment-size $SHMSIZE"
ARGS_ALL+=" --infologger-severity $SEVERITY"
#ARGS_ALL+=" --monitoring-backend influxdb-unix:///tmp/telegraf.sock"

ARGS_ALL_CONFIG="NameConf.mDirGRP=$FILEWORKDIR;NameConf.mDirGeom=$FILEWORKDIR;NameConf.mDirCollContext=$FILEWORKDIR;NameConf.mDirMatLUT=$FILEWORKDIR;keyval.input_dir=$FILEWORKDIR;keyval.output_dir=/dev/null"
ARGS_ALL_CONFIG="${ARGS_ALL_CONFIG};MCHCoDecParam.sampaBcOffset=913000"

DECOD_INSPEC="TF:MCH/RAWDATA_SAMPLED"
DATASAMPLING_JSON="$HOME/O2DataProcessing/testing/detectors/MCH/mch-datasampling.json"
PROXY_INSPEC="A:MCH/RAWDATA;dd:FLP/DISTSUBTIMEFRAME/0;eos:***/INFORMATION"

o2-dpl-raw-proxy $ARGS_ALL \
    --dataspec "$PROXY_INSPEC" \
    --readout-proxy "--channel-config 'name=readout-proxy,type=pull,method=connect,address=ipc://@$INRAWCHANNAME,transport=shmem,rateLogging=1'" \
| o2-datasampling-standalone \
        $ARGS_ALL  \
        --config json:/${DATASAMPLING_JSON} \
| o2-mch-raw-to-digits-workflow \
        $ARGS_ALL \
	--dataspec ${DECOD_INSPEC} \
        --configKeyValues "$ARGS_ALL_CONFIG" \
| o2-dpl-run \
        $ARGS_ALL $GLOBALDPLOPT --dds
