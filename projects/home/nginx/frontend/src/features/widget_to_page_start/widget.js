const button = document.querySelector(".scroll-to-top-btn");
const scrollThreshold = 2500; // Порог прокрутки в пикселях

// Функция, которая определяет, когда показывать кнопку
function toggleButtonVisibility() {
  // Если прокрутка больше заданного порога, показываем кнопку
  if (window.scrollY > scrollThreshold) {
    button.classList.remove("hidden");
  } else {
    button.classList.add("hidden");
  }
}

// Слушаем событие прокрутки
window.addEventListener("scroll", toggleButtonVisibility);

// Добавляем обработчик клика для прокрутки наверх
button.addEventListener("click", () => {
  window.scrollTo({
    top: 0,
    behavior: "smooth",
  });
});

// Вызываем функцию при загрузке страницы, чтобы проверить начальное положение
toggleButtonVisibility();
