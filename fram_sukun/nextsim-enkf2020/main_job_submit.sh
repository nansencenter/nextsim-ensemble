#!/bin/bash
set -e
# source ${NEXTSIM_ENV_ROOT_DIR}/run.fram.sh ./nextsim.cfg 1 -e ${NEXTSIM_ENV_ROOT_DIR}/nextsim.src   
# main job submitting script
# - core.sh includes 1) nextsim, 2) enkf. 
# results are saved in ENSPATH/filter/prior/***.nc.analysis,linked in NEXTSIM_DATA_DIR/...
# Directory structure:
# ENSPATH 2018-11-11 includes
#         -- mem001
#         -- mem002
#         -- ...
#         -- mem***
#         -- filter (include EnKF package)
#                     -- obs  (link observations from NEXTIM_DATA_DIR)
#                     -- prior 
# changes in nextsim.cfg, pseudo2D.nml are in part1_initialization.sh
#-----------------------------------------------------------

## common settings
#---  model paths and alias --------------
# Important modifications for Fram  
# 1. comment NEXTSIMDIR path
# 2. cp reference_grid.nc to data/ 
# 3. set RUNPATH to IO_nextsim on fram
# 4. path of CS2SMOS, check ~/src/data
# 5. put nextsim/bin/nextsim.exec in path
# 6. ln -s enkf-c/bin/enkf* to 
# 7. ln -sf /cluster/projects/nn2993k/sim/data/ECMWF_forecast_arctic/* /nextsim/data/ECMWF_forecast_arctic ,  not use INPUT_DATA_DIR includes too many data
#   same for /cluster/projects/nn2993k/sim/data/CS2_SMOS_v2.2, TOPAZ4RC_daily/20181*, 20190* .
# CS2_SMOS_v2.2 is weekly data, and variables are different.
#---------  Confirm working,data,ouput directories --------
RUNFILE=$(basename $0)               # name of this .sh
RUNPATH=$(cd `dirname $0`;pwd)       # path of this .sh 

#source ${NEXTSIM_ENV_ROOT_DIR}/nextsim.ensemble.intel.src is applied in .bashrc
# observation CS2SMOS data discription
OBSNAME_PREFIX=$NEXTSIMDIR/data/CS2_SMOS_v2.2/W_XX-ESA,SMOS_CS2,NH_25KM_EASE2_ 
OBSNAME_SUFFIX=_r_v202_01_l4sit
#--------  experiment settings ------------
time_init=2018-11-11   # starting date of simulation
duration=7    # forecast duration,#   tduration*duration is the total simulation time in days
tduration=4   # number of forecast-analysis cycle. 
ESIZE=1      # ensemble size
UPDATE=0 # 1: active assimilation
# duration=1    # forecast duration,#   tduration*duration is the total simulation time in days
# tduration=2   # number of forecast-analysis cycle. 
# ESIZE=1      # ensemble size
# UPDATE=0 # 1: active assimilation
maximum_instants=200   # max instants (submitted jobs)
OUTPUTPATH=${IO_nextsim}/test_Ne${ESIZE}_T${tduration}_D${duration}/I${INFLATION}_L${LOCRAD}_R${RFACTOR}_K${KFACTOR}   # output path
OUTPUTPATH=${OUTPUTPATH//./p}
echo 'work path:' $OUTPUTPATH 
[ -d $OUTPUTPATH ] && rm -r $OUTPUTPATH  
mkdir -p $OUTPUTPATH    
#>nohup.out  # empty this file

#-------------------------------------------
# execute ensemble runs
for (( iperiod=1; iperiod<=${tduration}; iperiod++ )); do
    if [ $iperiod -eq 1 ]; then 
        restart_from_analysis=false
    else 
        restart_from_analysis=true
        time_init=$(date +%Y-%m-%d -d "${time_init} + ${duration} day")        
    fi
    echo "start period ${time_init}"
    ENSPATH=$OUTPUTPATH/date${iperiod}  
    mkdir -p $ENSPATH        
# create ensemble directories and files
    source $RUNPATH/part1_initialization.sh   
# a forecast-analysis cycle
    source $RUNPATH/part2_core.sh  
done
cp ${RUNPATH}/*.sh ${OUTPUTPATH}
cp $RUNPATH/nohup.out $OUTPUTPATH/nohup.log
echo 'Simulation ' I${INFLATION}_L${LOCRAD}_R${RFACTOR}_K${KFACTOR} ' is done'
