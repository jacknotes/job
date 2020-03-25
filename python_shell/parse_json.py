import json

with open(r"D:\Python\wy_music.json","rb") as f:
	data = json.load(f)
print(data)