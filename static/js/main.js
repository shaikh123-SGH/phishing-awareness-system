/* ==========================================================================
   main.js - navigation, dropdowns, modals, toasts, search/filter, video modal
   ========================================================================== */
(function () {
  "use strict";

  /* ------------------------------------------------------------- toasts -- */
  const toastStack = document.getElementById("toastStack");

  window.showToast = function (message, type = "info", timeout = 4200) {
    if (!toastStack) return;
    const toast = document.createElement("div");
    toast.className = `toast toast--${type}`;
    toast.setAttribute("role", type === "error" ? "alert" : "status");
    toast.innerHTML =
      `<div>${message}</div>` +
      `<button class="toast__close" aria-label="Dismiss notification">&times;</button>`;
    toastStack.appendChild(toast);

    const remove = () => {
      toast.classList.add("is-leaving");
      toast.addEventListener("animationend", () => toast.remove(), { once: true });
    };
    toast.querySelector(".toast__close").addEventListener("click", remove);
    setTimeout(remove, timeout);
  };

  // Flash messages rendered by Flask are converted into animated toasts.
  document.querySelectorAll("[data-flash]").forEach((node, index) => {
    setTimeout(
      () => window.showToast(node.dataset.message, node.dataset.category || "info"),
      index * 220
    );
  });

  /* ---------------------------------------------------------- navigation - */
  const navbar = document.querySelector(".navbar");
  const navToggle = document.querySelector(".nav-toggle");
  const navLinks = document.getElementById("navLinks");

  if (navbar) {
    const onScroll = () => navbar.classList.toggle("is-scrolled", window.scrollY > 12);
    onScroll();
    window.addEventListener("scroll", onScroll, { passive: true });
  }

  if (navToggle && navLinks) {
    navToggle.addEventListener("click", () => {
      const open = navLinks.classList.toggle("is-open");
      navToggle.setAttribute("aria-expanded", String(open));
    });
    navLinks.querySelectorAll("a").forEach((link) =>
      link.addEventListener("click", () => {
        navLinks.classList.remove("is-open");
        navToggle.setAttribute("aria-expanded", "false");
      })
    );
  }

  /* ----------------------------------------------------------- dropdown -- */
  document.querySelectorAll(".dropdown").forEach((dropdown) => {
    const trigger = dropdown.querySelector("[data-dropdown-trigger]");
    if (!trigger) return;
    trigger.addEventListener("click", (event) => {
      event.preventDefault();
      const open = dropdown.classList.toggle("is-open");
      trigger.setAttribute("aria-expanded", String(open));
    });
    document.addEventListener("click", (event) => {
      if (!dropdown.contains(event.target)) {
        dropdown.classList.remove("is-open");
        trigger.setAttribute("aria-expanded", "false");
      }
    });
  });

  /* -------------------------------------------------------------- modals - */
  function openModal(modal) {
    if (!modal) return;
    modal.classList.add("is-open");
    modal.setAttribute("aria-hidden", "false");
    document.body.style.overflow = "hidden";
    const focusable = modal.querySelector("button, a, input, textarea, select");
    if (focusable) setTimeout(() => focusable.focus(), 120);
  }

  function closeModal(modal) {
    if (!modal) return;
    modal.classList.remove("is-open");
    modal.setAttribute("aria-hidden", "true");
    document.body.style.overflow = "";
    const frame = modal.querySelector("iframe");
    if (frame) frame.src = ""; // stop YouTube playback
  }

  window.openModal = openModal;
  window.closeModal = closeModal;

  document.querySelectorAll("[data-modal-open]").forEach((trigger) => {
    trigger.addEventListener("click", (event) => {
      if (trigger.tagName === "A") event.preventDefault();
      openModal(document.getElementById(trigger.dataset.modalOpen));
    });
  });

  document.querySelectorAll(".modal-backdrop").forEach((backdrop) => {
    backdrop.addEventListener("click", (event) => {
      if (event.target === backdrop || event.target.closest("[data-modal-close]")) {
        closeModal(backdrop);
      }
    });
  });

  document.addEventListener("keydown", (event) => {
    if (event.key === "Escape") {
      document.querySelectorAll(".modal-backdrop.is-open").forEach(closeModal);
    }
  });

  /* --------------------------------------------------------- video modal - */
  const videoModal = document.getElementById("videoModal");
  if (videoModal) {
    const frame = videoModal.querySelector("iframe");
    const titleEl = videoModal.querySelector("[data-video-title]");
    const descEl = videoModal.querySelector("[data-video-description]");

    document.querySelectorAll("[data-video-id]").forEach((card) => {
      card.addEventListener("click", () => {
        const id = card.dataset.videoId;
        frame.src = `https://www.youtube-nocookie.com/embed/${id}?autoplay=1&rel=0`;
        if (titleEl) titleEl.textContent = card.dataset.videoTitle || "Awareness video";
        if (descEl) descEl.textContent = card.dataset.videoDescription || "";
        openModal(videoModal);
        if (card.dataset.videoDbId) {
          fetch(`/videos/${card.dataset.videoDbId}/view`, {
            method: "POST",
            headers: { "X-CSRF-Token": window.CSRF_TOKEN },
          }).catch(() => {});
        }
      });
      card.addEventListener("keydown", (event) => {
        if (event.key === "Enter" || event.key === " ") {
          event.preventDefault();
          card.click();
        }
      });
    });
  }

  /* --------------------------------------------- detail modals (generic) - */
  document.querySelectorAll("[data-detail-modal]").forEach((card) => {
    card.addEventListener("click", (event) => {
      if (event.target.closest("a, button")) return;
      openModal(document.getElementById(card.dataset.detailModal));
    });
  });

  /* ------------------------------------------------- live search & filter - */
  document.querySelectorAll("[data-filter-input]").forEach((input) => {
    const targets = document.querySelectorAll(input.dataset.filterTarget);
    input.addEventListener("input", () => {
      const term = input.value.trim().toLowerCase();
      let visible = 0;
      targets.forEach((item) => {
        const haystack = (item.dataset.search || item.textContent).toLowerCase();
        const match = !term || haystack.includes(term);
        item.classList.toggle("filter-hide", !match);
        if (match) {
          item.classList.remove("filter-hide");
          item.classList.add("filter-show");
          visible += 1;
        }
      });
      const empty = document.querySelector(input.dataset.emptyTarget || "[data-empty-state]");
      if (empty) empty.hidden = visible !== 0;
    });
  });

  document.querySelectorAll("[data-filter-chip]").forEach((chip) => {
    chip.addEventListener("click", () => {
      const group = chip.dataset.filterGroup;
      document
        .querySelectorAll(`[data-filter-chip][data-filter-group="${group}"]`)
        .forEach((c) => c.classList.toggle("is-active", c === chip));
      const value = chip.dataset.filterValue;
      document.querySelectorAll(`[data-filter-item="${group}"]`).forEach((item) => {
        const match = !value || item.dataset.filterKey === value;
        item.classList.toggle("filter-hide", !match);
        if (match) item.classList.add("filter-show");
      });
    });
  });

  /* --------------------------------------------------------- button ink -- */
  document.querySelectorAll(".btn").forEach((btn) => {
    btn.addEventListener("click", () => {
      btn.classList.remove("is-clicked");
      void btn.offsetWidth;
      btn.classList.add("is-clicked");
    });
  });

  /* -------------------------------------------------- loading indicator -- */
  const overlay = document.getElementById("loadingOverlay");
  window.setLoading = (state) => overlay && overlay.classList.toggle("is-open", !!state);

  document.querySelectorAll("form[data-loading]").forEach((form) => {
    form.addEventListener("submit", () => window.setLoading(true));
  });

  /* ---------------------------------------------- confirm-before-delete -- */
  document.querySelectorAll("form[data-confirm]").forEach((form) => {
    form.addEventListener("submit", (event) => {
      if (!window.confirm(form.dataset.confirm)) event.preventDefault();
    });
  });

  /* ------------------------------------------------------ smooth anchors - */
  document.querySelectorAll('a[href^="#"]:not([href="#"])').forEach((anchor) => {
    anchor.addEventListener("click", (event) => {
      const target = document.querySelector(anchor.getAttribute("href"));
      if (!target) return;
      event.preventDefault();
      const top = target.getBoundingClientRect().top + window.scrollY - 90;
      window.scrollTo({ top, behavior: "smooth" });
    });
  });
})();
