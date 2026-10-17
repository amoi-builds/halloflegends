// Downloads the ROM and the emulator core once per visit and keeps them in
// memory, so starting a new run only has to restart the emulator.

const FILES = {
  rom: 'game/halloflegends.gba.gz',
  coreJs: 'vendor/mgba_libretro.js',
  coreWasm: 'vendor/mgba_libretro.wasm',
};

let cached = null;

// onProgress(loadedBytes, totalBytes) — totalBytes is 0 when unknown.
export function loadGameFiles(onProgress = () => {}) {
  cached ??= download(onProgress).catch((err) => {
    cached = null; // allow a retry
    throw err;
  });
  return cached;
}

async function download(onProgress) {
  const responses = await Promise.all(Object.values(FILES).map(async (url) => {
    const res = await fetch(url);
    if (!res.ok) throw new Error(`Couldn't download ${url} (HTTP ${res.status}).`);
    return res;
  }));

  // Content-Length is only meaningful when the host didn't re-encode the file.
  const sizes = responses.map((r) => (r.headers.get('Content-Encoding') ? 0 : Number(r.headers.get('Content-Length')) || 0));
  const total = sizes.every(Boolean) ? sizes.reduce((a, b) => a + b, 0) : 0;
  let loaded = 0;
  const report = (n) => { loaded += n; onProgress(loaded, total); };

  const [romGz, coreJs, coreWasm] = await Promise.all(responses.map((res) => readAll(res, report)));
  return {
    rom: await gunzip(romGz),
    coreJs: new Blob([coreJs], { type: 'text/javascript' }),
    coreWasm: new Blob([coreWasm], { type: 'application/wasm' }),
  };
}

async function readAll(res, report) {
  const reader = res.body.getReader();
  const chunks = [];
  let size = 0;
  for (;;) {
    const { done, value } = await reader.read();
    if (done) break;
    chunks.push(value);
    size += value.length;
    report(value.length);
  }
  const bytes = new Uint8Array(size);
  let offset = 0;
  for (const chunk of chunks) {
    bytes.set(chunk, offset);
    offset += chunk.length;
  }
  return bytes;
}

async function gunzip(bytes) {
  // Some hosts send .gz files with Content-Encoding: gzip, in which case the
  // browser has already unpacked it.
  if (bytes[0] !== 0x1f || bytes[1] !== 0x8b) return bytes;
  const stream = new Blob([bytes]).stream().pipeThrough(new DecompressionStream('gzip'));
  return new Uint8Array(await new Response(stream).arrayBuffer());
}
