#!/bin/ksh -x
#SBATCH --job-name=dart_d01
#SBATCH -A chipilskigroup_q
#SBATCH -t 00:55:00
#SBATCH --partition=chipilskigroup_q
#SBATCH -n 64
#SBATCH -C "intel,YEAR2018|intel,YEAR2019"
#SBATCH --mem-per-cpu=4000M
#SBATCH --output=output
#SBATCH --export=ALL
. ~/.kshrc
# # . /usr/share/lmod/lmod/init/ksh
# module purge
module load intel/21
module load openmpi/4.1.0
ml python/3  
# ml python/3   
# ml matlab/2022b   
# ml precompiled   
# ml intel/21   
# ml hdf5/1.10.4   
# ml mvapich/2.3.5   
# ml netcdf/4.7.0
ulimit -s unlimited

# This script is to run EAKF with DART

date

export FWD_DATE=$($BUILD_DIR/da_advance_time.exe $DATE ${CYCLE_RADAR}m -f ccyymmddhhnn 2>/dev/null)
#export FWD_DATE=$($BUILD_DIR/da_advance_time.exe $DATE 3 -f ccyymmddhhnn 2>/dev/null)
# export LAST_DATE=`${BUILD_DIR}/da_advance_time.exe $DATE 6 -w`
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

export year2=`echo  $PREV_DATE | cut -c1-4`
export month2=`echo $PREV_DATE | cut -c5-6`
export day2=`echo   $PREV_DATE | cut -c7-8`
export hour2=`echo  $PREV_DATE | cut -c9-10` 
export minute2=`echo  $PREV_DATE | cut -c11-12`

echo 'CYCLE_NUMBER'  $CYCLE_NUMBER
# prepare observations
# ln -sf ${OBS_D01_DIR}/obs_seq${DATE} ./obs_seq.out
# ln -sf /gpfs/home/sa24m/scratch/base/output/${DATE_short}/obs_seq.out ./obs_seq.out
ln -sf /gpfs/home/sa24m/scratch/base/output/2017042706/obs_seq.out ./obs_seq.out
#ln -sf ${OBS_D01_DIR}/obs_seq${DATE_short} ./obs_seq.out

# prepare executable file
ln -sf $DART_DIR/models/wrf/work/filter .
ln -sf $DART_DIR/assimilation_code/programs/gen_sampling_err_table/work/sampling_error_correction_table.nc .
ln -sf $DART_DIR/models/wrf/work/fill_inflation_restart .
ln -sf $DART_DIR/models/wrf/work/pert_wrf_bc .


# prepare first guess, ensembles and something related
echo "working directory is $WORK_DIR"
if [[ ! -d $WORK_DIR/priors ]]; then mkdir -p $WORK_DIR/priors; fi
IMEM=1
while (( IMEM <= ${NUM_MEMBERS} )) ; do

if [[ $IMEM -lt 100 ]]; then export CMEM=e0$IMEM;  fi
if [[ $IMEM -lt 10  ]]; then export CMEM=e00$IMEM; fi
 
#jkmod
#if [ -e ${BLEND_DIR}/$DATE/$CMEM/wrfinput_d01 ]; then
#   ln -sf ${BLEND_DIR}/$DATE/$CMEM/wrfinput_d01 $WORK_DIR/priors/wrfinput_d01.$CMEM
#else
   # jkmod after verfy begining of the DA cycle
#    ln -sf ${ENS_WRF_DIR}/${PREV_DATE}/$CMEM/wrfinput_d01_${FILE_DATE} $WORK_DIR/priors/wrfinput_d01.$CMEM
   ln -sf ${INITIAL_FC}/$CMEM/wrfout_d01_2017-04-27_06:00:00 $WORK_DIR/priors/wrfinput_d01.$CMEM
    # ln -sf ${ENS_WRF_DIR}/${DATE}/wrfinput_d01.${DATE}.$CMEM $WORK_DIR/priors/wrfinput_d01.$CMEM
    # echo "Linking wrfinput_d01 for member $CMEM from ${ENS_ICBC_DIR}/${DATE}/wrfinput_d01_${DATE}.$CMEM to $WORK_DIR/priors/wrfinput_d01.$CMEM"
   #ln -sf ${ENS_WRF_DIR}/${PREV_DATE}/$CMEM/wrfout_d01_${FILE_DATE} $WORK_DIR/priors/wrfinput_d01.$CMEM
   #ln -sf /glade/scratch/junkyung/MPD_exp/pecan/NR_CNTL_july15_mod_as4_39h_era5_auto_70levs_200mem/wrfrun/fc/${DATE_short}.${CMEM}/wrfout_d01_${FILE_DATE} $WORK_DIR/priors/wrfinput_d01.$CMEM

   # jkmod very begining valid at 2015071412
   #ln -sf /glade/scratch/junkyung/MPD_exp/pecan/NR_CNTL_july15_mod_as4_39h_era5_auto_70levs_200mem_mem041_40mem/wrfrun/fc/${DATE_short}.${CMEM}/wrfout_d01_${FILE_DATE} $WORK_DIR/priors/wrfinput_d01.$CMEM
#fi

let IMEM=$IMEM+1
done

ls $WORK_DIR/priors/wrfinput* > input_list_d01.txt
cp input_list_d01.txt output_list_d01.txt
sed -i 's/priors/posts/g' output_list_d01.txt
mkdir -p posts

#jkmod
##ln -sf ${REAL_FC_ERA_DIR}/$DATE_short/wrfinput_d01 ./wrfinput_d01
##ln -sf ${REAL_FC_ERA_DIR}/$DATE_short/wrfbdy_d01 ./wrfbdy_d01

#if [[ $DATE -eq 201507150000 ]];then
#if [ "${CYCLE_NUMBER}" -eq "0" ]; then
#   cp $ENSMEAN_BG_DIR/${PREV_DATE}/wrfinput_d01.mean ./wrfinput_d01
#   #cp ${REAL_FC_ERA_DIR}/${DATE_short}/wrfinput_d01 ./wrfinput_d01
#   cp ${REAL_FC_ERA_DIR}/${DATE_short}/wrfbdy_d01 ./wrfbdy_d01
#else
   #cp ${DART_D01_DIR}/${PREV_DATE}/wrfinput_d01 ./wrfinput_d01
   #cp ${DART_D01_DIR}/${PREV_DATE}/wrfbdy_d01 ./wrfbdy_d01
#    cp $ENSMEAN_BG_DIR/${DATE_short}/wrfinput_d01.mean ./wrfinput_d01
#    cp ${REAL_FC_ERA_DIR}/${DATE_short}/wrfbdy_d01 ./wrfbdy_d01
cp /gpfs/research/scratch/sa24m/base/output/2017042706/input.nml input.nml

cp /gpfs/research/chipilskigroup/stephen_asare/mpd/osse_out/real_fc/2017042700/wrfout_d01_2017-04-27_06:00:00 ./wrfinput_d01
cp /gpfs/research/chipilskigroup/stephen_asare/mpd/osse_out/real_fc/2017042700/wrfbdy_d01 ./wrfbdy_d01
#fi
## Add inflation restart file in input.nml
${WORK_DIR}/fill_inflation_restart

#jkmod for very begining valid at 2015071412
#cp /glade/scratch/junkyung/MPD_exp/pecan/NR_CNTL_july15_mod_as4_39h_era5_auto_70levs_200mem/rc/2015071412.e041/wrfinput_d01 ./wrfinput_d01
#cp /glade/scratch/junkyung/MPD_exp/pecan/NR_CNTL_july15_mod_as4_39h_era5_auto_70levs_200mem/rc/2015071412.e041/wrfbdy_d01 ./wrfbdy_d01

# creat input.nml
# rm input.nml

#if [[ $CYCLE_NUMBER -le 1 ]]; then 
   export inf_flavor=0
   export inf_initial_from_restart=".false."
   export inf_sd_initial_from_restart=".false."
#else
   #export inf_flavor=2
   #export inf_initial_from_restart=".true."
   #export inf_sd_initial_from_restart=".true."
##   if [[ "${minute2}" -eq "00" ]] then
#      ln -sf $DART_D01_DIR/$PREV_DATE/output_priorinf_mean.nc input_priorinf_mean.nc 
#      ln -sf $DART_D01_DIR/$PREV_DATE/output_priorinf_sd.nc   input_priorinf_sd.nc 
##   else
##      ln -sf $DART_D01_DIR/${year2}${month2}${day2}${hour2}00/output_postinf_mean.nc input_priorinf_mean.nc
##      ln -sf $DART_D01_DIR/${year2}${month2}${day2}${hour2}00/output_postinf_sd.nc   input_priorinf_sd.nc
##   fi
##fi

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

# sed -f script.sed $NML_DIR/input.nml.d01 > input.nml
# sed -f script.sed /gpfs/research/scratch/sa24m/base/rundir/input.nml > input.nml
# cp /gpfs/research/scratch/sa24m/base/output/2017042706/input.nml input.nml

# start EAKF analyze
#${RUN_CMD} ./filter #jkmod
# ${RUN_CMD} ${WORK_DIR}/filter
srun --partition=chipilskigroup_q -n 64 ${WORK_DIR}/filter
# srun --export=MV2_ENABLE_AFFINITY=0 ${WORK_DIR}/filter
# deal with the output data
mkdir analysis

MEM=1
while (( $MEM <= $NUM_MEMBERS )); do

export CMEM=e$MEM
if [[ $MEM -lt 100 ]]; then export CMEM=e0$MEM; fi
if [[ $MEM -lt 10  ]]; then export CMEM=e00$MEM; fi

##update initial ensemble 
#cp wrfinput_d01  ./analysis/wrfvar_output.${CMEM}
# cp ${ANALYSIS_DIR}/${PREV_DATE}/wrfinput_d01.${FILE_DATE}.$CMEM ./analysis/wrfvar_output.${CMEM}
# cp ${ANALYSIS_DIR}/${DATE}/wrfbdy_d01.$CMEM wrfbdy_d01
# cp ${ENS_WRF_DIR}/${PREV_DATE}/$CMEM/wrfinput_d01_${FILE_DATE} ./analysis/wrfvar_output.${CMEM}
# cp ${ENS_WRF_DIR}/${PREV_DATE}/$CMEM/wrfout_d01_${FILE_DATE}  ./analysis/wrfvar_output.${CMEM}
cp ${INITIAL_FC}/$CMEM/wrfout_d01_2017-04-27_06:00:00  ./analysis/wrfvar_output.${CMEM}
echo "Linking wrfvar_output.${CMEM} from ${INITIAL_FC}/${FILE_DATE}/$CMEM/wrfout_d01_${FILE_DATE} to ./analysis/wrfvar_output.${CMEM}"
ncks -A -v ${VAR_DART} ./posts/wrfinput_d01.${CMEM} ./analysis/wrfvar_output.${CMEM}

##update lateral boundary
# cp ${REAL_FC_ERA_DIR}/${DATE_short}/wrfbdy_d01 ./analysis/wrfbdy_d01.${CMEM}

# jkmod very begining valid at 2015071412
#
# cp /glade/scratch/junkyung/MPD_exp/pecan/NR_CNTL_july15_mod_as4_39h_era5_auto_70levs_200mem/rc/2015071412.e041/wrfbdy_d01 ./analysis/wrfbdy_d01.${CMEM}
ln -sf ${ANALYSIS_DIR}/${DATE_short}/wrfbdy_d01.${CMEM} ./analysis/wrfbdy_d01.${CMEM}


cat > parame.in << EOF
&control_param
 da_file            = './analysis/wrfvar_output.${CMEM}'
 wrf_bdy_file       = './analysis/wrfbdy_d01.${CMEM}'
 update_lateral_bdy = .true.
 update_low_bdy     = .false.
 update_lsm         = .false.
 iswater            = 16 /
EOF

ln -sf ${BUILD_DIR}/da_update_bc.exe .
# ./da_update_bc.exe > update_lbc.out.$CMEM 2>&1


(( MEM=$MEM+1 ))

done


date

exit 0
