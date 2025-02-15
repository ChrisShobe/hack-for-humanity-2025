import os
import pandas as pd
import librosa
import librosa.display
import matplotlib.pyplot as plt
import numpy as np
from tqdm import tqdm
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import LabelEncoder
import tensorflow as tf
from tensorflow.keras import layers, models
import warnings
import joblib

warning.filterwarnings('ignore')

csv_path = ""
audio_path = ""

#Load CSV 
df_csv = pd.read_csv(csv_path)


