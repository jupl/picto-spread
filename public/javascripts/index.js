$(function() {
  $('script[type="text/markdown"]').each(function() {
    $(this).replaceWith(marked(this.textContent));
  });
  hljs.initHighlightingOnLoad();
});