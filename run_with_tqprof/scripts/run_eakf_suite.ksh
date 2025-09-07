#!/bin/ksh -x

set echo
echo $(date) "Start"

export DATE=$INITIAL_DATE
export DATE_short=$(echo $DATE | cut -c1-10)

RC=0

while [[ $DATE -le $FINAL_DATE ]]; do 

# Decide whether to assimilate RADAR
if [ $DATE -ge $RADAR_START_DATE  ]; then
   let RADAR_NUMBER=$RADAR_NUMBER+1
fi


# Decide on length of forecast to run
if [ "${CYCLE_NUMBER}" -eq "0" ]; then
    #export FCST_RANGE=${SPINUP_TIME} #jkmod 
    #export FCST_MINUTE=0             #jkmod
    export FCST_RANGE=0
    export FCST_MINUTE=${CYCLE_RADAR}  # 15 min
elif [ "${CYCLE_NUMBER}" -gt "0" ] && [ "${RADAR_NUMBER}" -eq "0" ]; then
    export FCST_RANGE=${CYCLE_PERIOD}  # 3 hour
    export FCST_MINUTE=0
elif [ "${RADAR_NUMBER}" -gt "0" ] && [ $DATE -lt $FINAL_DATE ]; then
    export FCST_RANGE=0
    export FCST_MINUTE=${CYCLE_RADAR}
fi
if [ "${IF_BREAK}" -eq "0" ] && [ $DATE -eq $FINAL_DATE ]; then  # LAST CYCLE
#    export FCST_RANGE=${DE_FCST_RANGE}
#    export FCST_MINUTE=0
    export FCST_RANGE=0
    export FCST_MINUTE=${CYCLE_RADAR}
fi


if [ "${CYCLE_NUMBER}" -eq "0" ]; then
   export PREV_DATE=$($BUILD_DIR/da_advance_time.exe $DATE -${SPINUP_TIME}h -f ccyymmddhhnn 2>/dev/null)
else 
   export PREV_DATE=$($BUILD_DIR/da_advance_time.exe $DATE -${CYCLE_RADAR}m -f ccyymmddhhnn 2>/dev/null)
#elif [ ${CYCLE_NUMBER} -gt 1 ] && [ ${RADAR_NUMBER} -le 1 ]; then
#   #export PREV_DATE=$($BUILD_DIR/da_advance_time.exe $DATE -${CYCLE_PERIOD}h -f ccyymmddhhnn 2>/dev/null) #jkmod
#   export PREV_DATE=$($BUILD_DIR/da_advance_time.exe $DATE -${CYCLE_RADAR}m -f ccyymmddhhnn 2>/dev/null)
#elif [ ${RADAR_NUMBER} -gt 1 ]; then
#   export PREV_DATE=$($BUILD_DIR/da_advance_time.exe $DATE -${CYCLE_RADAR}m -f ccyymmddhhnn 2>/dev/null)
fi

if [ `echo $PREV_DATE | awk '{print length}'` -eq 10 ]; then
   export PREV_DATE=${PREV_DATE}00
fi

export FWD_DATE=$($BUILD_DIR/da_advance_time.exe $DATE ${FCST_RANGE}h${FCST_MINUTE}m -f ccyymmddhhnn 2>/dev/null)
 
echo "============"
echo    $PREV_DATE
echo     $DATE
echo    $FWD_DATE
echo "============"

export YYYY=$(echo $DATE | cut -c1-4)
export MM=$(echo $DATE | cut -c5-6)
export DD=$(echo $DATE | cut -c7-8)
export HH=$(echo $DATE | cut -c9-10)
export MN=$(echo $DATE | cut -c11-12)
export YYYY1=$(echo $FWD_DATE | cut -c1-4)
export MM1=$(echo $FWD_DATE | cut -c5-6)
export DD1=$(echo $FWD_DATE | cut -c7-8)
export HH1=$(echo $FWD_DATE | cut -c9-10)
export MN1=$(echo $FWD_DATE | cut -c11-12)
export FILE_DATE=${YYYY}-${MM}-${DD}_${HH}:${MN}:00


#--------------------------------------------------------------------------------
# [1] Run WPS
#--------------------------------------------------------------------------------
if  $RUN_WPS && [ "$CYCLE_NUMBER" -eq "0" ]; then

     export WORK_DIR=${WPS_RUN_DIR}
     echo "WORK_DIR = $WORK_DIR"
     if [[ ! -d $WORK_DIR ]]; then mkdir -p $WORK_DIR; fi
     cd $WORK_DIR

     echo "running wpsfc"
     $SCRIPTS_DIR/run_wps_fc.ksh > wps_run.log 2>&1

     RC=$?
     if [[ $RC != 0 ]]; then
         echo $(date) "${ERR}wps failed with error $RC$END"
         echo wps > FAIL
         break
     fi

fi
if  $RUN_ENS_WPS && [ "$CYCLE_NUMBER" -eq "0" ]; then
      echo "not running wps_ens becuase already run in generated ens with wrfda"

     export WORK_DIR=${WPS_ENS_DIR}
     echo "DEBUG: WPS_ENS_DIR=${WPS_ENS_DIR}"
     echo "DEBUG: WORK_DIR=${WORK_DIR}"

     if [[ ! -d $WORK_DIR ]]; then mkdir -p $WORK_DIR; fi
     cd $WORK_DIR
     echo "running eps_ens"
     $SCRIPTS_DIR/run_wps_ens.ksh > wps_ens_run.log 2>&1
     echo "running eps_ens done"
     RC=$?
     if [[ $RC != 0 ]]; then
         echo $(date) "${ERR}wps failed with error $RC$END"
         echo wps > FAIL
         break
     fi

fi

echo "222"
#--------------------------------------------------------------------------------
# [2] REAL-FC 
#--------------------------------------------------------------------------------
   
if  $RUN_REAL_FC && [ "${MN}" -eq "00" ]; then 
     export WORK_DIR=${REAL_FC_DIR}
     echo "WORK_DIR = $WORK_DIR"
     if [[ ! -d $WORK_DIR ]]; then mkdir -p $WORK_DIR; fi
     cd $WORK_DIR

     $SCRIPTS_DIR/run_real_fc.ksh > real_fc.log 2>&1

     RC=$?
     if [[ $RC != 0 ]]; then
         echo $(date) "${ERR}real failed with error $RC$END"
         echo wrf > FAIL
         break 
     fi	    

fi  

echo "3333"
if  $RUN_ENS_ICBC && [ "$CYCLE_NUMBER" -eq "0" ]; then
     echo "Do not need to run since im copying ens from wrfda"
     export WORK_DIR=${ICBC_ENS_DIR}
     echo "WORK_DIR = $WORK_DIR"
     if [[ ! -d $WORK_DIR ]]; then mkdir -p $WORK_DIR; fi
     cd $WORK_DIR

     $SCRIPTS_DIR/run_icbc_ens.ksh > icbc_ens_run.log 2>&1

     RC=$?
     if [[ $RC != 0 ]]; then
         echo $(date) "${ERR}wps failed with error $RC$END"
         echo wps > FAIL
         break
     fi

fi


#-----------------------------------------------------------------------
# [3] OBSPROC
#-----------------------------------------------------------------------
 
if $RUN_OBS_D01 && [ "${MN}" -eq "00" ]; then
   
   export WORK_DIR=${OBS_D01_DIR}/${DATE}
   if [[ ! -d $WORK_DIR ]]; then mkdir -p $WORK_DIR; fi
   cd $WORK_DIR
   
   # $SCRIPTS_DIR/run_obs_d01.ksh > obs_d01.log 2>&1 
   
      RC=$?
      if [[ $RC != 0 ]]; then
           echo `date` "${ERR}obsproc Failed with error $RC$END"
           echo hybrid > FAIL
           exit 1	   
      fi

fi 

if $RUN_OBS_D02 && [ ${RADAR_NUMBER} -ge 1 ]; then
   
   export WORK_DIR=${OBS_D02_DIR}/${DATE}
   if [[ ! -d $WORK_DIR ]]; then mkdir -p $WORK_DIR; fi
   cd $WORK_DIR
   
   # $SCRIPTS_DIR/run_obs_d02.ksh > obs_d02.log 2>&1 
   
      RC=$?
      if [[ $RC != 0 ]]; then
           echo `date` "${ERR}obsproc Failed with error $RC$END"
           echo hybrid > FAIL
           exit 1	   
      fi

fi 

#--------------------------------------------------------------------------------
# [4] RANDOM-CV: Generate Initial Ensembles
#--------------------------------------------------------------------------------
if $RUN_RCV && [ "$CYCLE_NUMBER" -eq "0" ]; then

      export WORK_DIR=${RUN_RCV_DIR}/$DATE
      if [[ ! -d $WORK_DIR ]]; then mkdir -p $WORK_DIR; fi
      cd $WORK_DIR

      $SCRIPTS_DIR/run_var_rcv.ksh > ens_rcv.log 2>&1

      RC=$?
      if [[ $? != 0 ]]; then
            echo $(date) "${ERR}run_rcv failed with error $RC$END"
            echo etkf > FAIL
            break
      fi

fi



#-----------------------------------------------------------------------
# Generate Initial Forecast Ensembles
# -----------------------------------------------------------------------
if $RUN_INITIAL_FC && [ "$CYCLE_NUMBER" -eq "0" ]; then
     export WORK_DIR=${INITIAL_FC}
     echo "WORK_DIR = $WORK_DIR"
     if [[ ! -d $WORK_DIR ]]; then mkdir -p $WORK_DIR; fi
     cd $WORK_DIR

     $SCRIPTS_DIR/run_initial_forecast.ksh > initial_forecast.log 2>&1

     RC=$?
     if [[ $RC != 0 ]]; then
         echo $(date) "${ERR}wrf failed with error $RC$END"
         echo wrf > FAIL
         break
     fi

fi

#-----------------------------------------------------------------------
# [5] Run BLENDING
#-----------------------------------------------------------------------

if $RUN_BLEND && [ "$CYCLE_NUMBER" -ge "1" ] && [ "${MN}" -eq "00" ] && [ `expr ${HH} % ${CYCLE_PERIOD}` == 0 ]; then

   export WORK_DIR=${BLEND_DIR}/${DATE}
   if [[ ! -d $WORK_DIR ]]; then mkdir -p $WORK_DIR; fi
   cd $WORK_DIR

   $SCRIPTS_DIR/run_blend.ksh > blend.log 2>&1
   RC=$?

      if [[ $? != 0 ]]; then
            echo $(date) "${ERR}run_blend failed with error $RC$END"
            echo blend > FAIL
            break 2
      fi

fi

# #-----------------------------------------------------------------------
# # [6] Run DART (Ensemble Adaptive Kalman Filter):
# #-----------------------------------------------------------------------

# #if $RUN_DART_D01 && [ "$CYCLE_NUMBER" -ge "1" ] && [ "${MN}" -eq "00" ] && [ `expr ${HH} % ${CYCLE_PERIOD}` == 0 ]; then
# if $RUN_DART_D01 ; then
#    echo "runing DART_D01"
#    export WORK_DIR=${DART_D01_DIR}/${DATE_short}
#    if [[ ! -d $WORK_DIR ]]; then mkdir -p $WORK_DIR; fi
#    cd $WORK_DIR

#    date
#    # sbatch $SCRIPTS_DIR/run_dart_d01.ksh > dart_d01.log 2>&1
#    $SCRIPTS_DIR/run_dart_d01.ksh > dart_d01.log 2>&1 &
#    DART_PID=$!


#    date
#    RC=$?
   
#    if [[ $? != 0 ]]; then
#          echo $(date) "${ERR}run_etkf failed with error $RC$END"
#          echo etkf > FAIL
#          break 2
#    fi 

#    analysis_count=`ls ${WORK_DIR}/analysis/wrfvar_output* | wc -l`
#    echo 'analysis_d01_count= ' $analysis_count
#    while [ ${analysis_count} -ne $NUM_MEMBERS ]
#    do
#        sleep 60
#        analysis_count=`ls ${WORK_DIR}/analysis/wrfvar_output* | wc -l`
#        echo 'analysis_d01_count= ' $analysis_count
#    done

#    upbdy_count=`ls ${WORK_DIR}/analysis/wrfbdy* | wc -l`
#    echo 'upbdy_count= ' $upbdy_count
#    while [ ${upbdy_count} -ne $NUM_MEMBERS ]
#    do
#        sleep 60
#        upbdy_count=`ls ${WORK_DIR}/analysis/wrfbdy* | wc -l`
#        echo 'upbdy_count= ' $upbdy_count
#    done

# fi


if $RUN_DART_D01 ; then
   echo "runing DART_D01"
   export WORK_DIR=${DART_D01_DIR}/${DATE_short}
   if [[ ! -d $WORK_DIR ]]; then mkdir -p $WORK_DIR; fi
   cd $WORK_DIR

   date
   # launch in background, capture PID
   $SCRIPTS_DIR/run_dart_d01.ksh > dart_d01.log 2>&1 &
   DART_PID=$!
   date

   # poll while it runs
   analysis_count=`ls ${WORK_DIR}/analysis/wrfvar_output* 2>/dev/null | wc -l`
   echo 'analysis_d01_count= ' $analysis_count
   upbdy_count=`ls ${WORK_DIR}/analysis/wrfbdy* 2>/dev/null | wc -l`
   echo 'upbdy_count= ' $upbdy_count

   while kill -0 $DART_PID 2>/dev/null
   do
       sleep 60
       analysis_count=`ls ${WORK_DIR}/analysis/wrfvar_output* 2>/dev/null | wc -l`
       echo 'analysis_d01_count= ' $analysis_count
       upbdy_count=`ls ${WORK_DIR}/analysis/wrfbdy* 2>/dev/null | wc -l`
       echo 'upbdy_count= ' $upbdy_count

       # Stop polling when all files are present
       if [ ${analysis_count} -ge $NUM_MEMBERS ] && [ ${upbdy_count} -ge $NUM_MEMBERS ]; then
           echo "All analysis files produced."
           break
       fi
   done

   # Reap background job, get its exit code
   wait $DART_PID
   RC=$?

   if [[ $RC != 0 ]]; then
         echo $(date) "${ERR}run_etkf failed with error $RC$END"
         echo etkf > FAIL
         break 2
   fi

   # ensure it doesn’t run again in later cycles
   RUN_DART_D01=false
fi

#if $RUN_DART_D02 && [ "$RADAR_NUMBER" -ge "1" ]; then
if $RUN_DART_D02 ; then

   export WORK_DIR=${DART_D02_DIR}/${DATE}
   if [[ ! -d $WORK_DIR ]]; then mkdir -p $WORK_DIR; fi
   cd $WORK_DIR

   date
   # qsub $SCRIPTS_DIR/run_dart_d02.ksh > dart_d02.log 2>&1 
   date
   RC=$?

   if [[ $? != 0 ]]; then
         echo $(date) "${ERR}run_etkf failed with error $RC$END"
         echo etkf > FAIL
         break 2
   fi

   analysis_count=`ls ${WORK_DIR}/analysis/wrfvar_output* | wc -l`
   echo 'analysis_d02_count= ' $analysis_count
   while [ ${analysis_count} -ne $NUM_MEMBERS ]
   do
       sleep 60
       analysis_count=`ls ${WORK_DIR}/analysis/wrfvar_output* | wc -l`
       echo 'analysis_d02_count= ' $analysis_count
   done

fi

#--------------------------------------------------------------------------------
# [7] Cycling-mode: Short Range (upto next cycle hour) Ensembles WRF
#--------------------------------------------------------------------------------

# if  $RUN_ENS_WRF; then  
   
#      export WORK_DIR=${ENS_WRF_DIR}/${DATE_short}
#      if [[ ! -d $WORK_DIR ]]; then mkdir -p $WORK_DIR; fi
#      cd $WORK_DIR
# #jkmod=======================
#      if [[ $NUM_MEMBERS -gt 0 ]]; then
#         export MEM=1
#         export JOB=1

#         export START_DATE=`${BUILD_DIR}/da_advance_time.exe $DATE 0 -w`
#         export END_DATE=`${BUILD_DIR}/da_advance_time.exe $DATE ${FCST_RANGE}h${FCST_MINUTE}m -w`

#         export ccyy_s=`echo $START_DATE | cut -c1-4`
#         export mm_s=`echo $START_DATE | cut -c6-7`
#         export dd_s=`echo $START_DATE | cut -c9-10`
#         export hh_s=`echo $START_DATE | cut -c12-13`
#         export mn_s=`echo $START_DATE | cut -c15-16`
#         export ccyy_e=`echo $END_DATE | cut -c1-4`
#         export mm_e=`echo $END_DATE | cut -c6-7`
#         export dd_e=`echo $END_DATE | cut -c9-10`
#         export hh_e=`echo $END_DATE | cut -c12-13`
#         export mn_e=`echo $END_DATE | cut -c15-16`

#       #   export wrfout_tmp=wrfout_d01_${ccyy_e}-${mm_e}-${dd_e}_${hh_e}:${mn_e}:00
#         export wrfout_tmp=wrfout_d01_${ccyy_e}-${mm_e}-${dd_e}_06:${mn_e}:00


#         while [[ $MEM -le $NUM_MEMBERS ]]; do
#            export CMEM=e$MEM
#            export CCMEM=$MEM
#            if [[ $MEM -lt 100 ]]; then export CMEM=e0$MEM; fi
#            if [[ $MEM -lt 10  ]]; then export CMEM=e00$MEM; fi

#            if [[ $MEM -lt 100 ]]; then export CCMEM=0$MEM; fi
#            if [[ $MEM -lt 10  ]]; then export CCMEM=00$MEM; fi
	
#            export RUN_DIR=$WORK_DIR/${CMEM}
#            mkdir -p $RUN_DIR
#            cd $RUN_DIR

#            ln -sf $WRF_DIR/run/* .
#            rm namelist.input

#         #   if [ "$CYCLE_NUMBER" -eq "0" ];then
#         #        if ${USE_GEFS}; then
#         #            cp ${ICBC_ENS_DIR}/${CMEM}/wrfinput_d01 .
#         #            cp ${ICBC_ENS_DIR}/${CMEM}/wrfbdy_d01 .
#         #        else
#         #            cp ${RUN_RCV_DIR}/${DATE}/wrfvar_output_randomcv.${CMEM} wrfinput_d01
#         #            cp ${RUN_RCV_DIR}/${DATE}/wrfbdy_d01.${CMEM}    wrfbdy_d01
#         #         fi
#         #   elif [ "$CYCLE_NUMBER" -gt "0" ] && [ "${mn_s}" -eq "00" ] && [ `expr ${hh_s} % ${CYCLE_PERIOD}` -eq 0 ]; then
               
#                #  cp $DART_D01_DIR/$DATE_short/analysis/wrfvar_output.${CMEM} wrfinput_d01 # supposed to use this but not working
#                #  cp $DART_D01_DIR/$DATE_short/analysis/wrfbdy_d01.${CMEM}    wrfbdy_d01
#         #   else
#         #        cp $ENS_WRF_DIR/$PREV_DATE/${CMEM}/wrfout_d01_${FILE_DATE} wrfinput_d01
#         #        cp $ENS_WRF_DIR/$PREV_DATE/${CMEM}/wrfbdy_d01    wrfbdy_d01
#         #   fi

#         #   if [ "${RADAR_NUMBER}" -ge "1" ]; then
#                #   cp $DART_D02_DIR/$DATE/analysis/wrfvar_output.${CMEM} wrfinput_d02
#         #   fi


#            date 
#            sbatch $SCRIPTS_DIR/run_wrf_ens.ksh > wrf_ens_${CMEM}.log 2>&1 
#            date 
#            RC=$?

#            if [[ $RC != 0 ]]; then
#                echo $(date) "${ERR}wrf failed with error $RC$END"
#            echo wrf > FAIL
#            break 2 
#            fi	 
   
#            let MEM=$MEM+1
#            let JOB=$JOB+1

#            if [[ $JOB -gt $NUM_JOBS || $MEM -gt $NUM_MEMBERS ]]; then
#               export JOB=1
#               wait # Wait for current jobs to finish
#            fi
#            sleep 2 # Leave 1s gap between job start
#          done

#          wrf_count=`ls ${WORK_DIR}/e*/${wrfout_tmp} | wc -l` 
#          echo 'wrf_count= ' $wrf_count
#          while [ ${wrf_count} -ne $NUM_MEMBERS ]
#          do
#              sleep 120
#              wrf_count=`ls ${WORK_DIR}/e*/${wrfout_tmp} | wc -l`
#              echo 'wrf_count= ' $wrf_count
#          done
#          sleep 120
#      fi  
# #jkmod=======================
# fi  


if $RUN_ENS_WRF; then
    WORK_DIR="${ENS_WRF_DIR}/${DATE_short}"
    mkdir -p "$WORK_DIR"
    cd "$WORK_DIR" || exit 1

    START_DATE="$(${BUILD_DIR}/da_advance_time.exe "$DATE" 0 -w)"
    END_DATE="$(${BUILD_DIR}/da_advance_time.exe "$DATE" ${FCST_RANGE}h${FCST_MINUTE}m -w)"
    echo "END_DATE = $END_DATE"

    export WORK_DIR START_DATE END_DATE NUM_MEMBERS \
           ENS_WRF_DIR DATE DATE_short BUILD_DIR FCST_RANGE FCST_MINUTE \
           LBC_FREQ CYCLE_RADAR INPUT_FROM_FILE_1 INPUT_FROM_FILE_2 \
           NL_TIME_STEP NL_E_WE_1 NL_E_WE_2 NL_E_SN_1 NL_E_SN_2 NL_E_VERT \
           NL_DXY_1 NL_DXY_2 I_PARENT_START_2 J_PARENT_START_2 PARENT_GRID_RATIO_2 \
           FEEDBACK NL_P_TOP_REQUESTED NL_NUM_METGRID_LEVELS NL_ETA_LEVELS \
           NL_MP_PHYSICS NL_RA_LW NL_RA_SW NL_RADT1 NL_RADT2 NL_SF_SFCLAY_PHYSICS \
           NL_SF_SURFACE_PHYSICS NL_BL_PBL_PHYSICS NL_BLDT NL_CU_PHYSICS1 \
           NL_CU_PHYSICS2 NL_CUDT1 NL_CUDT2 SKEB PERT_BDY WRF_DIR DART_DIR

      jid=$(sbatch --array=1-${NUM_MEMBERS} "$SCRIPTS_DIR/run_wrf_ens.ksh" | awk '{print $NF}')
      # while squeue -h -j "$jid" >/dev/null 2>&1; do sleep 60; done
      echo "Waiting for SLURM job $jid to finish..."
      while [[ -n $(squeue -h -j "$jid") ]]; do
         echo "$(date): Job $jid is still running..."
         sleep 60
      done
      echo "Job $jid has completed."
fi





if $RUN_DART_D01_2; then
   echo "runing DART_D01_2"
   export WORK_DIR=${DART_D01_2_DIR}/${DATE_short}
   if [[ ! -d $WORK_DIR ]]; then mkdir -p $WORK_DIR; fi
   cd $WORK_DIR

   date
   # launch in background, capture PID
   $SCRIPTS_DIR/run_dart_d01_2.ksh > dart_d01_2.log 2>&1 &
   DART_PID=$!
   date

   # poll while it runs
   analysis_count=`ls ${WORK_DIR}/analysis/wrfvar_output* 2>/dev/null | wc -l`
   echo 'analysis_d01_count= ' $analysis_count
   upbdy_count=`ls ${WORK_DIR}/analysis/wrfbdy* 2>/dev/null | wc -l`
   echo 'upbdy_count= ' $upbdy_count

   while kill -0 $DART_PID 2>/dev/null
   do
       sleep 60
       analysis_count=`ls ${WORK_DIR}/analysis/wrfvar_output* 2>/dev/null | wc -l`
       echo 'analysis_d01_count= ' $analysis_count
       upbdy_count=`ls ${WORK_DIR}/analysis/wrfbdy* 2>/dev/null | wc -l`
       echo 'upbdy_count= ' $upbdy_count

       # Stop polling when all files are present
       if [ ${analysis_count} -ge $NUM_MEMBERS ] && [ ${upbdy_count} -ge $NUM_MEMBERS ]; then
           echo "All analysis files produced."
           break
       fi
   done

   # Reap background job, get its exit code
   wait $DART_PID
   RC=$?

   if [[ $RC != 0 ]]; then
         echo $(date) "${ERR}run_etkf failed with error $RC$END"
         echo etkf > FAIL
         break 2
   fi

   # ensure it doesn’t run again in later cycles
   RUN_DART_D01_2=false
fi




#--------------------------------------------------------------------------------
# [8] Average ensembles
#--------------------------------------------------------------------------------
   if $RUN_ENSMEAN_D01; then
      export WORK_DIR=$ENSMEAN_DIR/${DATE}
      if [[ ! -d $WORK_DIR ]]; then mkdir -p $WORK_DIR; fi

      export FCST_RANGE=$CYCLE_PERIOD
      #jk added(output_dir: /scratch/jkkay/WRFV3/DAOU/WRFDA_save/DA_cyc/fc/2013110300)

      #$SCRIPTS_DIR/da_trace.sh gen_be_ensmean $RUN_DIR
      $SCRIPTS_DIR/da_run_ensmean_d01.ksh > wrf_ensmean_d01.log 2>&1 & 
      RC=$?
      if [[ $? != 0 ]]; then
         echo $(date) "${ERR}ensmean failed with error $RC$END"
         echo ensmean > FAIL
         break
      fi
      while [ ! -f $WORK_DIR/wrfvar_output_d01.mean.org ]
      do
           sleep 120
      done
   fi

   if $RUN_ENSMEAN_D02; then
      export WORK_DIR=$ENSMEAN_DIR/${DATE}
      if [[ ! -d $WORK_DIR ]]; then mkdir -p $WORK_DIR; fi

      export FCST_RANGE=$CYCLE_PERIOD
      #jk added(output_dir: /scratch/jkkay/WRFV3/DAOU/WRFDA_save/DA_cyc/fc/2013110300)

      #$SCRIPTS_DIR/da_trace.sh gen_be_ensmean $RUN_DIR
      $SCRIPTS_DIR/da_run_ensmean_d02.ksh > wrf_ensmean_d02.log 2>&1 &
      RC=$?
      if [[ $? != 0 ]]; then
         echo $(date) "${ERR}ensmean failed with error $RC$END"
         echo ensmean > FAIL
         break
      fi
      while [ ! -f $WORK_DIR/wrfvar_output_d02.mean.org ]
      do
           sleep 120
      done
   fi

   if $RUN_ENSMEAN_BG_D01; then
      export WORK_DIR=$ENSMEAN_BG_DIR/${DATE}
      if [[ ! -d $WORK_DIR ]]; then mkdir -p $WORK_DIR; fi

      export FCST_RANGE=$CYCLE_PERIOD
      #jk added(output_dir: /scratch/jkkay/WRFV3/DAOU/WRFDA_save/DA_cyc/fc/2013110300)

      #$SCRIPTS_DIR/da_trace.sh gen_be_ensmean $RUN_DIR
      $SCRIPTS_DIR/da_run_ensmean_bg_d01.ksh > wrf_ensmean_bg_d01.log 2>&1 &
      RC=$?
      if [[ $? != 0 ]]; then
         echo $(date) "${ERR}ensmean failed with error $RC$END"
         echo ensmean > FAIL
         break
      fi
      while [ ! -f $WORK_DIR/wrfinput_d01.mean.org ]
      do
           sleep 120
      done
   fi

   if $RUN_ENSMEAN_BG_D02; then
      export WORK_DIR=$ENSMEAN_BG_DIR/${DATE}
      if [[ ! -d $WORK_DIR ]]; then mkdir -p $WORK_DIR; fi

      export FCST_RANGE=$CYCLE_PERIOD
      #jk added(output_dir: /scratch/jkkay/WRFV3/DAOU/WRFDA_save/DA_cyc/fc/2013110300)

      #$SCRIPTS_DIR/da_trace.sh gen_be_ensmean $RUN_DIR
      $SCRIPTS_DIR/da_run_ensmean_bg_d02.ksh > wrf_ensmean_bg_d02.log 2>&1 &
      RC=$?
      if [[ $? != 0 ]]; then
         echo $(date) "${ERR}ensmean failed with error $RC$END"
         echo ensmean > FAIL
         break
      fi
      while [ ! -f $WORK_DIR/wrfinput_d02.mean.org ]
      do
           sleep 120
      done
      sleep 120
   fi
#--------------------------------------------------------------------------------
#  Next cycle....
#--------------------------------------------------------------------------------  
   export DATE=${FWD_DATE}
    
   let CYCLE_NUMBER=$CYCLE_NUMBER+1   
   #exit 0 #jkmod
done

echo $(date) "Finished"

if [[ $RC == 0 ]]; then
      touch SUCCESS
fi

exit $RC 
