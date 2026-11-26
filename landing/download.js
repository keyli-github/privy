const apk = document.querySelector('#apk');
const status = document.querySelector('#apk-status');

async function checkDownload() {
  if (window.location.protocol === 'file:') return;

  try {
    const response = await fetch(apk.href, { method: 'HEAD', cache: 'no-store' });
    const contentType = response.headers.get('content-type') ?? '';
    if (response.ok && /application\/(vnd\.android\.package-archive|octet-stream)/i.test(contentType)) {
      apk.hidden = false;
      status.hidden = true;
      for (const link of document.querySelectorAll('.download')) {
        link.href = apk.href;
        link.download = '';
      }
    }
  } catch {
    // Keep the availability message when the file cannot be reached.
  }
}

checkDownload();
