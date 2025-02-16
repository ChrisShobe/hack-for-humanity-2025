from flask import Flask, request, jsonify
from Inference import run_inference
import os

app = Flask(__name__)

# Specify the folder to save uploaded files
UPLOAD_FOLDER = 'uploads'
os.makedirs(UPLOAD_FOLDER, exist_ok=True)

# Set the allowed file extensions (you can add more if needed)
ALLOWED_EXTENSIONS = {'wav', 'mp3'}

def allowed_file(filename):
    """Check if the file extension is allowed"""
    return '.' in filename and filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS

@app.route('/', methods=['GET'])
def check_server():
    return jsonify({"message": "Server is up and running!"}), 200

@app.route('/upload', methods=['POST'])
def upload_file():
    """Handle file upload"""
    if 'file' not in request.files:
        return jsonify({"error": "No file part"}), 400
    file = request.files['file']
    if file.filename == '':
        return jsonify({"error": "No selected file"}), 400
    if file and allowed_file(file.filename):
        filepath = os.path.join(UPLOAD_FOLDER, file.filename)  # Move this line up here
        file.save(filepath)
        
        response = run_inference(filepath)  # Call run_inference after saving the file
        
        return jsonify({"message": response, "file_path": filepath}), 200
    
    return jsonify({"error": "Invalid file type"}), 400

if __name__ == '__main__':
    app.run(debug=True)
