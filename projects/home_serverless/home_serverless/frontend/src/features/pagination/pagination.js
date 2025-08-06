(() => {
  const ESTATES_PER_PAGE = 10;
  let currentPage = 1;
  let totalPages = 1;
  let fullEstateList = [];
  let renderFn = null;
  let shouldScrollToTop = false;

  function paginateAndRender(estates, renderEstates) {
    fullEstateList = estates;
    renderFn = renderEstates;
    totalPages = Math.ceil(estates.length / ESTATES_PER_PAGE);

    // Get a reference to the pagination container
    const paginationContainer = document.querySelector(".pgnt-visible");

    // Conditionally show/hide the entire pagination container
    if (totalPages <= 1) {
      if (paginationContainer) {
        paginationContainer.style.display = "none";
      }
    } else {
      if (paginationContainer) {
        paginationContainer.style.display = "";
      }
    }

    if (currentPage < 1 || currentPage > totalPages) {
      currentPage = 1;
    }

    const start = (currentPage - 1) * ESTATES_PER_PAGE;
    const visibleEstates = estates.slice(start, start + ESTATES_PER_PAGE);

    renderEstates(visibleEstates);

    if (shouldScrollToTop) {
      window.scrollTo(0, 0);
      shouldScrollToTop = false;
    }

    // Only render the pagination controls if there is more than one page
    if (totalPages > 1) {
      renderPaginationControls(totalPages, (pageNum) => {
        currentPage = pageNum;
        shouldScrollToTop = true;
        paginateAndRender(fullEstateList, renderFn);
      });
    }

    updateShowMoreVisibility();
  }

  function renderPaginationControls(totalPages, onPageChange) {
    const paginationList = document.querySelector(".pgnt__list");
    const prevBtn = document.querySelector(".pgnt__prev-page");
    const nextBtn = document.querySelector(".pgnt__next-page");

    if (!paginationList || !prevBtn || !nextBtn) return;

    paginationList.innerHTML = "";

    for (let i = 1; i <= totalPages; i++) {
      const btn = document.createElement("button");
      btn.classList.add("pgnt-item");
      btn.textContent = i;
      if (i === currentPage) btn.classList.add("active");

      btn.addEventListener("click", () => {
        shouldScrollToTop = true;
        onPageChange(i);
      });

      const li = document.createElement("li");
      li.appendChild(btn);
      paginationList.appendChild(li);
    }

    prevBtn.onclick = () => {
      if (currentPage > 1) {
        shouldScrollToTop = true;
        onPageChange(currentPage - 1);
      }
    };

    nextBtn.onclick = () => {
      if (currentPage < totalPages) {
        shouldScrollToTop = true;
        onPageChange(currentPage + 1);
      }
    };

    if (currentPage === 1) {
      prevBtn.classList.add("disabled");
    } else {
      prevBtn.classList.remove("disabled");
    }

    if (currentPage === totalPages) {
      nextBtn.classList.add("disabled");
    } else {
      nextBtn.classList.remove("disabled");
    }
  }

  function updateShowMoreVisibility() {
    const btn = document.getElementById("show-more-estates");
    if (!btn) return;
    btn.style.display = currentPage < totalPages ? "inline-block" : "none";
  }

  const showMoreBtn = document.getElementById("show-more-estates");
  if (showMoreBtn) {
    showMoreBtn.addEventListener("click", () => {
      if (!fullEstateList.length || !renderFn) return;

      currentPage++;
      const start = (currentPage - 1) * ESTATES_PER_PAGE;
      const visibleEstates = fullEstateList.slice(start, start + ESTATES_PER_PAGE);
      renderFn(visibleEstates, true);

      renderPaginationControls(totalPages, (pageNum) => {
        currentPage = pageNum;
        shouldScrollToTop = true;
        paginateAndRender(fullEstateList, renderFn);
      });

      updateShowMoreVisibility();
    });
  }

  window.paginateAndRender = paginateAndRender;
})();
