. ./path.sh
. ./cmd.sh3

##### Parameter used in this files ##############################
stage=6
numjobs=40		# USE 40 on server, equal to number of cores
dataset="dev_p3"

numLeavesTri1=506	# Number of triphone states
numGaussTri1=512	# Number of Gaussians, which is equal to 

##############################################################
#################### Data Preparation ########################

# Create wav.scp, text, spk2utt and utt2spk
if [ $stage -le 1 ]; then
local/prepare_rsr2015_part3_data.sh
for var in bkg_rsr dev_p3_te  dev_p3_tr
do
    mv data/${var}/text data/${var}/text.bak
    awk -F"\t" '{print $1"	SIL "$2" SIL"}' data/${var}/text.bak > data/${var}/text
done
fi


###### Prepare language model ################################

if [ $stage -le 2 ]; then
local/transfree_prepare_dict.sh data/bkg_rsr # Creates lexicon (dict) and temp_lng model
utils/prepare_lang.sh --sil-prob 0.0 --position-dependent-phones false --num-sil-states 3 --num-nonsil-states 3\
 data/local/dict_transfree "SIL" data/local/lm_tmp_transfree data/lang_transfree

fi

##############################################################
###### Feature extraction ####################################

mfccdir=mfcc
if [ $stage -le 3 ]; then
for var in bkg_rsr dev_p3_te  dev_p3_tr
do
steps/make_mfcc.sh --cmd "$train_cmd" --mfcc-config conf/mfcc.conf --nj $numjobs data/$var exp/make_mfcc/$var $mfccdir ## extract MFCC
steps/compute_cmvn_stats.sh data/$var exp/make_mfcc/$var $mfccdir ## Compute mean and variance for CMVN
utils/fix_data_dir.sh data/$var ## fixes data directory
done
fi

#########################################################################
# Background HMM Model Training
########################################################################
# Monophone

if [ $stage -le 4 ]; then
[ -d exp/bkg_rsr_mono ] && rm -r exp/bkg_rsr_mono
steps/train_mono.sh --cmd "$train_cmd" --nj $numjobs data/bkg_rsr data/lang_transfree exp/bkg_rsr_mono   ## monophone training
steps/align_si.sh --cmd "$train_cmd" --nj $numjobs data/bkg_rsr data/lang_transfree exp/bkg_rsr_mono exp/bkg_rsr_mono_ali ## align monophone
fi

## Triphone1
#if [ $stage -le 5 ]; then
#[ -d exp/bkg_rsr_tri1 ] && rm -r exp/bkg_rsr_tri1
#steps/train_deltas.sh --cmd "$train_cmd" $numLeavesTri1 $numGaussTri1 data/bkg_rsr data/lang_transfree exp/bkg_rsr_mono_ali exp/bkg_rsr_tri1
#fi


#######################################################################
########## Training: Speaker-utterance model adaptation #################
####### Note: No VAD applied during speaker modeling ####################
if [ $stage -le 6 ]; then
while read model_name
do
    utils/subset_data_dir.sh --utt-list data/${dataset}_tr/${model_name}/id.list data/${dataset}_tr data/${dataset}_tr/${model_name}
    [ -d exp/mono_ali_${dataset}_tr/${model_name} ] && rm -r exp/mono_ali_${dataset}_tr/${model_name}
    [ -d exp/mono_ali_${dataset}_tr_MAPadapt/${model_name} ] && rm -r exp/mono_ali_${dataset}_tr_MAPadapt/${model_name}
    steps/align_si.sh --nj 1 data/${dataset}_tr/${model_name} data/lang_transfree exp/bkg_rsr_mono exp/mono_ali_${dataset}_tr/${model_name}  ### alignment
    steps/train_map.sh --tau 15 data/${dataset}_tr/${model_name} data/lang_transfree exp/mono_ali_${dataset}_tr/${model_name} exp/mono_ali_${dataset}_tr_MAPadapt/${model_name} ## MAP adaptation
done < data/dev_p3_tr/model
fi

###Number of jobs have to given in the loop 
num_spk_text=`wc -l data/dev_p3_tr/model | awk '{print $1}'`
if [ $stage -le 8 ]; then
mkdir logfiles
[ -d scores ] && rm -r scores
$train_cmd JOB=1:$num_spk_text logfiles/gen_corr/align.JOB.log local/testing_script_RSR_sge.sh JOB "gen" "corr" $dataset
$train_cmd JOB=1:$num_spk_text logfiles/imp_corr/align.JOB.log local/testing_script_RSR_sge.sh JOB "imp" "corr" $dataset
fi


if [ $stage -le 9 ]; then
local/process_scores.sh "gen" "corr" $dataset $num_spk_text
local/process_scores.sh "imp" "corr" $dataset $num_spk_text

cd scores/${dataset}/combined_scores
paste gen_corr_model_combined gen_corr_bkg_combined | awk '{print $1, $2}' > gen_corr_all
paste imp_corr_model_combined imp_corr_bkg_combined | awk '{print $1, $2}' > imp_corr_all

rm gen_corr_kaldi imp_corr_kaldi

cat gen_corr_all |awk '{print $1-$2, "target"}' >gen_corr_kaldi
cat imp_corr_all |awk '{print $1-$2, "nontarget"}' >imp_corr_kaldi
cat gen_corr_kaldi imp_corr_kaldi >imp_corr_perf

compute-eer imp_corr_perf

fi

###################################################################################################################
