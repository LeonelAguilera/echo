#import numpy as np
#from scipy.io import wavfile
#import sys

#if len(sys.argv) < 3:
#    print("Provide in out file")
#    sys.exit(1)

#input = sys.argv[1]
#output = sys.argv[2]

#sr, data = wavfile.read(input)

#data = data.astype(np.int16)

#if data.ndim == 1:
#    data = np.stack((data, data), axis=1)

#np.savetxt(output, data, fmt="%d")
#print(f"Wrote {len(data)} stereo samples at {sr} Hz")
import math
import numpy as np
from scipy.io import wavfile
from scipy.signal import resample_poly
import sys

if len(sys.argv) < 3:
    print("Provide in out file")
    sys.exit(1)

in_path  = sys.argv[1]
out_path = sys.argv[2]
target_sr = 44100  # falls du NICHT resamplen willst: auf None setzen

sr, data = wavfile.read(in_path)

# ---- nach 44.1 kHz resamplen (optional) ----
# alles erstmal in float32 (-1..1) bringen
if data.dtype == np.int16:
    data_f = data.astype(np.float32) / 32768.0
elif data.dtype == np.int32:
    data_f = data.astype(np.float32) / 2147483648.0
elif data.dtype == np.uint8:
    data_f = (data.astype(np.float32) - 128) / 128.0
else:  # float already
    data_f = data.astype(np.float32)

if data_f.ndim == 1:
    data_f = data_f[:, None]

if target_sr and target_sr != sr:
    g = math.gcd(target_sr, sr)
    up, down = target_sr // g, sr // g
    data_f = resample_poly(data_f, up, down, axis=0)

# ---- in echte 16-Bit-Integer wandeln ----
data_f = np.clip(data_f, -1.0, 1.0)
data_i16 = (data_f * 32767.0).astype(np.int16)

# Mono zu Stereo duplizieren (wie in deinem Skript)
if data_i16.shape[1] == 1:
    data_i16 = np.concatenate([data_i16, data_i16], axis=1)

# A) Als Text mit 16-Bit-Ganzzahlen (dezimal) speichern
np.savetxt(out_path, data_i16, fmt="%d")

print(f"Wrote {len(data_i16)} stereo samples at {target_sr or sr} Hz as 16-bit integers")

