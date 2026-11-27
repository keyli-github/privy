const reducedMotion = window.matchMedia('(prefers-reduced-motion: reduce)');

if ('IntersectionObserver' in window && !reducedMotion.matches) {
  const animations = new WeakMap();
  const observer = new IntersectionObserver(entries => {
    for (const { target, isIntersecting } of entries) {
      const counters = target.querySelectorAll('[data-count]');
      const previous = animations.get(target);
      if (previous !== undefined) cancelAnimationFrame(previous);
      target.classList.toggle('in-view', isIntersecting);
      if (!counters.length) continue;
      if (!isIntersecting) {
        for (const counter of counters) counter.textContent = counter.dataset.count;
        continue;
      }
      const start = performance.now();
      const animate = now => {
        const progress = Math.min((now - start) / 850, 1);
        for (const counter of counters) {
          counter.textContent = Math.round(Number(counter.dataset.count) * (1 - (1 - progress) ** 3));
        }
        if (progress < 1) animations.set(target, requestAnimationFrame(animate));
      };
      animations.set(target, requestAnimationFrame(animate));
    }
  }, { threshold: 0.12 });

  const sections = document.querySelectorAll('[data-reveal]');
  document.documentElement.classList.add('motion');
  for (const section of sections) observer.observe(section);
  reducedMotion.addEventListener('change', event => {
    if (!event.matches) return;
    observer.disconnect();
    document.documentElement.classList.remove('motion');
    for (const section of sections) {
      const frame = animations.get(section);
      if (frame !== undefined) cancelAnimationFrame(frame);
      for (const counter of section.querySelectorAll('[data-count]')) counter.textContent = counter.dataset.count;
    }
  });
}

const community = document.querySelector('#community');
const statsUrl = community?.dataset.statsUrl;
if (statsUrl) {
  const count = document.querySelector('#community-count');
  const format = new Intl.NumberFormat('es');
  let current = 0;
  let frame;

  async function updateCommunity() {
    try {
      const response = await fetch(statsUrl, { cache: 'no-store', credentials: 'omit' });
      if (!response.ok) return;
      const { people } = await response.json();
      if (!Number.isSafeInteger(people) || people < 0) return;
      if (frame !== undefined) cancelAnimationFrame(frame);
      community.hidden = false;
      const from = current;
      const start = performance.now();
      const render = now => {
        const progress = reducedMotion.matches ? 1 : Math.min((now - start) / 650, 1);
        current = Math.round(from + (people - from) * progress);
        count.textContent = format.format(current);
        if (progress < 1) frame = requestAnimationFrame(render);
      };
      frame = requestAnimationFrame(render);
    } catch {
      // Keep the last verified aggregate if the endpoint is temporarily unavailable.
    } finally {
      window.setTimeout(updateCommunity, 30_000);
    }
  }

  updateCommunity();
}
