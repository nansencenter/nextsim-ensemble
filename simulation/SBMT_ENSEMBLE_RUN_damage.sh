#!/bin/bash

. neXtSIM_io_paths.env      # paths to relevant directories
. ensemble_run_function.sh  # functions used in this script
. ${DYNFILE}   # neXtSIM_ensemble.env
. ${ENVFILE}   # nextsim_johansen.src
> ./nohup.out
rm -rf ${ENSPATH}
checkpath ${ENSPATH}        # check if ensemble root directory/create
checkpath ${EnKFDIR}        # check if ensemble filter directory/create

sed  -e "s;^randf.*$;randf = .false.;g" ./pseudo2D.nml
damage=(-0.1 -0.08 -0.06 -0.04 -0.02  0.02  0.04  0.06  0.08 0.1 0.0)
echo $damage
for (( i=1; i<=${#damage[@]}; i++ )); do
#  for (( mem=1; mem<=${ESIZE}; mem++ )); do
#        MEMBER=$(leadingzero 2 ${mem})
	MEMBER=$(leadingzero 2 ${i})
        MEMNAME=ENS${MEMBER}
        mkdir -p ${ENSPATH}
        MEMPATH=${ENSPATH}/${MEMNAME}; checkpath ${MEMPATH}
        #MEMPATH=${ENSPATH}/${MEMNAME}; checkpath ${MEMPATH}
        SRUN=run_${EXPNAME}_${MEMNAME}.sh
        while true; do
            ${COPY} ${RUNFILE} ${MEMPATH}/${SRUN}
            [ ${DOCKER} != 0 ] && nml_path=${RUNPATH}
            [ ${DOCKER} == 0 ] && nml_path=${MEMPATH}
            [ ${DOCKER} != 0 ] && exporter_path="/docker_io"
            [ ${DOCKER} == 0 ] && exporter_path=${MEMPATH}

            sed "s;^iopath.*$;iopath = '${exporter_path}';g"\
                ${MODPATH}/modules/enkf/perturbation/nml/${NMLFILE} > ${MEMPATH}/${NMLFILE}

            [ ${ENVFILE}x != ''x ] && ${COPY} ${RUNPATH}/${ENVFILE} ${MEMPATH}/.

            sed -e "s;^alea_factor=.*$;alea_factor="${damage[i-1]}";g" \
                -e "s;^exporter_path=.*$;exporter_path="${exporter_path}";g" \
                ${RUNPATH}/${CONFILE} > ${MEMPATH}/${CONFILE}  # CONFILE： nextsim.cfg
            
            sed -e "s;^MEMNAME=.*$;MEMNAME="${MEMNAME}";g" \
                -e "s;^MEMPATH=.*$;MEMPATH="${MEMPATH}";g" \
                ${RUNPATH}/${DYNFILE} > ${MEMPATH}/${SRCFILE}

            cd ${MEMPATH};

            # submit nextsim run on docker for the ensemble member #${mem}
            ID=$( getpid ./${SRUN} ${CONFILE} ${NPROC} )
            XPID=${ID};echo ${XPID}
        #    # check whether current run is ongoing, done or crashed
            while kill -0 "$XPID" ; do
                echo "Process still running... ${XPID}"
                sleep 120
            done
            grep 'Total time spent' ${MEMPATH}/sbmt.log
            if [ $? -eq 0 ];then
                echo "${MEMNAME} is finished"
                break
            else
                # remove all files expect configureation files, go to next cycle to redo the crashed run
                #echo "nextsim exits accidently, recreate ${MEMNAME}"
                rm -rf *
                echo "${XPID} for ${MEMNAME} is stopped accidentally, redo"
            fi
        done
  #  done
done
