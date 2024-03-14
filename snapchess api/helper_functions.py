import tensorflow as tf
import numpy as np
from PIL import Image

# Transforms an array into a convolutional kernel
def make_kernel(a):
    a = np.asarray(a)
    a = a.reshape(list(a.shape) + [1, 1])
    return tf.constant(a, dtype=tf.float32)

# Convolutional operation
def simple_conv(x, k):
    x = tf.expand_dims(tf.expand_dims(x, 0), -1)
    y = tf.nn.depthwise_conv2d(x, k, strides=[1, 1, 1, 1], padding='SAME')
    return y[0, :, :, 0]

# Compute x gradient
def gradientx(x):
    gradient_x = make_kernel([[-1., 0., 1.],
                            [-1., 0., 1.],
                            [-1., 0., 1.]])
    return simple_conv(x, gradient_x)

# Compute y gradient
def gradienty(x):
    gradient_y = make_kernel([[-1., -1., -1.],[0.,0.,0.], [1., 1., 1.]])
    return simple_conv(x, gradient_y)

# Turn coordinates to FEN index for labelling
def coordinates_to_fen(coord):
    map = {'a': 0, 'b': 1, 'c': 2, 'd': 3, 'e': 4, 'f': 5, 'g': 6, 'h': 7}
    if(len(coord) != 2):
        print(coord)
    col = int(coord[1]) - 1
    row = map[coord[0]]
    return int((7 - col) * 8 + row)

# Determine label from file name
def extract_fen_from_path(path):
    s = path[:-7].replace('-', '')
    coord = path[-6:-4]
    return(s[coordinates_to_fen(coord)])

def fen_to_label(label):
    map = {
        '1': 'Empty Tile',
        'K': 'White King',
        'Q': 'White Queen',
        'R': 'White Rook',
        'B': 'White Bishop',
        'N': 'White Knight',
        'P': 'White Pawn',
        'k': 'Black King',
        'q': 'Black Queen',
        'r': 'Black Rook',
        'b': 'Black Bishop',
        'n': 'Black Knight',
        'p': 'Black Pawn'
    }
    return map[label]

def label_to_fen(name):
    map = {
    'Empty Tile': '1',
    'White King': 'K',
    'White Queen': 'Q',
    'White Rook': 'R',
    'White Bishop': 'B',
    'White Knight': 'N',
    'White Pawn': 'P',
    'Black King': 'k',
    'Black Queen': 'q',
    'Black Rook': 'r',
    'Black Bishop': 'b',
    'Black Knight': 'n',
    'Black Pawn': 'p'
    }
    return(map[name])

def is_empty_tile(img):
    # Convert the image to grayscale
    img_gray = img.convert('L')
    
    # Convert the image to a numpy array
    img_array = np.array(img_gray)
    
    # Calculate the standard deviation of pixel values
    std_dev = np.std(img_array)
    
    # Check if the standard deviation is below arbitrary threshold
    if std_dev < 25:
        return True
    else:
        return False
    
def is_piece_white(img):
    img_array = np.array(img)
    avg = np.sum(img_array) / (img.width * img.height)
    return avg
    # arbitrary threshold
    if avg > 40:
        return True
    else:
        return False
    
def position_to_fen(position):
    # Split the position into 8 groups of 8 characters
    groups = [position[i:i+8] for i in range(0, 64, 8)]
    
    # Reverse the order of the groups
    reversed_groups = groups[::-1]
    
    # Join the reversed groups into a single string
    fen = '/'.join(reversed_groups)
    fen = compress_fen(fen)
    return fen

def compress_fen(fen):
    compressed  = ''
    count = 0
    
    for char in fen:
        if char == '1':
            count += 1
        else:
            if count > 0:
                compressed += str(count)
                count = 0
            compressed += char
    
    # If the position ends in '1's
    if count > 0:
        compressed += str(count)
    
    return compressed