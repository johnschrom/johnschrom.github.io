/**
 * This file is a modified version of:
 * https://github.com/marmelab/highlight-search-term/blob/main/src/index.js
 * - We return the `nonMatchingElements`
 * - We fixed a bug: `getRangesForSearchTermInElement` got the `node.parentElement`, which is not working if there are multiple text nodes in one element.
 *
 * highlight-search-term is published under MIT License.
 *
 * MIT License
 *
 * Copyright (c) 2024 marmelab
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */
const highlightSearchTerm=({search:e,selector:t,customHighlightName:n="search"})=>{if(!t){throw new Error("The selector argument is required")}if(!CSS.highlights)return;CSS.highlights["delete"](n);if(!e){return}const r=[];const o=[];const h=document.querySelectorAll(t);Array.from(h).map(t=>{let n=false;getTextNodesInElementContainingText(t,e).forEach(t=>{const o=getRangesForSearchTermInNode(t,e);r.push(...o);if(o.length>0){n=true}});if(!n){o.push(t)}});if(r.length===0)return o;const s=new Highlight(...r);CSS.highlights.set(n,s);return o};const getTextNodesInElementContainingText=(e,t)=>{const n=[];const r=document.createTreeWalker(e,NodeFilter.SHOW_TEXT);let o;while(o=r.nextNode()){if(o.textContent&&o.textContent.toLowerCase().includes(t)){n.push(o)}}return n};const getRangesForSearchTermInNode=(e,t)=>{const n=[];const r=(e.textContent?e.textContent.toLowerCase():"")||"";let o=0;let h;while((h=r.indexOf(t,o))>=0){const r=new Range;r.setStart(e,h);r.setEnd(e,h+t.length);n.push(r);o=h+t.length}return n};export{highlightSearchTerm};