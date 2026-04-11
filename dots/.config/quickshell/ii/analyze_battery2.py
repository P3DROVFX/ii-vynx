import cv2
import numpy as np

img = cv2.imread('/home/pedro/.gemini/tmp/ii/images/clipboard-1775771012458.png')
if img is not None:
    print(f"Image shape: {img.shape}")
else:
    print("Could not read image")
