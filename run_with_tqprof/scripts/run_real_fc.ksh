#!/bin/ksh -x
# . ~/.kshrc

date

export OUTPUT_FREQ_MINUTE=`expr 60 \* ${OUTPUT_INTERVAL}`
export LBC_FREQ_SECOND=`expr 3600 \* ${LBC_FREQ}` # for REAL interpolation


export START_DATE=`${BUILD_DIR}/da_advance_time.exe $INITIAL_DATE 0 -w`
# export END_DATE=`${BUILD_DIR}/da_advance_time.exe $DATE $DE_FCST_RANGE -w`

datea=$START_DATE
while true; do
    # FINAL_DATE
    END_DATE=`${BUILD_DIR}/da_advance_time.exe $datea $DE_FCST_RANGE -w`
    ln -sf $WRF_DIR/run/* .
    rm namelist.input    

    ln -sf ${WPS_RUN_DIR}/met_em* .

    #  Run real.exe twice, once to get first time wrfinput_d0? and wrfbdy_d01,
    #  then again to get second time wrfinput_d0? file
    
    ccyy_c=${datea:0:4}; mm_c=${datea:5:2}; dd_c=${datea:8:2}; hh_c=${datea:11:2}
    OUTPUT_DIR=${ccyy_c}${mm_c}${dd_c}${hh_c}
    mkdir -p "$OUTPUT_DIR"
    echo "Cycle dir: $OUTPUT_DIR"

    n=1
    while [ $n -le 2 ]; do
        echo "RUNNING REAL, STEP $n"
        if [ $n -eq 1 ]; then
            date1=$datea
            date2=$END_DATE
            fcst_hours=$DE_FCST_RANGE
        else
            date1=$END_DATE
            date2=$END_DATE
            fcst_hours=0
        fi
        ccyy_s=${date1:0:4}; mm_s=${date1:5:2}; dd_s=${date1:8:2}; hh_s=${date1:11:2}
        ccyy_e=${date2:0:4}; mm_e=${date2:5:2}; dd_e=${date2:8:2}; hh_e=${date2:11:2}

        # export ccyy_s=`echo $date1 | cut -c1-4`
        # export mm_s=`echo $date1 | cut -c6-7`
        # export dd_s=`echo $date1 | cut -c9-10`
        # export hh_s=`echo $date1 | cut -c12-13`
        # export ccyy_e=`echo $date2 | cut -c1-4`
        # export mm_e=`echo $date2 | cut -c6-7`
        # export dd_e=`echo $date2 | cut -c9-10`
        # export hh_e=`echo $date2 | cut -c12-13`

        # OUTPUT_DIR=${ccyy_s}${mm_s}${dd_s}${hh_s}
        # mkdir -p $OUTPUT_DIR
        # echo "Running for $OUTPUT_DIR"


        # create namelist.input
        cat > namelist.input << EOF
        &time_control
        run_days                            = 0,
        run_hours                           = ${fcst_hours},
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
        history_interval                    = 15,15, 
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
        max_dom                             = ${MAX_DOM}
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
        num_metgrid_levels                  = ${NL_NUM_METGRID_LEVELS},
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
        NUM_LAND_CAT                        = 20,
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
        scalar_adv_opt                      = 2, 2,
        use_theta_m                        = 0
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
        module restore

        srun -n 4 ./real.exe

        rc=$?
        if (( rc != 0 )); then
            echo "real.exe exited with code $rc"
            exit $rc
        fi
        ## # need to look for something to know when this job is done
        SUCCESS=$(grep -c "real_em: SUCCESS COMPLETE REAL_EM" rsl.error.0000)
        if [ "$SUCCESS" -eq 0 ]; then
            echo "real.exe blown"
            exit -1
        fi
        # [ -f wrfinput_d01 ] && echo "Moving wrfinput_d01 to ${OUTPUT_DIR}" \
        #     && mv wrfinput_d01 "${OUTPUT_DIR}/wrfinput_d01_${hh_s}_${hh_e}"

        # [ -f wrfbdy_d01 ] && echo "Moving wrfbdy_d01 to ${OUTPUT_DIR}" \
        #     && mv wrfbdy_d01 "${OUTPUT_DIR}/wrfbdy_d01_${hh_s}_${hh_e}"
        # ALWAYS move into the fixed cycle dir
        if [ -f wrfinput_d01 ]; then
            echo "Moving wrfinput_d01 -> ${OUTPUT_DIR}/wrfinput_d01_${hh_s}_${hh_e}"
            mv -f wrfinput_d01 "${OUTPUT_DIR}/wrfinput_d01_${hh_s}_${hh_e}"
            rm -f wrfinput_d01
        else
            echo "wrfinput_d01 does not exist"
        fi
        if [ -f wrfbdy_d01 ]; then
            echo "Moving wrfbdy_d01 -> ${OUTPUT_DIR}/wrfbdy_d01_${hh_s}_${hh_e}"
            mv -f wrfbdy_d01 "${OUTPUT_DIR}/wrfbdy_d01_${hh_s}_${hh_e}"
            rm -f wrfbdy_d01
        else
            echo "wrfbdy_d01 does not exist"   
        fi

        n=$((n+1))
    done

    # move to next time, or exit if final time is reached
    echo "OUTPUT_DIR = $OUTPUT_DIR"
    if [ "$OUTPUT_DIR" -ge "${FINAL_DATE:0:10}" ]; then
        echo "Reached the final date"
        exit 0
    fi

    datea=`${BUILD_DIR}/da_advance_time.exe $datea $DE_FCST_RANGE -w`
    echo "starting next time: $datea"

done

exit 0

