import cv2
import numpy as np

img = cv2.imread('/home/pedro/.gemini/tmp/ii/images/clipboard-1775768852893.png', cv2.IMREAD_GRAYSCALE)
if img is not None:
    # Just print the middle row of pixels to see the shape roughly, or find contours
    _, thresh = cv2.threshold(img, 127, 255, cv2.THRESH_BINARY_INV)
    contours, _ = cv2.findContours(thresh, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
    for c in contours:
        x, y, w, h = cv2.boundingRect(c)
        if w > 20 and h > 10:
            print(f"Found box: w={w}, h={h}, ratio={w/h:.2f}")
else:
    print("Could not read image")
