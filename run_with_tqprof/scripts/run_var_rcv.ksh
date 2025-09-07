#!/bin/ksh -x

date

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

cp  $REAL_FC_DIR/$DATE/wrfinput_d01 ./fg	  	

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
use_synopobs                        = .false.,
use_shipsobs                        = .false.,
use_metarobs                        = .false.,
use_soundobs                        = .false.,
use_pilotobs                        = .false.,
use_airepobs                        = .false.,
use_geoamvobs                       = .false.,
use_polaramvobs                     = .false.,
use_bogusobs                        = .false.,
use_buoyobs                         = .false.,
use_profilerobs                     = .false.,
use_satemobs                        = .false.,
use_gpspwobs                        = .false.,
use_gpsrefobs                       = .false.,
use_qscatobs                        = .false.,
use_radarobs                        = .false.,
use_radar_rv                        = .false.,
use_radar_rf                        = .false.,
use_airsretobs                      = .false.,
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
 n_randomcv                          = ${NUM_MEMBERS}
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

ln -sf ${BUILD_DIR}/da_wrfvar.exe ./
${RUN_CMD} ./da_wrfvar.exe  > run_rcv.out 2>&1


# update lateral boundary
ln -sf ${BUILD_DIR}/da_update_bc.exe .
IMEM=1
while [[ $IMEM -le ${NUM_MEMBERS} ]] ; do
if [[ $IMEM -lt 100 ]]; then export CMEM=e0$IMEM; fi
if [[ $IMEM -lt 10  ]]; then export CMEM=e00$IMEM; fi

cp $REAL_FC_DIR/$DATE/wrfbdy_d01 ./wrfbdy_d01.$CMEM
cat > parame.in << EOF
&control_param
 da_file            = 'wrfvar_output_randomcv.$CMEM'
 wrf_bdy_file       = 'wrfbdy_d01.$CMEM'
 update_lateral_bdy = .true.
 update_low_bdy     = .false.
 update_lsm         = .false.
 iswater            = 16 /
EOF

./da_update_bc.exe
				
(( IMEM=IMEM+1 ))
done

date	

exit 0
