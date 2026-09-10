/* ==========================================================================
   spot-scam.js - the interactive "Spot the Scam" exercise
   Shows one fictional message at a time, grades the answer instantly and
   sends the final result to the server for signed-in users.
   ========================================================================== */
(function () {
  "use strict";

  const root = document.getElementById("spotScam");
  if (!root) return;

  const cards = Array.from(root.querySelectorAll("[data-example]"));
  const progressBar = document.getElementById("spotProgress");
  const counter = document.getElementById("spotCounter");
  const scoreEl = document.getElementById("spotScore");
  const correctEl = document.getElementById("spotCorrect");
  const wrongEl = document.getElementById("spotWrong");
  const feedback = document.getElementById("spotFeedback");
  const nextBtn = document.getElementById("spotNext");
  const finalPanel = document.getElementById("spotFinal");
  const playPanel = document.getElementById("spotPlay");
  const restartBtn = document.getElementById("spotRestart");

  let index = 0;
  let correct = 0;
  let wrong = 0;
  const answers = [];

  function show() {
    cards.forEach((card, i) => card.classList.toggle("is-active", i === index));
    if (progressBar) progressBar.style.width = ((index / cards.length) * 100).toFixed(1) + "%";
    if (counter) counter.textContent = `Message ${index + 1} of ${cards.length}`;
    if (feedback) {
      feedback.hidden = true;
      feedback.innerHTML = "";
    }
    if (nextBtn) nextBtn.hidden = true;
    root.querySelectorAll("[data-answer]").forEach((btn) => (btn.disabled = false));
  }

  function updateScore() {
    if (scoreEl) scoreEl.textContent = correct;
    if (correctEl) correctEl.textContent = correct;
    if (wrongEl) wrongEl.textContent = wrong;
  }

  function answer(choice) {
    const card = cards[index];
    const isScam = card.dataset.isScam === "1";
    const isCorrect = (choice === "scam") === isScam;
    answers.push({ id: Number(card.dataset.exampleId), answer: choice });

    if (isCorrect) correct += 1;
    else wrong += 1;
    updateScore();

    const signs = (card.dataset.warningSigns || "")
      .split("\n")
      .filter(Boolean)
      .map((s) => `<li>${s}</li>`)
      .join("");

    feedback.hidden = false;
    feedback.className = "card mt-2 " + (isCorrect ? "result-pop" : "result-shake");
    feedback.innerHTML = `
      <span class="badge ${isCorrect ? "badge--safe" : "badge--danger"}">
        ${isCorrect ? "Correct" : "Not quite"}
      </span>
      <h3 class="mt-1">${
        isScam
          ? isCorrect
            ? "Correct! This is suspicious."
            : "This one was actually a scam."
          : isCorrect
          ? "Correct. This message is safe."
          : "This message was actually safe."
      }</h3>
      <p>${card.dataset.explanation || ""}</p>
      ${signs ? `<h4 class="mt-1">What to look at</h4><ul class="tip-list ${isScam ? "tip-list--danger" : ""}">${signs}</ul>` : ""}
    `;

    root.querySelectorAll("[data-answer]").forEach((btn) => (btn.disabled = true));
    nextBtn.hidden = false;
    nextBtn.textContent = index === cards.length - 1 ? "See final result" : "Next message";
    nextBtn.focus();
  }

  root.querySelectorAll("[data-answer]").forEach((btn) => {
    btn.addEventListener("click", () => answer(btn.dataset.answer));
  });

  if (nextBtn) {
    nextBtn.addEventListener("click", () => {
      if (index === cards.length - 1) {
        finish();
        return;
      }
      const card = cards[index];
      card.classList.add("is-leaving");
      setTimeout(() => {
        card.classList.remove("is-leaving");
        index += 1;
        show();
      }, 260);
    });
  }

  function finish() {
    const percent = Math.round((correct / cards.length) * 100);
    playPanel.hidden = true;
    finalPanel.hidden = false;
    finalPanel.classList.add("result-pop");
    if (progressBar) progressBar.style.width = "100%";

    finalPanel.querySelector("[data-final-score]").textContent = `${correct} / ${cards.length}`;
    finalPanel.querySelector("[data-final-percent]").textContent = percent + "%";
    finalPanel.querySelector("[data-final-correct]").textContent = correct;
    finalPanel.querySelector("[data-final-wrong]").textContent = wrong;
    const ring = finalPanel.querySelector("[data-ring-live]");
    if (ring) {
      let current = 0;
      const tick = () => {
        current = Math.min(current + Math.max(1, percent / 40), percent);
        ring.style.background = `conic-gradient(var(--accent) ${current}%, rgba(126,156,214,0.14) 0)`;
        ring.querySelector(".score-ring__value").textContent = Math.round(current) + "%";
        if (current < percent) requestAnimationFrame(tick);
      };
      requestAnimationFrame(tick);
    }
    window.scrollTo({ top: finalPanel.offsetTop - 110, behavior: "smooth" });

    fetch("/spot-the-scam/submit", {
      method: "POST",
      headers: { "Content-Type": "application/json", "X-CSRF-Token": window.CSRF_TOKEN },
      body: JSON.stringify({ answers }),
    })
      .then((response) => response.json())
      .then((data) => {
        if (data.ok && data.saved) {
          window.showToast("Result saved to your profile.", "success");
          finalPanel.querySelector("[data-final-level]").textContent = data.level;
        } else {
          window.showToast("Sign in to save your results and track progress.", "info");
        }
      })
      .catch(() => window.showToast("Result could not be saved. Please try again.", "error"));
  }

  if (restartBtn) {
    restartBtn.addEventListener("click", () => {
      index = 0;
      correct = 0;
      wrong = 0;
      answers.length = 0;
      updateScore();
      finalPanel.hidden = true;
      finalPanel.classList.remove("result-pop");
      playPanel.hidden = false;
      show();
      window.scrollTo({ top: root.offsetTop - 110, behavior: "smooth" });
    });
  }

  updateScore();
  show();
})();
