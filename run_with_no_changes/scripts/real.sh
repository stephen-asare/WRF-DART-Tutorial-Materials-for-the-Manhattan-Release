#!/bin/bash



#======================================
#SBATCH --job-name=run_real
#SBATCH -A backfill2
#SBATCH --time=00:00:20
#SBATCH --partition=backfill2
#SBATCH --qos=normal
#SBATCH --output=run_real.out
#SBATCH --error=run_real.err
#SBATCH --ntasks=10
#SBATCH --mem-per-cpu=4000M
#SBATCH --export=ALL
#======================================


paramfile="$1"
source "$paramfile"

#  Change to the ICBC_DIR directory
# cd /gpfs/home/sa24m/scratch/base/icbc
# echo ${ICBC_DIR}
cd ${ICBC_DIR}
# Execute the WRF real.exe program using MPI
# echo ${RUN_DIR}
srun ${RUN_DIR}/WRF_RUN/real.exe
# srun /gpfs/home/sa24m/scratch/base/rundir/WRF_RUN/real.exe

# Check if the program completed successfully
if grep -q "SUCCESS COMPLETE REAL_EM INIT" ./rsl.out.0000; then
    # Create a file to indicate successful completion
    touch ${ICBC_DIR}/real_done
fi


