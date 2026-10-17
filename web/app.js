// Page controller: the title card, the emulator, and the toolbar and touch
// controls. The whole game is the ROM; this file only downloads and starts it.
import { Nostalgist } from './vendor/nostalgist.js';
import { loadGameFiles } from './game-files.js';

const $ = (id) => document.getElementById(id);
const app = document.querySelector('.app');
const screen = $('screen');
const ui = {
  play: $('play'),
  retry: $('retry'),
  sound: $('sound'),
  fullscreen: $('fullscreen'),
  loadingText: $('loading-text'),
  loadingDetail: $('loading-detail'),
  meter: $('meter'),
  errorText: $('error-text'),
};

// sessionStorage can throw when storage is blocked; the page works without it.
const session = {
  get(key) { try { return sessionStorage.getItem(key); } catch { return null; } },
  set(key, value) { try { sessionStorage.setItem(key, value); } catch { /* not remembered */ } },
};

let emu = null;
let muted = session.get('halloflegends-muted') === '1';
let starting = false;

// RetroArch opens a Web Audio context for each emulator and never closes it,
// so a restart would leave one running (and browsers cap how many a page can
// have). Track the contexts the emulator creates and close them on exit.
const audioContexts = [];
const NativeAudioContext = window.AudioContext;
if (NativeAudioContext) {
  window.AudioContext = class extends NativeAudioContext {
    constructor(...args) {
      super(...args);
      audioContexts.push(this);
    }
  };
}

function setState(state) {
  app.dataset.state = state;
  const playing = state === 'playing';
  ui.sound.disabled = !playing;
  ui.fullscreen.disabled = !playing || !document.fullscreenEnabled;
}

// --- Title card ------------------------------------------------------------------

// The trainer pics come straight from the game's graphics, where the
// background is a solid color (palette slot 0): clear the pixels that match
// the top-left corner.
async function drawTrainer(canvas) {
  const img = new Image();
  img.src = canvas.dataset.src;
  try {
    await img.decode();
  } catch {
    return; // the card works without them
  }
  const ctx = canvas.getContext('2d');
  ctx.drawImage(img, 0, 0);
  const data = ctx.getImageData(0, 0, canvas.width, canvas.height);
  const px = data.data;
  const [r, g, b] = px;
  for (let i = 0; i < px.length; i += 4) {
    if (px[i] === r && px[i + 1] === g && px[i + 2] === b) px[i + 3] = 0;
  }
  ctx.putImageData(data, 0, 0);
}
document.querySelectorAll('canvas.trainer').forEach(drawTrainer);

// --- Running the game --------------------------------------------------------------

const megabytes = (n) => (n / 1048576).toFixed(1);

function checkBrowser() {
  if (typeof WebAssembly !== 'object' || typeof DecompressionStream !== 'function') {
    throw new Error("This browser can't run the game. Use a recent version of Chrome, Edge, Firefox or Safari.");
  }
}

function stopEmulator() {
  if (emu) {
    try {
      emu.exit();
    } catch (err) {
      console.warn('Emulator exit failed', err);
    }
    emu = null;
  }
  for (const ctx of audioContexts.splice(0)) ctx.close().catch(() => {});
}

async function start() {
  if (starting) return;
  starting = true;
  try {
    checkBrowser();
    stopEmulator();
    setState('loading');
    ui.loadingText.textContent = 'Loading the game';
    ui.loadingDetail.textContent = '';
    const files = await loadGameFiles((loaded, total) => {
      ui.meter.style.width = total ? `${Math.min(100, (loaded / total) * 100)}%` : '50%';
      ui.loadingDetail.textContent = total ? `${megabytes(loaded)} of ${megabytes(total)} MB` : `${megabytes(loaded)} MB`;
    });

    ui.loadingText.textContent = 'Starting the emulator';
    ui.loadingDetail.textContent = '';
    ui.meter.style.width = '100%';

    const canvas = document.createElement('canvas');
    canvas.className = 'game-canvas';
    screen.prepend(canvas);
    emu = await Nostalgist.launch({
      core: 'mgba',
      element: canvas,
      size: { width: 720, height: 480 }, // render at 3x; CSS scales it to fit
      rom: { fileName: 'halloflegends.gba', fileContent: new Blob([files.rom]) },
      resolveCoreJs: () => files.coreJs,
      resolveCoreWasm: () => files.coreWasm,
      retroarchConfig: {
        audio_mute_enable: muted,
        savestate_thumbnail_enable: false,
      },
    });
    setState('playing');
  } catch (err) {
    console.error(err);
    stopEmulator();
    ui.errorText.textContent = String(err?.message || err);
    setState('error');
  } finally {
    starting = false;
  }
}

// --- Toolbar ---------------------------------------------------------------------

// Buttons keep focus after a click, and Enter is the game's Start button, so
// hand focus back to the page to avoid triggering the button again.
function onClick(button, handler) {
  button.addEventListener('click', () => {
    button.blur();
    handler();
  });
}

onClick(ui.play, start);
onClick(ui.retry, start);

onClick(ui.sound, () => {
  if (!emu) return;
  emu.sendCommand('MUTE');
  muted = !muted;
  session.set('halloflegends-muted', muted ? '1' : '0');
  showMuted();
});

function showMuted() {
  ui.sound.textContent = muted ? 'Unmute' : 'Mute';
  ui.sound.setAttribute('aria-pressed', String(muted));
}

onClick(ui.fullscreen, () => {
  if (document.fullscreenElement) document.exitFullscreen();
  else $('console').requestFullscreen().catch(() => {});
});

document.addEventListener('fullscreenchange', () => {
  ui.fullscreen.textContent = document.fullscreenElement ? 'Exit full screen' : 'Full screen';
});

// Don't let arrow keys and space scroll the page while playing.
window.addEventListener('keydown', (event) => {
  if (app.dataset.state === 'playing' && ['ArrowUp', 'ArrowDown', 'ArrowLeft', 'ArrowRight', ' '].includes(event.key)) {
    event.preventDefault();
  }
});

// Pause when the tab is hidden.
document.addEventListener('visibilitychange', () => {
  if (!emu) return;
  if (document.hidden) emu.pause();
  else emu.resume();
});

// Browsers start audio suspended unless it begins during a click; the
// emulator starts after the download, so resume it on the next interaction.
function resumeAudio() {
  for (const ctx of audioContexts) {
    if (ctx.state === 'suspended') ctx.resume().catch(() => {});
  }
}
window.addEventListener('pointerdown', resumeAudio);
window.addEventListener('keydown', resumeAudio);

// --- Touch controls ------------------------------------------------------------

for (const button of document.querySelectorAll('[data-button]')) {
  const release = () => {
    if (!button.classList.contains('is-down')) return;
    button.classList.remove('is-down');
    emu?.pressUp(button.dataset.button);
  };
  button.addEventListener('pointerdown', (event) => {
    event.preventDefault();
    button.setPointerCapture(event.pointerId);
    button.classList.add('is-down');
    emu?.pressDown(button.dataset.button);
  });
  button.addEventListener('pointerup', release);
  button.addEventListener('pointercancel', release);
  button.addEventListener('lostpointercapture', release);
}

// The d-pad follows the finger, so sliding from one direction to another works.
const dpad = document.querySelector('.dpad');
let heldDirection = null;

function setDirection(next) {
  if (next === heldDirection) return;
  if (heldDirection) emu?.pressUp(heldDirection);
  if (next) emu?.pressDown(next);
  heldDirection = next;
  dpad.dataset.dir = next ?? '';
}

function directionAt(event) {
  const box = dpad.getBoundingClientRect();
  const dx = event.clientX - (box.left + box.width / 2);
  const dy = event.clientY - (box.top + box.height / 2);
  if (Math.hypot(dx, dy) < box.width * 0.12) return null;
  if (Math.abs(dx) > Math.abs(dy)) return dx > 0 ? 'right' : 'left';
  return dy > 0 ? 'down' : 'up';
}

dpad.addEventListener('pointerdown', (event) => {
  event.preventDefault();
  dpad.setPointerCapture(event.pointerId);
  setDirection(directionAt(event));
});
dpad.addEventListener('pointermove', (event) => {
  if (dpad.hasPointerCapture(event.pointerId)) setDirection(directionAt(event));
});
dpad.addEventListener('pointerup', () => setDirection(null));
dpad.addEventListener('pointercancel', () => setDirection(null));

// For debugging from the browser console.
window.hallOfLegends = {
  get emulator() { return emu; },
};

setState('title');
showMuted();
ui.fullscreen.hidden = !document.fullscreenEnabled; // e.g. iPhone Safari
