import tensorflow as tf
import numpy as np
import matplotlib.pyplot as plt
import os
from PIL import Image
import scipy.signal
import cv2
from rembg import remove

import helper_functions as hf

np.set_printoptions(suppress=True)

img_file = 'test.png'
input_folder = 'test_images'

def initializeImage(img_file, input_folder):
    # Image path
    img = Image.open(f"{input_folder}/{img_file}")

    # Resize for large images
    if img.size[0] > 2000 or img.size[1] > 2000:
        new_size = 500.0  # px
        ratio = new_size / max(img.size[0], img.size[1])
        print(f"Reducing by factor of {1./ratio:.2g}")
        img = img.resize((int(img.size[0] * ratio), int(img.size[1] * ratio)), Image.ADAPTIVE)
        print(f"New size: ({img.size[0]} x {img.size[1]})")

    # Represent image as an array
    img = img.convert('L')
    img = np.array(img)

    return img

def houghTransform(img):
    # Making the image compatible with TensorFlow
    A = tf.cast(tf.Variable(img), tf.float32)

    # Calculate gradients
    Dx = hf.gradientx(A)
    Dy = hf.gradienty(A)

    # Convert Dx and Dy tensors to NumPy arrays using .numpy()
    Dx_array = Dx.numpy()
    Dy_array = Dy.numpy()

    # Clip Dx and Dy values to specified ranges
    Dx_pos = tf.clip_by_value(Dx, 0., 255., name="dx_positive")
    Dx_neg = tf.clip_by_value(Dx, -255., 0., name='dx_negative')
    Dy_pos = tf.clip_by_value(Dy, 0., 255., name="dy_positive")
    Dy_neg = tf.clip_by_value(Dy, -255., 0., name='dy_negative')

    # Compute Hough Transform for Dx and Dy
    hough_Dx = tf.reduce_sum(Dx_pos, axis=0) * tf.reduce_sum(-Dx_neg, axis=0) / (img.shape[0] * img.shape[0])
    hough_Dy = tf.reduce_sum(Dy_pos, axis=1) * tf.reduce_sum(-Dy_neg, axis=1) / (img.shape[1] * img.shape[1])

    # Plot Hough Transform results
    fig, (ax1, ax2) = plt.subplots(1, 2, sharey=True, figsize=(15, 5))

    # Arbitrarily choose a threshold
    hough_Dx_thresh = tf.reduce_max(hough_Dx) * 3 / 5
    hough_Dy_thresh = tf.reduce_max(hough_Dy) * 3 / 5

    return hough_Dx, hough_Dy, hough_Dx_thresh, hough_Dy_thresh

# Check if line distances are consistent
def checkMatch(lineset):
    linediff = np.diff(lineset)
    x = 0
    cnt = 0
    for line in linediff:
        # Within 5 px of the other (allowing for minor image errors)
        if np.abs(line - x) < 5:
            cnt += 1
        else:
            cnt = 0
            x = line
    return cnt == 5

# Prunes a set of lines to 7 in consistent increasing order (chessboard)
def pruneLines(lineset):
    linediff = np.diff(lineset)
    x = 0
    cnt = 0
    start_pos = 0
    for i, line in enumerate(linediff):
        # Within 5 px of the other (allowing for minor image errors)
        if np.abs(line - x) < 5:
            cnt += 1
            if cnt == 5:
                end_pos = i + 2
                return lineset[start_pos:end_pos]
        else:
            cnt = 0
            x = line
            start_pos = i
    return lineset

# Return skeletonized 1d array (thinned to single value, favor to the right)
def skeletonize_1d(arr):
    _arr = arr.copy()
    # Go forwards
    for i in range(_arr.size-1):
        # Will right-shift if they are the same
        if arr[i] <= _arr[i+1]:
            _arr[i] = 0

    # Go reverse
    for i in np.arange(_arr.size-1, 0, -1):
        if _arr[i-1] > _arr[i]:
            _arr[i] = 0
    return _arr

# Returns pixel indices for the 7 internal chess lines in x and y axes
def getChessLines(hdx, hdy, hdx_thresh, hdy_thresh):
    # Blur
    gausswin = scipy.signal.gaussian(21, 4)
    gausswin /= np.sum(gausswin)

    # Blur where there is a strong horizontal or vertical line (binarize)
    blur_x = np.convolve(hdx > hdx_thresh, gausswin, mode='same')
    blur_y = np.convolve(hdy > hdy_thresh, gausswin, mode='same')

    skel_x = skeletonize_1d(blur_x)
    skel_y = skeletonize_1d(blur_y)

    # Find points on skeletonized arrays (where returns 1-length tuple)
    lines_x = np.where(skel_x)[0] # vertical lines
    lines_y = np.where(skel_y)[0] # horizontal lines

    # Prune inconsistent lines
    lines_x = pruneLines(lines_x)
    lines_y = pruneLines(lines_y)

    is_match = len(lines_x) == 7 and len(lines_y) == 7 and checkMatch(lines_x) and checkMatch(lines_y)

    return lines_x, lines_y, is_match


def getChessTiles(img):
    hdx, hdy, hdx_thresh, hdy_thresh = houghTransform(img)
    lines_x, lines_y, is_match = getChessLines(hdx, hdy, hdx_thresh, hdy_thresh)
    
    # If it fails, do not let it into our dataset
    if(not is_match):
        return False
    
    stepx = np.round(np.mean(np.diff(lines_x)))
    stepy = np.round(np.mean(np.diff(lines_y)))

    # Pad edges as needed to fill out chessboard
    padl_x = padr_x = padl_y = padr_y = 0
    if(lines_x[0] - stepx < 0):
        padl_x = int(np.abs(lines_x[0] - stepx))
    if(lines_x[-1] + stepx > img.shape[1]-1):
        padr_x = int(np.abs(lines_x[-1] + stepx - img.shape[1]))
    if(lines_y[0] - stepy < 0):
        padl_y = int(np.abs(lines_y[0] - stepy))
    if(lines_y[-1] + stepx > img.shape[0]-1):
        padr_y = int(np.abs(lines_y[-1] + stepy - img.shape[0]))

    # New padded array
    a_padded = np.pad(img, ((padl_y, padr_y), (padl_x, padr_x)), mode='edge')
    setsx = np.hstack([lines_x[0] - stepx, lines_x, lines_x[-1] + stepx]).astype(int) + padl_x
    setsy = np.hstack([lines_y[0] - stepy, lines_y, lines_y[-1] + stepy]).astype(int) + padl_y

    squares = np.zeros([np.round(stepy).astype(int), np.round(stepx).astype(int), 64], dtype=np.uint8)

    # For each row
    for i in range(8):
        # For each column
        for j in range(8):
            # Calculate bounding box coordinates
            x1 = setsx[i]
            x2 = setsx[i + 1]
            y1 = setsy[j]
            y2 = setsy[j + 1]

            # Slice the padded image to extract the square
            square = a_padded[y1:y2, x1:x2]

            # Resize the square to match the expected dimensions
            square = cv2.resize(square, (np.round(stepx).astype(int), np.round(stepy).astype(int)))

            # Store the square in the matrix
            squares[:, :, (7 - j) * 8 + i] = square
    return squares

def generateTiles(img_file, input_folder, output_folder):
    img = initializeImage(img_file, input_folder)
    squares = getChessTiles(img)
    
    # When getChessTiles fails, do not let it into our dataset
    if squares == False:
        return

    if not os.path.exists(output_folder):
        os.makedirs(output_folder)

    for i in range(64):
        sqr_filename = f"{output_folder}/{img_file[:-4]}_{chr(ord('a') + i % 8)}{i // 8 + 1}.png"
        # Make resized 32x32 image from matrix and save
        img = remove(Image.fromarray(squares[:, :, i]).resize((32, 32), Image.ADAPTIVE))

        img.save(sqr_filename)
        print(i)

