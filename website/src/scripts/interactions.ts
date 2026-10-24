export {};

document.documentElement.classList.add("js");

const menu = document.querySelector<HTMLButtonElement>(".menu-toggle");
const nav = document.querySelector<HTMLElement>("#site-nav");
function closeMenu() {
  menu?.setAttribute("aria-expanded", "false");
  menu?.setAttribute("aria-label", "Buka navigasi");
  nav?.classList.remove("is-open");
}
menu?.addEventListener("click", () => {
  const open = menu.getAttribute("aria-expanded") !== "true";
  menu.setAttribute("aria-expanded", String(open));
  menu.setAttribute("aria-label", open ? "Tutup navigasi" : "Buka navigasi");
  nav?.classList.toggle("is-open", open);
});
nav
  ?.querySelectorAll("a")
  .forEach((link) => link.addEventListener("click", closeMenu));

const themeButton = document.querySelector<HTMLButtonElement>(".theme-toggle");
const preference = matchMedia("(prefers-color-scheme: dark)");
let explicitTheme = false;
try {
  explicitTheme = ["light", "dark"].includes(
    localStorage.getItem("dashtconnect-theme") || "",
  );
} catch {}
function applyTheme(theme: "light" | "dark") {
  document.documentElement.dataset.theme = theme;
  document
    .querySelectorAll<HTMLSourceElement>("source[data-theme-light]")
    .forEach((source) => {
      source.media = theme === "light" ? "all" : "not all";
    });
  document.querySelectorAll<HTMLElement>(".scroll-gallery").forEach((track) => {
    track.scrollLeft = 0;
    track.dispatchEvent(new Event("scroll"));
  });
  themeButton?.setAttribute("aria-pressed", String(theme === "dark"));
  themeButton?.setAttribute(
    "aria-label",
    theme === "dark" ? "Aktifkan tema terang" : "Aktifkan tema gelap",
  );

  document
    .querySelector('meta[name="theme-color"]')
    ?.setAttribute("content", theme === "dark" ? "#0e141e" : "#f6f7f9");
}
applyTheme(
  document.documentElement.dataset.theme === "dark" ? "dark" : "light",
);
if (themeButton) themeButton.hidden = false;
themeButton?.addEventListener("click", () => {
  const theme =
    document.documentElement.dataset.theme === "dark" ? "light" : "dark";
  explicitTheme = true;
  applyTheme(theme);
  try {
    localStorage.setItem("dashtconnect-theme", theme);
  } catch {}
});
preference.addEventListener("change", (event) => {
  if (!explicitTheme) applyTheme(event.matches ? "dark" : "light");
});
const motion = matchMedia("(prefers-reduced-motion: reduce)");
if (!motion.matches && "IntersectionObserver" in window) {
  const observer = new IntersectionObserver(
    (entries) => {
      entries.forEach((entry) => {
        if (!entry.isIntersecting) return;
        entry.target.animate(
          [{ transform: "translateY(14px)" }, { transform: "translateY(0)" }],
          { duration: 450, easing: "ease-out" },
        );
        observer.unobserve(entry.target);
      });
    },
    { threshold: 0.1 },
  );
  document
    .querySelectorAll(
      ".feature-story, .screenshot-archive figure, .steps > li, .runtime-media figure",
    )
    .forEach((item) => observer.observe(item));
}

const dialog = document.querySelector<HTMLDialogElement>("#screenshot-dialog");
const image = document.querySelector<HTMLImageElement>("#screenshot-image");
const caption = document.querySelector<HTMLElement>("#screenshot-caption");
const imageStatus = document.querySelector<HTMLElement>("#screenshot-status");
const originalLink = document.querySelector<HTMLAnchorElement>(
  "#screenshot-original",
);
let opener: HTMLElement | null = null;
image?.addEventListener("load", () => {
  image.hidden = false;
  if (imageStatus) imageStatus.hidden = true;
});
image?.addEventListener("error", () => {
  image.hidden = true;
  if (imageStatus) {
    imageStatus.hidden = false;
    imageStatus.textContent =
      "Screenshot belum dapat dimuat. Periksa koneksi, lalu buka file gambar untuk mencoba lagi.";
  }
  if (originalLink) originalLink.hidden = false;
});
document.querySelectorAll<HTMLElement>("[data-lightbox]").forEach((button) => {
  button.addEventListener("click", () => {
    const src =
      (document.documentElement.dataset.theme === "light" &&
        button.dataset.fullLight) ||
      button.dataset.full;
    if (!dialog || !image || !caption || !src) return;
    opener = button;
    if (imageStatus) {
      imageStatus.hidden = false;
      imageStatus.textContent = "Memuat screenshot…";
    }
    if (originalLink) {
      originalLink.hidden = true;
      originalLink.href = src;
    }
    image.hidden = true;
    image.src = src;
    image.alt = button.dataset.caption || "Screenshot DashTConnect";
    caption.textContent = image.alt;
    dialog.showModal();
    document.body.classList.add("dialog-open");
  });
});
dialog
  ?.querySelector("button")
  ?.addEventListener("click", () => dialog.close());
dialog?.addEventListener("click", (event) => {
  if (event.target === dialog) dialog.close();
});
dialog?.addEventListener("close", () => {
  document.body.classList.remove("dialog-open");
  opener?.focus();
});
document.addEventListener("keydown", (event) => {
  if (
    event.key === "Escape" &&
    menu?.getAttribute("aria-expanded") === "true"
  ) {
    closeMenu();
    menu.focus();
  }
});

const scrollButtons = document.querySelectorAll<HTMLButtonElement>(
  "[data-scroll-target]",
);
document
  .querySelectorAll<HTMLElement>(".scroll-buttons")
  .forEach((group) => (group.hidden = false));
scrollButtons.forEach((button) => {
  const track = document.getElementById(button.dataset.scrollTarget || "");
  if (!track) return;
  const direction = Number(button.dataset.direction);
  function update() {
    button.disabled =
      direction < 0
        ? track!.scrollLeft < 2
        : track!.scrollLeft >= track!.scrollWidth - track!.clientWidth - 2;
  }
  button.addEventListener("click", () => {
    const first = [...track.children].find(
      (child) => (child as HTMLElement).offsetWidth > 0,
    ) as HTMLElement | undefined;
    const distance = first
      ? first.getBoundingClientRect().width +
        parseFloat(getComputedStyle(track).columnGap || "0")
      : track.clientWidth;
    track.scrollBy({
      left: direction * distance,
      behavior: motion.matches ? "instant" : "smooth",
    });
  });
  track.addEventListener("scroll", update, { passive: true });
  new ResizeObserver(update).observe(track);
  update();
});
