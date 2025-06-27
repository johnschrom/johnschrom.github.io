---
layout: page
title: Portfolio
permalink: /portfolio/
description: Below are details on a few of the larger projects I've worked on.
nav: false
nav_order: 2
display_categories: [work, fun]
horizontal: true
---

<div class="projects">
{% assign sorted_projects = site.projects | sort: "importance" %}

{% if page.horizontal %}
  <div class="container">
    <div class="row row-cols-1 row-cols-md-12">
    {% for project in sorted_projects %}
      {% include projects_horizontal.liquid %}
    {% endfor %}
    </div>
  </div>
  {% else %}
  <div class="row row-cols-1 row-cols-md-3">
    {% for project in sorted_projects %}
      {% include projects.liquid %}
    {% endfor %}
  </div>
  {% endif %}
</div>