#!/bin/ksh

date  
export FINAL_DATE=2017042706

export LBC_FREQ_SECOND=`expr 3600 \* ${CYCLE_PERIOD}` 

export START_DATE=`${BUILD_DIR}/da_advance_time.exe $INITIAL_DATE 0 -w`
echo "start date = $START_DATE"
export END_DATE=`${BUILD_DIR}/da_advance_time.exe $FINAL_DATE $DE_FCST_RANGE -w`
echo "end date = $END_DATE"

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
echo ""
echo "LBC_FREQ_SECOND = $LBC_FREQ_SECOND"
echo "CYCLE_PERIOD = $CYCLE_PERIOD"
echo ""
IMEM=1
while (( IMEM <= $NUM_GEFS )) ; do
if [[ $IMEM -lt 100 ]]; then export CMEM=e0$IMEM; fi
if [[ $IMEM -lt 10  ]]; then export CMEM=e00$IMEM; fi

(( MEM=IMEM-1 ))
if [[ $MEM -lt 100 ]]; then export CMEM2=$MEM; fi
if [[ $MEM -lt 10  ]]; then export CMEM2=0$MEM; fi

if [[ ! -d $WORK_DIR/$CMEM ]]; then mkdir -p $WORK_DIR/$CMEM; fi
cd $WORK_DIR/$CMEM

ln -sf $WPS_DIR/* .
rm namelist.wps

# create namelist.wps
cat > namelist.wps << EOF
&share
 wrf_core = 'ARW',
 max_dom = ${MAX_DOM},
 start_date = '${ccyy_s}-${mm_s}-${dd_s}_${hh_s}:00:00','${ccyy_s}-${mm_s}-${dd_s}_${hh_s}:00:00','${ccyy_s}-${mm_s}-${dd_s}_${hh_s}:00:00',
 end_date   = '${ccyy_e}-${mm_e}-${dd_e}_${hh_e}:00:00','${ccyy_e}-${mm_e}-${dd_e}_${hh_e}:00:00','${ccyy_e}-${mm_e}-${dd_e}_${hh_e}:00:00',
 interval_seconds = ${LBC_FREQ_SECOND},
 io_form_geogrid = 2,
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
 fg_name = 'FILE','SOIL'
 io_form_metgrid = 2, 
/

EOF

# Run geogrid
need_geogrid=false          

# Loop over domains d01, d02, … up to MAX_DOM
for dom in $(seq -f "%02g" 1 "${MAX_DOM}"); do
    file="geo_em.d${dom}.nc"

    if [[ -e "${file}" ]]; then
    echo "Max_dom = ${dom}"
        echo "${file} already present in $(pwd)"
    elif [[ -e "${WPS_RUN_DIR}/${file}" ]]; then
        echo "${file} found in \$WPS_RUN_DIR - creating symlink"
        ln -sf "${WPS_RUN_DIR}/${file}" .
    else
        echo "${file} not found locally or in \$WPS_RUN_DIR - will regenerate"
        need_geogrid=true
    fi
done

# Only run geogrid.exe if something was missing after the checks above
if ${need_geogrid}; then
    echo "------------------------------------------------------------"
    echo "Running geogrid.exe to build missing geo_em files..."
    echo "------------------------------------------------------------"
   #  ./geogrid.exe
fi
	  
# Run ungrib:
   LOCAL_DATE=$INITIAL_DATE
   LAST_DATE=$($BUILD_DIR/da_advance_time.exe ${LOCAL_DATE} -${LBC_ENS_FREQ} -f ccyymmddhhnn 3>/dev/null)
   FILES=''
   FILES1=''
   while [[ $LOCAL_DATE -le $EDATE ]]; do
      export year=`echo  $LOCAL_DATE | cut -c1-4`
      export month=`echo $LOCAL_DATE | cut -c5-6`
      export day=`echo   $LOCAL_DATE | cut -c7-8`
      export hour=`echo  $LOCAL_DATE | cut -c9-10`
      export year1=`echo  $LAST_DATE | cut -c1-4`
      export month1=`echo $LAST_DATE | cut -c5-6`
      export day1=`echo   $LAST_DATE | cut -c7-8`
      export hour1=`echo  $LAST_DATE | cut -c9-10`

      FILES="$FILES $WPS_INPUT_DIR/GEFS/gensanl-b_3_${year}${month}${day}_${hour}00_000_${CMEM2}.grb2"
      FILES1="$FILES1 $WPS_INPUT_DIR/$year/$year$month$day/gfs.0p25.${year}${month}${day}${hour}.f000.grib2"
      LAST_DATE=$LOCAL_DATE
      LOCAL_DATE=$($BUILD_DIR/da_advance_time.exe ${LOCAL_DATE} ${LBC_FREQ} -f ccyymmddhhnn 3>/dev/null)
   done
   # dealing with the common variables from GSFS
   echo "FILES = $FILES"
   ./link_grib.csh $FILES
   ln -sf ./ungrib/Variable_Tables/Vtable.GEFS Vtable
   # ./ungrib.exe > ungrib.log 2>&1
   
   # dealing with the rest variables in GFS analysis
   echo "FILES1 = $FILES1"
   sed -i "s/prefix = 'FILE'/prefix = 'SOIL'/" namelist.wps
   if [ $IMEM -eq 1 ]; then
      ./link_grib.csh $FILES1
       ln -sf ./ungrib/Variable_Tables/Vtable.GFSSOIL Vtable
      # ./ungrib.exe
   else
      ln -sf ${WPS_ENS_DIR}/e001/SOIL* .
   fi
   
   # pwd
# Run metgrid:
   # ${RUN_CMD} --partition=backfill --nodes=1 -n8 ./metgrid.exe
   # ./metgrid.exe

(( IMEM=IMEM+1 ))

done

date	

exit 0  
