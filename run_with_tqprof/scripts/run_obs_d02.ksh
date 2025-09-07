#!/bin/ksh

date

export year=`echo  $DATE | cut -c1-4`
export month=`echo $DATE | cut -c5-6`
export day=`echo   $DATE | cut -c7-8`
export hour=`echo  $DATE | cut -c9-10`
export minute=`echo  $DATE | cut -c11-12`

rm input.nml
cp $NML_DIR/input.nml.obs .

if [ "${minute}" -eq "00" ]; then
   export ASSIM_CONV=TRUE
else
   export ASSIM_CONV=FALSE
fi

cat > script.sed << EOF
  /obs_seq_out_file_name/c\
  obs_seq_out_file_name = 'obs_seq.${DATE}',
  /date_str/c\
  date_str = '${DATE}',
  /Use_SynopObs/c\
  Use_SynopObs = .${ASSIM_CONV}.,
  /Use_ShipsObs/c\
  Use_ShipsObs = .${ASSIM_CONV}.,
  /Use_MetarObs/c\
  Use_MetarObs = .${ASSIM_CONV}.,
  /Use_BuoysObs/c\
  Use_BuoysObs = .${ASSIM_CONV}.,
  /Use_PilotObs/c\
  Use_PilotObs = .${ASSIM_CONV}.,
  /Use_SoundObs/c\
  Use_SoundObs = .${ASSIM_CONV}.,
  /Use_SatemObs/c\
  Use_SatemObs = .${ASSIM_CONV}.,
  /Use_SatobObs/c\
  Use_SatobObs = .${ASSIM_CONV}.,
  /Use_AirepObs/c\
  Use_AirepObs = .${ASSIM_CONV}.,  
  /Use_AmdarObs/c\
  Use_AmdarObs = .${ASSIM_CONV}.,
  /Use_GpspwObs/c\
  Use_GpspwObs = .${ASSIM_CONV}.,
  /Use_SsmiRetrievalObs/c\
  Use_SsmiRetrievalObs = .${ASSIM_CONV}.,
  /Use_SsmiTbObs/c\
  Use_SsmiTbObs = .${ASSIM_CONV}.,
  /Use_Ssmt1Obs/c\
  Use_Ssmt1Obs = .${ASSIM_CONV}.,
  /Use_Ssmt2Obs/c\
  Use_Ssmt2Obs = .${ASSIM_CONV}.,
  /Use_ProflObs/c\
  Use_ProflObs = .${ASSIM_CONV}.,
  /Use_QscatObs/c\
  Use_QscatObs = .${ASSIM_CONV}.,
  /Use_BogusObs/c\
  Use_BogusObs = .${ASSIM_CONV}.,
  /Use_gpsrefobs/c\
  Use_gpsrefobs = .${ASSIM_CONV}.,
  /Use_radar_rf/c\
  Use_radar_rf = .${ASSIM_RADAR}.,
  /Use_radar_rv/c\
  Use_radar_rv = .${ASSIM_RADAR}.,
  /Use_radar_clear/c\
  Use_radar_clear = .${ASSIM_RADAR}.,
EOF

sed -f script.sed input.nml.obs > input.nml
rm script.sed

ln -sf ${OBS_D01_DIR}/${year}${month}${day}${hour}00/ob.ascii .
ln -sf ${RADAR_DIR}/radar.${DATE} ob.radar
ln -sf ${DART_DIR}/observations/obs_converters/var/work/gts_radar_to_dart .

./gts_radar_to_dart
mv input.nml input.nml.d02

date

exit 0

