#!/bin/ksh

date
echo "running run_wps.ksh"
export LBC_FREQ_SECOND=`expr 3600 \* ${CYCLE_PERIOD}` 

export START_DATE=`${BUILD_DIR}/da_advance_time.exe $INITIAL_DATE 0 -w`
export END_DATE=`${BUILD_DIR}/da_advance_time.exe $FINAL_DATE $DE_FCST_RANGE -w`
echo "START_DATE = $START_DATE"
echo "END_DATE = $END_DATE"

export ccyy_s=`echo $START_DATE | cut -c1-4`
export mm_s=`echo $START_DATE | cut -c6-7`
export dd_s=`echo $START_DATE | cut -c9-10`
export hh_s=`echo $START_DATE | cut -c12-13`
export ccyy_e=`echo $END_DATE | cut -c1-4`
export mm_e=`echo $END_DATE | cut -c6-7`
export dd_e=`echo $END_DATE | cut -c9-10`
export hh_e=`echo $END_DATE | cut -c12-13`

export EDATE=${ccyy_e}${mm_e}${dd_e}${hh_e}00
echo ${EDATE}
ln -sf $WPS_DIR/* .
rm -fv namelist.wps SUCCESS

# create namelist.wps
cat > namelist.wps << EOF
&share
 wrf_core = 'ARW',
 max_dom = ${MAX_DOM},
 start_date = '${ccyy_s}-${mm_s}-${dd_s}_${hh_s}:00:00','${ccyy_s}-${mm_s}-${dd_s}_${hh_s}:00:00','${ccyy_s}-${mm_s}-${dd_s}_${hh_s}:00:00',
 end_date   = '${ccyy_e}-${mm_e}-${dd_e}_${hh_e}:00:00','${ccyy_e}-${mm_e}-${dd_e}_${hh_e}:00:00','${ccyy_e}-${mm_e}-${dd_e}_${hh_e}:00:00',
 interval_seconds = ${LBC_FREQ_SECOND},
 io_form_geogrid = 2,
 debug_level = 0,
 active_grid = .true., .true.,
/

&geogrid
 parent_id         =   1,1,1
 parent_grid_ratio =   1,${PARENT_GRID_RATIO_2},${PARENT_GRID_RATIO_3},
 i_parent_start    =   1,${I_PARENT_START_2},${I_PARENT_START_3},
 j_parent_start    =   1,${J_PARENT_START_2},${J_PARENT_START_3},
 e_we              =   ${NL_E_WE_1}, ${NL_E_WE_2}, ${NL_E_WE_3},
 e_sn              =   ${NL_E_SN_1}, ${NL_E_SN_2}, ${NL_E_SN_3},
 geog_data_res     = '${GEOG_DATA_RES_1}','${GEOG_DATA_RES_2}','${GEOG_DATA_RES_3}',
 dx = ${NL_DXY_1},
 dy = ${NL_DXY_1},
 map_proj = '${MAP_PROJ}',
 ref_lat   =  ${REF_LAT},
 ref_lon   =  ${REF_LON},
 truelat1  =  ${TRUELAT1},
 truelat2  =  ${TRUELAT2},
 stand_lon =  ${STAND_LON},
 geog_data_path = '${GEOG_DATA_PATH}'
/

&ungrib
 out_format = 'WPS',
 prefix = 'FILE',
/

&metgrid
 fg_name = 'FILE'
 io_form_metgrid = 2, 
/

&mod_levs
 press_pa = 201300 , 200100 , 100000 ,
             95000 ,  90000 ,
             85000 ,  80000 ,
             75000 ,  70000 ,
             65000 ,  60000 ,
             55000 ,  50000 ,
             45000 ,  40000 ,
             35000 ,  30000 ,
             25000 ,  20000 ,
             15000 ,  10000 ,
              5000 ,   1000
/

EOF

   run_geogrid=false

   if [[ $MAX_DOM -eq 1 ]]; then
      if [[ ! -f geo_em.d01.nc ]]; then
         run_geogrid=true
      fi
   elif [[ $MAX_DOM -eq 2 ]]; then
      if [[ ! -f geo_em.d01.nc || ! -f geo_em.d02.nc ]]; then
         run_geogrid=true
      fi
   elif [[ $MAX_DOM -eq 3 ]]; then
      if [[ ! -f geo_em.d01.nc || ! -f geo_em.d02.nc || ! -f geo_em.d03.nc ]]; then
         run_geogrid=true
      fi
   else
      echo "Total domains are =$MAX_DOM stopping"
      exit 1
   fi
   if $run_geogrid; then
      echo "Running geogrid.exe ..."
      ${RUN_CMD} -n 1 ./geogrid.exe > geogrid.log
   else
      echo "All geo_em files exist. Skipping geogrid.exe."
   fi

   echo "geogrid done"
# Run ungrib:
   # ln -fs ./ungrib/Variable_Tables/Vtable.GFS Vtable
   ln -fs ungrib/Variable_Tables/Vtable.ERA-interim.pl Vtable
   LOCAL_DATE=$INITIAL_DATE
   LAST_DATE=$($BUILD_DIR/da_advance_time.exe ${LOCAL_DATE} -${LBC_FREQ} -f ccyymmddhhnn 3>/dev/null)
   echo "LOCAL_DATE = $LOCAL_DATE"
   echo "LAST_DATE = $LAST_DATE"
   FILES=''
   while [[ $LOCAL_DATE -le $EDATE ]]; do
      export year=`echo  $LOCAL_DATE | cut -c1-4`
      export month=`echo $LOCAL_DATE | cut -c5-6`
      export day=`echo   $LOCAL_DATE | cut -c7-8`
      export hour=`echo  $LOCAL_DATE | cut -c9-10`
      export year1=`echo  $LAST_DATE | cut -c1-4`
      export month1=`echo $LAST_DATE | cut -c5-6`
      export day1=`echo   $LAST_DATE | cut -c7-8`
      export hour1=`echo  $LAST_DATE | cut -c9-10`

      FILES=/gpfs/research/chipilskigroup/stephen_asare/wrf_dart_debug_data/data/*_dart_new_api.grib ## Added by stephen for testing ECMWF data
      LAST_DATE=$LOCAL_DATE
      LOCAL_DATE=$($BUILD_DIR/da_advance_time.exe ${LOCAL_DATE} ${LBC_FREQ} -f ccyymmddhhnn 3>/dev/null)
   done
   echo FILES = $FILES
   ./link_grib.csh $FILES
   ./ungrib.exe > ungrib.log 2>&1

# Run metgrid:
if ls met_em.d01.*.nc 1> /dev/null 2>&1; then
    echo "met_em files already exist. Skipping metgrid.exe."
else
    echo "No met_em files found. Running metgrid.exe ..."
    ${RUN_CMD}  -n 1 ./metgrid.exe
fi

date	
echo "wps_fc done"
exit 0  
