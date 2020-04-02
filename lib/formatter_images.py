import PIL
from PIL import Image

from os import listdir
from os.path import isfile, join

w = 150

for f in listdir("images/"):
	img = Image.open("images/" + f)
	img = img.resize((w, w), PIL.Image.ANTIALIAS)
	img.save("resized_images/" + f)
	print("Done")