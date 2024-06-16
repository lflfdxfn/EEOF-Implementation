[![DOI](https://zenodo.org/badge/DOI/10.1109/ICDM58522.2023.00109.svg)](https://doi.org/10.1109/ICDM58522.2023.00109)

# EEOF
Official implementation of EEOF: "Online Ensemble of Ensemble OVA Framework for Class Evolution with Dominant Emerging Classes" in the proceedings of ICDM 2023

## Dependencies
MATLAB R2022b
  
## Data Preparation
* Steps:
  * Download ".zip" file in this [share link](https://drive.google.com/file/d/1ycg5T8YgpgUfR5moqWA5uMmNLpiJ32ld/view?usp=drive_link), and unzip it to the folder "./datasets"
  * Run the python scripts "synthetic_disp_reoccur.py" and "synthetic_emerging.py" in the ".zip" file to get all mentioned synthetic data streams.

* Synthetic data streams: "./datasets/synthetic_datasets"
  * Scenario 1: Class emergence with a dominant amount, varying hyperparameter $p_{max}$.
  * Scenario 2: Class emergence with a dominant amount, varying hyperparameter $T_{max}$.
  * Scenario 3: Class emergence with a dominant amount, varying hyperparameter $\sigma$.
  * Scenario 4: Class disappearance and class reoccrrence.
* Real-world data streams: "./datasets"
  * Tweet Stream-A: wed_ce.mat
  * Tweet Stream-B: christ_ce.mat
  * Tweet Stream-C: laden_ce.mat
  * Tweet Stream-20 classes: huge_tweet.mat
  * KDDCUP99: kddcup99.mat
  * Poker-hand: pokerlsn.mat

## Experiments
* EEOF and CBCE on synthetic data streams:
  * Run "main_real.m".
* EEOF and CBCE on real-world data streams:
  * Run "main_synthetic.m".

## Useful Information
* Results:
  * Running temporary files, including logs, figures, predictions, and other detailed information in algorithms, are stored in "./results".
  * Table that stores results for each data stream will be listed in current directory. 
* Code:
  * main_real.m: script that runs real-world data streams
  * main_synthetic.m: script that runs synthetic data streams
  * CBCE.m: the state-of-the-art method for comparison
  * EEOF.m: our proposed method
  * algo_list.m: list of method
  * algo_settings: hyperparameter settings in algorithm
  * eval_sliding.m: evaluation metric
  * run_algorithm.m: running setting for algorithms
  * store_in_csv.m: store evaluation results into ".csv" files

## Full Paper
The full paper can be found at [this link](https://ieeexplore.ieee.org/abstract/document/10415801).

## Citation
```bibtex
@INPROCEEDINGS{zhi2023online,
  author={Cao, Zhi and Zhang, Shuyi and Lin, Chin-Teng},
  booktitle={2023 IEEE International Conference on Data Mining (ICDM)}, 
  title={Online Ensemble of Ensemble OVA Framework for Class Evolution with Dominant Emerging Classes}, 
  year={2023},
  volume={},
  number={},
  pages={968-973},
  keywords={Degradation;Adaptation models;Pandemics;Data models;Data mining;data stream mining;online learning;class evolution;ensemble model},
  doi={10.1109/ICDM58522.2023.00109}
}
```