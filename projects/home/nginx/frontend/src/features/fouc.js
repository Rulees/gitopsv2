window.onload = () => {
  document.body.style.visibility = "visible";
};

document.addEventListener("contextmenu", function (e) {
  if (e.target.tagName === "IMG") {
    e.preventDefault();
  }
});
