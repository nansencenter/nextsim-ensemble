#!/bin/bash

sed -i --follow-symlinks "s;^randf.*$;randf = .true.;g" ./pseudo2D.nml
sed -i --follow-symlinks "s;^vwndspd.*$;vwndspd = 0.64;g" ./pseudo2D.nml
#sed -i "s/^EXPNAME.*$/EXPNAME=neXtSIM_test20_06/g" ./neXtSIM_ensemble.env
ASR_air_drag=(0.001 0.0015 0.002 0.0025 0.003 0.0035 0.004 0.0045)
#############################################################################
. ~/.bashrc
. neXtSIM_io_paths.env      # paths to relevant directories
. ensemble_run_function.sh  # functions used in this script
. ${DYNFILE}   # neXtSIM_ensemble.env
. ${ENVFILE}   # nextsim_johansen.src
> ./nohup_2306.out
rm -rf ${ENSPATH}
checkpath ${ENSPATH}        # check if ensemble root directory/create
checkpath ${FILTER}        # check if ensemble filter directory/create

ESIZE=${#ASR_air_drag[@]}
for (( mem=1; mem<=${ESIZE}; mem++ )); do
        MEMBER=$(leadingzero 2 ${mem})
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

            sed -e "s;^iopath.*$;iopath = '${exporter_path}';g"\
                ${MODPATH}/modules/enkf/perturbation/nml/${NMLFILE} > ${MEMPATH}/${NMLFILE}

            [ ${ENVFILE} != '' ] && ${COPY} ${RUNPATH}/${ENVFILE} ${MEMPATH}/.

             sed -e "s;^exporter_path=.*$;exporter_path="${exporter_path}";g" \
                 -e "s;^ASR_quad_drag_coef_air=.*$;ASR_quad_drag_coef_air="${ASR_air_drag[mem-1]}";g" \
                ${RUNPATH}/${CONFILE} > ${MEMPATH}/${CONFILE}  # CONFILE  nextsim.cfg
            
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
done
