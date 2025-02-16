import tensorflow as tf
import librosa
import numpy as np
from tensorflow.keras.models import load_model
from sklearn.preprocessing import LabelEncoder
import pickle

# Load the model (Keras .h5 model)
model = load_model('models/urban_sound_cnn_model.keras')

# Load the saved LabelEncoder
with open('models/label_encoder.pkl', 'rb') as f:
    label_encoder = pickle.load(f)

# Augment audio with pitch shifting
def augment_audio(audio, sr):
    pitch_shift = np.random.uniform(-4, 4)  # Random pitch shift between -4 and 4 semitones
    audio = librosa.effects.pitch_shift(y=audio, sr=sr, n_steps=pitch_shift)
    return audio

# Padding or truncating the spectrogram
def pad_or_truncate_spectrogram(spectrogram, target_length=600):
    if spectrogram.shape[1] < target_length:
        padding = target_length - spectrogram.shape[1]
        spectrogram = np.pad(spectrogram, ((0, 0), (0, padding)), mode='constant')
    elif spectrogram.shape[1] > target_length:
        spectrogram = spectrogram[:, :target_length]
    return spectrogram

# Run inference on a given audio file
def run_inference(file_path):
    audio, sr = librosa.load(file_path, sr=None)
    audio_length = len(audio)

    if audio_length <= 0:
        print("Invalid audio file.")
        return

    # Apply audio augmentation (like pitch shift)
    audio = augment_audio(audio, sr)

    # Compute the STFT (Short-time Fourier transform)
    stft_matrix = librosa.stft(audio, n_fft=2048, hop_length=512)
    
    # Compute Mel Spectrogram
    S = librosa.feature.melspectrogram(S=np.abs(stft_matrix) ** 2, sr=sr, n_mels=24, fmax=40000)
    
    # Convert to decibels (log scale)
    S_dB = librosa.power_to_db(S, ref=np.mean)

    # Pad or truncate the spectrogram
    S_dB = pad_or_truncate_spectrogram(S_dB)

    # Normalize the spectrogram (same as during training)
    S_dB = S_dB / np.max(S_dB)

    # Add channel dimension (for CNN input)
    S_dB = np.expand_dims(S_dB, axis=-1)

    # Expand batch dimension for prediction
    S_dB = np.expand_dims(S_dB, axis=0)

    # Predict with the model
    prediction = model.predict(S_dB)
    predicted_label_index = np.argmax(prediction)
    confidence = prediction[0][predicted_label_index] 
    predicted_label = label_encoder.inverse_transform([predicted_label_index])

    print(f"Predicted label: {predicted_label[0]}")
    print(f"Confidence: {confidence:.4f}")
    print("Prediction vector:", prediction)
    return predicted_label[0]


# Example usage (provide the path to your test audio file)
file_path = 'uploads/recording.wav'
run_inference(file_path)
