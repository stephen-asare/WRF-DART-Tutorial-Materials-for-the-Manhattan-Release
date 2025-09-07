#!/bin/ksh -x

#########################################################################
# Script: run_real_fc.ksh
#
# Purpose: 
#
# WYB, 01/2013
#########################################################################

date

export OUTPUT_FREQ_MINUTE=`expr 60 \* ${OUTPUT_INTERVAL}`
export LBC_FREQ_SECOND=`expr 3600 \* ${LBC_FREQ}` # for REAL interpolation

export START_DATE=`${BUILD_DIR}/da_advance_time.exe $DATE 0 -w`
export END_DATE=`${BUILD_DIR}/da_advance_time.exe $DATE $DE_FCST_RANGE -w`
export ccyy_s=`echo $START_DATE | cut -c1-4`
export mm_s=`echo $START_DATE | cut -c6-7`
export dd_s=`echo $START_DATE | cut -c9-10`
export hh_s=`echo $START_DATE | cut -c12-13`
export ccyy_e=`echo $END_DATE | cut -c1-4`
export mm_e=`echo $END_DATE | cut -c6-7`
export dd_e=`echo $END_DATE | cut -c9-10`
export hh_e=`echo $END_DATE | cut -c12-13`

IMEM=22
while (( IMEM <= ${NUM_MEMBERS} )) ; do

if [[ $IMEM -lt 100 ]]; then export CMEM=e0$IMEM;  fi
if [[ $IMEM -lt 10  ]]; then export CMEM=e00$IMEM; fi

if [[ ! -d $WORK_DIR/$CMEM ]]; then mkdir -p $WORK_DIR/$CMEM; fi
cd $WORK_DIR/$CMEM

if [[ $IMEM -le $NUM_GEFS ]]; then

ln -sf $WRF_DIR/run/* .
rm namelist.input    

ln -sf ${WPS_ENS_DIR}/$CMEM/met_em* .

# create namelist.input
cat > namelist.input << EOF
 &time_control
 run_days                            = 0,
 run_hours                           = ${DE_FCST_RANGE},
 run_minutes                         = 0,
 run_seconds                         = 0,
 start_year                          = ${ccyy_s},${ccyy_s},
 start_month                         = ${mm_s},${mm_s} 
 start_day                           = ${dd_s},${dd_s} 
 start_hour                          = ${hh_s},${hh_s}
 start_minute                        = 00,00, 
 start_second                        = 00,00,  
 end_year                            = ${ccyy_e},${ccyy_e} 
 end_month                           = ${mm_e},${mm_e} 
 end_day                             = ${dd_e},${dd_e}  
 end_hour                            = ${hh_e},${hh_e} 
 end_minute                          = 00,00, 
 end_second                          = 00,00,  
 interval_seconds                    = ${LBC_FREQ_SECOND},
 input_from_file                     = .true.,.true.,
 history_interval                    = ${OUTPUT_FREQ_MINUTE},${OUTPUT_FREQ_MINUTE}, 
 frames_per_outfile                  = 1,1,
 restart                             = .false.,
 restart_interval                    = 2161,
 debug_level                         = 0,
 write_input                         = .false.,
 /

 &domains
 time_step                           = ${NL_TIME_STEP},  
 time_step_fract_num                 = 0,
 time_step_fract_den                 = 1,
 max_dom                             = 1,
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
 num_metgrid_levels                  = 17
 num_metgrid_soil_levels             = 4,
 hypsometric_opt                     = 2,
 smooth_option                       = 0,
 eta_levels                          = ${NL_VERT_LEVELS}
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
 diff_opt                            = 1,
 gwd_opt                             = 1,
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

${RUN_CMD}  ./real.exe

else # Because the number of GEFS is limited, so use random_cv to generate the rest initial ensembles.

export DATE0=`${BUILD_DIR}/da_advance_time.exe ${DATE} +0h00min -wrf`
export DATE1=`${BUILD_DIR}/da_advance_time.exe ${DATE} ${WINDOW_START} -wrf`
export DATE2=`${BUILD_DIR}/da_advance_time.exe ${DATE} ${WINDOW_END} -wrf`

export START_DATE=`${BUILD_DIR}/da_advance_time.exe $DATE 0 -w`
export ccyy_s=`echo $START_DATE | cut -c1-4`
export mm_s=`echo $START_DATE | cut -c6-7`
export dd_s=`echo $START_DATE | cut -c9-10`
export hh_s=`echo $START_DATE | cut -c12-13`

let SEED1=1

ln -sf ${WRFVAR_DIR}/run/LANDUSE.TBL  ./

if [ "$CV_OPTIONS" -eq "3" ]; then
   ln -sf ${WRFVAR_DIR}/var/run/be.dat.cv3 ./be.dat
else
   ln -sf ${BE_DIR}/be.dat.rcv  ./be.dat
fi

(( MEM=IMEM-${NUM_GEFS} ))
if [[ $MEM -lt 100 ]]; then export CMEM2=e0$MEM; fi
if [[ $MEM -lt 10  ]]; then export CMEM2=e00$MEM; fi

cp  $ICBC_ENS_DIR/$CMEM2/wrfinput_d01 ./fg
cp  $ICBC_ENS_DIR/$CMEM2/wrfbdy_d01 .

# create WRFVAR namelist
export SEED2=$((${SEED1}*100))

rm -f ./namelist.input
cat > namelist.input << EOF 
&wrfvar1
/
&wrfvar2
/
&wrfvar3
/
&wrfvar4
/
&wrfvar5
put_rand_seed                       = .true.,
check_max_iv                        = .false.,
/
&wrfvar6
/
&wrfvar7
cv_options                          = ${CV_OPTIONS1},
/
&wrfvar8
/
&wrfvar9
/
&wrfvar10
/
&wrfvar11
cv_options_hum                      = 1,
check_rh                            = 1,
seed_array1                         = ${SEED1},
seed_array2                         = ${SEED2},
/
&wrfvar12
/
&wrfvar13
/
&wrfvar14
/
&wrfvar15
/
&wrfvar16
/
&wrfvar17
 analysis_type                       = 'RANDOMCV',
/
&wrfvar18
analysis_date="${DATE0}.0000",
/
&wrfvar19
/
&wrfvar20
/
&wrfvar21
time_window_min="${DATE1}.0000",
/
&wrfvar22
time_window_max="${DATE2}.0000",
/
&wrfvar23
/
&time_control
force_use_old_data=${FORCE_USE_OLD_DATA}
/
&fdda
/
&domains
e_we                                = ${NL_E_WE_1}
e_sn                                = ${NL_E_SN_1}
e_vert                              = ${NL_E_VERT}
dx                                  = ${NL_DXY_1}
dy                                  = ${NL_DXY_1}
/
&physics
mp_physics                          = ${NL_MP_PHYSICS},
sf_sfclay_physics                   = ${NL_SF_SFCLAY_PHYSICS},
sf_surface_physics                  = ${NL_SF_SURFACE_PHYSICS},
num_soil_layers                     = ${NL_NUM_SOIL_LAYERS},
/
&dfi_control
/
&namelist_quilt
/
EOF

ln -sf ${BUILD_DIR}/da_wrfvar.exe .
${RUN_CMD} ./da_wrfvar.exe  > run_rcv.out 2>&1

# update lateral boundary
cat > parame.in << EOF
&control_param
 da_file            = 'wrfvar_output_randomcv.e001'
 wrf_bdy_file       = 'wrfbdy_d01'
 update_lateral_bdy = .true.
 update_low_bdy     = .false.
 update_lsm         = .false.
 iswater            = 16 /
EOF

ln -sf ${BUILD_DIR}/da_update_bc.exe .
./da_update_bc.exe

mv wrfvar_output_randomcv.e001 wrfinput_d01
fi

(( IMEM=IMEM+1 ))
done



date

exit 0

