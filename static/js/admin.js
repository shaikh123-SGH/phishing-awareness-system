/* ==========================================================================
   admin.js - sidebar, CRUD modal prefill and table search for the admin panel
   ========================================================================== */
(function () {
  "use strict";

  /* -------------------------------------------------------- sidebar ----- */
  const sidebar = document.getElementById("adminSidebar");
  const overlay = document.getElementById("adminOverlay");
  const toggle = document.getElementById("adminSidebarToggle");

  if (toggle && sidebar) {
    toggle.addEventListener("click", () => {
      const open = sidebar.classList.toggle("is-open");
      if (overlay) overlay.classList.toggle("is-open", open);
      toggle.setAttribute("aria-expanded", String(open));
    });
  }
  if (overlay) {
    overlay.addEventListener("click", () => {
      sidebar.classList.remove("is-open");
      overlay.classList.remove("is-open");
      if (toggle) toggle.setAttribute("aria-expanded", "false");
    });
  }

  /* ----------------------------------------- prefill the edit/add modal -- */
  const form = document.querySelector("[data-crud-form]");
  const modal = document.getElementById("crudModal");
  const modalTitle = document.querySelector("[data-crud-title]");

  function resetForm(title) {
    if (!form) return;
    form.reset();
    const idField = form.querySelector('input[name="id"]');
    if (idField) idField.value = "";
    if (modalTitle) modalTitle.textContent = title;
  }

  document.querySelectorAll("[data-crud-add]").forEach((btn) => {
    btn.addEventListener("click", () => {
      resetForm(btn.dataset.crudAdd || "Add new entry");
      window.openModal(modal);
    });
  });

  document.querySelectorAll("[data-crud-edit]").forEach((btn) => {
    btn.addEventListener("click", () => {
      if (!form) return;
      resetForm(btn.dataset.crudTitle || "Edit entry");
      let payload = {};
      try {
        payload = JSON.parse(btn.dataset.crudEdit);
      } catch (error) {
        window.showToast("This record could not be loaded.", "error");
        return;
      }
      Object.entries(payload).forEach(([key, value]) => {
        const field = form.querySelector(`[name="${key}"]`);
        if (!field) return;
        if (field.type === "checkbox") field.checked = Boolean(Number(value));
        else if (field.type === "radio") {
          const radio = form.querySelector(`[name="${key}"][value="${value}"]`);
          if (radio) radio.checked = true;
        } else field.value = value === null ? "" : value;
      });
      window.openModal(modal);
    });
  });

  /* ------------------------------------------------------ table search -- */
  const tableSearch = document.getElementById("tableSearch");
  if (tableSearch) {
    tableSearch.addEventListener("input", () => {
      const term = tableSearch.value.trim().toLowerCase();
      let visible = 0;
      document.querySelectorAll("tbody tr").forEach((row) => {
        const match = row.textContent.toLowerCase().includes(term);
        row.style.display = match ? "" : "none";
        if (match) visible += 1;
      });
      const empty = document.getElementById("tableEmpty");
      if (empty) empty.hidden = visible !== 0;
    });
  }

  /* ------------------------------------------- YouTube link live check --- */
  const videoUrl = document.querySelector('[name="video_url"]');
  const preview = document.getElementById("videoPreview");
  if (videoUrl && preview) {
    const extract = (url) => {
      const match = url.match(
        /(?:youtube(?:-nocookie)?\.com\/(?:watch\?v=|embed\/|shorts\/|v\/)|youtu\.be\/)([A-Za-z0-9_-]{11})/
      );
      return match ? match[1] : null;
    };
    videoUrl.addEventListener("input", () => {
      const id = extract(videoUrl.value.trim());
      videoUrl.classList.toggle("has-error", videoUrl.value.trim() !== "" && !id);
      preview.innerHTML = id
        ? `<img src="https://img.youtube.com/vi/${id}/mqdefault.jpg" alt="Thumbnail preview of the linked video">`
        : '<span class="dim">Paste a YouTube link to preview the thumbnail.</span>';
    });
  }
})();
