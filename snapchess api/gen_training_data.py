import numpy as np
from selenium import webdriver
from PIL import Image
import matplotlib.pyplot as plt
import os
from io import BytesIO

# Generate a random FEN notation
def getRandomFEN():
    fen_chars = list('1KQRBNPkqrbnp')
    pieces = np.random.choice(fen_chars, 64)
    fen = '/'.join([''.join(pieces[i*8:(i+1)*8]) for i in range(8)])
    # can append ' w' or ' b' for white/black to play, defaults to white
    return fen

fen = getRandomFEN()

# Initialize the webdriver for webscraping
def web_driver():
  options = webdriver.ChromeOptions()
  options.add_argument('--verbose')
  options.add_argument('--no-sandbox')
  options.add_argument('--headless')
  options.add_argument('--disable-gpu')
  options.add_argument('--window-size=1920, 1200')
  options.add_argument('--disable-dev-shm-usage')
  driver = webdriver.Chrome(options=options)
  return driver

driver = web_driver()

# Manually collecting piece/set themes
# pieceSets = ["cburnett","merida", "alpha", "pirouetti", "chessnut", "chess7", "reillycraig", "companion", "riohacha", "kosal", "leipzig", "fantasy", "spatial", "celtic", "california", "caliente", "pixel", "maestro", "fresca", "cardinalgioco", "tatiana", "staunty", "governor", "dubrovny", "icpieces", "mpchess", "kiwen-suwi", "horsey", "anarcandy"]
# Left out a few exceptions (last three) that are deliberately designed to not look like chess pieces
# themes = ["blue", "blue2", "blue3", "blue_marble", "canvas", "wood", "wood2", "wood3", "wood4", "maple", "maple2", "brown", "leather", "green", "marble", "green-plastic", "grey", "metal", "olive", "newspaper", "purple", "purple-diag", "pink", "ic", "horsey"]
# backgrounds = ["light", "dark"]

# Generating Screenshots
out_folder = 'training_data_boards'
if not os.path.exists(out_folder):
    os.makedirs(out_folder)

N = 5

cookie_values = [
'a4d245fe158f7b920ecc96910d2b6a308ce8ad35-bg=dark&pieceSet=fantasy&sessionId=BNs2zUjfUCg6CmsbryXWLx&theme=blue&sid=3Jv2iffvoDzDm0nSdrNj5z',
'81a64ab96384a4953846e8af01dce2cf80f46dba-sid=SEwGrYU6BHrmLMjosrC6cY&theme=blue3&pieceSet=pixel',
'52614a27aa7ccf46d452d389a9a02610fff46702-sid=SGMA7fT9TmZHfVYLsacOWu&theme=green&pieceSet=fantasy',
'74e185e4b4708170311a456440ab4770dd1c913c-sid=je1NFX3e2hvtcPnx0mrlEn&pieceSet=cburnett',
'94b235b7cc3e2cc92847b824f95d5132e2bb1fc0-sid=92RsjLCTysAU4MPMrLpaFe&pieceSet=governor&theme=canvas&bg=darkBoard',
'219f44891946b64cb2035ed884072301657f20ec-sid=XW33suH5tgtX4n6pOh92lK&pieceSet=caliente&theme=maple&bg=darkBoard',
'090abd48f96d54765b08314756f0cd2ed551e07c-sid=T43yNKyKWEERU0qm7vWkFS&pieceSet=chessnut&theme=marble&bg=dark',
'4031de2dfed80f862c12e5593062918ec315ae9d-sid=5hYseNSrjdv26WDnklTXhw&pieceSet=merida&theme=blue-marble&bg=dark',
'ab0e126e31393632594a33d3538c54fc14b814fd-sid=RtXbiXvz08VeIaIeYnUSUR&pieceSet=celtic&theme=pink&bg=dark',
'5faf3cb906e16f9be2f02c05efd98a6434883828-sid=wgLEqqKjVkZ9pxM4jnjuZN&pieceSet=companion&theme=brown&bg=dark'
]

for cookie_value in cookie_values:
  cookie = {'name': 'lila2', 'value': cookie_value}
  for i in range(N):
    fen = getRandomFEN()
    url = "https://lichess.org/editor/" + fen
    driver.get(url)
    driver.add_cookie(cookie)
    driver.refresh()
    try:
      # Take a screenshot
      screenshot = driver.get_screenshot_as_png()
      original_image = Image.open(BytesIO(screenshot))

      # Left, Top, Right, Bottom Boundaries
      cropped_image = original_image.crop((420, 180, original_image.width - 752, original_image.height - 270))
      cropped_image.save(os.path.join(out_folder, f"lichess_{fen.replace('/','-')}.png"))
      print(f"Cropped screenshot {i + 1}/{N} saved successfully!")

    except Exception as e: # Catching errors
      print("An error occurred:", e)