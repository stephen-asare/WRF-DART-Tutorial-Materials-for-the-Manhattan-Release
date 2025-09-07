#!/bin/ksh

date

export DATE0=`${BUILD_DIR}/da_advance_time.exe ${DATE} +0h00min -wrf`
export DATE1=`${BUILD_DIR}/da_advance_time.exe ${DATE} ${WINDOW_START} -wrf`
export DATE2=`${BUILD_DIR}/da_advance_time.exe ${DATE} ${WINDOW_END} -wrf`

export DIS=`echo $NL_DXY_1 | cut -c1-2`

ln -sf $WRFVAR_DIR/var/obsproc/* .

if [[ $MAP_PROJ == lambert ]]; then
   export PROJ=1
elif [[ $MAP_PROJ == polar ]];  then
   export PROJ=2
elif [[ $MAP_PROJ == mercator ]]; then
   export PROJ=3
else
   echo "   Unknown MAP_PROJ = $MAP_PROJ."
   exit 1
fi

cat > namelist.obsproc << EOF
&record1
 obs_gts_filename = '$OBS_DIR/obs.${YYYY}${MM}${DD}${HH}',
 fg_format        = 'WRF',
 obs_err_filename = 'obserr.txt',
/

&record2
 time_window_min  = '${DATE1}',
 time_analysis    = '${DATE0}',
 time_window_max  = '${DATE2}',
/

&record3
 max_number_of_obs        = 400000,
 fatal_if_exceed_max_obs  = .TRUE.,
/

&record4
 qc_test_vert_consistency = .TRUE.,
 qc_test_convective_adj   = .TRUE.,
 qc_test_above_lid        = .TRUE.,
 remove_above_lid         = .TRUE.,
 domain_check_h           = .true.,
 Thining_SATOB            = .false.,
 Thining_SSMI             = .false.,
 Thining_QSCAT            = .false.,
/

&record5
 print_gts_read           = .TRUE.,
 print_gpspw_read         = .TRUE.,
 print_recoverp           = .TRUE.,
 print_duplicate_loc      = .TRUE.,
 print_duplicate_time     = .TRUE.,
 print_recoverh           = .TRUE.,
 print_qc_vert            = .TRUE.,
 print_qc_conv            = .TRUE.,
 print_qc_lid             = .TRUE.,
 print_uncomplete         = .TRUE.,
/

&record6
 ptop =  ${NL_P_TOP_REQUESTED},
 base_pres       = 100000.0,
 base_temp       = 290.0,
 base_lapse      = 50.0,
 base_strat_temp = 215.0,
 base_tropo_pres = 20000.0
/

&record7
 IPROJ = ${PROJ},
 PHIC  = ${REF_LAT},
 XLONC = ${REF_LON},
 TRUELAT1= ${TRUELAT1},
 TRUELAT2= ${TRUELAT2},
 MOAD_CEN_LAT = ${REF_LAT},
 STANDARD_LON = ${STAND_LON},
/

&record8
 IDD    =   1,
 MAXNES =   1,
 NESTIX =  ${NL_E_SN_1}, 
 NESTJX =  ${NL_E_WE_1}, 
 DIS    =  ${DIS}, 
 NUMC   =    1,  
 NESTI  =    1, 
 NESTJ  =    1,  
 / 

&record9
 PREPBUFR_OUTPUT_FILENAME = 'prepbufr_output_filename',
 PREPBUFR_TABLE_FILENAME = 'prepbufr_table_filename',
 OUTPUT_OB_FORMAT = 2
 use_for          = '3DVAR',
 num_slots_past   = 3,
 num_slots_ahead  = 3,
 write_synop = .true., 
 write_ship  = .true.,
 write_metar = .true.,
 write_buoy  = .true., 
 write_pilot = .true.,
 write_sound = .true.,
 write_amdar = .true.,
 write_satem = .true.,
 write_satob = .true.,
 write_airep = .true.,
 write_gpspw = .true.,
 write_gpsztd= .true.,
 write_gpsref= .true.,
 write_gpseph= .true.,
 write_ssmt1 = .true.,
 write_ssmt2 = .true.,
 write_ssmi  = .true.,
 write_tovs  = .true.,
 write_qscat = .true.,
 write_profl = .true.,
 write_bogus = .true.,
 write_airs  = .true.,
 /
EOF

 ./obsproc.exe

###############################################################################
rm input.nml
cp $NML_DIR/input.nml.obs .

cat > script.sed << EOF
  /obs_seq_out_file_name/c\
  obs_seq_out_file_name = 'obs_seq.${DATE}',
  /date_str/c\
  date_str = '${DATE}00',
  /Use_SynopObs/c\
  Use_SynopObs = .TRUE.,
  /Use_ShipsObs/c\
  Use_ShipsObs = .TRUE.,
  /Use_MetarObs/c\
  Use_MetarObs = .TRUE.,
  /Use_BuoysObs/c\
  Use_BuoysObs = .TRUE.,
  /Use_PilotObs/c\
  Use_PilotObs = .TRUE.,
  /Use_SoundObs/c\
  Use_SoundObs = .TRUE.,
  /Use_SatemObs/c\
  Use_SatemObs = .TRUE.,
  /Use_SatobObs/c\
  Use_SatobObs = .TRUE.,
  /Use_AirepObs/c\
  Use_AirepObs = .TRUE.,  
  /Use_AmdarObs/c\
  Use_AmdarObs = .TRUE.,
  /Use_GpspwObs/c\
  Use_GpspwObs = .TRUE.,
  /Use_SsmiRetrievalObs/c\
  Use_SsmiRetrievalObs = .TRUE.,
  /Use_SsmiTbObs/c\
  Use_SsmiTbObs = .TRUE.,
  /Use_Ssmt1Obs/c\
  Use_Ssmt1Obs = .TRUE.,
  /Use_Ssmt2Obs/c\
  Use_Ssmt2Obs = .TRUE.,
  /Use_ProflObs/c\
  Use_ProflObs = .TRUE.,
  /Use_QscatObs/c\
  Use_QscatObs = .TRUE.,
  /Use_BogusObs/c\
  Use_BogusObs = .TRUE.,
  /Use_gpsrefobs/c\
  Use_gpsrefobs = .TRUE.,
  /Use_radar_rf/c\
  Use_radar_rf = .FALSE.,
  /Use_radar_rv/c\
  Use_radar_rv = .FALSE.,
  /Use_radar_clear/c\
  Use_radar_clear = .FALSE.,
EOF

sed -f script.sed input.nml.obs > input.nml
rm script.sed

cp obs_gts_${DATE0}.3DVAR ob.ascii
ln -sf ${RADAR_DIR}/radar.${DATE} ob.radar
ln -sf ${DART_DIR}/observations/obs_converters/var/work/gts_radar_to_dart .

./gts_radar_to_dart
mv input.nml input.nml.d01

date	

exit 0
