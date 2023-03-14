/* ===============================================================================
wileyml-doc.js

Element Tree controls for Wiley ERM

Last Modified: November 13, 2018                                        

Copyright (c) 2017 by John Wiley & Sons, Inc. 

This stylesheet is proprietary confidential material owned by Wiley, and may be used and disclosed only in connection with agreed Wiley-related work. 
By using the stylesheets, you hereby agree to the terms set forth herein.
================================================================================== */

document.addEventListener("DOMContentLoaded", ready);

var currentElement = "";

function ready() {
	var title = getUrlParameter('title');
	var id = getUrlParameter('id');	
	var xreflabel = getUrlParameter('xreflabel');
	var tree = document.querySelector('.tree');
	if (title && id && xreflabel) {
		var element_parents = document.getElementById(xreflabel+'_parents');
		var parents = element_parents.querySelectorAll('a');
		parents[0].setAttribute('class','selectedParent');
		var textContent = (parents[0].textContent.indexOf(':') > -1) ? parents[0].textContent.substring(parents[0].textContent.indexOf(':') + 1) : parents[0].textContent;
		var parent_content = document.getElementById(textContent+'_content');
		tree.innerHTML = '<div class="parents">'+element_parents.innerHTML+'</div><div class="cm">'+parent_content.innerHTML+'</div>';
		currentElement = title;
		highlightElement();
	}
	else {
		currentElement = "";
	}
}

function parentClick(elem, id) {
	if (elem.getAttribute('class') !== 'selectedParent') {
		var parents = document.querySelectorAll('div.parents a');
		for (var i=0; i<parents.length; i++) parents[i].setAttribute('class','parent');
		elem.setAttribute('class','selectedParent');	
		var cm = document.querySelector('.cm');
		cm.innerHTML = document.getElementById(id).innerHTML;
		highlightElement();
	}
}

function highlightElement() {
	var elements = document.querySelector('.cm').querySelectorAll('div a');
	for (var i=0; i<elements.length; i++) {
		if (elements[i].textContent === currentElement) {
			elements[i].setAttribute('data-active','yes');
			// remove @target to open back in the same window/tab			
			elements[i].parentElement.children[1].removeAttribute('target');
			break;
		}
	}
	// unwrap highlighted element. check for ':' in the name and use a substring
	var textContent = (elements[i].textContent.indexOf(':') > -1) ? elements[i].textContent.substring(elements[i].textContent.indexOf(':') + 1) : elements[i].textContent;
	elementClick(elements[i],textContent+'_content');
}

function elementClick(elem, id) {
	if (elem.getAttribute('class') === 'unwrap') {
		elem.setAttribute('class','wrap');	
		var div = document.createElement("div");
		div.innerHTML = document.getElementById(id).innerHTML;
		elem.parentNode.appendChild(div);
	}
	else {
		elem.setAttribute('class','unwrap');
		elem.parentNode.removeChild(elem.parentNode.lastChild);
	}
}

function getUrlParameter(name) {
    name = name.replace(/[\[]/, '\\[').replace(/[\]]/, '\\]');
    var regex = new RegExp('[\\?&]' + name + '=([^&#]*)');
    var results = regex.exec(location.search);
    return results === null ? '' : decodeURIComponent(results[1].replace(/\+/g, ' '));
}
 