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
from tensorflow.keras import layers, models, regularizers
import warnings
import joblib

warnings.filterwarnings('ignore')

csv_path = "/Users/shaunak/.cache/kagglehub/datasets/rupakroy/urban-sound-8k/versions/1/UrbanSound8K.csv"
audio_path = "/Users/shaunak/.cache/kagglehub/datasets/rupakroy/urban-sound-8k/versions/1/UrbanSound8K/UrbanSound8K/audio"

# Percentage of files to process and train on
percentage = 10 # Set this value to control the percentage (e.g., 50 means using 50% of the files)

# Load CSV 
df_csv = pd.read_csv(csv_path)

# Initialize DataFrame
df = pd.DataFrame(columns=["Label", "Audio Length", "Audio Sample", "Spectrogram"])

# Count total audio files for progress bar
total_files = len(df_csv)
files_to_process = int(total_files * (percentage / 100))  # Calculate the number of files to process based on percentage

# Define augmentation function
def augment_audio(audio, sr):
    # Apply pitch shift augmentation
    pitch_shift = np.random.uniform(-4, 4)  # Random pitch shift between -4 and 4 semitones
    audio = librosa.effects.pitch_shift(y=audio, sr=sr, n_steps=pitch_shift)  # Explicitly named arguments
    return audio

# Process audio files using CSV
with tqdm(total=files_to_process, desc="Processing Audio Files") as pbar:
    for idx, row in df_csv.iterrows():
        if idx >= files_to_process:  # Stop after processing the desired percentage
            break
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

            # Apply data augmentation
            audio = augment_audio(audio, sr)

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

label_encoder = LabelEncoder()
y = label_encoder.fit_transform(y)

# Split the data first before any processing (avoid data leakage)
X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)

# Build the CNN model with regularization and dropout
model = models.Sequential([
    layers.InputLayer(input_shape=(X_train.shape[1], X_train.shape[2], 1)),
    layers.Conv2D(32, (3, 3), activation='relu', padding='same', kernel_regularizer=regularizers.l2(0.05)),  # L2 regularization
    layers.MaxPooling2D((2, 2)),
    layers.Conv2D(64, (3, 3), activation='relu', padding='same', kernel_regularizer=regularizers.l2(0.05)),  # L2 regularization
    layers.MaxPooling2D((2, 2)),
    layers.Conv2D(128, (3, 3), activation='relu', padding='same', kernel_regularizer=regularizers.l2(0.05)),  # L2 regularization
    layers.MaxPooling2D((2, 2)),
    layers.Flatten(),
    layers.Dense(256, activation='relu', kernel_regularizer=regularizers.l2(0.05)),  # L2 regularization
    layers.Dropout(0.5),  
    layers.Dense(len(np.unique(y)), activation='softmax')  # Output layer with softmax activation
])

# Compile the model
model.compile(optimizer='adam', loss='sparse_categorical_crossentropy', metrics=['accuracy'])

print("Training labels (encoded):")
print(np.unique(y_train))  # This will print the encoded class labels for training

# Optionally, print the corresponding human-readable class labels
print("Class labels (decoded):")
print(label_encoder.inverse_transform(np.unique(y_train)))  # Print the decoded class labels

# Train the model
history = model.fit(X_train, y_train, epochs=10, batch_size=32, validation_data=(X_test, y_test))

# After training, print the labels again to verify consistency
print("\nLabels at the end of training:")
print(np.unique(y_train))  # This will print the encoded class labels for training
print(label_encoder.inverse_transform(np.unique(y_train)))  # Print the decoded class labels

# Evaluate the model on the test set
test_loss, test_acc = model.evaluate(X_test, y_test)
print(f"Test Accuracy: {test_acc * 100:.2f}%")

# Save the model
model.save('urban_sound_cnn_model.keras')
print("Model saved in normal TensorFlow format.")

# Convert the model to TFLite format
# converter = tf.lite.TFLiteConverter.from_keras_model(model)
# tflite_model = converter.convert()

# # Save the TFLite model
# with open('urban_sound_cnn_model.tflite', 'wb') as f:
#     f.write(tflite_model)
# print("Model saved in TFLite format.")
