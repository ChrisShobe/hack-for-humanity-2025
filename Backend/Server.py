from flask import Flask, request, jsonify
import os
from Crypto.Cipher import AES
from Crypto.Util.Padding import unpad

# Define your key and IV (must match Dart values)
AES_KEY = "your32characterlongencryptionkey"  # 32 bytes (AES-256)
AES_IV = " " * 16  # 16 bytes IV (same as Dart, ensure it's consistent)

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
        print(f"File {file.filename} is valid. Proceeding with upload.")  # Debugging statement
        #runInference(filepath)
        filepath = os.path.join(UPLOAD_FOLDER, file.filename)
        
        # Save the file to the specified location
        file.save(filepath)
        print(f"File saved at {filepath}")  # Debugging statement
        
        # Decrypt the file
        #decrypt_file(filepath, filepath.replace(".enc", "_decrypted.wav"), AES_KEY, AES_IV)
        
        return jsonify({"message": "File successfully uploaded and decrypted", "file_path": filepath}), 200
    
    print("Invalid file type received.")  # Debugging statement
    return jsonify({"error": "Invalid file type"}), 400

def decrypt_file(input_file, output_file, key, iv):
    print(f"Starting decryption for {input_file}")  # Debugging statement

    try:
        with open(input_file, "rb") as f:
            encrypted_data = f.read()
            print(f"Encrypted data read successfully. Size: {len(encrypted_data)} bytes.")  # Debugging statement

        # Initialize AES cipher (same mode as in Dart)
        cipher = AES.new(key.encode("utf-8"), AES.MODE_CBC, iv.encode("utf-8"))
        print("AES cipher initialized.")  # Debugging statement

        # Decrypt and remove padding
        decrypted_data = unpad(cipher.decrypt(encrypted_data), AES.block_size)
        print(f"Decryption successful. Decrypted data size: {len(decrypted_data)} bytes.")  # Debugging statement

        with open(output_file, "wb") as f:
            f.write(decrypted_data)
        
        print(f"Decryption complete. File saved at: {output_file}")  # Debugging statement
    
    except Exception as e:
        print(f"Error during decryption: {e}")  # Debugging statement
        return jsonify({"error": f"Decryption failed: {str(e)}"}), 500

# Run decryption
#decrypt_file(encrypted_file, decrypted_file, AES_KEY, AES_IV)

if __name__ == '__main__':
    print("Starting Flask server...")  # Debugging statement
    app.run(debug=True)