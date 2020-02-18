#!/usr/bin/python
#coding:utf8

import sys
import re

def get_map(F, m):
    f = open(F, "r")
    while True:
        line = f.readline()
        if not line:
            break
        part = re.split(r'[,\t]', line.strip())
        if len(part) == 2:
            m[part[0]] = part[1]
        elif len(part) == 3:
            m[part[0]+"_"+part[1]] = part[2]
        else:
            print("text error for line: "+line)
            continue
    f.close()

def get_wav_scp(base_dir, file_list, wav_scp):
    in_f = open(file_list, "r")
    out_f = open(wav_scp, "w")
    while True:
        line = in_f.readline()
        if not line:
            break
        part = re.split(r'[/.]', line.strip())
        if len(part) != 4:
            print("file_list error for line: "+line)
            continue
        else:
            new_wav = base_dir + "/" + line.strip()
            newline = part[2] + "\tsox -t sph " + new_wav + " -b 16  -t wav - |\n"
            out_f.write(newline)
    in_f.close()
    out_f.close()

def get_text_utt2spk(wav_scp, text_m, text_file, utt2spk_file):
    wav_f = open(wav_scp, "r")
    text_f = open(text_file, "w")
    utt2spk_f = open(utt2spk_file, "w")
    while True:
        line = wav_f.readline()
        if not line:
            break
        wav = re.split(r'[\t]', line.strip())[0]
        part = wav.split("_")
        if len(part) != 3:
            print("error wave id:"+wav)
            continue
        spkr = part[0]
        sess = part[1]
        text = part[2]
        utt2spk_f.write(wav+"\t"+wav+"\n")
        if int(text) < 61:
            key = text
        else:
            key = sess+"_"+text
        if text_m.has_key(key):
            text_new = text_m[key]
            text_f.write(wav+"\t"+text_new+"\n")
        else:
            print("no text map for wave id:"+key)
            continue
    wav_f.close()
    text_f.close()   
    utt2spk_f.close()

num_map = {"0":"ZERO", "1":"ONE", "2":"TWO", "3":"THREE", "4":"FOUR", "5":"FIVE", "6":"SIX", "7":"SEVEN", "8":"EIGHT", "9":"NINE"}

def text_norm(text):
    text_new = text.replace('-', ' ')
    part = text_new.split(" ")
    for i in range(len(part)):
        if part[i] in num_map.keys():
            part[i] = num_map[part[i]]
    return " ".join(part).upper()


if __name__ == '__main__':

    if len(sys.argv) != 3:
        print("usage: rsr2015.py rsr_dir out_dir")
        sys.exit(1)
    
    rsr_dir = sys.argv[1]
    out_dir = sys.argv[2]

    file_list = rsr_dir + "/infos/filelist.lst"
    wav_scp = out_dir + "/wav.scp"
    get_wav_scp(rsr_dir, file_list, wav_scp)

    text_m = {}
    part1_list = rsr_dir + "/infos/promptpart1.lst"
    get_map(part1_list, text_m)
    part2_list = rsr_dir + "/infos/promptpart2.lst"
    get_map(part2_list, text_m)
    part3_list = rsr_dir + "/infos/promptpart3.lst"
    get_map(part3_list, text_m)

    for (k,v) in text_m.items():
        text_m[k] = text_norm(v)

    text_file = out_dir + "/text"
    utt2spk_file = out_dir + "/utt2spk"
    get_text_utt2spk(wav_scp, text_m, text_file, utt2spk_file)
