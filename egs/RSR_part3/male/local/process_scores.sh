########################################################################

genimp=$1 #"gen"  # "gen" or "imp"
corrwrong=$2 #"corr" # "corr" or "wrong"
dataset=$3
trial_num=$4

mkdir -p scores/$dataset/combined_scores

cd scores/$dataset

rm combined_scores/${genimp}_${corrwrong}_model_combined combined_scores/${genimp}_${corrwrong}_bkg_combined 

for var in `seq 1 $trial_num`  ## loop will be for number of list created
do
    cat ${genimp}_${corrwrong}/${genimp}_${corrwrong}_model$var.scores >> combined_scores/${genimp}_${corrwrong}_model_combined
    
    cat ${genimp}_${corrwrong}/${genimp}_${corrwrong}_bkg$var.scores >> combined_scores/${genimp}_${corrwrong}_bkg_combined
    #fi
done

cd combined_scores

paste ${genimp}_${corrwrong}_model_combined ${genimp}_${corrwrong}_bkg_combined | awk '{print $1, $2}' > ${genimp}_${corrwrong}_all ## |grep -v Inf 
cd ../../../
