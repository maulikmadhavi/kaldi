#!/bin/bash
#SBATCH --job-name=check_mdl
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --time=00:30:01



for i in `seq 0 12403`; 
    do 
#        echo $i; 
        model_name=$(printf model_'%05d' `expr $i`)
		filename=exp/mono_vow5_ali_tr_MAPadapt_tau3/${model_name}/final.mdl
		[ ! -f ${filename} ] && echo $model_name 
    done
