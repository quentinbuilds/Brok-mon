const screen = document.getElementById("screen");
const line = document.getElementById("line");
const hint = document.getElementById("hint");
const theme = document.getElementById("theme");
const musicBtn = document.getElementById("music");
const btnA = document.getElementById("btn-a");
const btnB = document.getElementById("btn-b");

let booting = false;

function pressA() {
  if (!line || booting) return;
  booting = true;
  line.classList.remove("hidden");
  if (hint) hint.textContent = "Iris closes on cap_beard. Game stays on the Arduino.";
  if (theme) theme.play().catch(() => {});
  if (musicBtn) musicBtn.textContent = "♪ THEME ON";
  window.setTimeout(() => {
    line.classList.add("hidden");
    booting = false;
    if (hint) hint.textContent = "That's the whole title sequence. A again if you missed the joke.";
  }, 1800);
}

function pressB() {
  if (hint) hint.textContent = "B is cancel. There is nothing to cancel. You already came to a landing page.";
}

function toggleMusic() {
  if (!theme) return;
  if (theme.paused) {
    theme.play().catch(() => {});
    if (musicBtn) musicBtn.textContent = "♪ THEME ON";
  } else {
    theme.pause();
    if (musicBtn) musicBtn.textContent = "♪ THEME OFF";
  }
}

if (screen) {
  screen.addEventListener("click", pressA);
  screen.addEventListener("keydown", (event) => {
    if (event.key === "Enter" || event.key === " ") {
      event.preventDefault();
      pressA();
    }
  });
}
if (btnA) btnA.addEventListener("click", pressA);
if (btnB) btnB.addEventListener("click", pressB);
if (musicBtn) musicBtn.addEventListener("click", toggleMusic);

window.addEventListener("keydown", (event) => {
  const key = event.key.toLowerCase();
  if (key === "a" || key === "z") pressA();
  if (key === "b" || key === "x") pressB();
  if (key === "m") toggleMusic();
});
