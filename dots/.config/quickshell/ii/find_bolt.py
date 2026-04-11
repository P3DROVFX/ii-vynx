import cv2
import numpy as np

img = cv2.imread('/home/pedro/.gemini/tmp/ii/100_charging.png')
# bolt is white (255, 255, 255)
# pill is green
# Let's find white pixels and green pixels
green_mask = cv2.inRange(img, np.array([0, 100, 0]), np.array([100, 255, 100]))
white_mask = cv2.inRange(img, np.array([200, 200, 200]), np.array([255, 255, 255]))

gx, gy, gw, gh = cv2.boundingRect(green_mask)
wx, wy, ww, wh = cv2.boundingRect(white_mask)

print(f"Pill: x={gx}, w={gw}, right_edge={gx+gw}")
print(f"Bolt: x={wx}, w={ww}, right_edge={wx+ww}")
