window.onload = () => {
  document.body.style.visibility = "visible";
};

const trigger = document.getElementById("consultation-trigger");
const popup = document.getElementById("consultation-popup");
const closeBtn = document.getElementById("popup-close");

let hideTimeout;

if (trigger && popup) {
  const showPopup = () => {
    clearTimeout(hideTimeout);
    popup.style.display = "block";
    const rect = trigger.getBoundingClientRect();
    popup.style.top = rect.bottom + 10 + "px";
    popup.style.left = rect.left + "px";
  };

  const hidePopup = () => {
    hideTimeout = setTimeout(() => {
      popup.style.display = "none";
    }, 220); // задержка, чтобы успеть попасть на popup
  };

  trigger.addEventListener("mouseenter", showPopup);
  trigger.addEventListener("mouseleave", hidePopup);

  popup.addEventListener("mouseenter", () => {
    clearTimeout(hideTimeout);
    popup.style.display = "block";
  });
  popup.addEventListener("mouseleave", hidePopup);

  // ✅ Close popup when clicking the close button
  if (closeBtn) {
    closeBtn.addEventListener("click", () => {
      popup.style.display = "none";
    });
  }
}
