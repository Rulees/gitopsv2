document.addEventListener("DOMContentLoaded", () => {
  const csvData = `Школа,нет,до 500м,до 1000м,до 1500м,
Детский сад,нет,до 500м,до 1000м,до 1500м,
Площадь ЖК,до 10Га,до 20Га,до 30 Га,до 40 Га,Более 50 Га
Количество домов в ЖК,2-5,6-10,11-20,20-30,более 30
Количество квартир в ЖК,До 300,300-1000,1000-1500,1500-2500,более 2500
Этажность,3-5,8-9,9-16,16-18,19-21
Плотность населения,,,,,
Расстояние до Центра на авто,10-15мин,,,,час и более
До остановки пешком,До 5мин,5-10мин,более 10мин,,
Отопление,Свой котел,Своя котельная на газе,Цетр.теплосеть,,
Закрытая территория,Полностью,Закр. от машин,Открытая,,
Окна с атермальным напылением,Да,Нет,,,,
Высота потолков,"2,5-2,75м","2,8-2,85","2,85-3,00",более 3м
Наличие Студий в ЖК,Да,Нет,,,,
Парковки,Подзем есть,Стилобаты,Только наземная,Многоуровневый паркинг
Коммерция,Своя в ЖК,Рядом много,Рядом ТРЦ,,
Дворы без машин,Да,Нет,,,,
Наличие парка, сквера рядом,Да,Нет,,,,
Кондиционеры,Случайно,В корзинах,Сбор конденсата,Сплит-румы,капает/не капает
Наличие водоема,Нет,Рядом,в 10-15мин,,
Колич квартир на этаже,4-5,6-8,9-10,11-14,
Колясочные, велосипедные,Да,Нет,,,,
Консьерж ,Нет,Да,Консьерж-сервис премиум,,
Вход в подъезд без ступеней,Да,Нет,,,,
Сквозные подъезды,Да,нет,,,,
Фитнес,На территории,Рядом,10-15 минут пешком,нет
Зарядная станция электроавтомобилей,Да,Нет,,,,
Видеонаблюдение,Нет,На входах и въездах,Полное,Умные камеры
Класс жилья,Эконом,Комфорт,Комфорт+,Бизнес,Премиум
Арендный потенциал,Низкий,Средний,Высокий,топ
Автополив газонов и деревьев,Да,Нет,,,,
Спортивные площадки и тренажеры,мало,много,круто,,
Краснодар или Адыгея,Краснодар,Адыгея,,,,
Трамвай,,,,,
Поликлиника,,,,,`;

  const parseCsvData = (csv) => {
    const lines = csv.split("\n").filter((line) => line.trim() !== "");
    const filters = {};
    lines.forEach((line) => {
      const parts = line.match(/(?:[^,"']+|"[^"]*")+/g).map((p) => p.replace(/"/g, "").trim());
      const filterName = parts[0];
      const options = parts.slice(1).filter((opt) => opt !== "");
      filters[filterName] = options;
    });
    return filters;
  };

  const mockBackendFilters = parseCsvData(csvData);

  const filterDescriptions = {
    Школа: "Наличие школы рядом с жилым комплексом.",
    "Детский сад": "Близость детского сада.",
    "Площадь ЖК": "Общая площадь жилого комплекса.",
    "Количество домов в ЖК": "Количество корпусов на территории ЖК.",
    "Количество квартир в ЖК": "Общее число квартир в комплексе.",
    Этажность: "Высота зданий в ЖК.",
    "Плотность населения": "Число жителей на квадратный метр.",
    "Расстояние до Центра на авто": "Время на автомобиле до центра города.",
    "До остановки пешком": "Пешая доступность к остановке.",
    Отопление: "Тип отопительной системы в доме.",
    "Закрытая территория": "Наличие ограждённой и охраняемой территории.",
    "Окна с атермальным напылением": "Энергосберегающие окна с защитой от солнца.",
    "Высота потолков": "Высота потолков в квартирах.",
    "Наличие Студий в ЖК": "Есть ли в комплексе студии.",
    Парковки: "Тип и расположение парковочных мест.",
    Коммерция: "Наличие магазинов или бизнеса в ЖК.",
    "Дворы без машин": "Пространство во дворе без автомобилей.",
    "Наличие парка, сквера рядом": "Близость зелёных насаждений.",
    Кондиционеры: "Наличие и тип кондиционирования.",
    "Наличие водоема": "Есть ли рядом река, озеро или пруд.",
    "Колич квартир на этаже": "Количество квартир на одном этаже.",
    "Колясочные, велосипедные": "Помещения для хранения колясок и велосипедов.",
    Консьерж: "Наличие дежурного у входа или премиум-сервиса.",
    "Вход в подъезд без ступеней": "Удобный вход без лестниц.",
    "Сквозные подъезды": "Подъезды с выходом во двор и на улицу.",
    Фитнес: "Наличие спортзала рядом или на территории.",
    "Зарядная станция электроавтомобилей": "Электрозарядки для авто.",
    Видеонаблюдение: "Камеры видеонаблюдения в ЖК.",
    "Класс жилья": "Уровень комфорта и категории жилья.",
    "Арендный потенциал": "Привлекательность ЖК для арендаторов.",
    "Автополив газонов и деревьев": "Автоматическая система полива.",
    "Спортивные площадки и тренажеры": "Оборудованные места для спорта.",
    "Краснодар или Адыгея": "Регион расположения комплекса.",
    Трамвай: "Близость трамвайной линии.",
    Поликлиника: "Медучреждение поблизости.",
  };

  const filterCategories = {
    Инфраструктура: ["Школа", "Детский сад", "Расстояние до Центра на авто", "До остановки пешком", "Наличие парка, сквера рядом", "Наличие водоема", "Краснодар или Адыгея", "Трамвай", "Поликлиника"],
    Архитектура: ["Площадь ЖК", "Количество домов в ЖК", "Количество квартир в ЖК", "Этажность", "Плотность населения", "Колич квартир на этаже", "Наличие Студий в ЖК", "Высота потолков"],
    Удобства: ["Отопление", "Закрытая территория", "Окна с атермальным напылением", "Парковки", "Коммерция", "Дворы без машин", "Кондиционеры", "Колясочные, велосипедные", "Консьерж"],
    Сервис: ["Вход в подъезд без ступеней", "Сквозные подъезды", "Фитнес", "Зарядная станция электроавтомобилей", "Видеонаблюдение", "Класс жилья", "Арендный потенциал", "Автополив газонов и деревьев", "Спортивные площадки и тренажеры"],
  };

  // 2. Render filters
  const container = document.getElementById("filter-grid-container");
  if (container) {
    for (const category in filterCategories) {
      const column = document.createElement("div");
      column.classList.add("filter-column");

      const heading = document.createElement("h4");
      heading.textContent = category;
      column.appendChild(heading);

      filterCategories[category].forEach((filterName) => {
        if (mockBackendFilters[filterName]) {
          const item = document.createElement("div");
          item.classList.add("filter-item");
          item.dataset.filterName = filterName;
          item.textContent = filterName;

          // Inject popup wrapper (initially hidden)
          const popup = document.createElement("div");
          popup.classList.add("popup", "popup--filter-item");
          const wrapper = document.createElement("div");
          wrapper.classList.add("popup__wrapper");

          const optionsBlock = document.createElement("div");
          optionsBlock.classList.add("popup__options");
          optionsBlock.setAttribute("data-popup-role", "options");

          mockBackendFilters[filterName].forEach((opt) => {
            const option = document.createElement("span");
            option.textContent = opt;
            option.classList.add("popup__button");
            optionsBlock.appendChild(option);
          });

          const infoBlock = document.createElement("div");
          infoBlock.classList.add("popup__info");
          infoBlock.setAttribute("data-popup-role", "info");
          const infoIcon = `
<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="currentColor" aria-hidden="true">
  <path fill-rule="evenodd" clip-rule="evenodd" d="M8 13.5a5.5 5.5 0 1 0 0-11 5.5 5.5 0 0 0 0 11M8 15A7 7 0 1 0 8 1a7 7 0 0 0 0 14M6.44 4.54c.43-.354.994-.565 1.56-.565 1.217 0 2.34.82 2.34 2.14 0 .377-.078.745-.298 1.1-.208.339-.513.614-.875.867-.217.153-.325.257-.379.328-.038.052-.038.07-.038.089a.75.75 0 0 1-1.5 0c0-.794.544-1.286 1.057-1.645.28-.196.4-.332.458-.426a.54.54 0 0 0 .075-.312c0-.3-.244-.641-.84-.641a1 1 0 0 0-.608.223c-.167.138-.231.287-.231.418a.75.75 0 0 1-1.5 0c0-.674.345-1.22.78-1.577M8 12a1 1 0 1 0 0-2 1 1 0 0 0 0 2"/>
</svg>`;

          const descriptionText = filterDescriptions[filterName] || "Описание недоступно.";
          const descriptionParagraph = document.createElement("p");
          descriptionParagraph.textContent = descriptionText;
          infoBlock.innerHTML = infoIcon; // Add SVG first
          infoBlock.appendChild(descriptionParagraph);

          // === Собираем строго по твоей структуре ===
          wrapper.appendChild(optionsBlock);
          wrapper.appendChild(infoBlock);
          popup.appendChild(wrapper);
          item.appendChild(popup);
          column.appendChild(item);
        }
      });

      container.appendChild(column);
    }
  }

  // === POPUP FUNCTIONALITY ===
  let activeItem = null;

  document.addEventListener("click", (e) => {
    const clickedItem = e.target.closest(".filter-item");

    if (clickedItem) {
      // same toggle
      if (clickedItem === activeItem) {
        closeActivePopup();
        return;
      }

      // close previous and open new
      closeActivePopup();

      clickedItem.classList.add("active");
      clickedItem.querySelector(".popup").classList.add("popup--active");
      activeItem = clickedItem;

      // Ensure popup is fully visible inside scroll container
      const popup = clickedItem.querySelector(".popup");
      const gridContainer = document.querySelector(".filter-grid"); // Make sure this selector correctly targets your scrollable div

      if (popup && gridContainer) {
        const itemRect = clickedItem.getBoundingClientRect();
        const popupRect = popup.getBoundingClientRect();
        const containerRect = gridContainer.getBoundingClientRect();

        // Calculate the relative positions within the scroll container
        const itemRelativeTop = itemRect.top - containerRect.top;
        const itemRelativeBottom = itemRect.bottom - containerRect.top;
        const popupRelativeBottom = popupRect.bottom - containerRect.top;

        // Desired padding from the edges
        const scrollPadding = 10;

        let scrollAmount = 0;

        // Case 1: Popup extends below the visible area of the container
        if (popupRelativeBottom > gridContainer.clientHeight - scrollPadding) {
          // Calculate how much to scroll down to show the full popup
          scrollAmount = popupRelativeBottom - (gridContainer.clientHeight - scrollPadding);

          // IMPORTANT: Prevent scrolling the clicked item out of view from the top
          // We don't want to scroll past the point where the item's top would be off-screen
          const maxScrollDownWithoutHidingItem = itemRelativeTop; // Max we can scroll down before item's top hits container top
          scrollAmount = Math.min(scrollAmount, maxScrollDownWithoutHidingItem); // Cap the scroll amount
        }
        // Case 2: Item is above the visible area (should not happen on click if it was visible, but for safety)
        else if (itemRelativeTop < scrollPadding) {
          scrollAmount = itemRelativeTop - scrollPadding; // Scroll up
        }

        if (scrollAmount !== 0) {
          gridContainer.scrollBy({
            top: scrollAmount,
            behavior: "smooth",
          });
        }
      }

      disableOtherItems(clickedItem);
    } else if (!e.target.closest(".popup--filter-item")) {
      // click outside
      closeActivePopup();
    }
  });

  function closeActivePopup() {
    if (activeItem) {
      activeItem.classList.remove("active");
      activeItem.querySelector(".popup").classList.remove("popup--active");
      activeItem = null;
      enableAllItems();
    }
  }

  function disableOtherItems(except) {
    document.querySelectorAll(".filter-item").forEach((el) => {
      if (el !== except) el.classList.add("disabled");
    });
  }

  function enableAllItems() {
    document.querySelectorAll(".filter-item").forEach((el) => el.classList.remove("disabled"));
  }

  document.addEventListener("keydown", (e) => {
    if (e.key === "Escape") {
      if (activeItem) {
        closeActivePopup();
      } else if (modalOverlay?.classList.contains("modal--active")) {
        closeModal();
      }
    }
  });

  // === MODAL FUNCTIONALITY ===
  const filterBtn = document.getElementById("filter-toggle-btn");
  const modalOverlay = document.querySelector(".filter-modal-overlay");
  const filterWrapper = modalOverlay?.querySelector(".filter-wrapper");
  const rollupBtn = filterWrapper?.querySelector(".rollup");

  if (filterBtn && modalOverlay && filterWrapper) {
    filterBtn.addEventListener("click", () => {
      modalOverlay.classList.add("modal--active");
      document.body.classList.add("modal-open");
    });

    rollupBtn?.addEventListener("click", closeModal);

    modalOverlay.addEventListener("click", (e) => {
      if (e.target === modalOverlay) {
        closeModal();
      }
    });
  }

  function closeModal() {
    modalOverlay.classList.remove("modal--active");
    document.body.classList.remove("modal-open");
    closeActivePopup();
  }
});
