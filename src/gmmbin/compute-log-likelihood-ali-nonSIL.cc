// gmmbin/gmm-acc-stats-ali.cc

// Copyright 2009-2012  Microsoft Corporation  Johns Hopkins University (Author: Daniel Povey)

// See ../../COPYING for clarification regarding multiple authors
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
// THIS CODE IS PROVIDED *AS IS* BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, EITHER EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION ANY IMPLIED
// WARRANTIES OR CONDITIONS OF TITLE, FITNESS FOR A PARTICULAR PURPOSE,
// MERCHANTABLITY OR NON-INFRINGEMENT.
// See the Apache 2 License for the specific language governing permissions and
// limitations under the License.


#include "base/kaldi-common.h"
#include "util/common-utils.h"
#include "gmm/am-diag-gmm.h"
#include "hmm/transition-model.h"
#include "gmm/mle-am-diag-gmm.h"

#include <sstream>
#include <iterator>
#include <algorithm>
#include <utility>

int main(int argc, char *argv[]) {
  using namespace kaldi;
  typedef kaldi::int32 int32;
  try {
    const char *usage =
        "compute utterance log likelihood based on the alignments.\n"
        "Usage:  compute-log-likelihood-ali [options] <model-in> <feature-rspecifier> "
        "<alignments-rspecifier> <score-out>\n"
        "e.g.:\n compute-log-likelihood-ali 1.mdl scp:train.scp ark:1.ali 1.score\n";

    ParseOptions po(usage);
    bool binary = false;
    BaseFloat acoustic_scale = 1.0;
    po.Register("binary", &binary, "Write output in binary mode");
    po.Register("acoustic-scale", &acoustic_scale, "Scaling factor for acoustic likelihoods");
    po.Read(argc, argv);

    if (po.NumArgs() < 4) {
      po.PrintUsage();
      exit(1);
    }

    std::vector<int32> sil_pdfids;
    std::string model_filename = po.GetArg(1),
        feature_rspecifier = po.GetArg(2),
        alignments_rspecifier = po.GetArg(3),
        score_wxfilename = po.GetArg(4),
	length_wspecifier = po.GetArg(5);
    if (po.NumArgs() == 6) {
    std::string sspecifier = po.GetArg(6);

    std::istringstream iss(sspecifier);
    std::string token;
    while (getline(iss, token, ',')) {
	int32 s;
	std::istringstream(token) >> s;
	sil_pdfids.push_back(s);
	//std::cout << s <<std::endl;
    }
}
    AmDiagGmm am_gmm;
    TransitionModel trans_model;
    {
      bool binary;
      Input ki(model_filename, &binary);
      trans_model.Read(ki.Stream(), binary);
      am_gmm.Read(ki.Stream(), binary);
    }

    Vector<double> transition_accs;
    trans_model.InitStats(&transition_accs);
    AccumAmDiagGmm gmm_accs;
    gmm_accs.Init(am_gmm, kGmmAll);

    double tot_like = 0.0;
    kaldi::int64 tot_t = 0;

    SequentialBaseFloatMatrixReader feature_reader(feature_rspecifier);
    RandomAccessInt32VectorReader alignments_reader(alignments_rspecifier);
     BaseFloatWriter scores_writer(score_wxfilename);
     Int32Writer length_writer(length_wspecifier);

    int32 num_done = 0, num_err = 0;
    for (; !feature_reader.Done(); feature_reader.Next()) {
      std::string key = feature_reader.Key();
      if (!alignments_reader.HasKey(key)) {
        KALDI_WARN << "No alignment for utterance " << key;
        num_err++;
      } else {
        const Matrix<BaseFloat> &mat = feature_reader.Value();
        const std::vector<int32> &alignment = alignments_reader.Value(key);

        if (alignment.size() != mat.NumRows()) {
          KALDI_WARN << "Alignments has wrong size " << (alignment.size())
                     << " vs. " << (mat.NumRows());
          num_err++;
          continue;
        }

        num_done++;
        BaseFloat tot_like_this_file = 0.0;
	int32 non_sil_frames = 0;
        for (size_t i = 0; i < alignment.size(); i++) {
          int32 tid = alignment[i],  // transition identifier.
              pdf_id = trans_model.TransitionIdToPdf(tid);
          trans_model.Accumulate(1.0, tid, &transition_accs);
	  if (std::find(sil_pdfids.begin(), sil_pdfids.end(), pdf_id) == sil_pdfids.end()) {
          	tot_like_this_file += gmm_accs.AccumulateForGmm(am_gmm, mat.Row(i),
                                                          pdf_id, 1.0);
		non_sil_frames ++;
	  }
        }
        tot_like += tot_like_this_file;
	scores_writer.Write(key, tot_like_this_file*acoustic_scale);
	length_writer.Write(key, non_sil_frames);
        tot_t += alignment.size();
      }
    }
    KALDI_LOG << "Done " << num_done << " files, " << num_err
              << " with errors.";

    KALDI_LOG << "Overall avg like per frame (Gaussian only) = "
              << (tot_like/tot_t) << " over " << tot_t << " frames.";

    {
      //Output ko(accs_wxfilename, binary);
      //transition_accs.Write(ko.Stream(), binary);
      //gmm_accs.Write(ko.Stream(), binary);
    }
    KALDI_LOG << "Written accs.";
    if (num_done != 0)
      return 0;
    else
      return 1;
  } catch(const std::exception &e) {
    std::cerr << e.what();
    return -1;
  }
}


