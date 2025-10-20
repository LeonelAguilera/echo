# resample_wav_safe.py
import numpy as np
from scipy.io import wavfile
from scipy.signal import resample_poly
import sys

if len(sys.argv) < 3:
    print("Usage: python resample_wav_safe.py in.wav out_44k.wav")
    sys.exit(1)

in_wav, out_wav = sys.argv[1], sys.argv[2]

sr_in, x = wavfile.read(in_wav)
print("Input:", in_wav, "sr:", sr_in, "dtype:", x.dtype, "shape:", x.shape)

# -> float32 [-1, 1]
if np.issubdtype(x.dtype, np.integer):
    den = 32768.0 if x.dtype == np.int16 else float(np.max(np.abs(x)) or 1.0)
    xf = x.astype(np.float32) / den
else:
    xf = x.astype(np.float32)

# Mono->Stereo bei Bedarf
if xf.ndim == 1:
    xf = np.stack([xf, xf], axis=1)

# Resample 11025 -> 44100  (Faktor 4)
up, down = 44100, sr_in
g = np.gcd(up, down)
up //= g; down //= g
print(f"Resample: up {up}, down {down}")
y = resample_poly(xf, up, down, axis=0)

# Debug: Peaks
peak_in  = float(np.max(np.abs(xf)))
peak_out = float(np.max(np.abs(y)))
print(f"Peak in: {peak_in:.6f}, peak out: {peak_out:.6f}")

# Optional: auf Input-Peak normalisieren (falls Filter leicht dämpft)
if peak_out > 0:
    y *= (peak_in / peak_out)

# Zurück auf int16
y16 = np.clip(y * 32767.0, -32768.0, 32767.0).astype(np.int16)

# Nochmals checken
print("Output sr: 44100, dtype:", y16.dtype, "shape:", y16.shape,
      "peak16:", int(np.max(np.abs(y16))))

wavfile.write(out_wav, 44100, y16)
print("Wrote:", out_wav)
