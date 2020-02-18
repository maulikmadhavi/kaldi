
genimp=$1 #"gen"  # "gen" or "imp"
corrwrong=$2 #"corr" # "corr" or "wrong"

rm ${genimp}_${corrwrong}_model_combined ${genimp}_${corrwrong}_bkg_combined ${genimp}_${corrwrong}_sent_combined ${genimp}_${corrwrong}_spk_combined

cd ../scores_MAPadapt_testali_SUali/dev_p1

for var in {1..1492}
do


cat ${genimp}_${corrwrong}/${genimp}_${corrwrong}_model$var.scores >> ../../process_scores/${genimp}_${corrwrong}_model_combined

cat ${genimp}_${corrwrong}/${genimp}_${corrwrong}_bkg$var.scores >> ../../process_scores/${genimp}_${corrwrong}_bkg_combined

cat sent_score/${genimp}_${corrwrong}/sent_${genimp}_${corrwrong}${var}.scores >> ../../process_scores/${genimp}_${corrwrong}_sent_combined

cat spk_score/${genimp}_${corrwrong}/spk_${genimp}_${corrwrong}${var}.scores >> ../../process_scores/${genimp}_${corrwrong}_spk_combined


done

cd ../../process_scores

paste ${genimp}_${corrwrong}_model_combined ${genimp}_${corrwrong}_bkg_combined ${genimp}_${corrwrong}_sent_combined ${genimp}_${corrwrong}_spk_combined| awk '{print $1, $2, $3, $4}' > organized_score/dev_p1/${genimp}_${corrwrong}_all
