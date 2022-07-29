# * NeuroSynth with Python on Local Machine
# 2020-10-05: remove dash from 'decision-making', otherwise, NeuroSynth does not give output.
# 2019-11-18

# See also this tutorial: https://github.com/neurosynth/neurosynth
# Database downloaded from https://github.com/neurosynth/neurosynth-data on 2019-11-18, July 2018 release (v0.7)

# Libraries
from neurosynth.base.dataset import Dataset

# * Environment
base = '/Users/vincent/Data/Documents/Utah/Kladblok/20181230_Langenecker/20190411_Kim_Langenecker_project/20191118_NeuroSynth/'
oDIR = base + '/outputMasks/01_neuroSynth'
my_database = base + '/neurSynthData/current_data/database.txt'
my_features = base + '/neurSynthData/current_data/features.txt'

# * Load database
# This takes minutes!
dataset = Dataset(my_database)


# * Load features
dataset.add_features(my_features)


# * Create list of list with all features that Katie and Joe selected
# Note: these terms are case-sensitive!!!
Emotional_Memory = ['memory', 'emotional', 'encoding retrieval', 'emotional information']
Interference_Resolution = ['stop', 'interference', 'response selection']
Facial_Emotion_Sensitivity = ['facial expressions', 'affective', 'emotional faces']
Simple_Impulsivity_Response_Style = ['decision making', 'impulsivity', 'reaction time', 'response selection']
Reward_Sensitivity = ['effort', 'loss', 'reinforcement', 'monetary incentive']
Complex_Inhibitory_Control = ['cognitive control', 'inhibition', 'impulsivity']
Sustained_Attention = ['attention', 'arousal', 'attention network', 'sustained attention']

listOfLists = [
    Emotional_Memory,
    Interference_Resolution,
    Facial_Emotion_Sensitivity,
    Simple_Impulsivity_Response_Style,
    Reward_Sensitivity,
    Complex_Inhibitory_Control,
    Sustained_Attention
]

labelsOfLists = [
    'Emotional_Memory',
    'Interference_Resolution',
    'Facial_Emotion_Sensitivity',
    'Simple_Impulsivity_Response_Style',
    'Reward_Sensitivity',
    'Complex_Inhibitory_Control',
    'Sustained_Attention'
]


# * Create a list of studies with these keywords.
# Loop over domains
for i in range(0, len(listOfLists)):

    # Domain name
    domain = str(labelsOfLists[i])

    # Loop over features
    for j in range(0, len(listOfLists[i])):

        # Feature name
        myFeature = str(listOfLists[i][j])
        print(myFeature)

        # Create list of Pubmed IDs with all studies adhering to the feature
        # frequency_threshold = 0.001, meaning that this word should be
        # in the paper 1 : 1000 words of the paper. After manually comparing
        # the number of studies and the mask resulting from the term 'emotion' with
        # this Python tool and the NeuroSynth webapp, 0.001 seems to be the default.
        ids = dataset.get_studies(features=myFeature, frequency_threshold=0.001)

        if len(ids) < 1:
            continue

        # Specific Output Folder
        ooDIR = oDIR + '/' + str(i + 1) + '_' + domain + '/' + myFeature.replace(" ", "_")

        # Save out masks
        from neurosynth.analysis import meta
        ma = meta.MetaAnalysis(dataset, ids)
        ma.save_results(ooDIR)

        # Save the list of Pubmed IDs to a text file for further analysis
        f = open(ooDIR + "/pubmedIDs.txt", "w")
        f.write(str(ids))
        f.close()
