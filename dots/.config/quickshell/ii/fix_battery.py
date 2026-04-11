import cv2
import numpy as np

img = cv2.imread('/home/pedro/.gemini/tmp/ii/images/clipboard-1775768852893.png')
if img is not None:
    print(f"Image shape: {img.shape}")
else:
    print("Could not read image")
