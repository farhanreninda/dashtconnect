import { test, expect } from "@playwright/test";

for (const width of [320, 390, 768, 1024, 1440]) {
  test(`screenshots match the selected theme at ${width}px`, async ({
    page,
  }) => {
    const errors: string[] = [];
    page.on("pageerror", (e) => errors.push(e.message));
    page.on("response", (r) => {
      if (r.status() >= 400) errors.push(`${r.status()} ${r.url()}`);
    });
    await page.setViewportSize({ width, height: 900 });
    await page.goto("./");
    await expect(page.locator("main [data-lightbox]")).toHaveCount(30);
    await expect(page.locator("main details img")).toHaveCount(0);
    await expect(page.getByRole("tab")).toHaveCount(0);
    for (const theme of ["light", "dark"]) {
      if ((await page.locator("html").getAttribute("data-theme")) !== theme)
        await page.locator(".theme-toggle").click();
      for (const wrong of await page
        .locator(
          `[data-available-theme="${theme === "dark" ? "light" : "dark"}"]`,
        )
        .all())
        await expect(wrong).not.toBeVisible();
      for (const shot of await page
        .locator("main [data-lightbox]:visible")
        .all()) {
        await expect(shot).toBeVisible();
        await shot.scrollIntoViewIfNeeded();
        const img = shot.locator("img");
        await expect
          .poll(() => img.evaluate((i: HTMLImageElement) => i.naturalWidth))
          .toBeGreaterThan(0);
      }
      expect(
        await page.evaluate(() => document.documentElement.scrollWidth),
      ).toBeLessThanOrEqual(width);
    }
    for (const href of await page
      .locator('a[href^="#"]')
      .evaluateAll((links) => links.map((a) => a.getAttribute("href")!)))
      await expect(page.locator(href)).toHaveCount(1);
    await expect(page.locator('link[rel="canonical"]')).toHaveAttribute(
      "href",
      "https://farhanreninda.my.id/dashtconnect/",
    );
    expect(errors).toEqual([]);
  });
}

test("available screenshots can zoom and return keyboard focus", async ({
  page,
}) => {
  await page.goto("./");
  for (const trigger of await page
    .locator("main [data-lightbox]:visible")
    .all()) {
    await trigger.click();
    await expect(page.getByRole("dialog")).toBeVisible();
    await expect
      .poll(() =>
        page
          .locator("#screenshot-image")
          .evaluate((i: HTMLImageElement) => i.naturalWidth),
      )
      .toBeGreaterThan(0);
    await page.keyboard.press("Escape");
    await expect(page.getByRole("dialog")).not.toBeVisible();
    await expect(trigger).toBeFocused();
  }
});

test("theme follows system until explicitly saved and survives reload", async ({
  page,
}) => {
  await page.emulateMedia({ colorScheme: "dark" });
  await page.goto("./");
  await expect(page.locator("html")).toHaveAttribute("data-theme", "dark");
  await page.emulateMedia({ colorScheme: "light" });
  await expect(page.locator("html")).toHaveAttribute("data-theme", "light");
  await page.getByRole("button", { name: "Aktifkan tema gelap" }).click();
  await expect(page.locator(".theme-toggle")).toHaveAttribute(
    "aria-pressed",
    "true",
  );
  await page.reload();
  await expect(page.locator("html")).toHaveAttribute("data-theme", "dark");
  await page.emulateMedia({ colorScheme: "dark" });
  await page.emulateMedia({ colorScheme: "light" });
  await expect(page.locator("html")).toHaveAttribute("data-theme", "dark");
  await page.getByRole("button", { name: "Aktifkan tema terang" }).click();
  await page.reload();
  await expect(page.locator("html")).toHaveAttribute("data-theme", "light");
});

test("menu, FAQ, reduced motion and keyboard access", async ({ page }) => {
  await page.setViewportSize({ width: 390, height: 844 });
  await page.emulateMedia({ reducedMotion: "reduce" });
  await page.goto("./");
  await page.keyboard.press("Tab");
  await expect(
    page.getByRole("link", { name: "Lewati ke konten" }),
  ).toBeFocused();
  const menu = page.locator(".menu-toggle");
  await menu.click();
  await page.keyboard.press("Escape");
  await expect(menu).toBeFocused();
  await expect(menu).toHaveAttribute("aria-expanded", "false");
  await menu.click();
  await page
    .getByRole("navigation")
    .getByRole("link", { name: "Panduan", exact: true })
    .click();
  await expect(menu).toHaveAttribute("aria-expanded", "false");
  for (const detail of await page.locator(".faq-list details").all()) {
    await detail.locator("summary").click();
    await expect(detail).toHaveAttribute("open", "");
  }
  expect(
    await page.evaluate(
      () => getComputedStyle(document.documentElement).scrollBehavior,
    ),
  ).toBe("auto");
  expect(await page.evaluate(() => document.getAnimations().length)).toBe(0);
});

test("all screenshots readable without JavaScript", async ({ browser }) => {
  const context = await browser.newContext({
    javaScriptEnabled: false,
    viewport: { width: 390, height: 844 },
  });
  const page = await context.newPage();
  await page.goto("http://127.0.0.1:4321/dashtconnect/");
  await expect(page.getByRole("navigation")).toBeVisible();
  for (const shot of await page.locator("main [data-lightbox]:visible").all())
    await expect(shot).toBeVisible();
  await expect(page.locator(".theme-toggle")).not.toBeVisible();
  expect(
    await page.evaluate(() => document.documentElement.scrollWidth),
  ).toBeLessThanOrEqual(390);
  await context.close();
});

test("blocked storage keeps theme and screenshot controls working", async ({
  page,
}) => {
  await page.addInitScript(() =>
    Object.defineProperty(window, "localStorage", {
      get() {
        throw new Error("Storage blocked");
      },
    }),
  );
  await page.goto("./");
  await page.locator(".theme-toggle").click();
  await expect(page.locator("html")).toHaveAttribute("data-theme", "dark");
  await page.locator(".hero-product [data-lightbox]").click();
  await expect(page.getByRole("dialog")).toBeVisible();
});

test("screenshot load error offers recovery", async ({ page }) => {
  await page.goto("./");
  const trigger = page.locator(".hero-product [data-lightbox]");
  const full =
    (await trigger.getAttribute("data-full-light")) ||
    (await trigger.getAttribute("data-full"));
  await page.route(`**${full}`, (route) => route.abort());
  await trigger.click();
  await expect(page.getByRole("status")).toContainText(
    "Screenshot belum dapat dimuat",
  );
  await expect(
    page.getByRole("link", { name: "Buka file gambar" }),
  ).toHaveAttribute("href", full!);
  await page.keyboard.press("Escape");
  await expect(page.getByRole("dialog")).not.toBeVisible();
});

test("galleries scroll by controls and keyboard without hiding photos", async ({
  page,
}) => {
  await page.setViewportSize({ width: 390, height: 844 });
  await page.emulateMedia({ reducedMotion: "reduce" });
  await page.goto("./");
  await expect(page.locator(".theme-toggle")).toHaveText("◐");
  await expect(page.locator(".theme-label")).toHaveCount(0);
  for (const id of ["feature-gallery", "session-gallery", "tutorial-gallery"]) {
    const track = page.locator(`#${id}`);
    const previous = page.locator(
      `[data-scroll-target="${id}"][data-direction="-1"]`,
    );
    const next = page.locator(
      `[data-scroll-target="${id}"][data-direction="1"]`,
    );
    await expect(previous).toBeDisabled();
    await next.click();
    await expect
      .poll(() => track.evaluate((e) => e.scrollLeft))
      .toBeGreaterThan(20);
    await expect(previous).toBeEnabled();
    await previous.click();
    await expect
      .poll(() => track.evaluate((e) => e.scrollLeft))
      .toBeLessThan(3);
    await track.focus();
    await page.keyboard.press("ArrowRight");
    await expect
      .poll(() => track.evaluate((e) => e.scrollLeft))
      .toBeGreaterThan(0);
    await track.evaluate((e) => (e.scrollLeft = e.scrollWidth));
    await expect(next).toBeDisabled();
  }
});

test("light screenshots follow theme and zoom uses the same version", async ({
  page,
}) => {
  await page.goto("./");
  const sources = page.locator("source[data-theme-light]");
  await expect(sources).toHaveCount(18);
  const trigger = page.getByRole("button", {
    name: "Perbesar home",
    exact: true,
  });
  const picture = trigger.locator("img");
  await trigger.scrollIntoViewIfNeeded();
  const lightSrc = await trigger.locator("source").getAttribute("srcset");
  await expect
    .poll(() => picture.evaluate((i: HTMLImageElement) => i.currentSrc))
    .toContain(lightSrc!);
  await trigger.click();
  await expect(page.locator("#screenshot-image")).toHaveAttribute(
    "src",
    (await trigger.getAttribute("data-full-light"))!,
  );
  await page.keyboard.press("Escape");
  await page.locator(".theme-toggle").click();
  await expect
    .poll(() => picture.evaluate((i: HTMLImageElement) => i.currentSrc))
    .not.toContain(lightSrc!);
  await trigger.click();
  await expect(page.locator("#screenshot-image")).toHaveAttribute(
    "src",
    (await trigger.getAttribute("data-full"))!,
  );
  await page.keyboard.press("Escape");
  await page.locator(".theme-toggle").click();
  await expect
    .poll(() => picture.evaluate((i: HTMLImageElement) => i.currentSrc))
    .toContain(lightSrc!);
});

test("theme filtering includes CarPlay hero and removes unmatched image slots", async ({
  page,
}) => {
  await page.goto("./");
  for (const theme of ["light", "dark", "light"]) {
    if ((await page.locator("html").getAttribute("data-theme")) !== theme)
      await page.locator(".theme-toggle").click();
    const photos = page.locator("main [data-lightbox]:visible");
    await expect(photos).toHaveCount(theme === "light" ? 23 : 19);
    for (const button of await photos.all()) {
      const source = button.locator("source[data-theme-light]");
      if (await source.count()) {
        await button.scrollIntoViewIfNeeded();
        const light = await source.getAttribute("srcset");
        if (theme === "light")
          await expect
            .poll(() =>
              button
                .locator("img")
                .evaluate((i: HTMLImageElement) => i.currentSrc),
            )
            .toContain(light!);
        else
          await expect
            .poll(() =>
              button
                .locator("img")
                .evaluate((i: HTMLImageElement) => i.currentSrc),
            )
            .not.toContain(light!);
      }
    }
    await expect(page.locator("#tutorial-gallery img:visible")).toHaveCount(
      theme === "dark" ? 4 : 0,
    );
    await expect(page.locator("#tutorial-gallery > li")).toHaveCount(4);
  }
});
