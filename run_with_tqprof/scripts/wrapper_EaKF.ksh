#!/bin/ksh
# LSF batch script

#SBATCH --job-name=cycle_dart_test
#SBATCH --ntasks=30
#SBATCH -A chipilskigroup_q
#SBATCH -t 01:30:00
#SBATCH --partition=chipilskigroup_q
#SBATCH --output=output_%j.log
#SBATCH --export=ALL
. ~/.kshrc
# . /usr/share/lmod/lmod/init/ksh
module load intel/21
module load openmpi/4.1.0
ml python/3  

#echo
# Set tasks
export lay_out=1
export tasks_per_node=15
export RUN_CMD="srun --partition=chipilskigroup_q"

export NUM_GEFS=1   #have not idea what this means will find out later.

# CODE direcotory
export  MODEL=/gpfs/research/chipilskigroup/stephen_asare/models/WRF/V4.6.1
export  WRFVAR_DIR=/gpfs/research/chipilskigroup/stephen_asare/models/WRFDA/V4.5.2
export  BUILD_DIR=$WRFVAR_DIR/var/build
export  WRF_DIR=/gpfs/research/chipilskigroup/stephen_asare/models/WRF/V4.6.1
export  WPS_DIR=/gpfs/research/chipilskigroup/stephen_asare/models/WPS/V4.5
# export  DART_DIR=/gpfs/home/sa24m/scratch/DART/DART
export  DART_DIR=/gpfs/research/chipilskigroup/stephen_asare/models/DART/v11.11.1
export  SCRIPTS_DIR=/gpfs/home/sa24m/Research/wrf_dart_tutorials/run_with_tqprof
export  NML_DIR=${SCRIPTS_DIR}/NML

# input data Directories:
export  GEOG_DATA_PATH=/gpfs/research/chipilskigroup/stephen_asare/data/WPS_GEOG
export  WPS_INPUT_DIR=/gpfs/home/sa24m/scratch/run3/run_witht_qprof/input/wps_input
# /gpfs/home/sa24m/scratch/mpd/mpd/osse_out/dart_eakf_d01_2/2017042700
export  OBS_DIR=/gpfs/home/sa24m/scratch/run3/run_witht_qprof/input/obs
export  RADAR_DIR=/gpfs/home/sa24m/scratch/run3/run_witht_qprof/input/radar
export  BE_DIR=/gpfs/home/sa24m/scratch/run3/run_witht_qprof/input/be

#jkmod
#export  REAL_FC_ERA_DIR=/glade/scratch/junkyung/MPD_exp/pecan/wrf/era5/70lev/3hourly
export  REAL_FC_ERA_DIR=/gpfs/home/sa24m/scratch/run3/run_witht_qprof/input

# output(working) data Directories:
############################################################
export  EXP_DIR=/gpfs/home/sa24m/scratch/run3/run_witht_qprof/osse_out
#prepare observations
export  OBS_D01_DIR=${EXP_DIR}/obs_d01
export  OBS_D02_DIR=${EXP_DIR}/obs_d02
#wps & real
export  WPS_RUN_DIR=$EXP_DIR/wps_fc
export  REAL_FC_DIR=$EXP_DIR/real_fc
# export  WPS_ENS_DIR=/gpfs/research/chipilskigroup/stephen_asare/mpd/input/wps_ens
export WPS_ENS_DIR=$EXP_DIR/wps_ens
#related to perturbations (ICBC)
export  RUN_RCV_DIR=$EXP_DIR/ens_rcv
# wrf-related
export  ENS_WRF_DIR=$EXP_DIR/ens_wrf
export  ANALYSIS_DIR=/gpfs/home/sa24m/scratch/generate_ensembles/icbc/test/rc
export INITIAL_FC=$EXP_DIR/initial_fc
export ENS_ICBC_DIR=$EXP_DIR/ens_icbc
export  ENSMEAN_DIR=$EXP_DIR/ensmean
export  ENSMEAN_BG_DIR=$EXP_DIR/ensmean_bg

# analysis proces
export  DART_D01_DIR=$EXP_DIR/dart_eakf_d01
export  DART_D02_DIR=$EXP_DIR/dart_eakf_d02
export  DART_D01_2_DIR=$EXP_DIR/dart_eakf_d01_2
#############################################################

#Time info:                        
export  INITIAL_DATE=201704270000 #201507140000
export  FINAL_DATE=201704271200 #201507151200
export  RADAR_START_DATE=201704270600   #201507150000
export  CYCLE_PERIOD=6  #forecaast range in cycle/en-forecast
export  CYCLE_RADAR=15  #frequency of radar assimilation (min) 
# export  DE_FCST_RANGE=9
export  DE_FCST_RANGE=6
export  SPINUP_TIME=3
export  LBC_FREQ=6        #GFS or FNL inteval 
export  OUTPUT_INTERVAL=15
if [[ $INITIAL_DATE -eq 201704270000 ]]; then export CYCLE_NUMBER=0; fi #201507140000
if [[ $INITIAL_DATE -gt 201704270000 ]]; then export CYCLE_NUMBER=2; fi 
export  RADAR_NUMBER=0

# Tasks to run: (run if true):        
export  RUN_WPS=true
export  RUN_REAL_FC=true
export RUN_ENS_WPS=false
export RUN_INITIAL_FC=false
export  RUN_OBS_D01=false
export  RUN_OBS_D02=false
export  RUN_RCV=false
export  RUN_BLEND=false
export  RUN_DART_D01=false
export  RUN_DART_D02=false
export  RUN_ENS_WRF=false
export  RUN_DART_D01_2=false
export  RUN_ENSMEAN_D01=false 
export  RUN_ENSMEAN_D02=false
export  RUN_ENSMEAN_BG_D01=false
export  RUN_ENSMEAN_BG_D02=false
export RUN_ENS_ICBC=false

# Domain:
export  MAP_PROJ=lambert
export  REF_LAT=39.0
export  REF_LON=-101.0
export  TRUELAT1=32.0
export  TRUELAT2=46.0
export  STAND_LON=-101.0
export  NL_TIME_STEP=60
export  NL_E_VERT=51
export  NL_P_TOP_REQUESTED=1500
export  FEEDBACK=1

#DOMAIN for NEST
export  MAX_DOM=1
export  PARENT_GRID_RATIO_1=1;  export PARENT_GRID_RATIO_2=2;   export PARENT_GRID_RATIO_3=3
export  NL_E_WE_1=415;  export NL_E_WE_2=295;     export NL_E_WE_3=211
export  NL_E_SN_1=325;  export NL_E_SN_2=165;     export NL_E_SN_3=151	
export  I_PARENT_START_1=1;  export I_PARENT_START_2=63;   export I_PARENT_START_3=103
export  J_PARENT_START_1=1;  export J_PARENT_START_2=41;   export J_PARENT_START_3=61
export  GEOG_DATA_RES_1=modis_30s+30s;  export GEOG_DATA_RES_2=2m;   export GEOG_DATA_RES_3=1m
export  NL_DXY_1=15000;  export NL_DXY_2=3000;  export NL_DXY_3=3000
export  INPUT_FROM_FILE_1=.true.;  export INPUT_FROM_FILE_2=.false.;   export INPUT_FROM_FILE_3=.false.
#export  NL_ETA_LEVELS=${NL_ETA_LEVELS:-1.0000, 0.9980, 0.9940, 0.9870, 0.9750, 0.9590, \
#                                 0.9390, 0.9160, 0.8920, 0.8650, 0.8350, 0.8020, 0.7660, \
#                                 0.7270, 0.6850, 0.6400, 0.5920, 0.5420, 0.4970, 0.4565, \
#                                 0.4205, 0.3877, 0.3582, 0.3317, 0.3078, 0.2863, 0.2670, \
#                                 0.2496, 0.2329, 0.2188, 0.2047, 0.1906, 0.1765, 0.1624, \
#                                 0.1483, 0.1342, 0.1201, 0.1060, 0.0919, 0.0778, 0.0657, \
#                                 0.0568, 0.0486, 0.0409, 0.0337, 0.0271, 0.0209, 0.0151, \
#                                 0.0097, 0.0047, 0.0000}
export AUTO_LEVELS_OPT=2; export DZBOT=20; export DZSTRETCH_S=1.08; export DZSTRETCH_U=1.1
			   
#physics					   
export NL_MP_PHYSICS=8 # 2 for Lin
export NL_RA_LW=4
export NL_RA_SW=4
export NL_RADT1=10; export NL_RADT2=10
export NL_SF_SFCLAY_PHYSICS=2
export NL_SF_SURFACE_PHYSICS=2 # 2 for CWB, 1 for Korea
export NL_BL_PBL_PHYSICS=2
export NL_BLDT=0
export NL_CU_PHYSICS1=1; export NL_CU_PHYSICS2=0
export NL_CUDT1=5; export NL_CUDT2=5
export NL_NUM_SOIL_LAYERS=4
export NL_NUM_METGRID_LEVELS=38

export SKEB=0   ##skeb,0 turn off ;1 turn on
export PERT_BDY=0
export RUN_MULTI_PHY=false  ##in wrf-ens   

# WRF-VAR
export NL_OB_FORMAT=2
export NL_NTMAX=80
export FORCE_USE_OLD_DATA=T
export WINDOW_START=-1h30min
export WINDOW_END=1h30min
export MAX_ERROR=3.0
export CV_OPTIONS1=5
export CV_OPTIONS2=7
export KIND_VAR=3
export NL_ALPHA_CORR_SCALE=100.   
export NL_JE_FACTOR=1.33333         
export NL_ALPHA_VERTLOC=true

#########################################################################################################
# For Ensembles
export NUM_MEMBERS=5
export MAX_ERROR=5
export ASSIM_INT_HOURS=6
export IC_PERTSCALE=0.25
export ADAPTIVE_INFLATION=0 
export NUM_VAR_DA=18
export VAR_DART=${VAR_DART:-"U,V,PH,THM,MU,QVAPOR,QCLOUD,QRAIN,QICE,QSNOW,QGRAUP,QNICE,QNRAIN,U10,V10,T2,Q2,PSFC"}
#export VAR_DART=${VAR_DART:-"U,V,W,PH,T,MU,QVAPOR,U10,V10,T2,Q2,PSFC,QCLOUD,QICE,QRAIN,QSNOW,QGRAUP"}
#export VAR_RADAR=${RADAR_DART:-"U,V,W,PH,T,MU,QVAPOR,U10,V10,T2,Q2,PSFC,QCLOUD,QICE,QRAIN,QSNOW,QGRAUP,REFL_10CM,VT_DBZ_WT"}
#########################################################################################################
echo "wrapper done"
$SCRIPTS_DIR/run_eakf_suite.ksh
exit 0

