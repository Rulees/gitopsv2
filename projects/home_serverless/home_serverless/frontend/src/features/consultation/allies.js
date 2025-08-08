// window.onload = () => {
//   document.body.style.visibility = "visible";

//   const trigger = document.getElementById("trigger-popup-allies");
//   const popup = document.getElementById("popup-allies");
//   const closeBtnSvg = document.querySelector("#popup-allies-close svg");

//   let hideTimeout;

//   if (trigger && popup) {
//     const showPopup = () => {
//       clearTimeout(hideTimeout);
//       popup.classList.add("popup--active");
//       const rect = trigger.getBoundingClientRect();
//       popup.style.top = rect.bottom + -0 + "px";
//       popup.style.left = rect.left + "px";
//     };

//     const hidePopup = () => {
//       hideTimeout = setTimeout(() => {
//         popup.classList.remove("popup--active");
//       }, 220);
//     };

//     trigger.addEventListener("mouseenter", showPopup);
//     trigger.addEventListener("mouseleave", hidePopup);

//     popup.addEventListener("mouseenter", () => {
//       clearTimeout(hideTimeout);
//       popup.classList.add("popup--active");
//     });
//     popup.addEventListener("mouseleave", hidePopup);

//     if (closeBtnSvg) {
//       closeBtnSvg.addEventListener("click", () => {
//         popup.classList.remove("popup--active");
//       });
//     }
//   }
// };

// document.addEventListener("contextmenu", function (e) {
//   if (e.target.tagName === "IMG") {
//     e.preventDefault();
//   }
// });
