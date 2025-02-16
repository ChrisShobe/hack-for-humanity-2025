import tensorflow as tf
import librosa
import numpy as np
from tensorflow.keras.models import load_model
from sklearn.preprocessing import LabelEncoder

# Load the model (Keras .h5 model)
model = load_model('models/urban_sound_cnn_model.keras')

label_encoder = LabelEncoder()
label_encoder.fit(['air_conditioner', 'car_horn', 'children_playing', 'dog_bark', 'drilling', 'engine_idling', 'gun_shot', 'jackhammer',
'siren', 'street_music'])

def pad_or_truncate_spectrogram(spectrogram, target_length=600):
    if spectrogram.shape[1] < target_length:
        padding = target_length - spectrogram.shape[1]
        spectrogram = np.pad(spectrogram, ((0, 0), (0, padding)), mode='constant')
    elif spectrogram.shape[1] > target_length:
        spectrogram = spectrogram[:, :target_length]
    return spectrogram

def run_inference(file_path):
    audio, sr = librosa.load(file_path, sr=None)
    audio_length = len(audio)

    if audio_length <= 0:
        print("Invalid audio file.")
        return

    # Compute STFT and mel spectrogram
    stft_matrix = librosa.stft(audio, n_fft=2048, hop_length=512)
    S = librosa.feature.melspectrogram(S=np.abs(stft_matrix) ** 2, sr=sr, n_mels=24, fmax=40000)
    S_dB = librosa.power_to_db(S, ref=np.mean)

    # Pad or truncate the spectrogram to match the model's expected input size
    S_dB = pad_or_truncate_spectrogram(S_dB)

    # Reshape the spectrogram to add the channel dimension (shape: (24, 600, 1))
    S_dB = np.expand_dims(S_dB, axis=-1)  # Adding the channel dimension

    # Normalize the spectrogram
    S_dB = S_dB / np.max(S_dB)

    # Add batch dimension (shape: (1, 24, 600, 1))
    S_dB = np.expand_dims(S_dB, axis=0)

    # Predict with the model
    prediction = model.predict(S_dB)
    predicted_label_index = np.argmax(prediction)
    confidence = prediction[0][predicted_label_index] 
    predicted_label = label_encoder.inverse_transform([predicted_label_index])

    print(f"Predicted label: {predicted_label[0]}")
    print(f"Confidence: {confidence:.4f}")



# Example usage
file_path = 'uploads/recording.wav'
run_inference(file_path)
