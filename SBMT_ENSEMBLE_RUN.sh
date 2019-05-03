#!/bin/bash

LBREAK="/------------------------------------------------------------/"
KERNEL=$(uname -s)
MACHINE=$(uname -n)
TWAIT=15

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

checkpath ${ENSPATH}        # check if ensemble root directory/create

if [ ${UPDATE} ]; then
# update ensemble
  checkpath ${FILTER}        # check if ensemble filter directory/create
  cd ${FILTER}; checkpath prior # store prior states here

# some of the EnKF config files should be modified each analysis cycle
# such as time of the observations/model outputs
# link configuration files
  sed -e "s;^ENSSIZE.*$;ENSSIZE = "${ESIZE}";g" \
         ${EnKF_CONF}/enkf.prm > enkf.prm
  sed -e "s;^ENSSIZE.*$;ENSSIZE = "${ESIZE}";g" \
         ${EnKF_CONF}/enkf-global.prm > enkf-global.prm
  ${LINK} ${EnKF_CONF}/{grid,model,obs,obstypes}.prm .
#  ${LINK} ${EnKF_CONF}/{stats}.prm .
# link makefile, shell script
  ${LINK} ${EnKF_CONF}/{Makefile,run_enkf.sh} .
# link directories including grid and observations
  ${LINK} ${EnKF_CONF}/{../examples/neXtSIM_config/conf,obs} .
# copy executables
  ${COPY} ${EnKF_EXEC}/enkf_{prep,calc,update} .

fi

# initialize and run ensemble
ENSEMBLE+=()                # copy files to ensemble members' paths
for (( mem=1; mem<=${ESIZE}; mem++ )); do
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

    sed "s;^exporter_path=.*$;exporter_path="${exporter_path}";g"\
        ${RUNPATH}/${CONFILE} > ${MEMPATH}/${CONFILE}

    sed -e "s;^MEMNAME=.*$;MEMNAME="${MEMNAME}";g" \
        -e "s;^MEMPATH=.*$;MEMPATH="${MEMPATH}";g" \
        ${RUNPATH}/${DYNFILE} > ${MEMPATH}/${SRCFILE}

    if [ ${mem} -gt "1" ];then
        while kill -0 "$XPID"; do
            echo "Process still running... ${XPID}"
            sleep ${TWAIT}
        done
    fi
# submit nextsim run on docker for the ensemble member #${mem}
    cd ${MEMPATH}; source ${ENVFILE}; ID=$( getpid ./${SRUN} ${CONFILE} ${NPROC} )
    XPID=${ID};echo ${XPID}
done

while kill -0 "$XPID"; do
    echo "Process still running... ${XPID}"
    sleep ${TWAIT}
done

# a docker file should be written for enkf
# other option is to loop each ensemble in a docker script then call enkf

cd ${ENSPATH}
for (( mem=1; mem<=${ESIZE}; mem++ )); do
    cp ${ENSEMBLE[${mem}]}/prior.nc ${FILTER}/prior/${ENSEMBLE[${mem}]}.nc
done

# 'make enkf' will call sequentially enkf_{prep,calc,update} executables

cd FILTER; make enkf &> out.enkf


# link mem???.nc.analysis data_links/mem???/analysis.nc/

