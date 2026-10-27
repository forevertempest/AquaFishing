<div align="center">

# AquaFishing

**ROBLOX · STEAL AN EGG · AUTO FISHING**

Auto cast. Auto reel. Dark GUI.

![Lua](https://img.shields.io/badge/Lua-0F151F?style=flat-square&logo=lua&logoColor=A3B6F6)
![Client](https://img.shields.io/badge/CLIENT_SCRIPT-0F151F?style=flat-square)
![UI](https://img.shields.io/badge/DARK_UI-0F151F?style=flat-square)
</div>

> [!WARNING]
> **RU · УЧЕБНЫЙ ПРОЕКТ — ИСПОЛЬЗОВАНИЕ НА СВОЙ РИСК**
>
> Исходный код опубликован для изучения клиентских интерфейсов и автоматизации ввода. Используй его только в собственных проектах или там, где такая автоматизация явно разрешена.
>
> Код предоставляется **«как есть»**, без гарантий. Запуск может нарушать правила платформы и привести к блокировке аккаунта. Пользователь самостоятельно оценивает риски и отвечает за соблюдение применимых законов и правил.
>
> **Учебная цель публикации не отменяет юридическую ответственность.** Ограничение ответственности автора действует только в пределах, допускаемых законом. Проект не связан с Roblox Corporation и не одобрен ею.

> [!WARNING]
> **EN · EDUCATIONAL PROJECT — USE AT YOUR OWN RISK**
>
> The source code is published for studying client-side interfaces and input automation. Use it only in projects you own or where this automation is explicitly permitted.
>
> The code is provided **“as is,”** without warranties. Running it may violate platform rules and result in account bans. Users assess the risks and are responsible for complying with applicable laws and rules.
>
> **An educational publication purpose does not remove legal liability.** Any limitation of the author's liability applies only to the extent permitted by law. This project is not affiliated with or endorsed by Roblox Corporation.

<div align="center">

**[RU — Русский](#ru)** &nbsp; / &nbsp; **[EN — English](#en)**

</div>

---

<a id="ru"></a>

## RU / Русский

Lua-скрипт автоматизации рыбалки в **Steal an Egg**, опубликованный для изучения клиентских интерфейсов и обработки ввода. Авто-заброс, вытаскивание и меню со звёздным фоном.

[Возможности](#возможности) · [Запуск](#запуск) · [Управление](#управление) · [Настройки](#настройки) · [Контакты](#contacts)

### Возможности

| Рыбалка | Интерфейс |
| :--- | :--- |
| Авто-заброс с зарядкой 1,05 с | Тёмная палитра, звёзды и метеоры |
| Клики до исчезновения подсказки | Перемещаемое окно и компактная полоса |
| Раздельное включение заброса и вытаскивания | Скрываемая плавающая кнопка |
| Пауза, счётчик циклов и время работы | Переназначаемые хоткеи |

> **Без лимита по числу кликов.** Значение `(000)` — игровой счётчик, а не цель. Вытаскивание продолжается, пока доступна подсказка «Нажимайте быстро!».

### Запуск

**Нужны:** Roblox, экипированная удочка и экзекьютор с `mouse1press` / `mouse1release`. Совместимость с конкретными экзекьюторами не подтверждена.

1. Зайди в **Steal an Egg**.
2. Скопируй код скрипта из репозитория в экзекьютор и выполни его.
3. Экипируй удочку и уведи курсор с меню и игровых кнопок.
4. Нажми **F1** или **«Запустить»**.

Автоматизация при запуске выключена. Скрипт не перемещает курсор — точку клика выбираешь ты.

### Управление

| Действие | Клавиша / кнопка |
| :--- | :--- |
| Запуск / остановка | **F1** |
| Показать / скрыть меню | **F6** |
| Пауза / продолжение | **Пауза / Продолжить** |
| Компактный режим / разворачивание | **− / +** |
| Скрыть окно | **×** в заголовке |
| Открыть окно | Плавающая кнопка **//** или **F6** |
| Удалить интерфейс и остановить скрипт | **Настройки → Выгрузить** |

**F1 и F6 переназначаются.** При активном текстовом поле или обработке клавиши игрой хоткеи не срабатывают.

**Скрытие меню не останавливает рыбалку.** После удаления плавающей кнопки меню остаётся доступно по хоткею.

### Настройки

**В меню:** авто-заброс, авто-вытаскивание, интервал кликов, хоткеи, плавающая кнопка, защита от кликов по меню, анимация фона.

| Параметр | По умолчанию |
| :--- | :--- |
| Зарядка после исчезновения готовности | **1,05 с** |
| Удержание одного клика | **25 мс** |
| Пауза между кликами | **25 мс** |
| Диапазон паузы в меню | **15–80 мс**, шаг **5 мс** |

Зарядка и длительность удержания меняются в `Config.PerfectCastTime` и `Config.ClickDownTime`. Полный период клика включает удержание, паузу и задержки выполнения.

Настройки и статистика сбрасываются при перезапуске.

<details>
<summary><b>Логика и ограничения</b></summary>

<br>

```text
Готовность → Зарядка → Поклёвка → Клики → Готовность
```

- Подсказки определяются по тексту GUI в `PlayerGui`. Поддерживаются русские и английские фразы из исходника.
- При исчезновении подсказки новые клики прекращаются; исчезновение подтверждается за **0,35 с**. При возврате — **0,08 с** стабилизации.
- Если прочитанный счётчик не меняется после отправки кликов **8 с**, автоматизация отключается. Предел одной попытки вытаскивания — **180 с**.
- `Config.ReelTimeout = 60` — ожидание появления подсказки, не длительность кликов.
- При потере фокуса, работе с текстовым полем или блокировке интерфейсом ввод приостанавливается. Фоновая работа не предусмотрена.
- Защита от кликов по меню относится только к интерфейсу скрипта.
- «Циклы» — завершённые последовательности интерфейса, не подтверждённые награды. «Клики» — игровой счётчик либо число отправленных нажатий, если счётчик не читается.
- Тайминг 1,05 с не гарантирует PERFECT. Изменения игры и ограничения экзекьютора могут нарушить работу.

</details>

---

### Назначение и ответственность

Исходный код опубликован в учебных и исследовательских целях. Используй его только в собственных проектах или средах, где такая автоматизация явно разрешена.

- Проект не связан с Roblox Corporation и не одобрен ею.
- Код предоставляется **«как есть»**, без гарантий работоспособности и безопасности. Экзекьюторы не входят в проект; их безопасность не подтверждается.
- Запуск может нарушать правила платформы и привести к блокировке аккаунта. Обход античита и защита от бана не заявлены.
- Пользователь самостоятельно принимает решение о запуске, оценивает риски и отвечает за соблюдение применимого законодательства и правил платформы.
- В пределах, допускаемых применимым законом, автор не отвечает за ущерб от использования кода. Этот текст не исключает ответственность, которую нельзя исключить по закону.

> **Учебная цель публикации не делает любое использование разрешённым и не отменяет юридическую ответственность.**

[↑ Выбор языка](#aquafishing)

---

<a id="en"></a>

## EN / English

A Lua auto fishing script for **Roblox Steal an Egg**, published for studying client-side interfaces and input automation. Auto cast, auto reel, and a dark GUI with an animated starfield.

[Features](#features) · [Getting started](#getting-started) · [Controls](#controls) · [Settings](#settings) · [Contacts](#contacts)

### Features

| Fishing | Interface |
| :--- | :--- |
| Auto cast with a 1.05 s charge | Dark palette, stars, and meteors |
| Clicks until the prompt disappears | Draggable window and compact status bar |
| Independent auto cast and auto reel toggles | Dismissible floating launcher |
| Pause, cycle counter, and active time | Customizable keybinds |

> **No fixed click count.** `(000)` is the game's progress counter, not a target. Reeling continues while the “Click fast” prompt is available.

### Getting started

**Required:** Roblox, an equipped fishing rod, and an executor providing `mouse1press` / `mouse1release`. Compatibility with specific executors is not confirmed.

1. Join **Steal an Egg**.
2. Copy the script from this repository into a compatible executor and run it.
3. Equip your fishing rod and move the cursor away from the menu and game buttons.
4. Press **F1** or **«Запустить»** (Start).

Automation starts **off**. The script does not move your cursor; you choose the click position.

**The script's GUI is in Russian.** This section documents its controls in English.

### Controls

| Action | Default key / button |
| :--- | :--- |
| Start / stop | **F1** |
| Show / hide menu | **F6** |
| Pause / resume | **«Пауза» / «Продолжить»** |
| Compact mode / expand | **− / +** |
| Hide window | **×** in the header |
| Open window | Floating **//** launcher or **F6** |
| Remove the GUI and stop the script | **«Настройки» → «Выгрузить»** (Settings → Unload) |

**F1 and F6 can be rebound.** Hotkeys are ignored while a text box is focused or the game has already handled the key event.

**Hiding the menu does not stop fishing.** If you dismiss the floating launcher, the menu remains accessible through its keybind.

### Settings

**In the GUI:** auto cast, auto reel, click interval, keybinds, floating launcher, menu click protection, and background animation.

| Parameter | Default |
| :--- | :--- |
| Charge after the ready prompt disappears | **1.05 s** |
| Mouse-down duration per click | **25 ms** |
| Pause between clicks | **25 ms** |
| Pause range in the GUI | **15–80 ms**, in **5 ms** steps |

Edit `Config.PerfectCastTime` and `Config.ClickDownTime` to change the charge and mouse-down duration. A full click period includes the hold, the pause, and execution delays.

Settings and statistics reset when the script is restarted.

<details>
<summary><b>Logic and limitations</b></summary>

<br>

```text
Ready → Charge → Bite → Clicks → Ready
```

- Prompts are identified from GUI text in `PlayerGui`. The Russian and English phrases listed in the source are supported.
- New clicks stop when the prompt disappears; disappearance is confirmed over **0.35 s**. If it returns, clicks resume after **0.08 s** of stabilization.
- If a previously read counter stops changing for **8 s** after clicks have been sent, automation switches off. One reeling attempt is limited to **180 s**.
- `Config.ReelTimeout = 60` limits the wait for the reeling prompt, not the clicking phase.
- Input pauses on focus loss, text entry, or interface blocking. Background operation is not supported.
- Menu click protection covers the script's own interface only.
- “Cycles” counts completed interface sequences, not confirmed rewards. “Clicks” shows the game counter, or the number of sent presses if the counter cannot be read.
- The 1.05 s timing does not guarantee a PERFECT cast. Game updates and executor limitations may break functionality.

</details>

---

### Purpose and responsibility

The source code is published for educational and research purposes. Use it only in projects you own or environments where this automation is explicitly permitted.

- This project is not affiliated with or endorsed by Roblox Corporation.
- The code is provided **“as is,”** without warranties of functionality or safety. Executors are not included, and their safety is not verified.
- Running the script may violate platform rules and result in account bans. No anti-cheat bypass or ban protection is claimed.
- Users decide whether to run the code, assess the risks, and are responsible for complying with applicable laws and platform rules.
- To the extent permitted by applicable law, the author is not liable for damage arising from use of the code. This notice does not exclude liability that cannot legally be excluded.

> **An educational publication purpose does not make every use permissible or remove legal liability.**

[↑ Language selection](#aquafishing)

---

<a id="contacts"></a>

## Контакты / Contacts

· Discord: `foreverfame` · [Telegram](https://t.me/tempestdevelop)
