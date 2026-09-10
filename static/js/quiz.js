/* ==========================================================================
   quiz.js - one-question-at-a-time flow for the pre-test and post-test
   ========================================================================== */
(function () {
  "use strict";

  const shell = document.getElementById("quizShell");
  if (!shell) return;

  const cards = Array.from(shell.querySelectorAll(".quiz-card"));
  const progressBar = document.getElementById("quizProgress");
  const counter = document.getElementById("quizCounter");
  const prevBtn = document.getElementById("quizPrev");
  const nextBtn = document.getElementById("quizNext");
  const submitBtn = document.getElementById("quizSubmit");
  const form = document.getElementById("quizForm");
  let index = 0;

  function render(direction) {
    cards.forEach((card, i) => {
      card.classList.toggle("is-active", i === index);
      if (i === index && direction === "back") {
        card.style.animation = "slide-down 0.4s cubic-bezier(0.22,1,0.36,1)";
        setTimeout(() => (card.style.animation = ""), 420);
      }
    });
    const percent = ((index + 1) / cards.length) * 100;
    if (progressBar) progressBar.style.width = percent + "%";
    if (counter) counter.textContent = `Question ${index + 1} of ${cards.length}`;
    if (prevBtn) prevBtn.disabled = index === 0;
    if (nextBtn) nextBtn.hidden = index === cards.length - 1;
    if (submitBtn) submitBtn.hidden = index !== cards.length - 1;
    window.scrollTo({ top: shell.offsetTop - 100, behavior: "smooth" });
  }

  function answered(card) {
    return !!card.querySelector('input[type="radio"]:checked');
  }

  shell.querySelectorAll(".option").forEach((option) => {
    const input = option.querySelector('input[type="radio"]');
    option.addEventListener("click", () => {
      const group = option.closest(".quiz-card");
      group.querySelectorAll(".option").forEach((o) => o.classList.remove("is-selected"));
      option.classList.add("is-selected");
      input.checked = true;
      // Auto-advance keeps the flow moving, but never on the final question.
      if (index < cards.length - 1) {
        setTimeout(() => {
          index += 1;
          render("next");
        }, 320);
      }
    });
  });

  if (nextBtn) {
    nextBtn.addEventListener("click", () => {
      if (!answered(cards[index])) {
        window.showToast("Please choose an answer before continuing.", "warning");
        cards[index].classList.add("result-shake");
        setTimeout(() => cards[index].classList.remove("result-shake"), 520);
        return;
      }
      index = Math.min(index + 1, cards.length - 1);
      render("next");
    });
  }

  if (prevBtn) {
    prevBtn.addEventListener("click", () => {
      index = Math.max(index - 1, 0);
      render("back");
    });
  }

  if (form) {
    form.addEventListener("submit", (event) => {
      const unanswered = cards.filter((card) => !answered(card)).length;
      if (unanswered > 0) {
        event.preventDefault();
        window.showToast(
          `${unanswered} question${unanswered > 1 ? "s are" : " is"} still unanswered.`,
          "warning"
        );
        const first = cards.findIndex((card) => !answered(card));
        index = first;
        render("back");
        return;
      }
      window.setLoading(true);
    });
  }

  render("next");
})();
