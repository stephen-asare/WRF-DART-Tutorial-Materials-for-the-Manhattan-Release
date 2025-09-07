#!/bin/bash

initial_date=$1
paramfile=$(readlink -f "$2") # Get absolute path for param.csh from command line arg
echo $paramfile
source "$paramfile"

cd "${RUN_DIR}"
echo "Running init_ensemble_var.sh at $(date) in $(pwd)"
# Generate the i/o lists in rundir automatically when initializing the ensemble
num_ens=${NUM_ENS}
input_file_name="input_list_d01.txt"
input_file_path="./advance_temp"
output_file_name="output_list_d01.txt"

n=1

[ -e "$input_file_name" ] && rm "$input_file_name"
[ -e "$output_file_name" ] && rm "$output_file_name"

while [ "$n" -le "$num_ens" ]; do
    ensstring=$(printf "%04d" "$n")

    in_file_name="${input_file_path}${n}/wrfinput_d01"
    out_file_name="filter_restart_d01.${ensstring}"


    echo "$in_file_name" >> "$input_file_name"
    echo "$out_file_name" >> "$output_file_name"

    n=$((n + 1))
done

###

gdate=($(echo $initial_date 0h -g | ${DART_DIR}/models/wrf/work/advance_time))
gdatef=($(echo $initial_date ${ASSIM_INT_HOURS}h -g | ${DART_DIR}/models/wrf/work/advance_time))
echo "gdate = $gdate"
echo "gdatef = $gdatef"

wdate=$(echo "$initial_date 0h -w" | "${DART_DIR}/models/wrf/work/advance_time")
echo "wdate = $wdate"
yyyy=$(echo "$initial_date" | cut -b1-4)

mm=$(echo "$initial_date" | cut -b5-6)
dd=$(echo "$initial_date" | cut -b7-8)
hh=$(echo "$initial_date" | cut -b9-10)

${COPY} "${TEMPLATE_DIR}/namelist.input.meso" namelist.input
${REMOVE} "${RUN_DIR}/WRF"
${LINK} "${OUTPUT_DIR}/${initial_date}" WRF

n=1
while [ "$n" -le "$NUM_ENS" ]; do
    echo "  QUEUEING ENSEMBLE MEMBER $n at $(date)"

    mkdir -p "${RUN_DIR}/advance_temp${n}"

    ${LINK} "${RUN_DIR}/WRF_RUN/"* "${RUN_DIR}/advance_temp${n}/."
    ${LINK} "${RUN_DIR}/input.nml" "${RUN_DIR}/advance_temp${n}/input.nml"

    # ${COPY} "${OUTPUT_DIR}/${initial_date}/wrfinput_d01_${gdate[0]}_${gdate[1]}_mean" \
    #           "${RUN_DIR}/advance_temp${n}/wrfvar_output.nc"
    sleep 3
    ${COPY} "${RUN_DIR}/add_bank_perts.ncl" "${RUN_DIR}/advance_temp${n}/."

    # cmd3="ncl 'MEM_NUM=${n}' 'PERTS_DIR=\"${PERTS_DIR}\"' ${RUN_DIR}/advance_temp${n}/add_bank_perts.ncl"
    # ${REMOVE} "${RUN_DIR}/advance_temp${n}/nclrun3.out"
#     cat > "${RUN_DIR}/advance_temp${n}/nclrun3.out" << EOF
# $cmd3
# EOF
#     echo "$cmd3" > "${RUN_DIR}/advance_temp${n}/nclrun3.out.tim"
    members=$(printf "%03d" $n)

    cat > "${RUN_DIR}/rt_assim_init_${n}.sh" << EOF
#!/bin/bash
#=================================================================
#SBATCH --job-name=first_advance_${n}
#SBATCH --output=first_advance_${n}.out
#SBATCH --error=first_advance_${n}.err
#SBATCH --account=backfill2
#SBATCH -t 00:20:00
#SBATCH --partition=backfill2
#SBATCH --priority=${ADVANCE_PRIORITY}
#SBATCH -n 64
#SBATCH -C "intel,YEAR2013|intel,YEAR2015|intel,YEAR2017|intel,YEAR2018|intel,YEAR2019"
#SBATCH --nodes=8
#SBATCH --mem-per-cpu=4000M
#=================================================================
ulimit -s unlimited
export MPI_SHEPHERD=FALSE


echo "rt_assim_init_${n}.sh is running in $(pwd)"

cd "${RUN_DIR}/advance_temp${n}"

# if [ -e wrfvar_output.nc ]; then
#     echo "Running nclrun3.out to create wrfinput_d01 for member $n at $(date)"

#     chmod +x nclrun3.out
#     ./nclrun3.out >& add_perts.out

#     if [ ! -s add_perts.err ]; then
#         echo "Perts added to member ${n}"
#     else
#         echo "ERROR! Non-zero status returned from add_bank_perts.ncl. Check ${RUN_DIR}/advance_temp${n}/add_perts.err."
#         cat add_perts.err
#         exit 1
#     fi

#     ${MOVE} wrfvar_output.nc wrfinput_d01
#     echo "wrfvar_output moved as  wrfinput_d01"
# fi


SRC1="/gpfs/home/sa24m/scratch/generate_ensembles/icbc/test/rc/${initial_date}/wrfinput_d01.${initial_date}.e${members}"
SRC2="/gpfs/home/sa24m/scratch/generate_ensembles/icbc/test/rc/${initial_date}/wrfbdy_d01.e${members}"

echo "Copying from \${SRC1} to ${RUN_DIR}/advance_temp${n}/wrfinput_d01"

DEST1="${RUN_DIR}/advance_temp${n}/wrfinput_d01"
DEST2="${RUN_DIR}/advance_temp${n}/wrfbdy_d01"

if [ -f "\${SRC1}" ]; then
    cp "\${SRC1}" "\${DEST1}"
    echo "Perturbed file copied to \${DEST1}"
else
    echo "Warning: File not found: \${SRC1}"
fi

if [ -f "\${SRC2}" ]; then
    cp "\${SRC2}" "\${DEST2}"
    echo "Perturbed boundary file copied to \${DEST2}"
else
    echo "Warning: File not found: \${SRC2}"
fi

    # # members=$(printf "%03d" $n)

    # # SRC1="/gpfs/research/chipilskigroup/stephen_asare/icbc/test/rc/${initial_date}/wrfinput_d01.${initial_date}.e${members}"
    # # SRC2="/gpfs/research/chipilskigroup/stephen_asare/icbc/test/rc/${initial_date}/wrfbdy_d01.e${members}"
    # echo "Copying from ${SRC1} to ${RUN_DIR}/advance_temp${n}/wrfinput_d01"

    # # Define the destination directory
    # DEST1="${RUN_DIR}/advance_temp${n}/wrfinput_d01"
    # DEST2="${RUN_DIR}/advance_temp${n}/wrfbdy_d01"

#     # Copy the file
#     if [ -f "$SRC1" ]; then
#         cp "$SRC1" "$DEST1"
#         echo "Perturbed file copied to $DEST1"
#     else
#         echo "Warning: File not found: $SRC1"
#     fi

#     if [ -f "$SRC2" ]; then
#         cp "$SRC2" "$DEST2"
#         echo "Perturbed boundary file copied to $DEST2"
#     else
#         echo "Warning: File not found: $SRC2"
#     fi

# # fi

cd ${RUN_DIR}


echo "Running first_advance.sh for member $n at $(date)"
"${SHELL_SCRIPTS_DIR}/first_advance.sh" $initial_date $n $paramfile

EOF

    sbatch "${RUN_DIR}/rt_assim_init_${n}.sh"

    n=$((n + 1))
done
echo "init done"
exit 0

