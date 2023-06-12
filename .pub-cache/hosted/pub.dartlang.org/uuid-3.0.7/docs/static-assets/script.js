/*
 *
 *  Update script.js versions in all lib/templates when modifying this file!
 *
 */
function initSideNav() {
  const leftNavToggle = document.getElementById('sidenav-left-toggle');
  const leftDrawer = document.querySelector('.sidebar-offcanvas-left');
  const overlay = document.getElementById('overlay-under-drawer');

  function toggleBoth() {
    if (leftDrawer) {
      leftDrawer.classList.toggle('active');
    }

    if (overlay) {
      overlay.classList.toggle('active');
    }
  }

  if (overlay) {
    overlay.addEventListener('click', toggleBoth);
  }

  if (leftNavToggle) {
    leftNavToggle.addEventListener('click', toggleBoth);
  }
}

function saveLeftScroll() {
  const leftSidebar = document.getElementById('dartdoc-sidebar-left');
  sessionStorage.setItem('dartdoc-sidebar-left-scrollt' + window.location.pathname, leftSidebar.scrollTop.toString());
  sessionStorage.setItem('dartdoc-sidebar-left-scrolll' + window.location.pathname, leftSidebar.scrollLeft.toString());
}

function saveMainContentScroll() {
  const mainContent = document.getElementById('dartdoc-main-content');
  sessionStorage.setItem('dartdoc-main-content-scrollt' + window.location.pathname, mainContent.scrollTop.toString());
  sessionStorage.setItem('dartdoc-main-content-scrolll' + window.location.pathname, mainContent.scrollLeft.toString());
}

function saveRightScroll() {
  const rightSidebar = document.getElementById('dartdoc-sidebar-right');
  sessionStorage.setItem('dartdoc-sidebar-right-scrollt' + window.location.pathname, rightSidebar.scrollTop.toString());
  sessionStorage.setItem('dartdoc-sidebar-right-scrolll' + window.location.pathname, rightSidebar.scrollLeft.toString());
}

function restoreScrolls() {
  const leftSidebar = document.getElementById('dartdoc-sidebar-left');
  const mainContent = document.getElementById('dartdoc-main-content');
  const rightSidebar = document.getElementById('dartdoc-sidebar-right');

  try {
    const leftSidebarX = sessionStorage.getItem('dartdoc-sidebar-left-scrolll' + window.location.pathname);
    const leftSidebarY = sessionStorage.getItem('dartdoc-sidebar-left-scrollt' + window.location.pathname);

    const mainContentX = sessionStorage.getItem('dartdoc-main-content-scrolll' + window.location.pathname);
    const mainContentY = sessionStorage.getItem('dartdoc-main-content-scrollt' + window.location.pathname);

    const rightSidebarX = sessionStorage.getItem('dartdoc-sidebar-right-scrolll' + window.location.pathname);
    const rightSidebarY = sessionStorage.getItem('dartdoc-sidebar-right-scrollt' + window.location.pathname);

    leftSidebar.scrollTo(parseFloat(leftSidebarX), parseFloat(leftSidebarY));
    mainContent.scrollTo(parseFloat(mainContentX), parseFloat(mainContentY));
    rightSidebar.scrollTo(parseFloat(rightSidebarX), parseFloat(rightSidebarY));
  } finally {
    // Set visibility to visible after scroll to prevent the brief appearance of the
    // panel in the wrong position.
    leftSidebar.style.visibility = 'visible';
    mainContent.style.visibility = 'visible';
    rightSidebar.style.visibility = 'visible';
  }
}

function initScrollSave() {
  const leftSidebar = document.getElementById('dartdoc-sidebar-left');
  const mainContent = document.getElementById('dartdoc-main-content');
  const rightSidebar = document.getElementById('dartdoc-sidebar-right');

  leftSidebar.addEventListener("scroll", saveLeftScroll, true);
  mainContent.addEventListener("scroll", saveMainContentScroll, true);
  rightSidebar.addEventListener("scroll", saveRightScroll, true);
}

const weights = {
  'library' : 2,
  'class' : 2,
  'mixin' : 3,
  'extension' : 3,
  'typedef' : 3,
  'method' : 4,
  'accessor' : 4,
  'operator' : 4,
  'constant' : 4,
  'property' : 4,
  'constructor' : 4
};

function findMatches(index, query) {
  if (query === '') {
    return [];
  }

  const allMatches = [];

  index.forEach(element => {
    function score(value) {
      value -= element.overriddenDepth * 10;
      const weightFactor = weights[element.type] || 4;
      allMatches.push({element: element, score: (value / weightFactor) >> 0});
    }

    const name = element.name;
    const qualifiedName = element.qualifiedName;
    const lowerName = name.toLowerCase();
    const lowerQualifiedName = qualifiedName.toLowerCase();
    const lowerQuery = query.toLowerCase();

    if (name === query || qualifiedName === query || name === `dart:${query}`) {
      score(2000);
    } else if (lowerName === `dart:${lowerQuery}`) {
      score(1800);
    } else if (lowerName === lowerQuery || lowerQualifiedName === lowerQuery) {
      score(1700);
    } else if (query.length > 1) {
      if (name.startsWith(query) || qualifiedName.startsWith(query)) {
        score(750);
      } else if (lowerName.startsWith(lowerQuery) || lowerQualifiedName.startsWith(lowerQuery)) {
        score(650);
      } else if (name.includes(query) || qualifiedName.includes(query)) {
        score(500);
      } else if (lowerName.includes(lowerQuery) || lowerQualifiedName.includes(query)) {
        score(400);
      }
    }
  });

  allMatches.sort((a, b) => {
    const x = b.score - a.score;
    if (x === 0) {
      return a.element.name.length - b.element.name.length;
    }
    return x;
  });

  const justElements = [];

  for (let i = 0; i < allMatches.length; i++) {
    justElements.push(allMatches[i].element);
  }

  return justElements;
}

let baseHref = '';

const minLength = 1;
const suggestionLimit = 10;

function initializeSearch(input, index) {
  input.disabled = false;
  input.setAttribute('placeholder', 'Search API Docs');

  // Handle grabbing focus when the users types / outside of the input
  document.addEventListener('keypress', (event) => {
    if (event.code === 'Slash' && !(document.activeElement instanceof HTMLInputElement)) {
      event.preventDefault();
      input.focus();
    }
  });

  // Prepare elements

  const parentForm = input.parentNode;
  const wrapper = document.createElement('div');
  wrapper.classList.add('tt-wrapper');

  parentForm.replaceChild(wrapper, input);

  const inputHint = document.createElement('input');
  inputHint.setAttribute('type', 'text');
  inputHint.setAttribute('autocomplete', 'off');
  inputHint.setAttribute('readonly', 'true');
  inputHint.setAttribute('spellcheck', 'false');
  inputHint.setAttribute('tabindex', '-1');
  inputHint.classList.add('typeahead', 'tt-hint');

  wrapper.appendChild(inputHint);

  input.setAttribute('autocomplete', 'off');
  input.setAttribute('spellcheck', 'false');
  input.classList.add('tt-input');

  wrapper.appendChild(input);

  const listBox = document.createElement('div');
  listBox.setAttribute('role', 'listbox');
  listBox.setAttribute('aria-expanded', 'false');
  listBox.style.display = 'none';
  listBox.classList.add('tt-menu');

  const presentation = document.createElement('div');
  presentation.classList.add('tt-elements');

  listBox.appendChild(presentation);

  wrapper.appendChild(listBox);

  // Set up various search functionality

  function highlight(text, query) {
    query = query.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
    return text.replace(new RegExp(query, 'gi'), (matched) => {
      return `<strong class='tt-highlight'>${matched}</strong>`;
    });
  }

  function createSuggestion(query, match) {
    const suggestion = document.createElement('div');
    suggestion.setAttribute('data-href', match.href);
    suggestion.classList.add('tt-suggestion');

    const suggestionTitle = document.createElement('span');
    suggestionTitle.classList.add('tt-suggestion-title');
    suggestionTitle.innerHTML = highlight(`${match.name} ${match.type.toLowerCase()}`, query);

    suggestion.appendChild(suggestionTitle);

    if (match.enclosedBy) {
      const fromLib = document.createElement('div');
      fromLib.classList.add('search-from-lib');
      fromLib.innerHTML = `from ${highlight(match.enclosedBy.name, query)}`;

      suggestion.appendChild(fromLib);
    }

    suggestion.addEventListener('mousedown', event => {
      event.preventDefault();
    });

    suggestion.addEventListener('click', event => {
      if (match.href) {
        window.location = baseHref + match.href;
        event.preventDefault();
      }
    });

    return suggestion;
  }

  let storedValue = null;
  let actualValue = '';
  let hint = null;

  let suggestionElements = [];
  let suggestionsInfo = [];
  let selectedElement = null;

  function setHint(value) {
    hint = value;
    inputHint.value = value || '';
  }

  function updateSuggestions(query, suggestions) {
    suggestionsInfo = [];
    suggestionElements = [];
    presentation.textContent = '';

    if (suggestions.length < minLength) {
      setHint(null)
      hideSuggestions();
      return;
    }

    for (let i = 0; i < suggestions.length; i++) {
      const element = createSuggestion(query, suggestions[i]);
      suggestionElements.push(element);
      presentation.appendChild(element);
    }

    suggestionsInfo = suggestions;

    setHint(query + suggestions[0].name.slice(query.length));
    selectedElement = null;

    showSuggestions();
  }

  function handle(newValue, forceUpdate) {
    if (actualValue === newValue && !forceUpdate) {
      return;
    }

    if (newValue === null || newValue.length === 0) {
      updateSuggestions('', []);
      return;
    }

    const suggestions = findMatches(index, newValue).slice(0, suggestionLimit);
    actualValue = newValue;

    updateSuggestions(newValue, suggestions);
  }

  function showSuggestions() {
    if (presentation.hasChildNodes()) {
      listBox.style.display = 'block';
      listBox.setAttribute('aria-expanded', 'true');
    }
  }

  function hideSuggestions() {
    listBox.style.display = 'none';
    listBox.setAttribute('aria-expanded', 'false');
  }

  // Hook up events

  input.addEventListener('focus', () => {
    handle(input.value, true);
  });

  input.addEventListener('blur', () => {
    selectedElement = null;
    if (storedValue !== null) {
      input.value = storedValue;
      storedValue = null;
    }
    hideSuggestions();
    setHint(null);
  });

  input.addEventListener('input', event => {
    handle(event.target.value);
  });

  input.addEventListener('keydown', event => {
    if (suggestionElements.length === 0) {
      return;
    }

    if (event.code === 'Enter') {
      const selectingElement = selectedElement || 0;
      const href = suggestionElements[selectingElement].dataset.href;
      if (href) {
        window.location = baseHref + href;
      }
      return;
    }

    if (event.code === 'Tab') {
      if (selectedElement === null) {
        // The user wants to fill the field with the hint
        if (hint !== null) {
          input.value = hint;
          handle(hint);
          event.preventDefault();
        }
      } else {
        // The user wants to fill the input field with their currently selected suggestion
        handle(suggestionsInfo[selectedElement].name);
        storedValue = null;
        selectedElement = null;
        event.preventDefault();
      }
      return;
    }

    const lastIndex = suggestionElements.length - 1;
    const previousSelectedElement = selectedElement;

    if (event.code === 'ArrowUp') {
      if (selectedElement === null) {
        selectedElement = lastIndex;
      } else if (selectedElement === 0) {
        selectedElement = null;
      } else {
        selectedElement--;
      }
    } else if (event.code === 'ArrowDown') {
      if (selectedElement === null) {
        selectedElement = 0;
      } else if (selectedElement === lastIndex) {
        selectedElement = null;
      } else {
        selectedElement++;
      }
    } else {
      if (storedValue !== null) {
        storedValue = null;
        handle(input.value);
      }
      return;
    }

    if (previousSelectedElement !== null) {
      suggestionElements[previousSelectedElement].classList.remove('tt-cursor');
    }

    if (selectedElement !== null) {
      const selected = suggestionElements[selectedElement];
      selected.classList.add('tt-cursor');

      // Guarantee the selected element is visible
      if (selectedElement === 0) {
        listBox.scrollTop = 0;
      } else if (selectedElement === lastIndex) {
        listBox.scrollTop = listBox.scrollHeight;
      } else {
        const offsetTop = selected.offsetTop;
        const parentOffsetHeight = listBox.offsetHeight;
        if (offsetTop < parentOffsetHeight || parentOffsetHeight < (offsetTop + selected.offsetHeight)) {
          selected.scrollIntoView({behavior: 'auto', block: 'nearest'});
        }
      }

      if (storedValue === null) {
        // Store the actual input value to display their currently selected item
        storedValue = input.value;
      }
      input.value = suggestionsInfo[selectedElement].name;
      setHint('');
    } else if (storedValue !== null && previousSelectedElement !== null) {
      // They are moving back to the input field, so return the stored value
      input.value = storedValue;
      setHint(storedValue + suggestionsInfo[0].name.slice(storedValue.length));
      storedValue = null;
    }

    event.preventDefault();
  });
}

document.addEventListener('DOMContentLoaded', () => {
  // Place this first so that unexpected exceptions in other JavaScript do not block page visibility.
  restoreScrolls();
  hljs.highlightAll();
  initSideNav();
  initScrollSave();

  const searchBox = document.getElementById('search-box');
  const searchBody = document.getElementById('search-body');
  const searchSidebar = document.getElementById('search-sidebar');

  if (document.body.getAttribute('data-using-base-href') === 'false') {
    // If dartdoc did not add a base-href tag, we will need to add the relative
    // path ourselves.
    baseHref = document.body.getAttribute('data-base-href');
  }

  function disableSearch() {
    console.log('Could not activate search functionality.');
    if (searchBox) {
      searchBox.placeholder = 'Failed to initialize search';
    }

    if (searchBody) {
      searchBody.placeholder = 'Failed to initialize search';
    }

    if (searchSidebar) {
      searchSidebar.placeholder = 'Failed to initialize search';
    }
  }

  if ('fetch' in window) {
    fetch(baseHref + 'index.json', {method: 'GET'})
        .then(response => response.json())
        .then(index => {
          // Handle if the user specified a `search` parameter in the URL
          if ('URLSearchParams' in window) {
            const search = new URLSearchParams(window.location.search).get('search');
            if (search) {
              const matches = findMatches(search);
              if (matches.length !== 0) {
                window.location = baseHref + matches[0].href;
                return;
              }
            }
          }

          // Initialize all three search fields
          if (searchBox) {
            initializeSearch(searchBox, index);
          }

          if (searchBody) {
            initializeSearch(searchBody, index);
          }

          if (searchSidebar) {
            initializeSearch(searchSidebar, index);
          }
        })
        .catch(() => {
          disableSearch();
        });
  } else {
    disableSearch();
  }
});
