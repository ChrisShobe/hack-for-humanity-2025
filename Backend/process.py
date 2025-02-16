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
from sklearn.metrics import confusion_matrix
import seaborn as sns
import warnings
import pickle

warnings.filterwarnings('ignore')

csv_path = "/Users/shaunak/.cache/kagglehub/datasets/rupakroy/urban-sound-8k/versions/1/UrbanSound8K.csv"
audio_path = "/Users/shaunak/.cache/kagglehub/datasets/rupakroy/urban-sound-8k/versions/1/UrbanSound8K/UrbanSound8K/audio"

percentage = 100

df_csv = pd.read_csv(csv_path)
df = pd.DataFrame(columns=["Label", "Audio Length", "Audio Sample", "Spectrogram"])

# Set thresholds and pitch shifts
low_classes = ['car_horn', 'gun_shot']
high_classes = ['engine_idling', 'jackhammer', 'dog_bark']
max_samples = 300
pitch_shifts = [-4, -2, 2, 4]

# Initialize class_counter to count "Siren" and "Not siren"
class_counter = {'Siren': 0, 'Not siren': 0}

# Augmentation function
def augment_audio(audio, sr, shifts):
    augmented_audios = []
    for shift in shifts:
        augmented_audios.append(librosa.effects.pitch_shift(y=audio, sr=sr, n_steps=shift))
    return augmented_audios

# Define your mapping for "Siren" and "Not siren"
siren_classes = ['siren', 'car_horn']  # Replace with actual siren class names
not_siren_classes = ['air_conditioner', 'children_playing', 'dog_bark', 'drilling', 'engine_idling', 'gun_shot', 'jackhammer', 'siren', 'street_music']  # Replace with actual not-siren class names

with tqdm(total=int(len(df_csv) * (percentage / 100)), desc="Processing Audio Files") as pbar:
    for idx, row in df_csv.iterrows():
        if idx >= int(len(df_csv) * (percentage / 100)):
            break

        file_name = row['slice_file_name']
        fold = row['fold']
        label = row['class']
        file_path = os.path.join(audio_path, f"fold{fold}", file_name)

        # Map label to "Siren" or "Not siren"
        if label in siren_classes:
            new_label = 'Siren'
        else:
            new_label = 'Not siren'

        if os.path.exists(file_path) and class_counter[new_label] < max_samples:
            audio, sr = librosa.load(file_path, sr=None)
            audio_length = len(audio)
            if audio_length <= 0:
                pbar.update(1)
                continue

            # Normal processing (original sample)
            stft_matrix = librosa.stft(audio, n_fft=2048, hop_length=512)
            S = librosa.feature.melspectrogram(S=np.abs(stft_matrix) ** 2, sr=sr, n_mels=24, fmax=40000)
            S_dB = librosa.power_to_db(S, ref=np.mean)

            # Append the original sample with the new label
            df = df._append({"Label": new_label, "Audio Length": audio_length, "Audio Sample": audio, "Spectrogram": S_dB}, ignore_index=True)
            class_counter[new_label] += 1

            # Apply augmentation to 50% of the samples
            if np.random.rand() < 0.5 and class_counter[new_label] < max_samples:
                augmented_audios = augment_audio(audio, sr, pitch_shifts)
                for augmented in augmented_audios:
                    stft_matrix = librosa.stft(augmented, n_fft=2048, hop_length=512)
                    S = librosa.feature.melspectrogram(S=np.abs(stft_matrix) ** 2, sr=sr, n_mels=24, fmax=40000)
                    S_dB = librosa.power_to_db(S, ref=np.mean)
                    # Append the augmented sample with the new label
                    df = df._append({"Label": new_label, "Audio Length": audio_length, "Audio Sample": augmented, "Spectrogram": S_dB}, ignore_index=True)
                    class_counter[new_label] += 1

        # If the class reaches the max_samples, stop adding more samples for it
        if class_counter[new_label] >= max_samples:
            print(f"Reached max samples for class {new_label}, stopping further additions.")
        
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
with open('models/label_encoder.pkl', 'wb') as f:
    pickle.dump(label_encoder, f)

print("Class label counts:")
print(df["Label"].value_counts())

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

# Make predictions on the test set
y_pred = model.predict(X_test)
y_pred_classes = np.argmax(y_pred, axis=1)  # Get the class labels with the highest probability

cm = confusion_matrix(y_test, y_pred_classes)

# Plot the confusion matrix
sns.heatmap(cm, annot=True, fmt="d", cmap="Blues", xticklabels=label_encoder.classes_, yticklabels=label_encoder.classes_)
plt.title('Confusion Matrix')
plt.ylabel('True Labels')
plt.xlabel('Predicted Labels')
plt.show()

# Identify misclassified samples
misclassified_indices = np.where(y_pred_classes != y_test)[0]

# Print misclassified samples
misclassified_samples = df.iloc[misclassified_indices]
misclassified_true_labels = label_encoder.inverse_transform(y_test[misclassified_indices])
misclassified_pred_labels = label_encoder.inverse_transform(y_pred_classes[misclassified_indices])

print("\nMisclassified samples:")
for idx, (true_label, pred_label) in enumerate(zip(misclassified_true_labels, misclassified_pred_labels)):
    print(f"Sample {misclassified_samples.iloc[idx]['Audio Sample']} - True label: {true_label}, Predicted label: {pred_label}")


# Save the model
model.save('models/urban_sound_cnn_model.keras')
print("Model saved in normal TensorFlow format.")

# Convert the model to TFLite format
# converter = tf.lite.TFLite
