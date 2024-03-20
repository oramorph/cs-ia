import os
os.environ["TF_CPP_MIN_LOG_LEVEL"] = "2"
import tensorflow as tf
from tensorflow import keras
from tensorflow.keras import layers
from tensorflow.keras.preprocessing.image import ImageDataGenerator

img_height = 32
img_width = 32
batch_size = 16

ds_train = tf.keras.preprocessing.image_dataset_from_directory(
    'training_data_tiles_sorted',
    labels='inferred',
    label_mode='categorical',
    class_names=['White King','White Queen','White Rook','White Bishop','White Knight','White Pawn','Black King','Black Queen','Black Rook','Black Bishop','Black Knight','Black Pawn'],
    color_mode='grayscale',
    batch_size=batch_size,
    image_size=(img_height, img_width),
    shuffle=True,
    seed=100,
    validation_split=0.1,
    subset="training",
)

ds_validation = tf.keras.preprocessing.image_dataset_from_directory(
    'training_data_tiles_sorted',
    labels='inferred',
    label_mode='categorical',
    class_names=['White King','White Queen','White Rook','White Bishop','White Knight','White Pawn','Black King','Black Queen','Black Rook','Black Bishop','Black Knight','Black Pawn'],
    color_mode='grayscale',
    batch_size=batch_size,
    image_size=(img_height, img_width),
    shuffle=True,
    seed=100,
    validation_split=0.1,
    subset="validation",
)

model = keras.Sequential([
    layers.Input((32, 32, 1)),
    layers.Conv2D(32, 3, padding='valid'),
    layers.Conv2D(32, 3, padding='same', activation='relu'),
    layers.MaxPooling2D(pool_size=(2,2)),
    layers.Conv2D(64, 3, activation='relu'),
    layers.MaxPooling2D(),
    layers.Conv2D(128, 3, activation='relu'),
    layers.Flatten(),
    layers.Dense(64, activation='relu'),
    layers.Dense(12),
])


model.compile(
    loss=keras.losses.CategoricalCrossentropy(from_logits=True), # Using categorical crossentropy loss model 
    optimizer=keras.optimizers.Adam(learning_rate=3e-4),
    metrics=["accuracy"],
)

model.fit(ds_train, epochs=15, batch_size = batch_size, verbose = 2) # Verbose = 2 for tracking progress
model.evaluate(ds_validation, batch_size = batch_size, verbose = 2)

model.save('piece_recognition.keras')
