import os
import pandas as pd
import librosa
import librosa.display
import matplotlib.pyplot as plt
import numpy as np
from tqdm import tqdm
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import LabelEncoder
#import tensorflow as tf
#from tensorflow.keras import layers, models
import warnings
import joblib

warnings.filterwarnings('ignore')

#audio_test = "/Users/mirandasheafor/Downloads/record_out.wav"

#Single file processor
def singleAudio(audio_path):
    if os.path.exists(audio_path):  # Ensure the file exists
            
        audio, sr = librosa.load(audio_path, sr=None)  # Load audio
        audio_length = len(audio)  # Length of audio array
        if audio_length <= 0: #Check audio exists
            print("Empty file")
            return

        # Compute STFT and mel spectrogram
        stft_matrix = librosa.stft(audio, n_fft=2048, hop_length=512)
        S = librosa.feature.melspectrogram(S=np.abs(stft_matrix) ** 2, sr=sr, n_mels=24, fmax=40000)
        S_dB = librosa.power_to_db(S, ref=np.mean)

        # Display the spectrogram
        #print(S_dB.shape)
        #plt.figure(figsize=(10, 4))
        #librosa.display.specshow(S_dB, sr=sr, x_axis='time', y_axis='mel')
        #plt.colorbar(format='%+2.0f dB')
        #plt.title(f'Mel Spectrogram')
        #plt.tight_layout()
        #plt.show()

        return S_dB
    print("Bad pathway")
    return

#singleAudio(audio_test)