window.onload = () => {
  document.body.style.visibility = "visible";

  const trigger = document.getElementById("trigger-popup-consultation");
  const popup = document.getElementById("popup-consultation");
  const closeBtnSvg = document.querySelector("#popup-consultation-close svg");

  let hideTimeout;

  if (trigger && popup) {
    const showPopup = () => {
      clearTimeout(hideTimeout);
      popup.classList.add("popup--active");
      const rect = trigger.getBoundingClientRect();
      popup.style.top = rect.bottom + -0 + "px";
      popup.style.left = rect.left + "px";
    };

    const hidePopup = () => {
      hideTimeout = setTimeout(() => {
        popup.classList.remove("popup--active");
      }, 220);
    };

    trigger.addEventListener("mouseenter", showPopup);
    trigger.addEventListener("mouseleave", hidePopup);

    popup.addEventListener("mouseenter", () => {
      clearTimeout(hideTimeout);
      popup.classList.add("popup--active");
    });
    popup.addEventListener("mouseleave", hidePopup);

    // ✅ Close popup when clicking the close button
    if (closeBtnSvg) {
      closeBtnSvg.addEventListener("click", () => {
        popup.classList.remove("popup--active");
      });
    }
  }

  //   // ✅ Фильтры: показать/скрыть
  //   const filterBtn = document.getElementById("filter-toggle-btn");
  //   const modalOverlay = document.querySelector(".filter-modal-overlay");
  //   const filterWrapper = modalOverlay?.querySelector(".filter-wrapper");
  //   const rollupBtn = filterWrapper?.querySelector(".rollup");

  //   if (filterBtn && modalOverlay && filterWrapper) {
  //     // Show modal + overlay
  //     filterBtn.addEventListener("click", () => {
  //       modalOverlay.style.display = "flex"; // Show overlay as flex (centered)
  //       document.body.classList.add("modal-open"); // ✅ Lock background scroll
  //     });

  //     // Close modal on rollup button click
  //     rollupBtn?.addEventListener("click", () => {
  //       modalOverlay.style.display = "none";
  //       document.body.classList.remove("modal-open"); // ✅ Unlock scroll
  //     });

  //     // Close modal when clicking outside modal content (on overlay)
  //     modalOverlay.addEventListener("click", (e) => {
  //       if (e.target === modalOverlay) {
  //         modalOverlay.style.display = "none";
  //         document.body.classList.remove("modal-open");
  //       }
  //     });

  //     document.addEventListener("keydown", (e) => {
  //       if (e.key === "Escape") {
  //         modalOverlay.style.display = "none";
  //         document.body.classList.remove("modal-open");
  //       }
  //     });
  //   }
};

// document.querySelectorAll(".filter-item").forEach((item) => {
//   // Пропускаем, если уже есть <svg> внутри
//   if (item.querySelector("svg")) return;

//   // Создаём <p> и переносим текст туда, если его нет
//   let contentText = item.textContent.trim();
//   item.textContent = ""; // Очищаем старый текст

//   const p = document.createElement("p");
//   p.textContent = contentText;

//   // Создаём SVG use
//   const svg = document.createElementNS("http://www.w3.org/2000/svg", "svg");
//   svg.classList.add("icon-info");
//   const use = document.createElementNS("http://www.w3.org/2000/svg", "use");
//   use.setAttributeNS("http://www.w3.org/1999/xlink", "xlink:href", "#icon-info");
//   svg.appendChild(use);

//   // Добавляем в DOM
//   item.appendChild(p);
//   item.appendChild(svg);
// });

document.addEventListener("contextmenu", function (e) {
  if (e.target.tagName === "IMG") {
    e.preventDefault();
  }
});
