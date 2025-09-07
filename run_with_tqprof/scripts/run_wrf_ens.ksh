#!/bin/ksh -x

#########################################################################
# Script: run_wrf_ens.ksh
#
# Purpose: Run WRF ensemble forecast 
#
# WYB, 01/2014
#
#######################################################################
#SBATCH --job-name=WRF_dart
#SBATCH --partition=backfill2
#SBATCH -A backfill2
#SBATCH -t 00:30:00
#SBATCH --ntasks=64
#SBATCH --nodes=10
#SBATCH --mem-per-cpu=4000M
#SBATCH --array=1-5 
#SBATCH --output=WRF_DART.%A_%a.log
#SBATCH --export=ALL
#######################################################################
ulimit -s unlimited
date

# ---- identify member ----
IMEM=${SLURM_ARRAY_TASK_ID:-1}
CMEM=$(printf 'e%03d' "$IMEM")
echo "Running $CMEM"

RUN_DIR="${WORK_DIR}/${CMEM}"
mkdir -p "$RUN_DIR"
cd "$RUN_DIR" || exit 1



cd $RUN_DIR

export MAX_DOM=1

# if [ ${FWD_DATE} -eq ${RADAR_START_DATE} ]; then
#   export INPUT_FROM_FILE_2=.false.
#   export MAX_DOM=2
# elif [ "${RADAR_NUMBER}" -ge "1" ]; then 
#   export INPUT_FROM_FILE_2=.true.
#   export MAX_DOM=2
# fi

#export OUTPUT_FREQ_MINUTE=`expr 60 \* ${OUTPUT_INTERVAL}`

#if [ ${RADAR_NUMBER} -ge 1 ] && [ ${DATE} -lt ${FINAL_DATE} ];then
   export OUTPUT_FREQ_MINUTE=${CYCLE_RADAR}
#fi

export LBC_FREQ_SECOND=`expr 3600 \* ${LBC_FREQ}` # for REAL interpolation

export START_DATE=2017-04-27_06:00:00 #`${BUILD_DIR}/da_advance_time.exe $DATE 0 -w`
echo "START_DATE = $START_DATE"
export END_DATE=2017-04-27_12:00:00 #`${BUILD_DIR}/da_advance_time.exe $DATE ${FCST_RANGE}h${FCST_MINUTE}m -w`

export ccyy_s=`echo $START_DATE | cut -c1-4`
export mm_s=`echo $START_DATE | cut -c6-7`
export dd_s=`echo $START_DATE | cut -c9-10`
export hh_s=`echo $START_DATE | cut -c12-13`
export mn_s=`echo $START_DATE | cut -c15-16`
export ccyy_e=`echo $END_DATE | cut -c1-4`
export mm_e=`echo $END_DATE | cut -c6-7`
export dd_e=`echo $END_DATE | cut -c9-10`
export hh_e=`echo $END_DATE | cut -c12-13`
export mn_e=`echo $END_DATE | cut -c15-16`

# IMEM=1
# while (( IMEM <= $NUM_MEMBERS )) ; do	 
# if [[ $IMEM -lt 100 ]]; then export CMEM=e0$IMEM; fi
# if [[ $IMEM -lt 10  ]]; then export CMEM=e00$IMEM; fi

if [[ ! -d $WORK_DIR/$CMEM ]]; then mkdir -p $WORK_DIR/$CMEM; fi
cd $WORK_DIR/$CMEM

ln -sf $WRF_DIR/run/* .
ln -sf $DART_DIR/models/wrf/work/pert_wrf_bc .

cp /gpfs/research/scratch/sa24m/base/output/2017042706/input.nml input.nml

###Try ####
cp /gpfs/research/chipilskigroup/stephen_asare/mpd/osse_out/dart_eakf_d01/2017042700/postassim_priorinf_mean.nc input_priorinf_mean.nc
cp /gpfs/research/chipilskigroup/stephen_asare/mpd/osse_out/dart_eakf_d01/2017042700/postassim_priorinf_sd.nc input_priorinf_sd.nc

# cp /gpfs/research/chipilskigroup/stephen_asare/mpd/osse_out/dart_eakf_d01/2017042700/posts/wrfinput_d01.$CMEM wrfinput_d01
cp /gpfs/research/chipilskigroup/stephen_asare/mpd/osse_out/dart_eakf_d01/2017042700/analysis/wrfvar_output.$CMEM wrfinput_d01
# cp /gpfs/research/chipilskigroup/stephen_asare/icbc/test/rc/2017042700/wrfbdy_d01.$CMEM wrfbdy_d01
ln -sf /gpfs/research/chipilskigroup/stephen_asare/wrf_dart_debug_data/base/output/2017042706/wrfbdy_d01_152057_43200_mean wrfbdy_d01

######################
# cp /gpfs/research/chipilskigroup/stephen_asare/mpd/osse_out/initial_fc/$CMEM/wrfout_d01_2017-04-27_06:00:00 wrfinput_d01 #worked
# cp /gpfs/research/chipilskigroup/stephen_asare/icbc/test/rc/2017042700/wrfbdy_d01.$CMEM wrfbdy_d01
# cp /gpfs/research/chipilskigroup/stephen_asare/icbc/test/rc/2017042700/wrfbdy_d01.$CMEM wrfbdy_d01
# cp /gpfs/research/scratch/sa24m/base2/base/output/2017042706/wrfbdy_d01_152057_43200_mean wrfbdy_d01 # worked
rm namelist.input    
# # cp /gpfs/research/scratch/sa24m/base2/base/output/2017042700/wrfinput_d01_152057_21600_mean wrfinput_next
# cp /gpfs/research/scratch/sa24m/base2/base/output/2017042706/wrfinput_d01_152057_43200_mean wrfinput_next  #worked
# cp /gpfs/research/scratch/sa24m/base2/base/output/2017042700/wrfinput_d01_152057_0_mean wrfinput_this #worked
# # cp /gpfs/research/scratch/sa24m/base2/base/output/2017042700/wrfbdy_d01_152057_21600_mean wrfbdy_this
# cp /gpfs/research/chipilskigroup/stephen_asare/wrf_dart_debug_data/base/output/2017042706/wrfbdy_d01_152057_43200_mean wrfbdy_this #worked
cp /gpfs/research/scratch/sa24m/base/output/2017042706/namelist.input namelist.input

echo "start_year                          = ${ccyy_s},${ccyy_s}"
echo " start_month                         = ${mm_s},${mm_s} "
echo "start_day                           = ${dd_s},${dd_s} "
echo "start_hour                          = ${hh_s},${hh_s}"
echo " start_minute                        = ${mn_s},${mn_s}, "

sed -i '/^ *end_hour *=/c\end_hour                   = '${hh_s}','${hh_s}',' namelist.input


ln -sf /gpfs/research/chipilskigroup/stephen_asare/mpd/osse_out/dart_eakf_d01/2017042700/analysis/wrfvar_output.$CMEM wrfinput_this
ln -sf /gpfs/research/chipilskigroup/stephen_asare/wrf_dart_debug_data/base/output/2017042706/wrfbdy_d01_152057_43200_mean wrfbdy_this
ln -sf /gpfs/research/chipilskigroup/stephen_asare/wrf_dart_debug_data/base/output/2017042706/wrfinput_d01_152057_43200_mean wrfinput_next
# ./pert_wrf_bc # out.pert_wrf_bc 2>&1 #worked
./pert_wrf_bc > pert_${CMEM}.log 2>&1 || exit $?
rm wrfinput_this wrfinput_next wrfbdy_this #worked
# if [ "$CYCLE_NUMBER" -eq "0" ];then
#   if ${USE_GEFS}; then
#      cp ${ICBC_ENS_DIR}/${CMEM}/wrfinput_d01 .
#      cp ${ICBC_ENS_DIR}/${CMEM}/wrfbdy_d01 .
#   else
#      cp ${RUN_RCV_DIR}/${DATE}/wrfvar_output_randomcv.${CMEM} wrfinput_d01  
#      cp ${RUN_RCV_DIR}/${DATE}/wrfbdy_d01.${CMEM}    wrfbdy_d01 
#   fi
# elif [ "$CYCLE_NUMBER" -gt "0" ] && [ "${mn_s}" -eq "00" ] && [ `expr ${hh_s} % ${CYCLE_PERIOD}` -eq 0 ]; then	  
#   echo "Copying wrfinput_d01 and wrfbdy_d01 from DART_D01_DIR"
  # cp $DART_D01_DIR/$DATE/analysis/wrfvar_output.${CMEM} wrfinput_d01  
#   cp $DART_D01_DIR/$DATE/analysis/wrfbdy_d01.${CMEM}    wrfbdy_d01 
# else
#   echo "Copying wrfinput_d01 and wrfbdy_d01 from ENS_WRF_DIR"
  # cp $ENS_WRF_DIR/$PREV_DATE/${CMEM}/wrfout_d01_${FILE_DATE} wrfinput_d01
  # cp $ENS_WRF_DIR/$PREV_DATE/${CMEM}/wrfbdy_d01    wrfbdy_d01
#   echo "Previous date is ${PREV_DATE} and file date is ${FILE_DATE}"
#   cp ${ENS_ICBC_DIR}/${PREV_DATE}/wrfinput_d01.${FILE_DATE}.$CMEM wrfinput_d01
#   cp ${ENS_ICBC_DIR}/${PREV_DATE}/wrfbdy_d01.${FILE_DATE}.$CMEM wrfbdy_d01
# fi

# if [ "${RADAR_NUMBER}" -ge "1" ]; then
#   cp $DART_D02_DIR/$DATE/analysis/wrfvar_output.${CMEM} wrfinput_d02
# fi


# create namelist.input
cat > namelist.input << EOF
 &time_control
 run_days                            = 0,
 run_hours                           = ${FCST_RANGE},
 run_minutes                         = ${FCST_MINUTE},
 run_seconds                         = 0,
 start_year                          = ${ccyy_s},${ccyy_s},
 start_month                         = ${mm_s},${mm_s} 
 start_day                           = ${dd_s},${dd_s} 
 start_hour                          = ${hh_s},${hh_s}
 start_minute                        = ${mn_s},${mn_s}, 
 start_second                        = 00,00,  
 end_year                            = ${ccyy_e},${ccyy_e} 
 end_month                           = ${mm_e},${mm_e} 
 end_day                             = ${dd_e},${dd_e}  
 end_hour                            = ${hh_e},${hh_e} 
 end_minute                          = ${mn_e},${mn_e}
 end_second                          = 00,00,  
 interval_seconds                    = ${LBC_FREQ_SECOND},
 input_from_file                     = ${INPUT_FROM_FILE_1},${INPUT_FROM_FILE_2}
 history_interval                    = ${OUTPUT_FREQ_MINUTE},${OUTPUT_FREQ_MINUTE}, 
 frames_per_outfile                  = 1,1,
 restart                             = .false.,
 restart_interval                    = 2161,
 debug_level                         = 0,
 write_input                         = .false.,
 input_outname="wrfinput_d<domain>_<date>",
 inputout_interval                   =${CYCLE_RADAR}, ${CYCLE_RADAR},
 inputout_begin_m                    = 0,  0,
 inputout_end_m                      = ${CYCLE_RADAR},  ${CYCLE_RADAR},
 /

 &domains
 time_step                           = ${NL_TIME_STEP},  
 time_step_fract_num                 = 0,
 time_step_fract_den                 = 1,
 max_dom                             = ${MAX_DOM},
 e_we                                = ${NL_E_WE_1},${NL_E_WE_2} 
 e_sn                                = ${NL_E_SN_1},${NL_E_SN_2}
 e_vert                              = ${NL_E_VERT},${NL_E_VERT}
 dx                                  = ${NL_DXY_1},${NL_DXY_2} 
 dy                                  = ${NL_DXY_1},${NL_DXY_2}
 grid_id                             = 1, 2, 
 parent_id                           = 0, 1,
 i_parent_start                      = 1, ${I_PARENT_START_2}
 j_parent_start                      = 1, ${J_PARENT_START_2}
 parent_grid_ratio                   = 1, ${PARENT_GRID_RATIO_2}
 parent_time_step_ratio              = 1, ${PARENT_GRID_RATIO_2} 
 feedback                            = ${FEEDBACK},
 p_top_requested                     = ${NL_P_TOP_REQUESTED},
 num_metgrid_levels                  = ${NL_NUM_METGRID_LEVELS},
 num_metgrid_soil_levels             = 4,
 hypsometric_opt                     = 2,
 smooth_option                       = 0,
 eta_levels                          = ${NL_ETA_LEVELS}
 /

 &physics
 mp_physics                          = ${NL_MP_PHYSICS},${NL_MP_PHYSICS},
 ra_lw_physics                       = ${NL_RA_LW}, ${NL_RA_LW},  
 ra_sw_physics                       = ${NL_RA_SW}, ${NL_RA_SW},
 radt                                = ${NL_RADT1}, ${NL_RADT2}, 
 sf_sfclay_physics                   = ${NL_SF_SFCLAY_PHYSICS}, ${NL_SF_SFCLAY_PHYSICS},
 sf_surface_physics                  = ${NL_SF_SURFACE_PHYSICS}, ${NL_SF_SURFACE_PHYSICS}, 
 bl_pbl_physics                      = ${NL_BL_PBL_PHYSICS},  ${NL_BL_PBL_PHYSICS},
 bldt                                = ${NL_BLDT}, 
 cu_physics                          = ${NL_CU_PHYSICS1},${NL_CU_PHYSICS2},   
 cudt                                = ${NL_CUDT1},${NL_CUDT2},  
 DO_RADAR_REF                        = 1,
 isfflx                              = 1,
 ifsnow                              = 1,
 icloud                              = 1,
 surface_input_source                = 1,
 num_soil_layers                     = 4,
 NUM_LAND_CAT =         24
 /
 
 &stoch
 stoch_force_opt                     =$SKEB,
 stoch_vertstruc_opt                 =1,
 tot_backscat_psi                    =1.0E-5
 tot_backscat_t                      =1.0E-6
 nens                                =$NUM_MEMBERS
 perturb_bdy                         =$PERT_BDY
 /
 
 &fdda
 /

 &dynamics
 w_damping                           = 1,
 gwd_opt                             = 0,
 diff_opt                            = 1,
 km_opt                              = 4,
 diff_6th_opt                        = 0,
 diff_6th_factor                     = 0.12,
 base_temp                           = 290.,
 damp_opt                            = 0,
 zdamp                               = 5000., 5000.,
 dampcoef                            = 0.15, 0.15, 
 khdif                               = 0, 0,  
 kvdif                               = 0, 0,
 non_hydrostatic                     = .true., .true.,
 moist_adv_opt                       = 1, 1,
 scalar_adv_opt                      = 0, 0,
 /
 &bdy_control
 spec_bdy_width                      = 5,
 spec_zone                           = 1,
 relax_zone                          = 4,
 specified                           = .true., .false., 
 nested                              = .false., .true.,
 /
 &grib2
 /
 &namelist_quilt
 nio_tasks_per_group = 0,
 nio_groups = 1,
 /
 &dfi_control
 /
EOF
cp /gpfs/research/scratch/sa24m/base/output/2017042706/namelist.input namelist.input
sed -i '/^ *history_interval *=/c\ history_interval                   = 15, 15,' namelist.input

   echo  "NOW $CMEM RUNNING!!!"	 
  #  ${RUN_CMD} ./wrf.exe
   srun -N 10  -n 64 ./wrf.exe > wrf_${CMEM}.log 2>&1
   RC=$?
   [[ -f rsl.out.0000 ]] && grep -q 'SUCCESS COMPLETE WRF' rsl.out.0000 || RC=1

#   if  grep -q 'SUCCESS COMPLETE WRF' rsl.out.0000; then echo success;else ${RUN_CMD} ./wrf.exe; fi
   
      # if [[ -f rsl.out.0000 ]]; then
      #   grep -q 'SUCCESS COMPLETE WRF' rsl.out.0000
      #   RC=$?		
      # fi

  #    (( IMEM=IMEM+1 ))
  # done

date

exit $RC

