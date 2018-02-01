var search = document.querySelector('#start_station');
var results = document.querySelector('#start_stations');
var templateContent = document.querySelector('#resultstemplate').content;
search.addEventListener('keyup', function handler(event) {
    while (results.children.length) results.removeChild(results.firstChild);
    var inputVal = new RegExp(search.value.trim(), 'i');
    var clonedOptions = templateContent.cloneNode(true);
    var set = Array.prototype.reduce.call(clonedOptions.children, function searchFilter(frag, el) {
        if (inputVal.test(el.textContent) && frag.children.length < 5) frag.appendChild(el);
        return frag;
    }, document.createDocumentFragment());
    results.appendChild(set);
});

var search_two = document.querySelector('#stop_station');
var results_two = document.querySelector('#stop_stations');
var templateContent = document.querySelector('#resultstemplate').content;
search_two.addEventListener('keyup', function handler(event) {
    while (results_two.children.length) results_two.removeChild(results_two.firstChild);
    var inputVal_two = new RegExp(search_two.value.trim(), 'i');
    var clonedOptions_two = templateContent.cloneNode(true);
    var set_two = Array.prototype.reduce.call(clonedOptions_two.children, function searchFilter(frag_two, el_two) {
        if (inputVal_two.test(el_two.textContent) && frag_two.children.length < 5) frag_two.appendChild(el_two);
        return frag_two;
    }, document.createDocumentFragment());
    results_two.appendChild(set_two);
});
