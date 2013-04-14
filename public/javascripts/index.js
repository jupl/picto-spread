[].slice.call(document.querySelectorAll('script[type="text/markdown"]'), 0).forEach(function(el) {
  var newEl = document.createElement('div');
  newEl.innerHTML = marked(el.innerHTML);
  el.parentNode.replaceChild(newEl, el);
});
hljs.initHighlightingOnLoad();