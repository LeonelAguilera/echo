import numpy as np
from scipy.io import wavfile
import sys

if len(sys.argv) < 3:
    print("Provide in out file")
    sys.exit(1)

input = sys.argv[1]
output = sys.argv[2]

samples = np.loadtxt(input, dtype=np.int16)
sr = 44100
wavfile.write(output, sr, samples)
print("Wrote stereo output.wav")
