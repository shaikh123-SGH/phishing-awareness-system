/* ==========================================================================
   dashboard.js - animated SVG/CSS charts for the admin dashboard and reports
   Data comes from /admin/api/analytics (no external chart library required).
   ========================================================================== */
(function () {
  "use strict";

  const container = document.getElementById("analytics");
  if (!container) return;

  const palette = { accent: "#2ee6c5", blue: "#37a6ff", violet: "#8b7bff", muted: "#4a5b7d" };

  function barChart(el, items, options = {}) {
    if (!items.length) {
      el.innerHTML = '<p class="dim">No data recorded yet.</p>';
      return;
    }
    const max = Math.max(...items.flatMap((i) => i.values), 1);
    el.innerHTML =
      '<div class="bar-chart">' +
      items
        .map((item, index) => {
          const bars = item.values
            .map((value, vi) => {
              const height = Math.max(4, (value / max) * 160);
              const colour = (options.colours || [palette.accent, palette.blue])[vi] || palette.blue;
              return `<div class="bar chart-bar" style="height:${height}px;background:${colour};animation-delay:${
                index * 0.07 + vi * 0.05
              }s"><span class="bar__value">${value}${options.suffix || ""}</span></div>`;
            })
            .join("");
          return `<div class="bar-group"><div class="bar-stack">${bars}</div><span class="bar-label">${item.label}</span></div>`;
        })
        .join("") +
      "</div>" +
      (options.legend
        ? `<div class="legend">${options.legend
            .map(
              (l, i) =>
                `<span><i style="background:${(options.colours || [palette.accent, palette.blue])[i]}"></i>${l}</span>`
            )
            .join("")}</div>`
        : "");
  }

  function lineChart(el, points) {
    if (points.length < 2) {
      el.innerHTML = '<p class="dim">At least two periods of data are needed for this chart.</p>';
      return;
    }
    const width = 640;
    const height = 200;
    const max = Math.max(...points.map((p) => p.value), 1);
    const step = width / (points.length - 1);
    const coords = points.map((p, i) => [i * step, height - (p.value / max) * (height - 30) - 10]);
    const line = coords.map((c, i) => `${i ? "L" : "M"}${c[0].toFixed(1)},${c[1].toFixed(1)}`).join(" ");
    const area = `${line} L${width},${height} L0,${height} Z`;

    el.innerHTML = `
      <svg class="line-chart" viewBox="0 0 ${width} ${height}" preserveAspectRatio="none" role="img"
           aria-label="Participation over time">
        <defs>
          <linearGradient id="areaFill" x1="0" x2="0" y1="0" y2="1">
            <stop offset="0%" stop-color="${palette.accent}" stop-opacity="0.55"/>
            <stop offset="100%" stop-color="${palette.accent}" stop-opacity="0"/>
          </linearGradient>
        </defs>
        <path class="area" d="${area}"></path>
        <path class="line" d="${line}"></path>
        ${coords.map((c) => `<circle cx="${c[0].toFixed(1)}" cy="${c[1].toFixed(1)}" r="4"></circle>`).join("")}
      </svg>
      <div class="legend">${points.map((p) => `<span>${p.label}: ${p.value}</span>`).join("")}</div>`;

    const path = el.querySelector("path.line");
    const length = path.getTotalLength();
    path.style.strokeDasharray = length;
    path.style.strokeDashoffset = length;
    path.animate([{ strokeDashoffset: length }, { strokeDashoffset: 0 }], {
      duration: 1200,
      easing: "cubic-bezier(0.22,1,0.36,1)",
      fill: "forwards",
    });
  }

  fetch("/admin/api/analytics", { headers: { "X-CSRF-Token": window.CSRF_TOKEN } })
    .then((response) => response.json())
    .then((data) => {
      const prePost = document.getElementById("chartPrePost");
      if (prePost) {
        barChart(
          prePost,
          (data.per_user || []).map((u) => ({
            label: u.full_name.split(" ")[0],
            values: [u.pre_pct || 0, u.post_pct || 0],
          })),
          { colours: [palette.muted, palette.accent], legend: ["Pre-test %", "Post-test %"], suffix: "%" }
        );
      }

      const participation = document.getElementById("chartParticipation");
      if (participation) {
        lineChart(
          participation,
          (data.participation || []).map((p) => ({ label: p.period, value: p.total }))
        );
      }

      const performance = document.getElementById("chartPerformance");
      if (performance) {
        const labels = { pre: "Pre-test", post: "Post-test", spot: "Spot the Scam" };
        barChart(
          performance,
          (data.performance || []).map((p) => ({
            label: labels[p.quiz_type] || p.quiz_type,
            values: [p.avg_percent || 0],
          })),
          { colours: [palette.blue], suffix: "%" }
        );
      }

      const categories = document.getElementById("chartCategories");
      if (categories) {
        barChart(
          categories,
          (data.category_awareness || []).map((c) => ({
            label: c.name,
            values: [c.accuracy || 0],
          })),
          { colours: [palette.violet], suffix: "%" }
        );
      }
    })
    .catch(() => {
      container.querySelectorAll("[id^='chart']").forEach((el) => {
        el.innerHTML = '<p class="dim">Analytics could not be loaded.</p>';
      });
    });
})();
