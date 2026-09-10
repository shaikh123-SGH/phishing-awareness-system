/* ==========================================================================
   animations.js - scroll reveal, counters, progress bars and page transitions
   ========================================================================== */
(function () {
  "use strict";

  const reduceMotion = window.matchMedia("(prefers-reduced-motion: reduce)").matches;

  document.body.classList.add("page-enter");

  /* ------------------------------------------------------ scroll reveal -- */
  const revealItems = document.querySelectorAll(".reveal");
  if (reduceMotion) {
    revealItems.forEach((el) => el.classList.add("is-visible"));
  } else if ("IntersectionObserver" in window) {
    const observer = new IntersectionObserver(
      (entries) => {
        entries.forEach((entry) => {
          if (entry.isIntersecting) {
            entry.target.classList.add("is-visible");
            observer.unobserve(entry.target);
          }
        });
      },
      { threshold: 0.12, rootMargin: "0px 0px -60px 0px" }
    );
    revealItems.forEach((el) => observer.observe(el));
  } else {
    revealItems.forEach((el) => el.classList.add("is-visible"));
  }

  /* ------------------------------------------------------- number count -- */
  function countUp(el) {
    const target = parseFloat(el.dataset.count || "0");
    const suffix = el.dataset.suffix || "";
    const duration = 1100;
    if (reduceMotion) {
      el.textContent = target + suffix;
      return;
    }
    const start = performance.now();
    function step(now) {
      const progress = Math.min((now - start) / duration, 1);
      const eased = 1 - Math.pow(1 - progress, 3);
      el.textContent = Math.round(target * eased) + suffix;
      if (progress < 1) requestAnimationFrame(step);
    }
    requestAnimationFrame(step);
  }

  const counters = document.querySelectorAll("[data-count]");
  if ("IntersectionObserver" in window) {
    const counterObserver = new IntersectionObserver(
      (entries) => {
        entries.forEach((entry) => {
          if (entry.isIntersecting) {
            countUp(entry.target);
            counterObserver.unobserve(entry.target);
          }
        });
      },
      { threshold: 0.4 }
    );
    counters.forEach((el) => counterObserver.observe(el));
  } else {
    counters.forEach(countUp);
  }

  /* ------------------------------------------------------ progress bars -- */
  function fillBars(scope) {
    (scope || document).querySelectorAll("[data-progress]").forEach((bar) => {
      const value = Math.max(0, Math.min(100, parseFloat(bar.dataset.progress || "0")));
      setTimeout(() => {
        bar.style.width = value + "%";
      }, 180);
    });
  }
  window.fillProgressBars = fillBars;
  fillBars(document);

  /* --------------------------------------------------------- score ring -- */
  document.querySelectorAll("[data-ring]").forEach((ring) => {
    const value = parseFloat(ring.dataset.ring || "0");
    let current = 0;
    const tick = () => {
      current = Math.min(current + Math.max(1, value / 40), value);
      ring.style.background = `conic-gradient(var(--accent) ${current}%, rgba(126,156,214,0.14) 0)`;
      if (current < value) requestAnimationFrame(tick);
    };
    if (reduceMotion) {
      ring.style.background = `conic-gradient(var(--accent) ${value}%, rgba(126,156,214,0.14) 0)`;
    } else {
      setTimeout(() => requestAnimationFrame(tick), 260);
    }
  });

  /* --------------------------------------------- subtle hero parallax ---- */
  const heroVisual = document.querySelector(".shield-visual");
  if (heroVisual && !reduceMotion) {
    window.addEventListener(
      "scroll",
      () => {
        const offset = Math.min(window.scrollY * 0.06, 40);
        heroVisual.style.transform = `translateY(${offset}px)`;
      },
      { passive: true }
    );
  }
})();
