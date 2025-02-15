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

# Initialize DataFrame
df = pd.DataFrame(columns=["Label", "Audio Length", "Audio Sample", "Spectrogram"])

# Count total audio files for progress bar
total_files = len(df_csv)

# Process audio files using CSV 
with tqdm(total=total_files, desc="Processing Audio Files") as pbar:
    for _, row in df_csv.iterrows():
        file_name = row['slice_file_name']
        fold = row['fold']
        label = row['class']
        
        # Construct file path
        file_path = os.path.join(audio_path, f"fold{fold}", file_name)
        
        if os.path.exists(file_path):  # Ensure the file exists
            
            audio, sr = librosa.load(file_path, sr=None)  # Load audio
            audio_length = len(audio)  # Length of audio array
            if audio_length <= 0:
                pbar.update(1)
                continue

            # Compute STFT and mel spectrogram
            stft_matrix = librosa.stft(audio, n_fft=2048, hop_length=512)
            S = librosa.feature.melspectrogram(S=np.abs(stft_matrix) ** 2, sr=sr, n_mels=24, fmax=40000)
            S_dB = librosa.power_to_db(S, ref=np.mean)

            # Append data to DataFrame
            df = df._append(
                {
                    "Label": label,
                    "Audio Length": audio_length,
                    "Audio Sample": audio,
                    "Spectrogram": S_dB
                },
                ignore_index=True,
            )
        
        pbar.update(1)

# Optionally, display the first spectrogram
if not df.empty:
    first_spectrogram = df.iloc[0]["Spectrogram"]
    print(first_spectrogram.shape)
    plt.figure(figsize=(10, 4))
    librosa.display.specshow(first_spectrogram, sr=sr, x_axis='time', y_axis='mel')
    plt.colorbar(format='%+2.0f dB')
    plt.title(f'Mel Spectrogram of {df.iloc[0]["Label"]}')
    plt.tight_layout()
    plt.show()

# Preprocess the data for neural network input
def pad_or_truncate_spectrogram(spectrogram, target_length=600):
    # If the spectrogram is shorter than the target length, pad it with zeros
    if spectrogram.shape[1] < target_length:
        padding = target_length - spectrogram.shape[1]
        spectrogram = np.pad(spectrogram, ((0, 0), (0, padding)), mode='constant')
    # If the spectrogram is longer than the target length, truncate it
    elif spectrogram.shape[1] > target_length:
        spectrogram = spectrogram[:, :target_length]
    return spectrogram

# Preprocess the data and pad/truncate spectrograms
X = np.array([pad_or_truncate_spectrogram(x) for x in df["Spectrogram"]])
y = np.array(df["Label"])
X = X / np.max(X)
X = np.expand_dims(X, axis=-1) 
print(df['Label'].value_counts())
label_encoder = LabelEncoder()
y = label_encoder.fit_transform(y)
X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)

for i in range(len(X_train)):
    spectogram_size = X_train[i].shape
    label = label_encoder.inverse_transform([y_train[i]])[0]
    print(f"Sample {i+1}: Spectogram Shape: {spectogram_size}, Label: {label}")

# Build the CNN model 
model = models.Sequential([
    layers.InputLayer(input_shape=(X_train.shape[1], X_train.shape[2], 1)),
    layers.Conv2D(32, (3, 3), activation='relu', padding='same'),
    layers.MaxPooling2D((2, 2)),
    layers.Conv2D(64, (3, 3), activation='relu', padding='same'),
    layers.MaxPooling2D((2, 2)),
    layers.Conv2D(128, (3, 3), activation='relu', padding='same'),
    layers.MaxPooling2D((2, 2)),
    layers.Flatten(),
    layers.Dense(256, activation='relu'),
    layers.Dropout(0.5),
    layers.Dense(len(np.unique(y)), activation='softmax')  # Output layer with softmax activation
])

# Compile the model
model.compile(optimizer='adam', loss='sparse_categorical_crossentropy', metrics=['accuracy'])

# Train the model
history = model.fit(X_train, y_train, epochs=10, batch_size=32, validation_data=(X_test, y_test))

# Evaluate the model on the test set
test_loss, test_acc = model.evaluate(X_test, y_test)
print(f"Test Accuracy: {test_acc * 100:.2f}%")

model.save('urban_sound_cnn_model.h5')
print("Model saved in normal TensorFlow format.")

