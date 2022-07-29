#!/bin/bash

# 2020-10-05: Errors with venv:
# https://stackoverflow.com/questions/23233252/broken-references-in-virtualenvs
# 2019-11-18

# Create Virtual Environment for NeuroSynth

# Environment
DIR="/Users/vincent/Data/Documents/Utah/Kladblok/20181230_Langenecker/20190411_Kim_Langenecker_project/20191118_NeuroSynth/venv"
mkdir -p "${DIR}"

# Virtualenv
virtualenv -p python3 "${DIR}"
source "${DIR}"/bin/activate

# Install toolboxes
${DIR}/bin/pip3 install \
      ipython \
      neurosynth \
      matplotlib \
      nibabel \
      numpy \
      scipy \
      pandas==0.25.3\
      ply \
      scikit-learn \
      six \
      biopython
