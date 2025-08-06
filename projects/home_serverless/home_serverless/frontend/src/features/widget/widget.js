document.addEventListener("DOMContentLoaded", function () {
  // Select the main elements of the widget
  const widgetWrapper = document.querySelector(".b24-widget-button-wrapper");
  const socialLinksContainer = widgetWrapper.querySelector(".b24-widget-button-social");
  const toggleButton = widgetWrapper.querySelector("[data-b24-crm-button-block-button]");

  // Select the filter modal element
  const filterModal = document.querySelector(".filter-modal-overlay");

  // Иконки внутри кнопки
  const mainIcons = toggleButton.querySelectorAll(".b24-widget-button-icon-container .b24-widget-button-inner-item");
  const closeIcon = toggleButton.querySelector(".b24-widget-button-close");

  // Функция для переключения состояния виджета
  function toggleWidget() {
    const isVisible = socialLinksContainer.classList.contains("b24-widget-button-show");

    if (isVisible) {
      // Если меню видимо, скрываем его
      socialLinksContainer.classList.remove("b24-widget-button-show");
      socialLinksContainer.classList.add("b24-widget-button-hide");

      // Показываем основные иконки, скрываем иконку "закрыть"
      mainIcons.forEach((icon) => (icon.style.opacity = "1"));
      closeIcon.style.opacity = "0";

      // Скрываем затемнение
      const shadow = document.querySelector(".b24-widget-button-shadow");
      if (shadow) {
        shadow.classList.remove("b24-widget-button-show");
        shadow.classList.add("b24-widget-button-hide");
        // Удаляем обработчик, чтобы не было лишних событий
        shadow.removeEventListener("click", toggleWidget);
      }
    } else {
      // Если меню скрыто, показываем его
      socialLinksContainer.classList.remove("b24-widget-button-hide");
      socialLinksContainer.classList.add("b24-widget-button-show");

      // Скрываем основные иконки, показываем иконку "закрыть"
      mainIcons.forEach((icon) => (icon.style.opacity = "0"));
      closeIcon.style.opacity = "1";

      // Показываем затемнение
      let shadow = document.querySelector(".b24-widget-button-shadow");
      if (!shadow) {
        // Если элемента затемнения нет в DOM, создаём его
        shadow = document.createElement("div");
        shadow.className = "b24-widget-button-shadow b24-widget-button-hide";
        document.body.appendChild(shadow);
      }
      shadow.classList.remove("b24-widget-button-hide");
      shadow.classList.add("b24-widget-button-show");

      // Добавляем обработчик для закрытия по клику на затемнение
      shadow.addEventListener("click", toggleWidget);
    }
  }

  // Добавляем обработчик клика на главную кнопку
  if (toggleButton) {
    toggleButton.addEventListener("click", toggleWidget);
  }

  // Добавляем обработчик для закрытия по нажатию "Escape"
  document.addEventListener("keydown", function (event) {
    if (event.key === "Escape") {
      const isVisible = socialLinksContainer.classList.contains("b24-widget-button-show");
      if (isVisible) {
        toggleWidget();
      }
    }
  });

  // ***** КРИТИЧЕСКОЕ ИЗМЕНЕНИЕ *****
  // Устанавливаем начальное состояние виджета при загрузке страницы.
  // Это гарантирует, что иконка звонка видна сразу.
  // Мы используем тот же метод, что и в функции toggleWidget
  const mainIcon = toggleButton.querySelector("[data-b24-crm-button-icon='callback']");
  if (mainIcon) {
    mainIcon.style.opacity = "1";
  }
  if (closeIcon) {
    closeIcon.style.opacity = "0";
  }
  // ***********************************

  setTimeout(function () {
    const widgetWrapper = document.querySelector(".b24-widget-button-wrapper");
    if (widgetWrapper) {
      widgetWrapper.classList.add("b24-widget-button-visible");
    }
  }, 1000);
});
