. ../path.sh



#cd organized_score/eval_p2/utt_comp

cd organized_score/dev_p3/utt_comp

rm gen_corr_kaldi gen_wrong_kaldi imp_corr_kaldi imp_wrong_kaldi gen_wrong_perf imp_corr_perf imp_wrong_perf

cat gen_corr_all |awk '{print $1-1*$2-0*$3, "target"}' >gen_corr_kaldi

#cat gen_wrong_all |awk '{print $1-0.5*$2-0.5*$3, "nontarget"}' >gen_wrong_kaldi

cat imp_corr_all |awk '{print $1-1*$2-0*$3, "nontarget"}' >imp_corr_kaldi

#cat imp_wrong_all |awk '{print $1-0.5*$2-0.5*$3, "nontarget"}' >imp_wrong_kaldi

#cat gen_corr_kaldi gen_wrong_kaldi >gen_wrong_perf

cat gen_corr_kaldi imp_corr_kaldi >imp_corr_perf

#cat gen_corr_kaldi imp_wronng_kaldi >imp_wrong_perf

#compute-eer gen_wrong_perf

compute-eer imp_corr_perf 

#compute-eer imp_wrong_perf


