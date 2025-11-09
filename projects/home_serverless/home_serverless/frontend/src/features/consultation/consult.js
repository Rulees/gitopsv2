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

  if (closeBtnSvg) {
    closeBtnSvg.addEventListener("click", () => {
      popup.classList.remove("popup--active");
    });
  }
}
