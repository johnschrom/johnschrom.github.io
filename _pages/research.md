---
layout: page
permalink: /research/
title: Research
description: Below are research products, including journal articles, oral presentations, and poster presentations, that I have been involved with, arranged in reverse chronological order. All items listed here were either peer reviewed or invited. Use the search box below to filter articles by type (article, oral, poster), co-author, title, or abstract.
nav: true
nav_order: 1
---

<!-- _pages/publications.md -->

<!-- Bibsearch Feature -->

Below are research products, including journal articles, oral presentations, and poster presentations, that I have been involved with, arranged in reverse chronological order. All items listed here were either peer reviewed or invited. Use the search box below to filter articles by type (article, oral, poster), co-author, title, or abstract.

{% include bib_search.liquid %}

<div class="publications">

{% bibliography %}

</div>

<script>
document.addEventListener('DOMContentLoaded', function() {
  // Helper function to track events in Umami
  function trackEvent(eventName, eventData = {}) {
    if (typeof umami !== 'undefined') {
      umami.track(eventName, eventData);
    }
  }

  // Count total publications on page load
  const publicationCount = document.querySelectorAll('.bibliography > li').length;
  
  // Track research page load
  trackEvent('res-page-load', {
    totalPublications: publicationCount
  });
});
</script>
