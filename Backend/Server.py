from flask import Flask, request, jsonify
from Inference import run_inference
from cryptography.hazmat.primitives.ciphers import Cipher, algorithms, modes
from cryptography.hazmat.primitives import padding
from cryptography.hazmat.backends import default_backend
import os

# Define your key and IV (must match Dart values)
AES_KEY = b'your32characterlongencryptionkey'   # 32 bytes (AES-256)
AES_IV = b'MyIVKey123456789'  # Exactly 16 bytes


# Paths
encrypted_file = "recording.wav.enc"
decrypted_file = "recording_decrypted.wav"

app = Flask(__name__)

# Specify the folder to save uploaded files
UPLOAD_FOLDER = 'uploads'
os.makedirs(UPLOAD_FOLDER, exist_ok=True)

# Set the allowed file extensions (you can add more if needed)
ALLOWED_EXTENSIONS = {'wav', 'mp3', 'enc'}

def allowed_file(filename):
    """Check if the file extension is allowed"""
    print(f"Checking file extension for: {filename}")  # Debugging statement
    return '.' in filename and filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS

@app.route('/', methods=['GET'])
def check_server():
    print("Server health check request received.")  # Debugging statement
    return jsonify({"message": "Server is up and running!"}), 200

@app.route('/upload', methods=['POST'])
def upload_file():
    """Handle file upload"""
    print("Received file upload request.")  # Debugging statement
    
    if 'file' not in request.files:
        print("No file part in the request.")  # Debugging statement
        return jsonify({"error": "No file part"}), 400
    file = request.files['file']
    if file.filename == '':
        print("No selected file.")  # Debugging statement
        return jsonify({"error": "No selected file"}), 400
    
    if file and allowed_file(file.filename):
        filepath = os.path.join(UPLOAD_FOLDER, file.filename)  # Move this line up here
        file.save(filepath)
        filepath = decrypt_file(filepath)
        response = run_inference(filepath)  # Call run_inference after saving the file
        
        return jsonify({"message": response, "file_path": filepath}), 200
    
    print("Invalid file type received.")  # Debugging statement
    return jsonify({"error": "Invalid file type"}), 400

key = AES_KEY  # Must be 16, 24, or 32 bytes long
iv = AES_IV # Must be 16 bytes long
def decrypt_file(encrypted_file_path):
    try:
        # Read the encrypted file (already saved by the upload route)
        print("File size:", os.path.getsize(encrypted_file_path))

        # Now read the saved file
        with open(encrypted_file_path, 'rb') as enc_file:
            encrypted_data = enc_file.read()

        # Create the AES cipher object
        cipher = Cipher(algorithms.AES(key), modes.CBC(iv), backend=default_backend())

        # Create a decryptor
        decryptor = cipher.decryptor()

        # Decrypt the data
        decrypted_data = decryptor.update(encrypted_data) + decryptor.finalize()

        # Remove padding (same padding used during encryption)
        unpadder = padding.PKCS7(algorithms.AES.block_size).unpadder()
        unpadded_data = unpadder.update(decrypted_data) + unpadder.finalize()

        # Save the decrypted file
        decrypted_file_path = encrypted_file_path.rsplit('.', 1)[0]  # Removes the extension
        decrypted_file_path = f'{decrypted_file_path}'  # Or use `.wav` if preferred

        with open(decrypted_file_path, 'wb') as dec_file:
            dec_file.write(unpadded_data)

        print(f"File decrypted and saved at: {decrypted_file_path}")
        os.remove(encrypted_file_path)
        return decrypted_file_path
    
    except Exception as e:
        print(f"An error occurred during decryption: {e}")
        return None


if __name__ == '__main__':
    print("Starting Flask server...")  # Debugging statement
    app.run(debug=True)