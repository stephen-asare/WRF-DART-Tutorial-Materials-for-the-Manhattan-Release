#!/bin/ksh -x
#PBS -N dart_d02
#PBS -A NEOL0010
#PBS -l walltime=07:00:00
##PBS -q economy
#PBS -q regular
#PBS -j oe
### Select 1 nodes with 36 CPUs for 1008 MPI processes
#PBS -l select=5:ncpus=36:mpiprocs=36
##PBS -m abe
#PBS -M junkyung@ucar.edu
ulimit -s unlimited

date

#export FWD_DATE=$($BUILD_DIR/da_advance_time.exe $DATE $CYCLE_RADAR -f ccyymmddhhnn 2>/dev/null)
export FWD_DATE=$($BUILD_DIR/da_advance_time.exe $DATE 3 -f ccyymmddhhnn 2>/dev/null)

# time related
export year=`echo   $DATE | cut -c1-4`
export month=`echo  $DATE | cut -c5-6`
export day=`echo    $DATE | cut -c7-8`
export hour=`echo   $DATE | cut -c9-10` 
export minute=`echo   $DATE | cut -c11-12`

export year1=`echo  $FWD_DATE | cut -c1-4`
export month1=`echo $FWD_DATE | cut -c5-6`
export day1=`echo   $FWD_DATE | cut -c7-8`
export hour1=`echo  $FWD_DATE | cut -c9-10` 
export minute1=`echo  $FWD_DATE | cut -c11-12`

# prepare observations
ln -sf $OBS_D02_DIR/obs_seq${DATE} ./obs_seq.out
#ln -sf ${OBS_D01_DIR}/obs_seq${DATE_short} ./obs_seq.out

# prepare executable file
ln -sf $DART_DIR/models/wrf/work/filter .
ln -sf $DART_DIR/assimilation_code/programs/gen_sampling_err_table/work/sampling_error_correction_table.nc .

# prepare first guess, ensembles and something related
if [[ ! -d $WORK_DIR/priors ]]; then mkdir -p $WORK_DIR/priors; fi
IMEM=1
while (( IMEM <= ${NUM_MEMBERS} )) ; do

if [[ $IMEM -lt 100 ]]; then export CMEM=e0$IMEM;  fi
if [[ $IMEM -lt 10  ]]; then export CMEM=e00$IMEM; fi

ln -sf ${ENS_WRF_DIR}/${PREV_DATE}/$CMEM/wrfinput_d02_${FILE_DATE} $WORK_DIR/priors/wrfinput_d02.$CMEM
#ln -sf ${ENS_WRF_DIR}/${PREV_DATE}/$CMEM/wrfout_d02_${FILE_DATE} $WORK_DIR/priors/wrfinput_d02.$CMEM
# for very begining of DA cycle valid at 2014071412
#ln -sf /glade/scratch/junkyung/MPD_exp/pecan/NR_CNTL_july15_mod_as4_39h_era5_auto_70levs_200mem_mem041_40mem/wrfrun/fc/${DATE_short}.${CMEM}/wrfout_d02_${FILE_DATE} $WORK_DIR/priors/wrfinput_d02.$CMEM

#ncks -A -v ${VAR_RADAR} ${ENS_WRF_DIR}/${PREV_DATE}/$CMEM/wrfout_d02_${FILE_DATE} $WORK_DIR/priors/wrfinput_d02.$CMEM

let IMEM=$IMEM+1
done

ls $WORK_DIR/priors/wrfinput* > input_list_d02.txt
cp input_list_d02.txt output_list_d02.txt
sed -i 's/priors/posts/g' output_list_d02.txt
mkdir posts

#ln -sf ${ENS_WRF_DIR}/$PREV_DATE/e001/wrfout_d02_${FILE_DATE} ./wrfinput_d01
#cp ${REAL_FC_ERA_DIR}/${DATE_short}/wrfinput_d02 ./wrfinput_d01
#if [[ $DATE -eq 201507150000 ]];then
#   cp ${REAL_FC_ERA_DIR}/${DATE_short}/wrfinput_d02 ./wrfinput_d01
#else
   #cp ${DART_D02_DIR}/${PREV_DATE}/wrfinput_d01 ./wrfinput_d01
   cp $ENSMEAN_BG_DIR/${PREV_DATE}/wrfinput_d02.mean ./wrfinput_d01
#fi
#jkmod very begining valid at 2015071412
#cp /glade/scratch/junkyung/MPD_exp/pecan/NR_CNTL_july15_mod_as4_39h_era5_auto_70levs_200mem/rc/2015071412.e041/wrfinput_d02 ./wrfinput_d01

# creat input.nml
rm input.nml

#if [[ $RADAR_NUMBER -eq 1 ]]; then 
   export inf_flavor=0
   export inf_initial_from_restart=".false."
   export inf_sd_initial_from_restart=".false."
#else
#   export inf_flavor=2
#   export inf_initial_from_restart=".true."
#   export inf_sd_initial_from_restart=".true."
#   ln -sf $DART_D02_DIR/$PREV_DATE/output_priorinf_mean.nc input_priorinf_mean.nc 
#   ln -sf $DART_D02_DIR/$PREV_DATE/output_priorinf_sd.nc   input_priorinf_sd.nc 
#fi

cat > script.sed << EOF
  /ens_size/c\
  ens_size = ${NUM_MEMBERS},
  /num_output_obs_members/c\
      num_output_obs_members = ${NUM_MEMBERS},
  /inf_flavor/c\
      inf_flavor = ${inf_flavor}, 4
  /inf_initial_from_restart/c\
      inf_initial_from_restart = ${inf_initial_from_restart}, .false.,
  /inf_sd_initial_from_restart/c\
      inf_sd_initial_from_restart = ${inf_sd_initial_from_restart}, .false.,
  /layout/c\
      layout = ${lay_out},
  /tasks_per_node/c\
      tasks_per_node = ${tasks_per_node},
  /first_bin_center/c\
      first_bin_center = ${year},${month},${day},${hour}, 0, 0
  /last_bin_center/c\
      last_bin_center = ${year1},${month1},${day1},${hour1}, 0, 0
EOF

sed -f script.sed $NML_DIR/input.nml.d02 > input.nml

# start EAKF analyze
#${RUN_CMD} ./filter
${RUN_CMD} ${WORK_DIR}/filter

# deal with the output data
mkdir analysis

MEM=1
while (( $MEM <= $NUM_MEMBERS )); do

export CMEM=e$MEM
if [[ $MEM -lt 100 ]]; then export CMEM=e0$MEM; fi
if [[ $MEM -lt 10  ]]; then export CMEM=e00$MEM; fi

##update initial ensemble 
#cp wrfinput_d01  ./analysis/wrfvar_output.${CMEM}
cp ${ENS_WRF_DIR}/${PREV_DATE}/$CMEM/wrfinput_d02_${FILE_DATE} ./analysis/wrfvar_output.${CMEM}
#cp ${ENS_WRF_DIR}/${PREV_DATE}/$CMEM/wrfout_d02_${FILE_DATE} ./analysis/wrfvar_output.${CMEM}
#ncks -A -v ${VAR_RADAR} ./posts/wrfinput_d02.${CMEM} ./analysis/wrfvar_output.${CMEM}
ncks -A -v ${VAR_DART} ./posts/wrfinput_d02.${CMEM} ./analysis/wrfvar_output.${CMEM}
(( MEM=$MEM+1 ))

done

date

exit 0
