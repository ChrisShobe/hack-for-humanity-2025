import kagglehub
#Path to dataset files: /Users/shaunak/.cache/kagglehub/datasets/vishnu0399/emergency-vehicle-siren-sounds/versions/4
# Download latest version
# path = kagglehub.dataset_download("vishnu0399/emergency-vehicle-siren-sounds")
# path = kagglehub.dataset_download("mlneo07/random-noise-audio")
#path = kagglehub.dataset_download("abigailcopiaco/daseedataset") DO NOT UNCOMMENT THIS LINE UNLESS YOU ARE CHRIS

path = kagglehub.dataset_download("rupakroy/urban-sound-8k")
print("Path to dataset files:", path)