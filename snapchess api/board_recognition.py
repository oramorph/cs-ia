import comp_vision as cv
import numpy as np
import matplotlib.pyplot as plt
from keras.models import load_model
from PIL import Image
from rembg import remove
import os
import helper_functions as hf
img_file = 'image1.png'
img_folder = 'test_images'

def getfen(img_file, img_folder):
    # Initializing FEN
    position = ''

    # Initializing Chess Tiles
    img = cv.initializeImage(img_file, img_folder)
    tiles_preprocessed = cv.getChessTiles(img)


    # Setting up TensorFlow model
    model = load_model('piece_recognition.keras')

    # Map from index to label
    class_names = ['White King','White Queen','White Rook','White Bishop','White Knight','White Pawn','Black King','Black Queen','Black Rook','Black Bishop','Black Knight','Black Pawn']
    index_to_label = {i: class_names[i] for i in range(len(class_names))}


    # Specify the directory path and file name
    output_directory = "recognitiontest"

    # Create the directory if it doesn't already exist
    if not os.path.exists(output_directory):
        os.makedirs(output_directory)
    else:
        for filename in os.listdir(output_directory):
            file_path = os.path.join(output_directory, filename)
            os.remove(file_path)


    for i in range(64):
        input_image = Image.fromarray(tiles_preprocessed[:, :, i])

        # Detect if tile is empty
        if(hf.is_empty_tile(input_image)):
            predicted_class = "Empty Tile"
        
        # Otherwise apply AI model
        else:
            img = remove(input_image.resize((32, 32), Image.ADAPTIVE)).convert('L')
            # Add a channel dimension to be compatible with model input
            img_with_channel = np.expand_dims(img, axis=0)

            # Make prediction using the model
            prediction = model.predict(img_with_channel)
            
            # Get the predicted class index
            index = np.argmax(prediction)
            
            # Get the predicted class label
            predicted_class = index_to_label[index]
        
        # For Debugging
        print(i)
        print(predicted_class)

        # Save the output image to a file
        output_file = f"{i} {predicted_class} {hf.is_piece_white(input_image)}.jpg"
        output_path = os.path.join(output_directory, output_file)
        input_image.save(output_path)  

        # Update position
        position += hf.label_to_fen(f"{predicted_class}")

    fen = hf.position_to_fen(position)
    return fen
    
