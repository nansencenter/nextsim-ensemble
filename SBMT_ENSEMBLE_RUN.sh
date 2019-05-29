#!/bin/bash

LBREAK="/------------------------------------------------------------/"
KERNEL=$(uname -s)
MACHINE=$(uname -n)
TWAIT=15 # time in seconds to wait to check the status of the previous member

[[ ${KERNEL} == 'Linux' ]] || DOCKER=1
[ !$# ] || [[ $@ == "EnKF" ]] && UPDATE=1

if [ ${DOCKER} ]; then
  echo ${LBREAK}
  echo " Running on a non-Linux machine  "
  echo ${LBREAK}
else
  echo ${LBREAK}
  echo " Running on a Linux machine  "
  echo ${LBREAK}
fi

[ ${UPDATE} ] && echo '/--State WILL be updated--/' || echo '/--NO state update--/'

. neXtSIM_io_paths.env      # paths to relevant directories
. ensemble_run_function.sh  # functions used in this script
. ${DYNFILE}

# checkpath is called from ensemble_run_function.sh
checkpath ${ENSPATH} # check if ensemble root directory/create

if [ ${UPDATE} ]; then
# update ensemble
  checkpath ${FILTER} # check if ensemble filter directory/create
  cd ${FILTER}; checkpath prior # store prior states here

# some of the EnKF config files should be modified each analysis cycle
# such as time of the observations/model outputs
# here copy or link configuration files
  sed -e "s;^ENSSIZE.*$;ENSSIZE = "${ESIZE}";g" \
         ${EnKF_CONF}/enkf.prm > enkf.prm
  sed -e "s;^ENSSIZE.*$;ENSSIZE = "${ESIZE}";g" \
         ${EnKF_CONF}/enkf-global.prm > enkf-global.prm
  ${LINK} ${EnKF_CONF}/{grid,model,obstypes,singleob}.prm .
#  ${LINK} ${EnKF_CONF}/{stats}.prm .
  ${COPY} ${EnKF_CONF}/obs.prm .

# list observation data in the assimlation cycle into obs.prm
# ToDo: this part can be called from another script
  tind=$(echo "(${duration}+1)/1"|bc)
#  for (( tind = 0; tind < ${tduration}; tind++ )); do
  SMOSOBS=${OBSPATH}/${OBSNAME}_$(date +%Y%m%d -d "${time_init} + ${tind} day").nc
  [ -f ${SMOSOBS} ] && echo "FILE = ${SMOSOBS}" >> obs.prm
#  done
# link makefile, shell script
  ${LINK} ${EnKF_CONF}/{Makefile,run_enkf.sh,obs} .
# link directories including grid and observations
  ${LINK} ${GRDFILE} ${REMLINK}/reference_grid.nc
  ${LINK} ${GRDFILE} reference_grid.nc
# copy executables
  ${COPY} ${EnKF_EXEC}/enkf_{prep,calc,update} .
fi # UPDATE

# initialize and run ensemble
ENSEMBLE+=()                # copy files to ensemble members' paths
for (( mem=1; mem<=${ESIZE}; mem++ )); do
# submiting ensemble members one by one on a machine without queue system
# ToDo: should be in a seperate script on fram or sisu
    MEMBER=$(leadingzero 3 ${mem}); MEMNAME=mem${MEMBER}
    ENSEMBLE+=([${mem}]=${MEMNAME})
    MEMPATH=${ENSPATH}/${MEMNAME}; checkpath ${MEMPATH}
    SRUN=run_${EXPNAME}_${MEMNAME}.sh

    ${COPY} ${RUNFILE} ${MEMPATH}/${SRUN}
    [ ${DOCKER} ] && nml_path=${RUNPATH} ||  nml_path=${MEMPATH}
    [ ${DOCKER} ] && exporter_path="/docker_io" || exporter_path=${MEMPATH}

    sed "s;^iopath.*$;iopath = '${exporter_path}';g"\
        ${EnKF_ROOT}/perturbation/nml/${NMLFILE} > ${MEMPATH}/${NMLFILE}

    [ ${ENVFILE} ] && ${COPY} ${RUNPATH}/${ENVFILE} ${MEMPATH}/.

# modify nextsim.cfg for each member
    sed -e "s;^exporter_path=.*$;exporter_path="${exporter_path}";g"\
        -e "s;^time_init=.*$;time_init="${time_init}";g"\
        -e "s;^id=.*$;id=${mem};g"\
        -e "s;^duration=.*$;duration="${duration}";g"\
        -e "s;^output_timestep=.*$;output_timestep="${duration}";g"\
        ${RUNPATH}/${CONFILE} > ${MEMPATH}/${CONFILE}

# modify environment neXtSIM_ensemble.env for each member
    sed -e "s;^MEMNAME=.*$;MEMNAME="${MEMNAME}";g" \
        -e "s;^MEMPATH=.*$;MEMPATH="${MEMPATH}";g" \
        ${RUNPATH}/${DYNFILE} > ${MEMPATH}/${SRCFILE}

# wait for the previous member (after the 1st) to finish before submitting the next one
    if [ ${mem} -gt "1" ];then
        while kill -0 "$XPID"; do
            echo "Process still running... ${XPID}"
            sleep ${TWAIT}
        done
    fi
# submit ensemble member #${mem} and get PID to wait
    cd ${MEMPATH}; source ${ENVFILE}; ID=$( getpid ./${SRUN} ${CONFILE} ${NPROC} )
    XPID=${ID};echo ${XPID}
done

# wait all members to finish before update
while kill -0 "$XPID"; do
    echo "Process still running... ${XPID}"
    sleep ${TWAIT}
done # ENSEMBLE

# ToDo: a docker file should be written for enkf
# other option is to loop each ensemble in a docker script then call enkf

if [ ${UPDATE} ]; then

cd ${ENSPATH}
for (( mem=1; mem<=${ESIZE}; mem++ )); do
    cp ${ENSEMBLE[${mem}]}/prior.nc ${FILTER}/prior/${ENSEMBLE[${mem}]}.nc
done

# 'make enkf' will call sequentially enkf_{prep,calc,update} executables
cd ${FILTER}; make enkf &> out.enkf
#cd FILTER; make singleob &> out.enkf
fi #UPDATE


# link mem???.nc.analysis data_links/mem???/analysis.nc to restart from the analysed state

