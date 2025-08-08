document.addEventListener("DOMContentLoaded", () => {
  const selectedFilters = {};

  const parseDescriptionsCsv = (csv) => {
    const rows = [];

    // Регулярное выражение для поиска номера и описания в кавычках.
    // Флаг 'g' позволяет найти все совпадения в файле.
    // Флаг 's' (dotAll) позволяет '.' соответствовать переносам строк.
    const regex = /(\d+),\s*"([^"]*)"/gs;

    let match;
    while ((match = regex.exec(csv)) !== null) {
      // match[1] - это Номер ЖК
      // match[2] - это полное Описание
      const obj = {
        "Номер ЖК": match[1].trim(),
        Описание: match[2].trim().replace(/""/g, '"'),
      };
      rows.push(obj);
    }

    return rows;
  };

  const parseCsvData = (csv, hasHeader = true) => {
    const rows = [];
    const lines = csv
      .split(/\r?\n/)
      .map((line) => line.trim())
      .filter(Boolean);

    const parseLine = (line) => {
      const result = [];
      let value = "";
      let insideQuotes = false;

      for (let i = 0; i < line.length; i++) {
        const char = line[i];
        const nextChar = line[i + 1];

        if (char === '"' && insideQuotes && nextChar === '"') {
          value += '"';
          i++;
        } else if (char === '"') {
          insideQuotes = !insideQuotes;
        } else if (char === "," && !insideQuotes) {
          result.push(value.trim());
          value = "";
        } else {
          value += char;
        }
      }
      result.push(value.trim());
      return result;
    };

    const headers = hasHeader ? parseLine(lines.shift()) : null;

    lines.forEach((line) => {
      const parsed = parseLine(line);
      if (hasHeader) {
        const obj = {};
        headers.forEach((h, i) => {
          obj[h] = parsed[i] ?? "";
        });
        rows.push(obj);
      } else {
        rows.push(parsed);
      }
    });

    return rows;
  };

  Promise.all([fetch("/projects/home/nginx/frontend/public/data/filters.csv").then((response) => response.text()), fetch("/projects/home/nginx/frontend/public/data/values.csv").then((response) => response.text()), fetch("/projects/home/nginx/frontend/public/data/descriptions.csv").then((response) => response.text())])
    .then(([filtersCsv, valuesCsv, descriptionsCsv]) => {
      const filtersData = parseCsvData(filtersCsv);
      const valuesData = parseCsvData(valuesCsv);
      const descriptionsData = parseDescriptionsCsv(descriptionsCsv);

      const mockBackendFilters = {};
      const conflictingAnswers = {};
      const filterDefinitions = {};
      const filterCategories = {};
      const descriptions = {};

      descriptionsData.forEach((row) => {
        let descriptionText = row["Описание"] || "";
        const formattedDescription = `<div><p>${descriptionText.replace(/\n/g, "</p><p>")}</p></div>`;
        descriptions[row["Номер ЖК"]] = formattedDescription;
      });

      filtersData.forEach((row) => {
        const filterName = row["Фильтр"];
        const possibleValues = row["Возможные значения"] || "";
        mockBackendFilters[filterName] = possibleValues
          .split(",")
          .map((v) => v.trim())
          .filter(Boolean);
        filterDefinitions[filterName] = row["Описание"];

        const conflictType = row["Конфликтующие / Тип"];
        if (conflictType === "single") {
          conflictingAnswers[filterName] = "all-conflicting";
        } else if (conflictType && conflictType.startsWith("multi")) {
          const conflictOptions = conflictType
            .substring(conflictType.indexOf(",") + 1)
            .split(",")
            .map((v) => v.trim())
            .filter(Boolean);
          if (conflictOptions.length > 0) {
            conflictingAnswers[filterName] = conflictOptions;
          }
        }

        const categoryName = row["Группа"];
        if (categoryName) {
          if (!filterCategories[categoryName]) {
            filterCategories[categoryName] = [];
          }
          filterCategories[categoryName].push(filterName);
        }
      });

      const mockEstates = valuesData.map((row) => {
        const id = row["Номер ЖК"];
        const filters = {};
        for (const key in row) {
          if (key !== "Номер ЖК" && row[key]) {
            filters[key] = row[key].split(",").map((v) => v.trim());
          }
        }
        // Для демонстрации, мы будем считать, что у каждого ЖК 5 изображений.
        const imageCount = 5;
        const images = Array.from({ length: imageCount }, (_, i) => `/projects/home/nginx/frontend/public/images/${id}/${i + 1}.jpg`);

        return { id, filters, images };
      });

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

              const definitionText = filterDefinitions[filterName];

              if (definitionText) {
                const descriptionParagraph = document.createElement("p");
                descriptionParagraph.textContent = definitionText;
                infoBlock.innerHTML = infoIcon; // Add SVG first
                infoBlock.appendChild(descriptionParagraph);
              }

              wrapper.appendChild(optionsBlock);

              if (definitionText) {
                wrapper.appendChild(infoBlock);
              }

              popup.appendChild(wrapper);
              item.appendChild(popup);
              column.appendChild(item);
            }
          });
          container.appendChild(column);
        }
      }

      function toggleSelectedOption(filterItem, filterName, optionText) {
        if (!selectedFilters[filterName]) {
          selectedFilters[filterName] = [];
        }

        const currentSelection = selectedFilters[filterName];
        const index = currentSelection.indexOf(optionText);
        const popupButtons = filterItem.querySelectorAll(".popup__button");

        const conflictRule = conflictingAnswers[filterName];

        if (index > -1) {
          currentSelection.splice(index, 1);
        } else {
          const isConflictingRule = conflictRule === "all-conflicting" || (Array.isArray(conflictRule) && conflictRule.includes(optionText));
          const hasNoOption = mockBackendFilters[filterName].includes("Нет") || mockBackendFilters[filterName].includes("нет");
          const isNoOption = optionText === "Нет" || optionText === "нет";

          if (isConflictingRule || isNoOption || hasNoOption) {
            currentSelection.length = 0;
          }

          currentSelection.push(optionText);
        }

        popupButtons.forEach((btn) => {
          if (currentSelection.includes(btn.textContent.trim())) {
            btn.classList.add("selected");
          } else {
            btn.classList.remove("selected");
          }
        });

        updateFilterStatus(filterItem, filterName);
      }

      let activeItem = null;
      const filterGrid = document.querySelector(".filter-grid");

      document.addEventListener("click", (e) => {
        const clickedItem = e.target.closest(".filter-item");
        const clickedPopupBtn = e.target.closest(".popup__button");

        if (clickedPopupBtn) {
          const filterItem = clickedPopupBtn.closest(".filter-item");
          const filterName = filterItem.dataset.filterName;
          const optionText = clickedPopupBtn.textContent.trim();
          toggleSelectedOption(filterItem, filterName, optionText);
          applyFilter();
          return;
        }

        if (clickedItem) {
          if (clickedItem === activeItem) {
            closeActivePopup();
            filterGrid?.classList.remove("has-open-popup");
            return;
          }

          closeActivePopup();

          clickedItem.classList.add("active");
          clickedItem.querySelector(".popup").classList.add("popup--active");
          activeItem = clickedItem;

          if (filterGrid) {
            filterGrid.classList.add("has-open-popup");
          }

          const popup = clickedItem.querySelector(".popup");
          const gridContainer = document.querySelector(".filter-grid");

          if (popup && gridContainer) {
            const itemRect = clickedItem.getBoundingClientRect();
            const popupRect = popup.getBoundingClientRect();
            const containerRect = gridContainer.getBoundingClientRect();

            const itemRelativeTop = itemRect.top - containerRect.top;
            const popupRelativeBottom = popupRect.bottom - containerRect.top;

            const scrollPadding = 10;
            let scrollAmount = 0;

            if (popupRelativeBottom > gridContainer.clientHeight - scrollPadding) {
              scrollAmount = popupRelativeBottom - (gridContainer.clientHeight - scrollPadding);
              const maxScrollDownWithoutHidingItem = itemRelativeTop;
              scrollAmount = Math.min(scrollAmount, maxScrollDownWithoutHidingItem);
            } else if (itemRelativeTop < scrollPadding) {
              scrollAmount = itemRelativeTop - scrollPadding;
            }

            if (scrollAmount !== 0) {
              gridContainer.scrollBy({
                top: scrollAmount,
                behavior: "smooth",
              });
            }
          }

          const filterName = activeItem.dataset.filterName;
          if (selectedFilters[filterName]) {
            const popupButtons = activeItem.querySelectorAll(".popup__button");
            popupButtons.forEach((button) => {
              if (selectedFilters[filterName].includes(button.textContent.trim())) {
                button.classList.add("selected");
              } else {
                button.classList.remove("selected");
              }
            });
          }

          disableOtherItems(clickedItem);
        } else if (!e.target.closest(".popup--filter-item")) {
          closeActivePopup();
        }
      });

      function closeActivePopup() {
        if (activeItem) {
          activeItem.classList.remove("active");
          activeItem.querySelector(".popup").classList.remove("popup--active");
          activeItem = null;
          enableAllItems();
          if (filterGrid) {
            filterGrid.classList.remove("has-open-popup");
          }
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

      function updateFilterStatus(filterItem, filterName) {
        if (selectedFilters[filterName] && selectedFilters[filterName].length > 0) {
          filterItem.classList.add("is-selected");
        } else {
          filterItem.classList.remove("is-selected");
        }
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

      const filterBtn = document.getElementById("filter-toggle-btn");
      const modalOverlay = document.querySelector(".filter-modal-overlay");
      const filterWrapper = modalOverlay?.querySelector(".filter-wrapper");
      const rollupBtn = filterWrapper?.querySelector(".rollup");
      const resetBtn = document.querySelector(".filter-footer .reset button");

      document.addEventListener("click", (e) => {
        if (e.target.closest("#filter-modal-close")) {
          closeModal();
        }
      });

      if (filterBtn && modalOverlay && filterWrapper) {
        filterBtn.addEventListener("click", () => {
          modalOverlay.classList.add("modal--active");
          document.body.classList.add("modal-open");

          // Add this block to find the widget and hide it
          const widgetWrapper = document.querySelector(".b24-widget-button-wrapper");
          if (widgetWrapper) {
            widgetWrapper.classList.add("hide-on-modal");
          }
        });

        rollupBtn?.addEventListener("click", closeModal);

        modalOverlay.addEventListener("mousedown", (e) => {
          const wrapper = modalOverlay.querySelector(".filter-wrapper");
          const isClickOutside = !wrapper.contains(e.target);
          if (isClickOutside) {
            closeModal();
          }
        });

        resetBtn?.addEventListener("click", () => {
          for (const filterName in selectedFilters) {
            selectedFilters[filterName] = [];
          }
          document.querySelectorAll(".filter-item.is-selected").forEach((el) => el.classList.remove("is-selected"));
          document.querySelectorAll(".popup__button.selected").forEach((el) => el.classList.remove("selected"));
          applyFilter();
        });
      }

      function closeModal() {
        modalOverlay.classList.remove("modal--active");
        document.body.classList.remove("modal-open");
        closeActivePopup();

        document.body.style.pointerEvents = "none";
        setTimeout(() => {
          document.body.style.pointerEvents = "";
        }, 250);

        // Add this block to find the widget and show it again
        const widgetWrapper = document.querySelector(".b24-widget-button-wrapper");
        if (widgetWrapper) {
          widgetWrapper.classList.remove("hide-on-modal");
        }
      }

      const mainBot = document.querySelector(".main-bot .estates");
      const showBtn = document.querySelector(".filter-footer .show button");

      const applyFilter = () => {
        const active = Object.entries(selectedFilters).filter(([, val]) => val.length > 0);
        const filtered = mockEstates.filter((estate) =>
          active.every(([name, selected]) => {
            const estateVals = estate.filters[name] || [];
            return selected.some((v) => estateVals.includes(v));
          })
        );
        paginateAndRender(filtered, renderEstates);
        if (showBtn) showBtn.textContent = `Выбрано ${filtered.length} ЖК`;
        if (filtered.length === 0) {
          if (mainBot) {
            mainBot.innerHTML = `
                                    <div class="no-results" style="
                                    display: flex; 
                                    flex-direction: column; 
                                    align-items: center; 
                                    justify-content: center; 
                                    padding: 20px 20px 40px 20px; 
                                    color: #555; 
                                    font-family: Arial, sans-serif;
                                    text-align: center;
                                    gap: 16px;
                                    box-shadow: 0px 1px 5px rgba(0, 0, 0, 0.15);
                                    border-radius: 20px;
                                    background-color: #ffffff;
                                    color: #262626;
                                  ">
                                    <img 
                                      src="https://statics.dmclk.ru/web-ui-library/illustrations/png/Box-180.png" 
                                      alt="Пустая коробка" 
                                      width="180" height="180"
                                      style="object-fit: contain;"
                                    >
                                    <div style="font-size: 1.6rem; font-weight: 600;">Поиск не дал результатов</div>
                                    <div style="font-size: 1rem; line-height: 1.4;">
                                      Попробуйте изменить критерии поиска или свяжитесь с нами
                                    </div>
                                  </div>
`;
          }
        } else {
          paginateAndRender(filtered, renderEstates);
        }
      };

      const renderEstates = (estates, append = false) => {
        if (!mainBot) return;
        if (!append) mainBot.innerHTML = "";
        estates.forEach((estate) => {
          const imageCount = 5;
          const images = Array.from({ length: imageCount }, (_, i) => `/projects/home/nginx/frontend/public/images/estates/${estate.id}/${i + 1}.jpg`);

          const div = document.createElement("div");
          div.classList.add("item", "box-shadow");

          const description = descriptions[estate.id] || "";

          const formattedDescription = description.replace(/\r?\n/g, "<br>");

          div.innerHTML = `
        <div class="images">
          <div class="gallery">
              <img src="${images[0]}" />
              <button class="nav-area nav-area-prev" aria-label="Показать предыдущее изображение">
                  <div class="show-on-hover">
                      <div class="icon">
                          <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="none"><path fill="currentColor" fill-rule="evenodd" d="M4.91 8.59a.833.833 0 0 1 0-1.18l5-5a.833.833 0 1 1 1.18 1.18L6.678 8l4.41 4.41a.833.833 0 1 1-1.178 1.18l-5-5Z" clip-rule="evenodd"></path></svg>
                      </div>
                  </div>
              </button>
              <button class="nav-area nav-area-next" aria-label="Показать следующее изображение">
                  <div class="show-on-hover">
                      <div class="icon">
                          <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="none"><path fill="currentColor" fill-rule="evenodd" d="M11.09 8.59a.833.833 0 0 0 0-1.18l-5-5a.833.833 0 1 0-1.18 1.18L9.322 8l-4.41 4.41a.833.833 0 1 0 1.178 1.18l5-5Z" clip-rule="evenodd"></path></svg>
                      </div>
                  </div>
              </button>
          </div>
          <div class="counter">
              <span class="text">1 из ${images.length}</span>
              <span class="button button-active"></span>
              <span class="button"></span>
              <span class="button"></span>
          </div>
        </div>
        <div class="definition">
          <header>ЖК # ${estate.id}</header>
          <div class="description">${formattedDescription}</div>
          <button>Узнать ЖК</button>
        </div>
      `;
          mainBot.appendChild(div);

          const gallery = div.querySelector(".gallery");
          if (gallery) {
            const imgElement = gallery.querySelector("img");
            const counterTextElement = div.querySelector(".counter .text");
            const prevButton = gallery.querySelector(".nav-area-prev");
            const nextButton = gallery.querySelector(".nav-area-next");
            const dotButtons = div.querySelectorAll(".counter .button");
            let currentImageIndex = 0;

            const updateGallery = () => {
              // Логика для 3-х точек
              dotButtons.forEach((btn) => btn.classList.remove("button-active"));

              if (currentImageIndex === 0) {
                // Первое фото, активна первая точка
                dotButtons[0].classList.add("button-active");
              } else if (currentImageIndex === images.length - 1) {
                // Последнее фото, активна последняя точка
                dotButtons[2].classList.add("button-active");
              } else {
                // Все остальные фото, активна средняя точка
                dotButtons[1].classList.add("button-active");
              }

              imgElement.src = images[currentImageIndex] || "";
              counterTextElement.textContent = `${currentImageIndex + 1} из ${images.length}`;
            };

            prevButton.addEventListener("click", () => {
              currentImageIndex = (currentImageIndex - 1 + images.length) % images.length;
              updateGallery();
            });

            nextButton.addEventListener("click", () => {
              currentImageIndex = (currentImageIndex + 1) % images.length;
              updateGallery();
            });
          }
        });
      };

      paginateAndRender(mockEstates, renderEstates);

      // inject call inside your existing toggleSelectedOption
      const originalToggle = toggleSelectedOption;
      toggleSelectedOption = function (...args) {
        originalToggle(...args);
        applyFilter();
      };

      // also update reset button (already present)
      resetBtn?.addEventListener("click", () => {
        for (const filterName in selectedFilters) selectedFilters[filterName] = [];
        document.querySelectorAll(".filter-item.is-selected").forEach((el) => el.classList.remove("is-selected"));
        document.querySelectorAll(".popup__button.selected").forEach((el) => el.classList.remove("selected"));
        applyFilter();
      });

      document.addEventListener("click", (e) => {
        if (e.target.closest("#show-choosed-estates")) {
          console.log("Delegated show-click triggered");
          closeModal();
        }
      });
    })
    .catch((error) => {
      console.error("Error fetching CSV files:", error);
    });
});
