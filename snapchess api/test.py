# Sort images with their labels
for x in os.listdir(output_tile_folder):
    # No need to create training data for empty tiles
    if(hf.extract_label_from_path(x) == '1'):
       continue
   
    source_path = os.path.join(output_tile_folder, x)
    destination_folder = os.path.join("training_data_tiles_sorted", hf.fen_to_label(hf.extract_fen_from_path(x)))
    destination_path = os.path.join(destination_folder, x)


    # Check if destination folder exists, create if not
    if not os.path.exists(destination_folder):
        os.makedirs(destination_folder)


    # Move the file to the destination folder
    shutil.copy(source_path, destination_path)