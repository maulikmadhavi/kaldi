#!/usr/bin/python
#coding:utf8

import sys
import re

if __name__ == '__main__':

    if len(sys.argv) != 4:
        print("usage: get_wav_bkg.py all_dir bkg_dir gender[f|m|a]")
        sys.exit(1)
    
    all_dir = sys.argv[1]
    bkg_dir = sys.argv[2]
    gender  = sys.argv[3]
    if gender not in ['f', 'm', 'a']:
        print("error gender: "+gender)
        sys.exit(1)

    all_f = open(all_dir+"/wav.scp", "r")
    bkg_f = open(bkg_dir+"/id.list", "w")
    while True:
        line = all_f.readline()
        if not line:
            break
        part = re.split(r'[\t]', line.strip())
        if len(part) != 2:
            print("error wav_scp line:"+line)
            continue
        wav_id = part[0]
        part = wav_id.split("_")
        if len(part) != 3:
            print("error wav_id line:"+line)
            continue
        if gender == 'a' or part[0][0] == gender:
            spkr = part[0][1:]
            sess = part[1]
            text = part[2]
            if spkr <= "050" and text >= "061":
                bkg_f.write(wav_id+"\n")
    all_f.close()
    bkg_f.close()

