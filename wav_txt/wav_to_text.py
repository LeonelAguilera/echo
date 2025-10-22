import numpy as np
from scipy.io import wavfile
import sys

if len(sys.argv) < 3:
    print("Provide in out file")
    sys.exit(1)

input = sys.argv[1]
output = sys.argv[2]

sr, data = wavfile.read(input)

data = data.astype(np.int16)

if data.ndim == 1:
    data = np.stack((data, data), axis=1)

np.savetxt(output, data, fmt="%d")
print(f"Wrote {len(data)} stereo samples at {sr} Hz")
