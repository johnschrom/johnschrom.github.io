import { highlightSearchTerm } from "./highlight-search-term.js";

document.addEventListener("DOMContentLoaded", function () {
  // Helper function to track events in Umami
  function trackEvent(eventName, eventData = {}) {
    if (typeof umami !== 'undefined') {
      umami.track(eventName, eventData);
    }
  }
  // actual bibsearch logic
  const filterItems = (searchTerm) => {
    document.querySelectorAll(".bibliography, .unloaded").forEach((element) => element.classList.remove("unloaded"));

    // highlight-search-term
    if (CSS.highlights) {
      const nonMatchingElements = highlightSearchTerm({ search: searchTerm, selector: ".bibliography > li" });
      if (nonMatchingElements == null) {
        return;
      }
      nonMatchingElements.forEach((element) => {
        element.classList.add("unloaded");
      });
    } else {
      // Simply add unloaded class to all non-matching items if Browser does not support CSS highlights
      document.querySelectorAll(".bibliography > li").forEach((element, index) => {
        const text = element.innerText.toLowerCase();
        if (text.indexOf(searchTerm) == -1) {
          element.classList.add("unloaded");
        }
      });
    }

    document.querySelectorAll("h2.bibliography").forEach(function (element) {
      let iterator = element.nextElementSibling; // get next sibling element after h2, which can be h3 or ol
      let hideFirstGroupingElement = true;
      // iterate until next group element (h2), which is already selected by the querySelectorAll(-).forEach(-)
      while (iterator && iterator.tagName !== "H2") {
        if (iterator.tagName === "OL") {
          const ol = iterator;
          const unloadedSiblings = ol.querySelectorAll(":scope > li.unloaded");
          const totalSiblings = ol.querySelectorAll(":scope > li");

          if (unloadedSiblings.length === totalSiblings.length) {
            ol.previousElementSibling.classList.add("unloaded"); // Add the '.unloaded' class to the previous grouping element (e.g. year)
            ol.classList.add("unloaded"); // Add the '.unloaded' class to the OL itself
          } else {
            hideFirstGroupingElement = false; // there is at least some visible entry, don't hide the first grouping element
          }
        }
        iterator = iterator.nextElementSibling;
      }
      // Add unloaded class to first grouping element (e.g. year) if no item left in this group
      if (hideFirstGroupingElement) {
        element.classList.add("unloaded");
      }
    });
  };

  const updateInputField = () => {
    const hashValue = decodeURIComponent(window.location.hash.substring(1)); // Remove the '#' character
    
    // Check if it's a direct article reference (starts with 'article:')
    if (hashValue.startsWith('article:')) {
      const articleKey = hashValue.substring(8); // Remove 'article:' prefix
      filterToSingleArticle(articleKey);
    } else {
      // Regular search functionality
      document.getElementById("bibsearch").value = hashValue;
      filterItems(hashValue);
    }
  };
  
  const filterToSingleArticle = (articleKey) => {
    // Find the specific article
    const articleElement = document.getElementById(articleKey);
    if (articleElement) {
      const articleLi = articleElement.closest('li');
      
      // Hide all articles except the target one
      document.querySelectorAll('.bibliography > li').forEach(li => {
        if (li === articleLi) {
          li.classList.remove('unloaded');
        } else {
          li.classList.add('unloaded');
        }
      });
      
      // Hide year headers that don't contain the target article
      document.querySelectorAll('h2.bibliography').forEach(function (element) {
        let iterator = element.nextElementSibling;
        let hasVisibleArticle = false;
        
        while (iterator && iterator.tagName !== "H2") {
          if (iterator.tagName === "OL") {
            const visibleSiblings = iterator.querySelectorAll(':scope > li:not(.unloaded)');
            if (visibleSiblings.length > 0) {
              hasVisibleArticle = true;
            }
          }
          iterator = iterator.nextElementSibling;
        }
        
        if (!hasVisibleArticle) {
          element.classList.add('unloaded');
        } else {
          element.classList.remove('unloaded');
        }
      });
      
      // Show clear filter button
      showClearFilterButton(articleKey);
      
      // Scroll to top of publications
      setTimeout(() => {
        document.querySelector('.publications').scrollIntoView({ 
          behavior: 'smooth', 
          block: 'start' 
        });
      }, 100);
      
      // Track direct article access
      const articleSlug = articleKey.replace(/[^a-zA-Z0-9]/g, '-').substring(0, 30);
      trackEvent(`art-link-${articleSlug}`, {
        articleKey: articleKey,
        articleTitle: articleElement.querySelector('.title')?.textContent || 'Unknown'
      });
    }
  };
  
  const showClearFilterButton = (articleKey) => {
    console.log('Showing clear filter button for:', articleKey);
    
    // Get the article title for display
    const articleElement = document.getElementById(articleKey);
    const articleTitle = articleElement ? 
      articleElement.querySelector('.title')?.textContent || articleKey : 
      articleKey;
    
    // Remove existing clear button
    const existingButton = document.getElementById('clear-article-filter');
    if (existingButton) {
      existingButton.remove();
    }
    
    // Create clear filter button
    const clearButton = document.createElement('div');
    clearButton.id = 'clear-article-filter';
    clearButton.innerHTML = `
      <div style="
        background: var(--global-bg-color);
        border: 2px solid var(--global-theme-color);
        color: var(--global-text-color);
        padding: 12px 15px;
        border-radius: 8px;
        margin: 10px 0;
        display: flex;
        align-items: center;
        justify-content: space-between;
        font-size: 14px;
        box-shadow: 0 2px 8px rgba(0,0,0,0.1);
        transition: all 0.2s ease;
      " onmouseover="this.style.boxShadow='0 4px 12px rgba(0,0,0,0.15)'" 
         onmouseout="this.style.boxShadow='0 2px 8px rgba(0,0,0,0.1)'">
        <div style="flex: 1;">
          <strong style="color: var(--global-theme-color);">Filtered to:</strong> 
          <span style="margin-left: 8px;">${articleTitle.length > 120 ? articleTitle.substring(0, 120) + '...' : articleTitle}</span>
        </div>
        <button style="
          background: none;
          border: none;
          color: var(--global-text-color-light);
          font-size: 18px;
          cursor: pointer;
          padding: 4px 8px;
          border-radius: 4px;
          transition: all 0.2s ease;
          margin-left: 15px;
        " onmouseover="this.style.background='var(--global-divider-color)'; this.style.color='var(--global-text-color)'" 
           onmouseout="this.style.background='none'; this.style.color='var(--global-text-color-light)'"
           title="Clear filter and show all publications">&times;</button>
      </div>
    `;
    
    // Insert after search box
    const searchInput = document.querySelector('#bibsearch');
    if (searchInput) {
      // Insert immediately after the search input
      searchInput.insertAdjacentElement('afterend', clearButton);
    } else {
      // Fallback: prepend to body if we can't find search
      document.body.insertBefore(clearButton, document.body.firstChild);
    }
    
    // Add click handlers
    const closeButton = clearButton.querySelector('button');
    const mainArea = clearButton.querySelector('div');
    
    // Click on X button
    closeButton.addEventListener('click', (e) => {
      e.stopPropagation();
      clearArticleFilter();
    });
    
    // Click on main area (but not the X button)
    mainArea.addEventListener('click', (e) => {
      if (e.target !== closeButton) {
        clearArticleFilter();
      }
    });
  };
  
  const clearArticleFilter = () => {
    // Clear the hash
    window.location.hash = '';
    
    // Show all articles
    document.querySelectorAll('.bibliography > li, h2.bibliography').forEach(el => {
      el.classList.remove('unloaded');
    });
    
    // Remove clear button
    const clearButton = document.getElementById('clear-article-filter');
    if (clearButton) {
      clearButton.remove();
    }
    
    // Clear search field
    document.getElementById("bibsearch").value = '';
    
    // Track filter clear
    trackEvent('art-clear');
  };

  // Sensitive search. Only start searching if there's been no input for 300 ms
  let timeoutId;
  document.getElementById("bibsearch").addEventListener("input", function () {
    clearTimeout(timeoutId); // Clear the previous timeout
    const searchTerm = this.value.toLowerCase();
    
    // If there's an article filter active and user starts typing, clear it
    const clearButton = document.getElementById('clear-article-filter');
    if (clearButton && searchTerm.trim().length > 0) {
      clearButton.remove();
      // Clear the hash but don't trigger hashchange event
      history.replaceState(null, null, window.location.pathname);
    }
    
    // Track search if search term is not empty
    if (searchTerm.trim().length > 0) {
      const searchSlug = searchTerm.replace(/[^a-zA-Z0-9]/g, '-').substring(0, 20);
      trackEvent(`search-${searchSlug}`, { 
        searchTerm: searchTerm.substring(0, 50) // Limit length for privacy 
      });
    }
    
    timeoutId = setTimeout(filterItems(searchTerm), 300);
  });

  window.addEventListener("hashchange", updateInputField); // Update the filter when the hash changes
  
  // Handle browser back/forward buttons and direct navigation
  window.addEventListener("hashchange", function() {
    // If hash is cleared or doesn't start with 'article:', remove any article filter button
    const hashValue = decodeURIComponent(window.location.hash.substring(1));
    if (!hashValue.startsWith('article:')) {
      const clearButton = document.getElementById('clear-article-filter');
      if (clearButton) {
        clearButton.remove();
      }
    }
  });

  updateInputField(); // Update filter when page loads
  
  // Set up impression tracking for publication items
  const observedPublications = new Set();
  const publicationObserver = new IntersectionObserver((entries) => {
    entries.forEach(entry => {
      if (entry.isIntersecting && entry.intersectionRatio > 0.5) {
        const publicationItem = entry.target;
        const publicationId = publicationItem.id;
        const titleElement = publicationItem.querySelector('.title');
        const publicationTitle = titleElement ? titleElement.textContent : 'Unknown';
        
        // Only track each publication impression once per session
        if (!observedPublications.has(publicationId)) {
          observedPublications.add(publicationId);
          
          const publicationSlug = publicationId.replace(/[^a-zA-Z0-9]/g, '-').substring(0, 30);
          trackEvent(`pub-view-${publicationSlug}`, {
            publicationId: publicationId,
            publicationTitle: publicationTitle.substring(0, 50), // Limit length for privacy
            pageUrl: window.location.pathname
          });
        }
      }
    });
  }, {
    threshold: 0.5, // Trigger when 50% of the publication is visible
    rootMargin: '0px'
  });
  
  // Observe all publication items
  document.querySelectorAll('.bibliography > li').forEach(publicationItem => {
    // Only observe items that have an ID (not all li items might)
    if (publicationItem.id) {
      publicationObserver.observe(publicationItem);
    }
  });
});
