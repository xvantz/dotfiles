# Client Q&A: "Figma grid template / our widths don't match"

Real scenario: client Mikhail, lactb.ru news-site project (Next.js + Tailwind v4, Ivan = PM). Client found Tailwind community Figma files, worried their artboards (1920/1440/1024/768/360) don't match Tailwind's recommended widths (1536/1280/1024/768/640/320).

## Ready-to-send answer (RU)

```
Привет!

Всё нормально, противоречия тут нет.

Коротко: ширины из шаблона (1536, 1280, 640, 320) - это технические
точки Tailwind, на которых сайт сам перестраивается. А наши артборды
(1920, 1440, 1024, 768, 360) - это просто размеры макетов, на которых
мы проверяем дизайн. Они не обязаны совпадать: между макетами всё
плавно растягивается, ничего не ломается.

Практически рисуем так:
- 1440 - основной десктоп
- 360 - основной мобильный
- 1024 и 768 - планшет и маленький ноутбук (обязательны)
- 1920 - опционально, проверка широких экранов. Можно не для
  каждой страницы, только ключевые

Сетку в Figma настраиваем так (12 колонок):
- Десктоп: gutter 24px, отступы по краям 32px
- Планшет (768-1024): gutter 24px, отступы 24px
- Мобильный (360): gutter 16px, отступы 16-20px

Это стандартная схема, вёрстка по ней совпадёт с макетами.
Нашёл шаблон получше - бери его как референс, но настраивать
сетку руками по цифрам выше быстрее, чем адаптировать чужой файл.
```

## One-liner for full-bleed expectation
"Рисуем широко: фон на всю ширину, контент в сетке по центру. На 1440 и 1920 контентная часть выглядит одинаково, отличаются только поля по бокам."

## Decomposing the client's question
- They are NOT asking for CSS theory. They're asking: "am I drawing correctly, and will the build match my designs?"
- Answer = confirmation + concrete numbers + decoupling from community files.
- If the PM themselves is confused (backend/DevOps background), explain breakpoint = min-width threshold with the salary-grade analogy: "от 100к" means "100k and up", not "exactly 100k".

## Source facts to cite
- StatCounter desktop resolutions worldwide (Jun 2025-Jul 2026): 1920×1080 22.3%, 1536×864 ~10% (3rd), 1366×768 legacy, 1440×900 ~5-7%. gs.statcounter.com/screen-resolution-stats/desktop/worldwide
- Tailwind v4 docs: default breakpoints table (sm 640 / md 768 / lg 1024 / xl 1280 / 2xl 1536), `@theme` customization. tailwindcss.com/docs/responsive-design
- WebHelpAgency "Website Dimensions Guide 2026": design width 1366-1440, content container 1140-1280 (Full HD: 1140-1280), large-desktop design width 1440-1600.
- UXPin "Responsive Design Best Practices (2026)": container queries, clamp(), breakpoints-that-follow-content, 5-breakpoint system; news publishers (Guardian/NYT/Bloomberg) use card grids with a narrow text column — text is never full-width.
