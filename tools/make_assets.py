"""Icônes de l'app, image de présentation Play Store et sonneries (WAV)."""
import math, struct, wave
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parent.parent
RED, NAVY, WHITE = (198, 40, 40), (16, 38, 61), (255, 255, 255)

def bell(d, cx, cy, s, col=WHITE):
    """Cloche centrée en (cx, cy), hauteur ~ s."""
    u = s / 100
    d.ellipse([cx - 7*u, cy - 50*u, cx + 7*u, cy - 36*u], fill=col)            # anneau
    d.pieslice([cx - 30*u, cy - 42*u, cx + 30*u, cy + 18*u], 180, 360, fill=col)  # dôme
    d.rectangle([cx - 30*u, cy - 12*u, cx + 30*u, cy + 22*u], fill=col)        # corps
    d.polygon([(cx - 30*u, cy + 18*u), (cx + 30*u, cy + 18*u), (cx + 42*u, cy + 32*u), (cx - 42*u, cy + 32*u)], fill=col)
    d.ellipse([cx - 10*u, cy + 34*u, cx + 10*u, cy + 50*u], fill=col)          # battant

def icon(bg, size=1024, scale=0.62, transparent=False):
    im = Image.new('RGBA', (size, size), (0, 0, 0, 0) if transparent else bg + (255,))
    bell(ImageDraw.Draw(im), size / 2, size / 2, size * scale)
    return im

out = ROOT / 'assets' / 'icon'
icon(RED).save(out / 'manager.png')
icon(RED, scale=0.40, transparent=True).save(out / 'manager-fg.png')   # icône adaptative Android
icon(NAVY).save(out / 'caisse.png')
play = ROOT / 'docs' / 'play-store'
icon(RED, 512).convert('RGB').save(play / 'icone-512.png')

# Image de présentation 1024 x 500
fg = Image.new('RGB', (1024, 500), RED)
d = ImageDraw.Draw(fg)
bell(d, 890, 250, 240)
B = '/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf'; R = '/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf'
d.text((70, 130), 'Alerte Manager', font=ImageFont.truetype(B, 66), fill=WHITE)
d.text((72, 240), 'La caisse appelle, votre téléphone sonne.', font=ImageFont.truetype(R, 29), fill=WHITE)
d.text((72, 286), '« J’arrive » arrête la sonnerie des autres.', font=ImageFont.truetype(R, 29), fill=WHITE)
fg.save(play / 'image-presentation-1024x500.png')

# Sonneries : une par canal de notification Android (le son d'un canal ne peut pas changer).
SR = 22050
def tone(name, seconds, f):
    p = ROOT / 'assets' / 'sons' / f'{name}.wav'
    with wave.open(str(p), 'w') as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR)
        w.writeframes(b''.join(struct.pack('<h', int(32000 * max(-1, min(1, f(i / SR))))) for i in range(int(seconds * SR))))

def env(t, period, on):  # bips
    x = t % period
    return 0.0 if x > on else min(1, x * 80, (on - x) * 80)

tone('sirene', 2.0, lambda t: 0.8 * math.sin(2 * math.pi * (650 + 350 * math.sin(2 * math.pi * 1.0 * t)) * t))
tone('bip', 1.6, lambda t: 0.85 * env(t, 0.4, 0.18) * math.sin(2 * math.pi * 1250 * t))
tone('carillon', 2.0, lambda t: 0.7 * sum(math.exp(-3 * ((t - s) % 2)) * math.sin(2 * math.pi * fr * t) * (t >= s) for s, fr in ((0, 880), (0.35, 698.5), (0.7, 523.3))))
tone('urgence', 1.5, lambda t: 0.9 * env(t, 0.25, 0.12) * (1 if math.sin(2 * math.pi * 900 * t) > 0 else -1) * 0.6)
print('ok')
