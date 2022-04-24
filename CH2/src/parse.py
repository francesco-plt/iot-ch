from csv import DictReader
from sys import argv

fn = "iot-feeds.csv"

if len(argv) != 2:
    print("Usage: ./csv-to-json.py <code>")
    exit(1)
code = argv[1]

entries = []
with open(fn) as f:
    r = DictReader(f)
    for row in r:
        entries.append(row)

index = 0
for entry in entries:
    if entry["code"] == str(code):
        break
    index += 1

res = []
for entry in entries[index : index + 99]:
    res.append(entry)

print("printing field1 values:")
for entry in res:
    if entry == res[0]:
        print(entry["field1"], end="")
    else:
        print(",{}".format(entry["field1"]), end="")
print("\n")

print("printing field2 values:")
for entry in res:
    if entry == res[0]:
        print(entry["field2"], end="")
    else:
        print(",{}".format(entry["field2"]), end="")
print("\n")

print("printing field5 values:")
for entry in res:
    if entry == res[0]:
        print(entry["field5"], end="")
    else:
        print(",{}".format(entry["field5"]), end="")
print("\n")
