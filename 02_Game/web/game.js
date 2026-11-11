// The game's browser behaviour: the browser displays and navigates, all computation is in R. Plain JavaScript, no external
// script.
//  - game_tab (from the server): the body class is-game shows the game pane and hides the Theory shell.
//  - [data-game] controls send one input, game_action, with the action and the element's data (topic, card, chap, kind, ref, page,
//    item); the decision form sends publish with its fields; the server answers a refused or warned decision with game_decision.
//  - the login: the form sends game_login with the user's id and the entry and nothing else; the
//    server's answer (game_login) is told on the line below the button, the field is cleared and held for the server's wait, and
//    game_login is sent once more without the entry (clear). Nothing about the login is kept in the browser: no cookie, no storage.
//  - the Runs screen: [data-runs] controls. "+ Create new run" and Rename open their inline forms in
//    the slot (Escape or Cancel closes them), Delete and Reset the run open their confirms in the slot; the forms, the confirms' buttons,
//    Continue, the run's setting (a checkbox), the developer's Unlock all topics, Open the theory, Sign out and Try again send one
//    input, runs_action, with the action, the slot and the name or the setting's value. Every action is the server's. The screen's
//    first state, "Connecting to your runs…", asks the server for the runs (load) as soon as it is shown.
//  - the Theory: game_tab(false) shows the theory section with the bar that leads back ([data-game="theory_back"]); when the game shows
//    again the focus returns to its screen's heading.
//  - the paper: the folded paper opens the edition as an overlay of spreads of a fixed height, scaled down whole on a shorter
//    window; Previous pages, Next pages and the arrow keys turn it two pages at a time, an index line opens its page; Escape, "Fold the
//    paper" and a click beside the paper close it; the switch "The staff's selection" toggles one state (game_paper_selection). The chat: the bar's chevron opens and closes the pane. A window (an exhibit, the map, the
//    Compare window, the report) closes with its button or Escape. An exhibit's slider sends game_exhibit; the server answers with
//    the exhibit's body (game_exhibit). Reduced motion is the stylesheet's (no transition, no animation).
//  - the chat: only the governor's questions and the chief economist's answers. It opens scrolled to the newest message with the
//    focus in its question field, and stays at the newest as the server redraws it. A question sends ask with its text; the pane shows
//    the question and a "thinking" line until the server answers with the redrawn desk, after which the focus returns to the question
//    field. Enter sends, Shift+Enter breaks the line.
//  - the interim card over the desk: Back, Skip the brief and Continue are [data-game] buttons; when the card is drawn the focus
//    moves to its title.
//  - the economy's map: the arrows drawn between the actors' boxes from the map's
//    data, the boxes folded and unfolded, the walk through the quarter with its forks, a box on hover and focus pinned by a click, the small
//    graph working in a pinned box, the boxes dragged and moved by the arrow keys, springing back to the border, Reset the map; the
//    arrangement sent as game_map_arrange; on the Desk the map is a drop-down panel in the window slot (the panel's data-pin pins an item).
//  - the task board: the line in the panel's header row is a button ([data-board="toggle"]) whose box unrolls
//    downward into the drop-down and rolls back up (data-state opening, open, closing; at once under reduced motion); Enter, Space and
//    the chevron open and close it, Escape closes it. A desk drawn with data-board-auto (a step changed) opens it by itself with its
//    note, announces the change in the polite live region (#board-live) and closes it at the next click, wherever it lands; the finished
//    steps' line ([data-board="done"]) lists them on a click.
//  - the chat and the task line's drop-down are equals: the one clicked last lies on top. A click on the chat's
//    bar or pane (or the chat opened) puts an open drop-down behind it (the board's is-behind); a click on the line or inside the drop-down
//    brings it to the front; a drop-down opened by itself for a step change stays behind an open chat; folded, the line always lies under
//    the open chat (the stylesheet's layers). The layers as one stack (02_Game/web/game.css): the tour, then a card
//    the windows (the report window), then the open chat and the open drop-down as equals, then the desk; a step change's auto-open waits
//    while a card or a window covers the line's place.
//  - the decision: the bar one line, Publish sending the rate as typed; in topic 1 the bar's own rule refuses a rate below
//    the field's data-min with its data-below line, nothing sent. From topic 4 the bank's word: the path on the
//    rate chart (dragged, moved by the arrow keys, typed; the switch, "+", Back), its marks by the engine's rule, the bar's band and summary,
//    Set to the floor, the record line, and Publish sending the path; the confirm step lists every breach the server names.
//  - the record line: from topic 4, the line under the guidance ([data-desk="record"], a button)
//    opens and closes the list of the term's promises below it (aria-expanded follows); Escape closes it, the focus back on the line.
//  - the guided tour: a desk drawn with a tour (.tour[data-tour-auto]) runs it: the steps whose element
//    is on the page (the others left out, the count following); the screen greyed, the element framed in white above the grey (it and
//    its frame carry is-tour-target), the box beside it on the side the step names or where there is room, its arrow on the side facing
//    the element; Previous, Next, the count and, on the last step, End tutorial; Escape ends the tour as End tutorial does; the focus moves
//    into the box and returns at the end to where it was; a small graph moves by its grip (drag, or the arrow keys); reduced motion turns
//    every movement off. A task board's auto-open drawn with it waits for the tour's end. A card drawn with it (the brief's at a topic's
//    start) is held, its slot hidden, and opens when the tour ends.
//  - after a screen change the keyboard focus moves to the new screen's heading ([data-game-focus]).
(function () {
  'use strict';
  var pending = false, spread = 0, lastFocus = null, exTimer = null, lastAction = '';
  function send(action, el, extra) {
    var v = {action: action, nonce: Date.now() + Math.random()}, k;
    if (el) ['topic', 'card', 'chap', 'kind', 'ref', 'page', 'item'].forEach(function (n) { if (el.dataset[n] !== undefined) v[n] = el.dataset[n]; });
    if (extra) for (k in extra) if (Object.prototype.hasOwnProperty.call(extra, k)) v[k] = extra[k];
    pending = true; lastAction = action;
    window.Shiny.setInputValue('game_action', v, {priority: 'event'});
  }
  function $q(sel, root) { return (root || document).querySelector(sel); }
  function $all(sel, root) { return Array.prototype.slice.call((root || document).querySelectorAll(sel)); }

  // --- the paper -----------------------------------------------------------------------------------
  // The open paper is read in spreads of two pages of a fixed height (the rows R laid out), scaled down whole on a shorter window; the bar's
  // Previous pages and Next pages (and the arrow keys) turn it, an index line opens its page's spread, Escape, Fold the paper and a click
  // beside the paper fold it. The staff's selection is one state on the folded paper and the open one, sent to the server to keep with the run.
  function overlay() { return $q('#paper-overlay'); }
  function showSpread(k) {
    var o = overlay(); if (!o) return;
    var pages = $all('.paper-page', o), n = Math.max(1, Math.ceil(pages.length / 2));
    spread = Math.max(0, Math.min(n - 1, k));
    pages.forEach(function (p, i) { p.hidden = Math.floor(i / 2) !== spread; });
    $all('.paper-count', o).forEach(function (c) { c.hidden = c.getAttribute('data-spread') !== String(spread + 1); });
    var prev = $q('[data-paper="prev"]', o), next = $q('[data-paper="next"]', o);
    if (prev) prev.disabled = spread === 0;
    if (next) next.disabled = spread >= n - 1;
    o.setAttribute('data-spread', String(spread + 1));
    keepNote();
  }
  function paperFit() {                                               // the whole spread scaled down to a shorter or narrower window
    var o = overlay(); if (!o || o.hidden) return;
    var sp = $q('.paper-spread', o), st = $q('.paper-stage', o), bar = $q('.paper-bar', o); if (!sp || !st) return;
    var W = sp.offsetWidth, H = sp.offsetHeight; if (!W || !H) { o.setAttribute('data-scale', '1'); return; }
    var aw = window.innerWidth - 32, ah = window.innerHeight - (bar ? bar.offsetHeight : 48) - 56;
    var k = Math.min(1, aw / W, ah / H); if (!(k > 0)) k = 1;
    sp.style.transform = k < 1 ? 'scale(' + k.toFixed(4) + ')' : '';
    st.style.height = Math.round(H * k) + 'px'; o.setAttribute('data-scale', k.toFixed(3));
  }
  function openPaper() {
    var o = overlay(); if (!o) return;
    lastFocus = document.activeElement; o.hidden = false; document.body.classList.add('paper-open'); showSpread(0); paperFit();
    var f = $q('[data-paper="fold"]', o); if (f) f.focus();
  }
  function foldPaper() {
    var o = overlay(); if (!o || o.hidden) return;
    o.hidden = true; document.body.classList.remove('paper-open'); keepNote();
    var b = $q('.paper-folded'); if (b) b.focus(); else if (lastFocus && lastFocus.focus) lastFocus.focus();
  }
  function paperOpen() { var o = overlay(); return !!(o && !o.hidden); }

  // --- the screen kept across a redraw --------------------------------------------
  // A redraw of the same view (the root's data-view: the desk of a topic, the Menu) that the player did not ask for (a background job's return
  // that concerns the screen: its debrief's progress, the Menu's notice) keeps where the panel, a window's body and the page were scrolled and
  // the paper open at its spread. The state is noted as the player scrolls and turns the paper and read when Shiny announces the new value, so
  // that it does not matter whether the announcement comes before the redraw (Shiny's order) or after it.
  var kept = {view: null, panel: 0, body: 0, page: 0, paper: false, spread: 0};
  function screenView() { var r = $q('#game_screen [data-view]'); return r ? r.getAttribute('data-view') : null; }
  function keepNote() {
    var v = screenView(); if (!v) return;
    var p = $q('#desk-panel'), b = $q('#game_screen .window-body'), se = document.scrollingElement || document.documentElement;
    kept = {view: v, panel: p ? p.scrollTop : 0, body: b ? b.scrollTop : 0, page: se ? se.scrollTop : 0, paper: paperOpen(), spread: spread};
  }
  function keepRestore(k) {
    if (!k || !k.view || screenView() !== k.view) return false;
    var p = $q('#desk-panel'), b = $q('#game_screen .window-body'), se = document.scrollingElement || document.documentElement;
    if (p) p.scrollTop = k.panel; if (b) b.scrollTop = k.body; if (se) se.scrollTop = k.page;
    var o = overlay();
    if (k.paper && o) { o.hidden = false; document.body.classList.add('paper-open'); showSpread(k.spread); paperFit(); }
    kept = k; return true;
  }
  // --- the table of contents -----------------------------------------------------------------
  // A chapter's row unfolds its topics on a click and folds them on the next; no fold button, no word for it. The chapters the player unfolded
  // or folded stay so while the Menu is drawn again (a row clicked, a background return); any other screen forgets them, so that a Menu drawn
  // after it (a run opened, the desk left) shows the server's: the chapter of the topic in play unfolded.
  var toc = {};                                                        // chapter id -> unfolded, by the player's clicks on this Menu
  function tocSet(btn, open) {
    var list = document.getElementById(btn.getAttribute('aria-controls')); if (!list) return;
    btn.setAttribute('aria-expanded', open ? 'true' : 'false'); list.hidden = !open;
    var li = btn.closest('.game-chapter'); if (li) li.classList.toggle('is-open', open);
  }
  function tocAfterRender() {
    if (screenView() !== 'menu') { toc = {}; return; }
    $all('#game_screen [data-toc]').forEach(function (b) { var k = b.getAttribute('data-toc'); if (Object.prototype.hasOwnProperty.call(toc, k)) tocSet(b, toc[k]); });
  }
  document.addEventListener('scroll', function (e) {                // the panel, a window's body or the page scrolled: noted
    var t = e.target; if (t === document || t === document.documentElement || (t && t.closest && t.closest('#game_screen'))) keepNote();
  }, true);
  function paperSelection(on) {
    $all('.paper-overlay, .paper-folded-wrap').forEach(function (x) { x.classList.toggle('is-selection', on); });
    $all('[data-paper="selection"]').forEach(function (b) { b.setAttribute('aria-pressed', on ? 'true' : 'false'); });
  }
  function toggleSelection() {
    var b = $q('[data-paper="selection"]'), on = !(b && b.getAttribute('aria-pressed') === 'true');
    paperSelection(on);
    if (window.Shiny && window.Shiny.setInputValue) window.Shiny.setInputValue('game_paper_selection', {on: on, nonce: Date.now()}, {priority: 'event'});
  }
  window.addEventListener('resize', paperFit);

  // --- the chat -------------------------------------------------------------------------------------------------------------
  function chatBottom() { var l = $q('.chat-list'); if (l) l.scrollTop = l.scrollHeight; }
  function chat(open) {
    var p = $q('#chat-pane'), t = $q('[data-chat="toggle"]'); if (!p) return;
    p.hidden = !open; if (t) t.setAttribute('aria-expanded', open ? 'true' : 'false');
    if (window.Shiny && window.Shiny.setInputValue) window.Shiny.setInputValue('game_chat_read', {open: !!open, nonce: Date.now()}, {priority: 'event'});
    if (!open) boardBehind(false);                                    // no chat open: an open drop-down is in front again
    var badge = $q('.chat-badge'); if (open && badge) badge.remove();
    if (open) {                                                       // the newest message in view, the focus in the question field
      chatBottom(); var q = $q('#chat-question');
      if (q && !q.disabled) q.focus({preventScroll: true}); else { var h = $q('.chat-title', p); if (h) { h.setAttribute('tabindex', '-1'); h.focus(); } }
    } else if (t) t.focus();
  }
  function chatOpen() { var p = $q('#chat-pane'); return !!(p && !p.hidden); }
  function ask() {
    var t = $q('#chat-question'); if (!t || t.disabled) return;
    var q = t.value.replace(/^\s+|\s+$/g, ''); if (!q) { t.focus(); return; }
    var list = $q('.chat-list');
    if (list) {
      var li = document.createElement('li'); li.className = 'chat-msg kind-question'; li.textContent = q; list.appendChild(li);
      var w = document.createElement('li'); w.className = 'chat-msg kind-thinking'; w.setAttribute('role', 'status');
      w.textContent = (t.getAttribute('data-thinking') || ''); list.appendChild(w);
      list.scrollTop = list.scrollHeight;
    }
    t.disabled = true; var b = $q('#chat-form button'); if (b) b.disabled = true;
    var rc = $q('#desk-rate'), extra = {question: q}, dp = wordPath(); if (rc) extra.rate = rc.value; if (dp) extra.path = dp;
    send('ask', null, extra);
  }
  function windowOpen() { return !!$q('#game_window .game-window'); }
  // the debrief's chat box: its one line sent with the debrief's key; the line and Ask wait for the answer
  function debriefAsk() {
    var t = $q('#debrief-question'), f = $q('#debrief-chat-form'); if (!t || t.disabled || !f) return;
    var q = t.value.replace(/^\s+|\s+$/g, ''); if (!q) { t.focus(); return; }
    t.disabled = true; var b = $q('#debrief-chat-form button'); if (b) b.disabled = true;
    send('debrief_ask', null, {question: q, ref: f.getAttribute('data-ref')});
  }

  // --- the economy's map ---------------------------------------
  // Each .map carries its data (.map-data: the boxes with their designed places and sizes, the parts, the arrows, the walk and the loops, the
  // walk's words; 02_Game/ui/map.R). Here: the arrows drawn between the boxes (a folded box stands for its parts, its arrows grouped, one line for
  // each pair of ends and direction); a folded box unfolded by a click (or Enter, Space), folded again by a second click on it; the walk through
  // the quarter that follows the arrows: it starts at the quarter's cause, and at every part its box offers
  // one button per arrow that leaves it ("Follow the arrow to ..."), lights only those arrows and their two ends (a button pointed at or focused
  // lights its arrow and its end more), shows the part's text and the text of the arrow just followed; Previous goes back one step, Next follows
  // the one arrow where a single one leaves, Start again where none leaves; a folded box lights as a whole); a part's, an arrow's or a folded box's box on
  // hover and focus, pinned by a click, Enter or Space (again, its Close or Escape lets it go, the focus back on the item), a small graph drawn
  // when its box is pinned and redrawn as its sliders move; the boxes dragged anywhere within the map, springing back until their outer edge
  // lies on the border, the arrows following, the arrow keys moving a focused box (Shift a larger step); "Reset the map" returns every box to
  // its designed place, folded, and the walk to rest. The arrangement (the places the player moved the boxes to and the unfolded boxes) goes to
  // the server as game_map_arrange and is kept with the run; a redrawn map comes back with it.
  var maps = {}, mapPin = null, mapTimer = null, mapQuiet = false, mapDrag = null, mapDragged = 0;
  var SVGNS = 'http://www.w3.org/2000/svg';
  function mapItem(map, id) { return map ? $q('[data-map-item="' + id + '"]', map) : null; }
  function mapTipId(item) { return item ? (item.getAttribute('data-tip') || item.getAttribute('data-map-item')) : null; }
  function mapTip(map, id) { var it = mapItem(map, id), t = mapTipId(it) || id; return map ? $q('.map-tip[data-tip-for="' + t + '"]', map) : null; }
  function mapState(map) { return map ? maps[map.id] : null; }
  function mapReduced() { return !!(window.matchMedia && window.matchMedia('(prefers-reduced-motion: reduce)').matches); }
  function mapFmt(x, d) { var s = Math.abs(x).toFixed(d === undefined ? 2 : d); return (x < -1e-9 ? '−' : (x > 1e-9 ? '+' : '')) + s; }
  function mapFill(t, o) { return String(t || '').replace(/\{(\w+)\}/g, function (m, k) { return o[k] !== undefined ? o[k] : m; }); }
  function mapInit(el) {
    var src = $q('.map-data', el); if (!src) return null;
    var d; try { d = JSON.parse(src.textContent); } catch (err) { return null; }
    var st = {el: el, d: d, open: {}, at: {}, walk: null, box: {}}, prev = maps[el.id];
    d.boxes.forEach(function (b) { st.at[b.id] = [b.at[0], b.at[1]]; if (b.open) st.open[b.id] = true; st.box[b.id] = b; });
    if (prev && prev.d.topic === d.topic && prev.walk && d.parts[prev.walk.node]) st.walk = prev.walk;   // a redrawn map keeps its walk
    maps[el.id] = st; el.setAttribute('data-map-ready', 'true');
    mapLayout(st); mapWalkShow(st);
    if (d.walk && d.start && d.parts[d.start]) {
      st.walk = {node: d.start, via: null, hist: []};
      d.walk.forEach(function (aid) { var w = String(aid).split('>'); var a = d.arrows.filter(function (x) { return x.id === w[0] && x.from === st.walk.node && (!w[1] || x.to === w[1]); })[0];
        if (a) { st.walk.hist.push({node: st.walk.node, via: st.walk.via}); st.walk = {node: a.to, via: a.id, hist: st.walk.hist}; } });
      mapWalkShow(st);
    }
    return st;
  }
  function mapAll() { $all('.map[data-map-topic]').forEach(function (el) { if (el.getAttribute('data-map-ready') !== 'true') mapInit(el); }); }
  // A box's size now (folded or unfolded) and its rectangle; a part's rectangle (its box unfolded); an arrow end's rectangle: the part where its
  // box is unfolded, else the box.
  function mapSize(st, id) { var b = st.box[id]; return st.open[id] ? b.opened : b.folded; }
  function mapBoxRect(st, id) { var c = st.at[id], s = mapSize(st, id); return {x: c[0] - s[0] / 2, y: c[1] - s[1] / 2, w: s[0], h: s[1]}; }
  function mapPartRect(st, part) {
    var g = $q('.map-part[data-part="' + part + '"]', st.el), b = st.d.parts[part].box, c = st.at[b];
    return {x: c[0] + Number(g.getAttribute('data-x')), y: c[1] + Number(g.getAttribute('data-y')), w: Number(g.getAttribute('data-w')), h: Number(g.getAttribute('data-h'))};
  }
  function mapEnd(st, part) { var b = st.d.parts[part].box; return st.open[b] ? {key: 'p:' + part, r: mapPartRect(st, part)} : {key: 'b:' + b, r: mapBoxRect(st, b)}; }
  function mapClip(r, dx, dy) {                                        // from a rectangle's centre along (dx, dy) to its border
    var tx = dx ? (r.w / 2) / Math.abs(dx) : Infinity, ty = dy ? (r.h / 2) / Math.abs(dy) : Infinity, t = Math.min(tx, ty);
    return [r.x + r.w / 2 + t * dx, r.y + r.h / 2 + t * dy];
  }
  function mapClamp(st, id, c) {                                       // within the map, its outer edge on the border at most
    var s = mapSize(st, id), W = st.d.canvas[0], H = st.d.canvas[1];
    return [Math.min(Math.max(c[0], s[0] / 2), W - s[0] / 2), Math.min(Math.max(c[1], s[1] / 2), H - s[1] / 2)];
  }
  function mapPlaceBox(st, id) {
    var g = $q('.map-box[data-box="' + id + '"]', st.el); if (!g) return;
    g.setAttribute('transform', 'translate(' + st.at[id][0].toFixed(1) + ',' + st.at[id][1].toFixed(1) + ')');
    g.classList.toggle('is-open', !!st.open[id]); g.setAttribute('aria-expanded', st.open[id] ? 'true' : 'false');
  }
  // The arrows between their ends, grouped by pair and direction; a pair with both directions drawn apart.
  function mapLines(st) {
    var groups = {}, order = [], words = st.d.words;
    st.d.arrows.forEach(function (a) {
      var A = mapEnd(st, a.from), B = mapEnd(st, a.to); if (A.key === B.key) return;
      var k = A.key + '>' + B.key; if (!groups[k]) { groups[k] = {key: k, A: A, B: B, arrows: []}; order.push(k); }
      groups[k].arrows.push(a);
    });
    var layer = $q('.map-lines', st.el); if (!layer) return;
    while (layer.firstChild) layer.removeChild(layer.firstChild);
    order.forEach(function (k) {
      var gr = groups[k], A = gr.A.r, B = gr.B.r, cx1 = A.x + A.w / 2, cy1 = A.y + A.h / 2, cx2 = B.x + B.w / 2, cy2 = B.y + B.h / 2;
      var dx = cx2 - cx1, dy = cy2 - cy1, n = Math.sqrt(dx * dx + dy * dy) || 1; dx /= n; dy /= n;
      var p1 = mapClip(A, dx, dy), p2 = mapClip(B, -dx, -dy), back = groups[gr.B.key + '>' + gr.A.key], off = back ? 5 : 0;
      p1 = [p1[0] - dy * off, p1[1] + dx * off]; p2 = [p2[0] - dy * off, p2[1] + dx * off];
      var dec = gr.arrows.every(function (a) { return a.kind === 'decision'; }), nw = gr.arrows.some(function (a) { return a.new; });
      var ids = gr.arrows.map(function (a) { return a.id; }), g = document.createElementNS(SVGNS, 'g');
      var one = ids.length === 1 || gr.arrows.every(function (a) { return a.row === gr.arrows[0].row; });
      g.setAttribute('class', 'map-line' + (dec ? ' is-decision' : '') + (nw ? ' is-new' : ''));
      g.setAttribute('data-map-item', 'L-' + ids.join('-')); g.setAttribute('data-arrows', ids.join(' ')); g.setAttribute('data-tip', one ? ids[0] : 'group');
      g.setAttribute('tabindex', '0'); g.setAttribute('role', 'button'); g.setAttribute('aria-expanded', 'false');
      var t0 = $q('.map-tip[data-tip-for="' + ids[0] + '"] .map-tip-title', st.el);
      g.setAttribute('aria-label', one && t0 ? t0.textContent : mapFill(words.group_title, {from: mapEndName(st, gr.A.key), to: mapEndName(st, gr.B.key), n: ids.length}));
      var d = 'M' + p1[0].toFixed(1) + ',' + p1[1].toFixed(1) + ' L' + p2[0].toFixed(1) + ',' + p2[1].toFixed(1);
      var hit = document.createElementNS(SVGNS, 'path'); hit.setAttribute('class', 'map-hit'); hit.setAttribute('d', d);
      var ln = document.createElementNS(SVGNS, 'path'); ln.setAttribute('class', 'map-stroke'); ln.setAttribute('d', d);
      ln.setAttribute('marker-end', 'url(#' + st.el.id + '-head' + (nw ? '-new' : '') + ')');
      g.appendChild(hit); g.appendChild(ln);
      if (dec) {                                                        // the player's next decision, dashed, named on the line
        var tx = document.createElementNS(SVGNS, 'text'); tx.setAttribute('class', 'map-decision-label'); tx.setAttribute('text-anchor', 'middle');
        tx.setAttribute('x', ((p1[0] + p2[0]) / 2).toFixed(1)); tx.setAttribute('y', ((p1[1] + p2[1]) / 2 - 6).toFixed(1)); tx.textContent = words.decision; g.appendChild(tx);
      }
      layer.appendChild(g);
    });
    mapLight(st); mapPins(st);
  }
  function mapEndName(st, key) { var id = key.slice(2); return key.charAt(0) === 'p' ? st.d.parts[id].name : st.box[id].label; }
  function mapLayout(st) { st.d.boxes.forEach(function (b) { mapPlaceBox(st, b.id); }); mapLines(st); }
  // The walk: the part it stands on, the arrows that leave it and their ends lit, the rest dimmed; a folded box lit when any of its parts is.
  function mapWalkOut(st) {                                            // the arrows that leave the part the walk stands on, in the tables' order
    var w = st.walk; if (!w) return [];
    return st.d.arrows.filter(function (a) { return a.from === w.node && a.to !== w.node; });
  }
  function mapWalkLit(st) {
    var w = st.walk, parts = {}, arrows = {}; if (!w) return null;
    parts[w.node] = true;
    mapWalkOut(st).forEach(function (a) { arrows[a.id] = true; parts[a.to] = true; });
    return {parts: parts, arrows: arrows, here: w.node};
  }
  function mapLight(st) {
    var lit = mapWalkLit(st), el = st.el;
    el.classList.toggle('is-walking', !!lit);
    $all('.map-part', el).forEach(function (p) { var id = p.getAttribute('data-part'); p.classList.toggle('is-lit', !!(lit && lit.parts[id])); p.classList.toggle('is-here', !!(lit && lit.here === id)); });
    $all('.map-box', el).forEach(function (b) {
      var id = b.getAttribute('data-box'), on = !!lit && st.box[id].parts.some(function (p) { return lit.parts[p]; });
      b.classList.toggle('is-lit', on && !st.open[id]); b.classList.toggle('has-lit', on);
    });
    $all('.map-line', el).forEach(function (g) {
      var on = !!lit && g.getAttribute('data-arrows').split(' ').some(function (a) { return lit.arrows[a]; });
      g.classList.toggle('is-lit', on);
      var ln = $q('.map-stroke', g); if (ln) ln.setAttribute('marker-end', 'url(#' + el.id + '-head' + (on ? '-lit' : (g.classList.contains('is-new') ? '-new' : '')) + ')');
    });
    mapHot(st, null);
  }
  function mapHot(st, aid) {                                           // a Follow button pointed at or focused: its arrow and its end lit more
    var a = aid ? st.d.arrows.filter(function (x) { return x.id === aid; })[0] : null, el = st.el;
    $all('.map-line', el).forEach(function (g) { g.classList.toggle('is-hot', !!a && g.getAttribute('data-arrows').split(' ').indexOf(a.id) >= 0); });
    $all('.map-part', el).forEach(function (p) { p.classList.toggle('is-hot', !!a && p.getAttribute('data-part') === a.to); });
    $all('.map-box', el).forEach(function (b) { var id = b.getAttribute('data-box'); b.classList.toggle('is-hot', !!a && !st.open[id] && st.d.parts[a.to].box === id); });
  }
  function mapWalkShow(st) {
    var w = st.walk, d = st.d, W = d.words, box = $q('.map-walk', st.el); if (!box) return;
    var bar = $q('.map-walk-buttons', box), text = $q('.map-walk-text', box), steps = $q('.map-walk-steps', box);
    var btn = function (act, label, extra) {
      var b = document.createElement('button'); b.type = 'button'; b.className = 'btn-quiet map-walk-btn'; b.setAttribute('data-map', act);
      if (extra) Object.keys(extra).forEach(function (k) { b.setAttribute(k, extra[k]); }); b.textContent = label; return b;
    };
    while (bar.firstChild) bar.removeChild(bar.firstChild);
    while (text.firstChild) text.removeChild(text.firstChild);
    if (!w) {                                                           // at rest: Walk through the quarter alone
      st.el.setAttribute('data-walk', 'rest'); st.el.removeAttribute('data-walk-node'); st.el.removeAttribute('data-walk-via');
      bar.appendChild(btn('walk_start', W.start)); text.hidden = true; steps.hidden = true; mapLight(st); return;
    }
    var out = mapWalkOut(st), part = d.parts[w.node];
    st.el.setAttribute('data-walk', out.length ? 'node' : 'end'); st.el.setAttribute('data-walk-node', w.node); st.el.setAttribute('data-walk-via', w.via || '');
    out.forEach(function (a) { bar.appendChild(btn('walk_follow', a.follow, {'data-arrow': a.id})); });
    if (!out.length) bar.appendChild(btn('walk_again', W.again));       // the walk's end: no arrow leaves the part
    var h = document.createElement('h4'); h.className = 'map-walk-title'; h.textContent = part.name; text.appendChild(h);
    var para = function (cls, t) { var q = document.createElement('p'); q.className = cls; q.textContent = t; text.appendChild(q); };
    (part.walk || []).forEach(function (t) { para('map-walk-part', t); });
    var via = w.via ? d.arrows.filter(function (a) { return a.id === w.via; })[0] : null;   // under it, the arrow just followed
    if (via) (via.walk || []).forEach(function (t) { para('map-walk-arrow', t); });
    text.hidden = false; steps.hidden = false;
    var prev = $q('[data-map="walk_previous"]', steps), next = $q('[data-map="walk_next"]', steps);
    prev.disabled = !w.hist.length; prev.classList.toggle('is-none', !w.hist.length); prev.setAttribute('aria-hidden', w.hist.length ? 'false' : 'true');   // none at the cause
    next.disabled = out.length !== 1;                                  // only where one arrow leaves: greyed where several or none do
    mapLight(st);
  }
  function mapWalk(map, act, el) {
    var st = mapState(map); if (!st) return;
    var w = st.walk, d = st.d, hist = w ? w.hist.slice() : [];
    var go = function (a) { if (!a) return; hist.push({node: w.node, via: w.via}); st.walk = {node: a.to, via: a.id, hist: hist}; };
    if (act === 'walk_start' || act === 'walk_again') st.walk = d.start && d.parts[d.start] ? {node: d.start, via: null, hist: []} : null;
    else if (!w) return;
    else if (act === 'walk_end') st.walk = null;                         // End the walk: the map to rest from any step
    else if (act === 'walk_follow') go(d.arrows.filter(function (a) { return a.id === el.getAttribute('data-arrow') && a.from === w.node; })[0]);
    else if (act === 'walk_next') { var out = mapWalkOut(st); if (out.length === 1) go(out[0]); else return; }
    else if (act === 'walk_previous') { var p = hist.pop(); if (!p) return; st.walk = {node: p.node, via: p.via, hist: hist}; }
    var ae = document.activeElement, into = !!(ae && ae.closest && ae.closest('.map-walk'));
    mapWalkShow(st);
    if (!into) return;                                                 // the focus stays in the walk's box: on Previous or Next while it can, else
    var keep = (act === 'walk_previous' || act === 'walk_next') && ae.isConnected && !ae.disabled;   // on the box's first button
    var first = $q('.map-walk-buttons button', map); if (!keep && first) first.focus({preventScroll: true});
  }
  document.addEventListener('mouseover', function (e) {               // a Follow button pointed at: its arrow and its end lit more
    var b = e.target && e.target.closest ? e.target.closest('.map-walk [data-arrow]') : null; if (!b) return;
    var st = mapState(b.closest('.map')); if (st) mapHot(st, b.getAttribute('data-arrow'));
  });
  document.addEventListener('mouseout', function (e) {
    var b = e.target && e.target.closest ? e.target.closest('.map-walk [data-arrow]') : null; if (!b) return;
    var to = e.relatedTarget && e.relatedTarget.closest ? e.relatedTarget.closest('.map-walk [data-arrow]') : null; if (to === b) return;
    var st = mapState(b.closest('.map')); if (st) mapHot(st, null);
  });
  document.addEventListener('focusin', function (e) {
    var b = e.target && e.target.closest ? e.target.closest('.map-walk [data-arrow]') : null; if (!b) return;
    var st = mapState(b.closest('.map')); if (st) mapHot(st, b.getAttribute('data-arrow'));
  });
  document.addEventListener('focusout', function (e) {
    var b = e.target && e.target.closest ? e.target.closest('.map-walk [data-arrow]') : null; if (!b) return;
    var st = mapState(b.closest('.map')); if (st) mapHot(st, null);
  });
  // Folding, moving, keeping.
  function mapSave(st) {
    var boxes = {}, open = [];
    st.d.boxes.forEach(function (b) {
      var a = st.at[b.id]; if (Math.abs(a[0] - b.home[0]) > 0.05 || Math.abs(a[1] - b.home[1]) > 0.05) boxes[b.id] = [Number(a[0].toFixed(1)), Number(a[1].toFixed(1))];
      if (st.open[b.id]) open.push(b.id);
    });
    if (window.Shiny && window.Shiny.setInputValue) window.Shiny.setInputValue('game_map_arrange', {boxes: boxes, open: open, nonce: Date.now() + Math.random()}, {priority: 'event'});
  }
  function mapFold(map, id, open) {
    var st = mapState(map); if (!st || !st.box[id]) return;
    if (mapPin && mapPin.map === map.id) mapUnpin(false);
    if (open) st.open[id] = true; else delete st.open[id];
    st.at[id] = mapClamp(st, id, st.at[id]);                            // a box unfolded near the border opens inward
    mapLayout(st); mapSave(st);
    var g = $q('.map-box[data-box="' + id + '"]', map);
    if (g && open) { var p = $q('.map-part', g); if (p && document.activeElement && document.activeElement.closest && document.activeElement.closest('.map-box') === g) p.focus({preventScroll: true}); }
    else if (g && !open && g.focus) { mapQuiet = true; g.focus({preventScroll: true}); mapQuiet = false; }
  }
  function mapMove(st, id, c) { st.at[id] = c; mapPlaceBox(st, id); mapLines(st); }
  function mapSpring(st, id) {                                         // released beyond the border: back until its outer edge lies on it
    var from = st.at[id].slice(), to = mapClamp(st, id, from), g = $q('.map-box[data-box="' + id + '"]', st.el);
    if (Math.abs(to[0] - from[0]) < 0.05 && Math.abs(to[1] - from[1]) < 0.05) { mapSave(st); return; }
    if (mapReduced()) { mapMove(st, id, to); mapSave(st); return; }
    if (g) g.classList.add('is-springing'); var t0 = Date.now();
    var tick = function () {                                           // 180 ms, however slow the frames
      var k = Math.min(1, (Date.now() - t0) / 180), e = 1 - (1 - k) * (1 - k);
      mapMove(st, id, [from[0] + (to[0] - from[0]) * e, from[1] + (to[1] - from[1]) * e]);
      if (k < 1) setTimeout(tick, 16); else { if (g) g.classList.remove('is-springing'); mapSave(st); }
    };
    setTimeout(tick, 16);
  }
  function mapScale(st) { var svg = $q('.map-svg', st.el), r = svg ? svg.getBoundingClientRect() : null; return r && r.width > 0 ? st.d.canvas[0] / r.width : 1; }
  function mapKeyMove(e, box) {
    var map = box.closest('.map'), st = mapState(map), id = box.getAttribute('data-box'); if (!st) return false;
    var step = e.shiftKey ? st.d.step[1] : st.d.step[0], dx = 0, dy = 0;
    if (e.key === 'ArrowLeft') dx = -step; else if (e.key === 'ArrowRight') dx = step; else if (e.key === 'ArrowUp') dy = -step; else if (e.key === 'ArrowDown') dy = step; else return false;
    e.preventDefault(); if (mapPin && mapPin.map === map.id) mapUnpin(false);
    mapMove(st, id, mapClamp(st, id, [st.at[id][0] + dx, st.at[id][1] + dy])); mapSave(st);
    return true;
  }
  function mapReset(map) {
    var st = mapState(map); if (!st) return;
    mapUnpin(false); st.open = {}; st.d.boxes.forEach(function (b) { st.at[b.id] = [b.home[0], b.home[1]]; }); st.walk = null;
    mapLayout(st); mapWalkShow(st); mapSave(st);
  }
  // The boxes on hover, focus and pin.
  function mapPlace(map, item, tip) {
    var c = map.getBoundingClientRect(), r = item.getBoundingClientRect(), w = tip.offsetWidth || 360, room = map.clientWidth || w;
    tip.style.left = Math.max(0, Math.min(r.left - c.left + r.width / 2 - w / 2, room - w)) + 'px';
    tip.style.top = Math.max(0, r.bottom - c.top + 8) + 'px';
  }
  function mapGroupFill(map, item) {                                   // a line between folded boxes: one section per arrow it stands for
    var tip = $q('.map-tip[data-tip-for="group"]', map), st = mapState(map); if (!tip || !st) return;
    var ids = item.getAttribute('data-arrows').split(' '), body = $q('.map-tip-body', tip), seen = {};
    while (body.firstChild) body.removeChild(body.firstChild);
    $q('.map-tip-title', tip).textContent = item.getAttribute('aria-label');
    ids.forEach(function (id) {
      var a = st.d.arrows.filter(function (x) { return x.id === id; })[0]; if (!a || seen[a.row]) return; seen[a.row] = true;
      var src = $q('.map-tip[data-tip-for="' + id + '"]', map); if (!src) return;
      var sec = document.createElement('div'); sec.className = 'map-group-item';
      var h = document.createElement('button'); h.type = 'button'; h.className = 'map-group-title'; h.setAttribute('aria-expanded', 'false'); h.textContent = $q('.map-tip-title', src).textContent; sec.appendChild(h);
      var txt = document.createElement('div'); txt.className = 'map-group-text'; txt.hidden = true; sec.appendChild(txt);
      ['.map-lead', '.map-equation'].forEach(function (c) { var s = $q(c, src); if (s) { var p = document.createElement('p'); p.className = c.slice(1); p.textContent = s.textContent; txt.appendChild(p); } });
      h.addEventListener('click', function (e) { e.preventDefault(); e.stopPropagation(); var op = txt.hidden; txt.hidden = !op; h.setAttribute('aria-expanded', op ? 'true' : 'false'); });
      body.appendChild(sec);
    });
  }
  function mapShow(map, id) {
    if (!map || (mapPin && mapPin.map === map.id) || mapDrag) return;   // a pinned box holds its map's attention
    clearTimeout(mapTimer);
    var item = mapItem(map, id); if (!item) return;
    if (item.getAttribute('data-tip') === 'group') mapGroupFill(map, item);
    var tip = mapTip(map, id);
    $all('.map-tip', map).forEach(function (t) { if (t !== tip) t.hidden = true; });
    $all('[data-map-item]', map).forEach(function (i) { if (i !== item) i.setAttribute('aria-expanded', 'false'); });
    if (!tip) return;
    tip.hidden = false; item.setAttribute('aria-expanded', 'true'); mapPlace(map, item, tip);
  }
  function mapHide(map, id) {
    if (!map || (mapPin && mapPin.map === map.id && mapPin.item === id)) return;
    var tip = mapTip(map, id), item = mapItem(map, id);
    if (tip) tip.hidden = true;
    if (item) item.setAttribute('aria-expanded', 'false');
  }
  function mapLater(map, id) { clearTimeout(mapTimer); mapTimer = setTimeout(function () { mapHide(map, id); }, 200); }
  function mapPins(st) {                                               // the pin's mark on the pinned item
    var layer = $q('.map-pins', st.el); if (!layer) return;
    while (layer.firstChild) layer.removeChild(layer.firstChild);
    if (!mapPin || mapPin.map !== st.el.id) return;
    var it = mapItem(st.el, mapPin.item), x, y;
    if (!it) return;
    if (it.classList.contains('map-part')) { var r = mapPartRect(st, it.getAttribute('data-part')); x = r.x + r.w - 6; y = r.y + 4; }
    else if (it.classList.contains('map-line')) { var dd = ($q('.map-stroke', it).getAttribute('d') || '').match(/-?[\d.]+/g); if (!dd) return; x = (Number(dd[0]) + Number(dd[2])) / 2; y = (Number(dd[1]) + Number(dd[3])) / 2; }
    else { var bb = it.closest('.map-box'); if (!bb) return; var br = mapBoxRect(st, bb.getAttribute('data-box')); x = br.x + br.w - 8; y = br.y + 6; }
    var c = document.createElementNS(SVGNS, 'circle'); c.setAttribute('class', 'map-pin'); c.setAttribute('cx', x.toFixed(1)); c.setAttribute('cy', y.toFixed(1)); c.setAttribute('r', '7');
    var dot = document.createElementNS(SVGNS, 'circle'); dot.setAttribute('class', 'map-pin-dot'); dot.setAttribute('cx', x.toFixed(1)); dot.setAttribute('cy', y.toFixed(1)); dot.setAttribute('r', '2.5');
    layer.appendChild(c); layer.appendChild(dot);
  }
  function mapUnpin(back) {
    if (!mapPin) return;
    var map = document.getElementById(mapPin.map), id = mapPin.item; mapPin = null;
    var tip = mapTip(map, id), item = mapItem(map, id);
    if (tip) { tip.classList.remove('is-pinned'); tip.hidden = true; }
    if (map && mapState(map)) mapPins(mapState(map));
    if (item) {
      item.classList.remove('is-pinned'); item.setAttribute('aria-expanded', 'false');
      if (back && item.focus) { mapQuiet = true; item.focus({preventScroll: true}); mapQuiet = false; }   // back on the item, without opening its box again
    }
  }
  function mapPinTo(map, id, quiet) {
    if (!map) return;
    var same = mapPin && mapPin.map === map.id && mapPin.item === id;
    mapUnpin(false); if (same) return;
    mapShow(map, id);
    var tip = mapTip(map, id), item = mapItem(map, id); if (!tip || !item) return;
    tip.classList.add('is-pinned'); item.classList.add('is-pinned'); mapPin = {map: map.id, item: id};
    mapPins(mapState(map));
    var ga = $q('.map-graph-area[data-map-graph]', tip); if (ga) mapGraphDraw(ga);   // the small graph works only in a pinned box
    if (!quiet) { var h = $q('.map-tip-title', tip); if (h) h.focus({preventScroll: true}); }
  }
  // The small graphs (map_view's relations: the engine's responses, linear in the sliders).
  function mapSlider(area, key, label, lo, hi, step, val) {
    var w = document.createElement('label'); w.className = 'map-graph-slider';
    var t = document.createElement('span'); t.className = 'map-graph-slider-label'; t.textContent = label;
    var i = document.createElement('input'); i.type = 'range'; i.min = lo; i.max = hi; i.step = step; i.value = val; i.setAttribute('data-map-slider', key);
    var o = document.createElement('output'); o.className = 'map-graph-out'; o.setAttribute('data-for', key);
    w.appendChild(t); w.appendChild(i); w.appendChild(o); area.appendChild(w); return i;
  }
  function mapGraphDraw(area) {
    var g = JSON.parse(area.getAttribute('data-map-graph')), box = $q('.map-graph', area), map = area.closest('.map'), st = mapState(map); if (!box || !st) return;
    var W = st.d.words.graph;
    if (!area.getAttribute('data-drawn')) {
      var sl = $q('.map-graph-sliders', area); if (!sl) { sl = document.createElement('div'); sl.className = 'map-graph-sliders'; box.parentNode.insertBefore(sl, box.nextSibling); }
      var L = g.sliders || [];
      if (g.kind === 'demand_curve') mapSlider(sl, 'd', L[0] || '', g.x[0], g.x[1], g.step || 0.5, -1);
      else if (g.kind === 'trade_off') { mapSlider(sl, 'cost', L[0] || '', g.cost[0], g.cost[1], g.step || 0.25, 1); mapSlider(sl, 'gap', 'the output gap, in percent', g.x[0], g.x[1], 0.25, 0); }
      else if (g.kind === 'crowding_out') mapSlider(sl, 'g', L[0] || '', g.g[0], g.g[1], g.step || 0.5, 1);
      area.setAttribute('data-drawn', 'true');
    }
    var v = {}; $all('input[data-map-slider]', area).forEach(function (i) { v[i.getAttribute('data-map-slider')] = Number(i.value); });
    var out = function (k, txt) { var o = $q('output[data-for="' + k + '"]', area); if (o) o.textContent = txt; var i = $q('input[data-map-slider="' + k + '"]', area); if (i) i.setAttribute('aria-valuetext', txt); };
    var w = 300, h = 170, l = 44, r = 10, t = 10, b = 30, svg = '';
    var X = function (x, x0, x1) { return l + (x - x0) / (x1 - x0) * (w - l - r); }, Y = function (y, y0, y1) { return t + (1 - (y - y0) / (y1 - y0)) * (h - t - b); };
    var axes = function (x0, x1, y0, y1, xl, yl) {
      return '<line class="map-graph-axis" x1="' + l + '" y1="' + (h - b) + '" x2="' + (w - r) + '" y2="' + (h - b) + '"/><line class="map-graph-axis" x1="' + l + '" y1="' + t + '" x2="' + l + '" y2="' + (h - b) + '"/>' +
             '<text class="map-graph-tick" x="' + l + '" y="' + (h - b + 14) + '" text-anchor="start">' + mapFmt(x0, 1).replace('+', '') + '</text><text class="map-graph-tick" x="' + (w - r) + '" y="' + (h - b + 14) + '" text-anchor="end">' + mapFmt(x1, 1).replace('+', '') + '</text>' +
             '<text class="map-graph-tick" x="' + (l - 4) + '" y="' + (t + 8) + '" text-anchor="end">' + mapFmt(y1, 1).replace('+', '') + '</text><text class="map-graph-tick" x="' + (l - 4) + '" y="' + (h - b) + '" text-anchor="end">' + mapFmt(y0, 1).replace('+', '') + '</text>' +
             '<text class="map-graph-axis-label" x="' + ((l + w - r) / 2) + '" y="' + (h - 2) + '" text-anchor="middle">' + (xl || '') + '</text>' +
             '<text class="map-graph-axis-label" x="' + (l + 4) + '" y="' + (t + 8) + '">' + (yl || '') + '</text>';
    };
    var A = g.axes || [];
    if (g.kind === 'demand_curve') {
      var y = function (x) { return g.slope * x; }, x0 = g.x[0], x1 = g.x[1], y0 = g.y[0], y1 = g.y[1], cl = function (q) { return Math.max(y0, Math.min(y1, q)); };
      svg = axes(x0, x1, y0, y1, A[0], A[1]) + '<line class="map-graph-zero" x1="' + l + '" y1="' + Y(0, y0, y1) + '" x2="' + (w - r) + '" y2="' + Y(0, y0, y1) + '"/>' +
            '<line class="map-graph-needed" x1="' + X(0, x0, x1) + '" y1="' + t + '" x2="' + X(0, x0, x1) + '" y2="' + (h - b) + '"/>' +
            '<line class="map-graph-line" x1="' + X(x0, x0, x1) + '" y1="' + Y(cl(y(x0)), y0, y1) + '" x2="' + X(x1, x0, x1) + '" y2="' + Y(cl(y(x1)), y0, y1) + '"/>' +
            '<circle class="map-graph-point" cx="' + X(v.d, x0, x1) + '" cy="' + Y(cl(y(v.d)), y0, y1) + '" r="5"/>';
      out('d', mapFmt(v.d) + ' ' + W.distance);
      area.setAttribute('data-value', y(v.d).toFixed(4));
      box.setAttribute('aria-label', mapFill(W.spending, {value: mapFmt(y(v.d)) + ' ' + W.percent}));
    } else if (g.kind === 'trade_off') {
      var f = function (x) { return g.slope * x + g.lift * v.cost; }, a0 = g.x[0], a1 = g.x[1], b0 = g.y[0], b1 = g.y[1], c2 = function (q) { return Math.max(b0, Math.min(b1, q)); };
      svg = axes(a0, a1, b0, b1, A[0], A[1]) + '<line class="map-graph-zero" x1="' + l + '" y1="' + Y(0, b0, b1) + '" x2="' + (w - r) + '" y2="' + Y(0, b0, b1) + '"/>' +
            '<line class="map-graph-needed" x1="' + X(0, a0, a1) + '" y1="' + t + '" x2="' + X(0, a0, a1) + '" y2="' + (h - b) + '"/>' +
            '<line class="map-graph-line" x1="' + X(a0, a0, a1) + '" y1="' + Y(c2(f(a0)), b0, b1) + '" x2="' + X(a1, a0, a1) + '" y2="' + Y(c2(f(a1)), b0, b1) + '"/>' +
            '<circle class="map-graph-point" cx="' + X(v.gap, a0, a1) + '" cy="' + Y(c2(f(v.gap)), b0, b1) + '" r="5"/>';
      out('cost', mapFmt(v.cost) + ' ' + W.distance); out('gap', mapFmt(v.gap) + ' ' + W.percent);
      area.setAttribute('data-value', f(v.gap).toFixed(4));
      box.setAttribute('aria-label', mapFill(W.inflation, {value: mapFmt(f(v.gap)) + ' ' + W.distance}));
    } else if (g.kind === 'crowding_out') {
      var rows = [[g.bars[0], v.g, W.percent], [g.bars[1], g.output_share * v.g, W.percent], [g.bars[2], (g.output_share - 1) * v.g, W.percent]];
      var m = Math.max.apply(null, rows.map(function (q) { return Math.abs(q[1]); }).concat([0.01])), mid = w / 2;
      svg = '<line class="map-graph-axis" x1="' + mid + '" y1="' + (t + 14) + '" x2="' + mid + '" y2="' + (h - 4) + '"/>' + rows.map(function (q, j) {
        var yy = t + j * 52, len = q[1] / m * (w / 2 - r - 6);
        return '<text class="map-graph-axis-label" x="4" y="' + (yy + 10) + '">' + q[0] + '</text><text class="map-graph-tick" x="' + (w - r) + '" y="' + (yy + 10) + '" text-anchor="end">' + mapFmt(q[1]) + ' ' + q[2] + '</text>' +
               '<rect class="map-graph-bar' + (q[1] < 0 ? ' is-down' : '') + '" x="' + Math.min(mid, mid + len) + '" y="' + (yy + 16) + '" width="' + Math.abs(len) + '" height="18"/>';
      }).join('');
      out('g', v.g.toFixed(2) + ' ' + W.percent);
      area.setAttribute('data-value', (g.output_share * v.g).toFixed(4));
      box.setAttribute('aria-label', mapFill(W.output, {value: mapFmt(g.output_share * v.g) + ' ' + W.percent}));
    }
    box.innerHTML = '<svg class="map-graph-svg" viewBox="0 0 ' + w + ' ' + h + '" role="img" aria-hidden="true">' + svg + '</svg>';
  }
  function mapAfterRender() {                                         // returns true when it pinned the item a panel asks for
    mapAll();
    var open = !!$q('#game_window .map-panel');
    $all('[data-game="map"]').forEach(function (b) { b.setAttribute('aria-expanded', open ? 'true' : 'false'); });
    var pp = $q('.map[data-pin]:not([data-pinned])');
    if (pp) {                                                         // the panel opened with an item pinned: its box unfolded first
      pp.setAttribute('data-pinned', 'true'); var pm = pp, id = pp.getAttribute('data-pin');
      mapReveal(mapState(pm), id);
      if (pm && mapItem(pm, id)) { mapPin = null; mapPinTo(pm, id); return true; }
    }
    if (!mapPin) return false;
    var map = document.getElementById(mapPin.map), pid = mapPin.item;
    if (!map || !mapItem(map, pid)) { mapPin = null; return false; }
    var t = mapTip(map, pid); if (t && t.classList.contains('is-pinned')) return false;   // the same map: nothing redrawn
    mapReveal(mapState(map), pid); mapPin = null; mapPinTo(map, pid, true);   // a redrawn map keeps its pin, the part's box unfolded
    return false;
  }
  function mapReveal(st, id) {                                         // a part's box unfolded so that the part can be pinned
    if (!st || !st.d.parts[id]) return;
    var b = st.d.parts[id].box; if (st.open[b]) return;
    st.open[b] = true; st.at[b] = mapClamp(st, b, st.at[b]); mapLayout(st);
  }
  // The pointer: a box dragged by any of its points (a click without a move unfolds a folded box or pins a part).
  function mapDown(e, x, y) {
    var t = e.target && e.target.closest ? e.target : null; if (!t) return;
    var box = t.closest('.map-box'); if (!box) return;
    var map = box.closest('.map'), st = mapState(map); if (!st) return;
    var id = box.getAttribute('data-box');
    mapDrag = {map: map, st: st, id: id, x0: x, y0: y, c0: st.at[id].slice(), moved: false, k: mapScale(st)};
  }
  function mapMoveTo(x, y) {
    var m = mapDrag; if (!m) return;
    var dx = (x - m.x0) * m.k, dy = (y - m.y0) * m.k;
    if (!m.moved && Math.abs(dx) + Math.abs(dy) < 4) return;
    if (!m.moved) { m.moved = true; clearTimeout(mapTimer); $all('.map-tip:not(.is-pinned)', m.map).forEach(function (tp) { tp.hidden = true; }); var g = $q('.map-box[data-box="' + m.id + '"]', m.map); if (g) g.classList.add('is-lifted'); }
    var W = m.st.d.canvas[0], H = m.st.d.canvas[1], s = mapSize(m.st, m.id), pad = 0.6;        // within the window, but the box may be pulled a little past it
    mapMove(m.st, m.id, [Math.min(Math.max(m.c0[0] + dx, -s[0] * pad), W + s[0] * pad), Math.min(Math.max(m.c0[1] + dy, -s[1] * pad), H + s[1] * pad)]);
  }
  function mapUp() {
    var m = mapDrag; mapDrag = null; if (!m) return;
    var g = $q('.map-box[data-box="' + m.id + '"]', m.map); if (g) g.classList.remove('is-lifted');
    if (m.moved) { mapDragged = Date.now(); mapSpring(m.st, m.id); }
  }
  document.addEventListener('mousedown', function (e) { if (e.button === 0 || e.button === undefined) mapDown(e, e.clientX, e.clientY); });
  document.addEventListener('mousemove', function (e) { if (mapDrag) { mapMoveTo(e.clientX, e.clientY); if (mapDrag && mapDrag.moved) e.preventDefault(); } });
  document.addEventListener('mouseup', function () { mapUp(); });
  document.addEventListener('touchstart', function (e) { var p = e.touches && e.touches[0]; if (p) mapDown(e, p.clientX, p.clientY); }, {passive: true});
  document.addEventListener('touchmove', function (e) { var p = e.touches && e.touches[0]; if (p && mapDrag) { mapMoveTo(p.clientX, p.clientY); if (mapDrag && mapDrag.moved && e.cancelable) e.preventDefault(); } }, {passive: false});
  document.addEventListener('touchend', function () { mapUp(); });
  // the map's controls, from the document's click handler: true when the click was the map's
  function mapClick(e, t) {
    var mc = t.closest('[data-map]');
    if (mc) {
      var act = mc.getAttribute('data-map'), map = mc.closest('.map'); e.preventDefault();
      if (act === 'unpin') { mapUnpin(true); return true; }
      if (act === 'reset') { mapReset(map); return true; }
      if (act.indexOf('walk_') === 0) { mapWalk(map, act, mc); return true; }
      return true;
    }
    var mi = t.closest('[data-map-item]');
    if (mi) {
      e.preventDefault(); if (Date.now() - mapDragged < 300) return true;   // the click that ends a drag
      var m = mi.closest('.map'), id = mi.getAttribute('data-map-item');
      if (id.indexOf('box-') === 0) { var b = mi.closest('.map-box'); if (b) mapFold(m, b.getAttribute('data-box'), true); return true; }   // a folded box unfolds
      mapPinTo(m, id); return true;
    }
    if (t.closest('.map-box') && Date.now() - mapDragged < 300) { e.preventDefault(); return true; }
    var ob = t.closest('.map-box.is-open');                            // a second click on an unfolded box, beside its parts, folds it
    if (ob) { e.preventDefault(); mapFold(ob.closest('.map'), ob.getAttribute('data-box'), false); return true; }
    return false;
  }
  function mapKey(e) {
    var t = e.target && e.target.closest ? e.target : null; if (!t) return false;
    var box = t.classList && t.classList.contains('map-box') ? t : null;
    if (box && mapKeyMove(e, box)) return true;                        // the arrow keys move a focused box
    if (box && (e.key === 'Enter' || e.key === ' ')) { e.preventDefault(); mapFold(box.closest('.map'), box.getAttribute('data-box'), !box.classList.contains('is-open')); return true; }
    var mk = (e.key === 'Enter' || e.key === ' ') ? t.closest('[data-map-item]') : null;
    if (mk) { e.preventDefault(); mapPinTo(mk.closest('.map'), mk.getAttribute('data-map-item')); return true; }
    return false;
  }

  // --- the task board -------------------------------------------------------------------------------------------------------
  // A step change's auto-open waits while a card or a window covers the line's place (the explanation card, the
  // Compare window, the report drawn at the same moment): boardWait holds the change's data-board-seq and its announcement, and the
  // drop-down opens when the player closes the card (the desk redrawn) or the window (the window slot emptied).
  var boardTimer = null, boardCloser = null, boardWait = null, boardWaitMsg = '';
  function reducedMotion() { return !!(window.matchMedia && window.matchMedia('(prefers-reduced-motion: reduce)').matches); }
  function board() { return $q('.task-board'); }
  function boardBehind(on) { var b = board(); if (b) b.classList.toggle('is-behind', !!on); }   // under an open chat clicked last
  function boardIsOpen() { var b = board(); return !!(b && b.classList.contains('is-open') && b.getAttribute('data-state') !== 'closing'); }
  function boardDisarm() { if (boardCloser) { document.removeEventListener('click', boardCloser, true); boardCloser = null; } }
  function boardArm() {                                               // the next click anywhere closes the drop-down it opened by itself
    boardDisarm();
    boardCloser = function (e) { boardDisarm(); e.boardClosed = true; boardClose(false); };
    document.addEventListener('click', boardCloser, true);
  }
  function boardOpen(auto) {
    var b = board(); if (!b) return;
    var drop = $q('.task-drop', b), line = $q('.task-line', b), note = $q('.task-auto-note', b);
    clearTimeout(boardTimer);
    b.classList.add('is-open'); drop.hidden = false; line.setAttribute('aria-expanded', 'true');
    if (note) note.hidden = !auto;
    boardBehind(auto && chatOpen());                                  // opened by itself: behind an open chat; by the player: in front
    if (reducedMotion()) b.setAttribute('data-state', 'open');
    else {                                                            // rolled up first, then down: the clip's transition runs
      b.setAttribute('data-state', 'opening');
      boardTimer = setTimeout(function () { if (b.getAttribute('data-state') === 'opening') b.setAttribute('data-state', 'open'); }, 20);
    }
    if (auto) boardArm(); else boardDisarm();
  }
  function boardClose(focusLine) {
    var b = board(); if (!b || !b.classList.contains('is-open')) return;
    var drop = $q('.task-drop', b), line = $q('.task-line', b);
    boardDisarm(); clearTimeout(boardTimer); line.setAttribute('aria-expanded', 'false');
    var shut = function () { b.classList.remove('is-open', 'is-behind'); drop.hidden = true; b.setAttribute('data-state', 'closed'); };
    if (reducedMotion()) shut(); else { b.setAttribute('data-state', 'closing'); boardTimer = setTimeout(shut, 240); }
    if (focusLine) line.focus();
  }
  function boardToggle() { if (boardIsOpen()) boardClose(false); else boardOpen(false); }
  function boardCovered() { return !!($q('#game .interim-card') || $q('#game .debrief-slot:not([hidden]) .debrief-window') || $q('#game_window .game-window')); }   // a card (the debrief's), or a window over the desk
  function boardAfterRender() {                                       // a redrawn desk: an auto-open for a step change, announced
    boardDisarm();
    var b = board(); if (!b) { boardWait = null; return; }
    if (b.getAttribute('data-board-auto') === 'true') { b.setAttribute('data-board-auto', 'done'); boardWait = b.getAttribute('data-board-seq'); boardWaitMsg = b.getAttribute('data-announce') || ''; }
    else if (boardWait !== null && b.getAttribute('data-board-seq') !== boardWait) boardWait = null;   // another step's desk: the wait is over
    boardResume();
  }
  function boardResume() {                                            // the waiting auto-open, once no tour, card or window is in its way
    var b = board(); if (!b || boardWait === null || b.getAttribute('data-board-seq') !== boardWait) return;
    if (tour || $q('.tour[data-tour-auto="true"]') || boardCovered()) return;   // a tour first (it calls this when it ends); a card or a window: on its close
    boardWait = null;
    boardOpen(true);
    var live = $q('#board-live'), msg = boardWaitMsg;
    if (live) setTimeout(function () { live.textContent = msg; }, 50);
  }
  function boardWindowChanged() {                                     // the window slot redrawn: a window over an auto-opened drop-down rolls it up
    var b = board(); if (!b) return;                                  // to wait again; a window closed lets a waiting one open
    if (boardCovered()) { if (boardCloser && boardIsOpen()) { boardWait = b.getAttribute('data-board-seq'); boardClose(false); } return; }
    boardResume();
  }
  function boardDone(btn) {                                           // the finished steps listed or folded
    var list = document.getElementById(btn.getAttribute('aria-controls')); if (!list) return;
    var open = btn.getAttribute('aria-expanded') !== 'true';
    btn.setAttribute('aria-expanded', open ? 'true' : 'false'); list.hidden = !open;
  }

  // --- the guided tour --------------------------------------------------------------------------------------------------------
  var tour = null;                                                   // {root, steps, i, back}
  function tourTargets(step) { try { var sels = step.getAttribute('data-target').split(','); for (var i = 0; i < sels.length; i++) { var found = $all(sels[i].trim()); if (found.length) return found; } return []; } catch (e) { return []; } }
  function tourRect(els) {                                            // the union of the elements' boxes
    var r = null;
    els.forEach(function (el) { var b = el.getBoundingClientRect();
      r = r ? {left: Math.min(r.left, b.left), top: Math.min(r.top, b.top), right: Math.max(r.right, b.right), bottom: Math.max(r.bottom, b.bottom)}
            : {left: b.left, top: b.top, right: b.right, bottom: b.bottom}; });
    return r || {left: 0, top: 0, right: 0, bottom: 0};
  }
  function tourPlace(box, r, prefer) {                                // the box beside the element: the preferred side if it fits, else the roomiest
    var vw = window.innerWidth || 1280, vh = window.innerHeight || 800, bw = box.offsetWidth || 420, bh = box.offsetHeight || 260, gap = 16;
    var room = {below: vh - r.bottom, above: r.top, right: vw - r.right, left: r.left};
    var need = {below: bh + gap, above: bh + gap, right: bw + gap, left: bw + gap};
    var side = room[prefer] >= need[prefer] ? prefer : ['below', 'above', 'right', 'left'].sort(function (a, b) { return (room[b] - need[b]) - (room[a] - need[a]); })[0];
    var cx = (r.left + r.right) / 2, cy = (r.top + r.bottom) / 2, x, y;
    if (side === 'below' || side === 'above') { x = Math.max(8, Math.min(cx - bw / 2, vw - bw - 8)); y = side === 'below' ? r.bottom + gap : r.top - gap - bh; }
    else { y = Math.max(8, Math.min(cy - bh / 2, vh - bh - 8)); x = side === 'right' ? r.right + gap : r.left - gap - bw; }
    y = Math.max(8, Math.min(y, vh - bh - 8));
    box.style.left = Math.round(x) + 'px'; box.style.top = Math.round(y) + 'px';
    var arrow = {below: 'top', above: 'bottom', right: 'left', left: 'right'}[side];   // the arrow on the box's side that faces the element
    box.setAttribute('data-arrow', arrow); box.setAttribute('data-side', side);
    var a = $q('.tour-arrow', box);
    if (a) { if (arrow === 'top' || arrow === 'bottom') { a.style.left = Math.round(Math.max(16, Math.min(cx - x, bw - 16))) + 'px'; a.style.top = ''; }
             else { a.style.top = Math.round(Math.max(16, Math.min(cy - y, bh - 16))) + 'px'; a.style.left = ''; } }
  }
  function tourShow(i) {
    var t = tour; if (!t) return;
    t.i = Math.max(0, Math.min(t.steps.length - 1, i));
    $all('.is-tour-target').forEach(function (el) { el.classList.remove('is-tour-target'); });
    t.steps.forEach(function (st, k) { st.hidden = k !== t.i; });
    var st = t.steps[t.i], els = tourTargets(st), box = $q('.tour-box', t.root), frame = $q('.tour-frame', t.root);
    els.forEach(function (el) { el.classList.add('is-tour-target'); });
    var pts = (st.getAttribute('data-points') || '').split(' ').filter(Boolean);
    $all('.is-tour-lit').forEach(function (el) { el.classList.remove('is-tour-lit'); });
    pts.forEach(function (id) { $all('[data-map-item="' + id + '"], .map-line[data-arrows~="' + id + '"]').forEach(function (el) { el.classList.add('is-tour-lit'); }); });
    if (els[0] && els[0].scrollIntoView) els[0].scrollIntoView({block: 'nearest', behavior: 'auto'});   // at once: the frame is measured after it
    tourFrame();
    var title = $q('.tour-title', st); if (title) box.setAttribute('aria-labelledby', title.id);
    var count = $q('.tour-count', box); if (count) count.textContent = (count.getAttribute('data-template') || '%1 / %2').replace('%1', String(t.i + 1)).replace('%2', String(t.steps.length));
    var prev = $q('[data-tour="prev"]', box), next = $q('[data-tour="next"]', box), last = t.i === t.steps.length - 1;
    if (prev) prev.disabled = t.i === 0;
    if (next) { next.textContent = next.getAttribute(last ? 'data-end' : 'data-next'); next.setAttribute('data-last', last ? 'true' : 'false'); }
    box.setAttribute('data-step', st.getAttribute('data-step'));
    if (title) title.focus({preventScroll: true});
  }
  function tourFrame() {                                              // the frame on the step's elements, the box beside them (again on a scroll)
    var t = tour; if (!t) return;
    var st = t.steps[t.i], els = tourTargets(st), box = $q('.tour-box', t.root), frame = $q('.tour-frame', t.root);
    var r = tourRect(els), pad = 6;
    frame.style.left = Math.round(r.left - pad) + 'px'; frame.style.top = Math.round(r.top - pad) + 'px';
    frame.style.width = Math.round(r.right - r.left + 2 * pad) + 'px'; frame.style.height = Math.round(r.bottom - r.top + 2 * pad) + 'px';
    frame.classList.add('is-tour-target');
    tourPlace(box, r, st.getAttribute('data-place') || 'below');
  }
  window.addEventListener('scroll', function () { if (tour) tourFrame(); }, true);
  window.addEventListener('resize', function () { if (tour) tourFrame(); });
  document.addEventListener('animationend', function () { if (tour) tourFrame(); }, true);   // the map panel's drop ended: framed again
  function tourCards() {                                              // the card held while the tour ran opens: its focus
    var held = $all('#game .interim-slot[data-tour-held]');
    held.forEach(function (slot) { slot.hidden = false; slot.removeAttribute('data-tour-held'); });
    return held.length > 0;
  }
  function tourStart() {
    var root = $q('.tour[data-tour-auto="true"]'); if (!root) return false;
    root.setAttribute('data-tour-auto', 'running');
    var steps = $all('.tour-step', root).filter(function (st) { return tourTargets(st).length > 0; });   // an absent element: left out
    if (!steps.length) { root.setAttribute('data-tour-auto', 'done'); if (tourCards()) { var c = $q('#game [data-card-focus]'); if (c) c.focus({preventScroll: true}); } return false; }
    tour = {root: root, steps: steps, i: 0, back: document.activeElement};
    root.hidden = false; document.body.classList.add('tour-open');
    tourShow(Number(root.getAttribute('data-tour-start') || 1) - 1);
    return true;
  }
  function tourEnd() {
    var t = tour; if (!t) return;
    tour = null; t.root.hidden = true; t.root.setAttribute('data-tour-auto', 'done'); document.body.classList.remove('tour-open');
    $all('.is-tour-target').forEach(function (el) { el.classList.remove('is-tour-target'); });
    var card = tourCards() ? $q('#game [data-card-focus]') : null;      // the card the tour held: it opens now, with the focus
    var back = card || (t.back && document.body.contains(t.back) && t.back !== document.body ? t.back : $q('#game [data-card-focus]') || $q('#game [data-game-focus]'));
    if (back && back.focus) back.focus({preventScroll: true});
    boardAfterRender();                                                // a step change's auto-open waited for the tour
    if ($q('#chat-pane') && !chatOpen()) chat(true);                  // the walk-through ends on the chat, which opens (scripts appendix §9)
  }
  function tourKey(e) {                                               // inside the box: Escape ends, Tab stays in the box
    if (e.key === 'Escape') { e.preventDefault(); tourEnd(); return true; }
    var g = e.target && e.target.closest ? e.target.closest('[data-tour="grip"]') : null;
    if (g && /^Arrow/.test(e.key)) { e.preventDefault(); tourMove(g.closest('.tour-graph'), {ArrowLeft: -10, ArrowRight: 10}[e.key] || 0, {ArrowUp: -10, ArrowDown: 10}[e.key] || 0); return true; }
    if (e.key === 'Tab') {
      var box = $q('.tour-box', tour.root), f = $all('button:not([disabled]), [tabindex="-1"]', box).filter(function (el) { return !el.closest('[hidden]'); });
      if (f.length) { var k = f.indexOf(document.activeElement);
        if (e.shiftKey && k <= 0) { e.preventDefault(); f[f.length - 1].focus(); } else if (!e.shiftKey && k === f.length - 1) { e.preventDefault(); f[0].focus(); } }
      return true;
    }
    return false;
  }
  function tourMove(g, dx, dy) {                                      // the small graph moved by its grip
    if (!g) return;
    var x = Number(g.getAttribute('data-dx') || 0) + dx, y = Number(g.getAttribute('data-dy') || 0) + dy;
    g.setAttribute('data-dx', String(x)); g.setAttribute('data-dy', String(y)); g.style.transform = 'translate(' + x + 'px,' + y + 'px)';
  }
  var drag = null;
  document.addEventListener('mousedown', function (e) {
    var g = e.target && e.target.closest ? e.target.closest('[data-tour="grip"]') : null; if (!g) return;
    e.preventDefault(); drag = {g: g.closest('.tour-graph'), x: e.clientX, y: e.clientY};
  });
  document.addEventListener('mousemove', function (e) { if (!drag) return; tourMove(drag.g, e.clientX - drag.x, e.clientY - drag.y); drag.x = e.clientX; drag.y = e.clientY; });
  document.addEventListener('mouseup', function () { drag = null; });

  // --- the Runs screen --------------------------------------------------------------------------------------------------------
  function runsSend(action, slot, extra) {
    var v = {action: action, nonce: Date.now() + Math.random()}, k;
    if (slot !== undefined && slot !== null && slot !== '') v.slot = Number(slot);
    if (extra) for (k in extra) if (Object.prototype.hasOwnProperty.call(extra, k)) v[k] = extra[k];
    pending = true; lastAction = 'runs';
    window.Shiny.setInputValue('runs_action', v, {priority: 'event'});
  }
  function runsClose(box, kind) {                                    // an inline form closed, its opener shown and focused again
    var f = $q(kind === 'create' ? '.run-create' : '.run-rename', box); if (f) f.hidden = true;
    var op = kind === 'create' ? $q('.run-new', box) : $q('[data-runs="rename"]', box), nm = $q('.run-name', box);
    if (kind === 'rename' && nm) nm.hidden = false;
    if (op) { op.hidden = false; op.setAttribute('aria-expanded', 'false'); op.focus(); }
  }
  function runsOpen(box, kind, opener) {
    var f = $q(kind === 'create' ? '.run-create' : '.run-rename', box); if (!f) return;
    f.hidden = false; opener.setAttribute('aria-expanded', 'true');
    if (kind === 'create') opener.hidden = true; else { var nm = $q('.run-name', box); if (nm) nm.hidden = true; }
    var i = $q('.run-input', f); if (i) { i.focus(); if (i.select) i.select(); }
  }
  function runsClick(el) {
    var a = el.dataset.runs, slot = el.dataset.slot, box = el.closest('.run-slot') || document;
    if (a === 'new') { runsOpen(box, 'create', el); return; }
    if (a === 'create-cancel') { runsClose(box, 'create'); return; }
    if (a === 'rename') { runsOpen(box, 'rename', el); return; }
    if (a === 'rename-cancel') { runsClose(box, 'rename'); return; }
    if (a === 'delete' || a === 'reset') {
      var c = $q('[data-confirm="' + a + '"]', box); if (!c) return;
      c.hidden = false; el.setAttribute('aria-expanded', 'true'); var fb = $q('button', c); if (fb) fb.focus(); return; }
    if (a === 'confirm-cancel') {
      var cb = el.closest('[data-confirm]'); if (!cb) return; cb.hidden = true;
      var op = $q('[data-runs="' + cb.dataset.confirm + '"]', box); if (op) { op.setAttribute('aria-expanded', 'false'); op.focus(); } return; }
    if (a === 'delete-confirm') { runsSend('delete', slot); return; }
    if (a === 'reset-confirm') { runsSend('reset', slot); return; }
    runsSend(a, slot);                                               // continue, unlock_all, theory, sign_out, retry
  }

  // --- the login ----------------------------------------------------------------------------------------------------------
  function loginHold(on) { ['#login-user', '#login-password', '#login-form button'].forEach(function (s) { var el = $q(s); if (el) el.disabled = on; }); }
  function signIn() {
    var f = $q('#login-password'), u = $q('#login-user'); if (!f || f.disabled || !u) return;
    var v = f.value; if (!v) { f.focus(); return; }
    var m = $q('#login-message'); if (m) m.textContent = '';
    loginHold(true); pending = true; lastAction = 'login';
    window.Shiny.setInputValue('game_login', {user: u.value, password: v, nonce: Date.now() + Math.random()}, {priority: 'event'});
  }

  // --- the bank's word: the path on the rate chart -----------------------------
  // From topic 4 the rate chart runs into the eight quarters ahead. The editor's data (.word-editor's data-word, 02_Game/ui/desk.R): the coming
  // quarter t, the horizon H, the mode ("path": the switch "Announce a path" starts off; "every", from topic 5: it is locked on, the path's first quarter
  // has no x, and Publish without a path is refused by the bar, nothing sent), whether a path stands
  // (locked: every announced quarter binds, never withdrawn; the switch starts on), the standing rates for t + 1 .. and, in a quarter with news, their room, the cone,
  // the floor, the rate due and the words (no text here). The chart's geometry is the layer's (.path-draft's data-geom). The new path is drawn
  // as solid points the player drags (snapping to the step) or moves by the arrow keys, and typed in the row of fields under the chart; "+"
  // extends it, a new quarter's x removes it and those after it, "Back to the path you announced" restores the standing one; the switch off
  // greys the path typed out and keeps it, nothing sent, and on again brings it back. Each point is compared with its standing rate for display only, by
  // the engine's rule (wordBroken, as ui_word_broken in 02_Game/ui/desk.R: the distance from the segment between the rate and its room, in hundredths,
  // the band b(h) or more); a point on or outside its band turns red with its note, and the bar's band and summary follow. term_check decides
  // at Publish; the editor never shows what a breach costs in trust.
  var word = null;
  function wordRound(v) { var r = Math.round(v); if (Math.abs(v % 1) === 0.5) r = 2 * Math.round(v / 2); return r; }   // R's round, half to even
  function wordBroken(x, a, d, b) {
    var I = wordRound(100 * x), A = wordRound(100 * a), D = wordRound(100 * d), lo = Math.min(A, D), hi = Math.max(A, D);
    return Math.abs(I - Math.min(Math.max(I, lo), hi)) >= wordRound(100 * b);
  }
  function wordFill(t, o) { return String(t).replace(/\{([a-z_]+)\}/g, function (m, k) { return o[k] !== undefined ? String(o[k]) : m; }); }
  function wordNum(s) { var v = parseFloat(String(s).trim().replace(',', '.')); return /^\s*-?[0-9]+([.,][0-9]*)?\s*$/.test(String(s)) ? v : NaN; }
  function wordFmt(v) { return Number(v).toFixed(word ? word.cfg.decimals : 2).replace(/^-/, '\u2212'); }   // the minus sign as the R side writes it
  function wordField(v) { return Number(v).toFixed(word ? word.cfg.decimals : 2); }                          // a field's value, typed back as is
  function rateValue() { var r = $q('#desk-rate'); return r ? wordNum(r.value) : NaN; }
  function wordInit() {
    var el = $q('.word-editor'); word = null; if (!el) return;
    var cfg; try { cfg = JSON.parse(el.getAttribute('data-word')); } catch (err) { return; }
    var fig = el.closest('figure'), g = fig ? $q('.path-draft', fig) : null, geom = null;
    try { geom = g ? JSON.parse(g.getAttribute('data-geom')) : null; } catch (err) { geom = null; }
    cfg.standing = cfg.standing || []; cfg.cone = cfg.cone || [];
    word = {cfg: cfg, el: el, g: g, geom: geom, on: cfg.mode === 'every' || !!cfg.locked || !!cfg.draft, draft: (cfg.draft || cfg.standing).slice(), bad: {}};
    if (cfg.mode === 'every' && !word.draft.length && !isNaN(rateValue())) word.draft = [rateValue()];   // from topic 5: next quarter starts as this one
    wordFields(); wordMarks();
  }
  // the entries of the draft against the standing path: per quarter j (t + 1 + j) its kind (unchanged, revised, breach, new) and its note
  function wordEntry(j) {
    var c = word.cfg, x = word.draft[j];
    if (j >= c.standing.length) return {kind: 'new'};
    var a = c.standing[j], d = c.room && c.room.length > j ? c.room[j] : a, b = c.cone[j];
    var e = {a: a, d: d, b: b, room: Math.abs(d - a) > 1e-9};
    if (isNaN(x) || Math.abs(x - a) <= 1e-9) { e.kind = 'unchanged'; return e; }
    e.kind = wordBroken(x, a, d, b) ? 'breach' : 'revised';
    if (e.kind === 'breach') e.note = e.room ? wordFill(word.cfg.strings.note_room, {room: wordFmt(d), rate: wordFmt(x), announced: wordFmt(a), band: wordFmt(b)})
                                             : wordFill(word.cfg.strings.note_band, {rate: wordFmt(x), announced: wordFmt(a), band: wordFmt(b)});
    return e;
  }
  function wordRateBreach() {
    var c = word.cfg, x = rateValue(); if (c.due === null || c.due === undefined || isNaN(x)) return null;
    var d = c.due_room === null || c.due_room === undefined ? c.due : c.due_room;
    if (!wordBroken(x, c.due, d, c.cone[0])) return null;
    return Math.abs(d - c.due) > 1e-9 ? wordFill(c.strings.note_room, {room: wordFmt(d), rate: wordFmt(x), announced: wordFmt(c.due), band: wordFmt(c.cone[0])})
                                      : wordFill(c.strings.note_band, {rate: wordFmt(x), announced: wordFmt(c.due), band: wordFmt(c.cone[0])});
  }
  // the row of typed fields, the switch and the add button: rebuilt when the path's shape changes (on, off, a quarter added or removed, Back);
  // switched off the fields stay, greyed and disabled
  function wordFields() {
    var c = word.cfg, box = $q('.path-fields', word.el), S = c.strings; if (!box) return;
    var sw = $q('[data-path="switch"]', word.el); if (sw) { sw.setAttribute('aria-checked', word.on ? 'true' : 'false'); sw.disabled = c.mode === 'every'; }
    var q = function (x) { return String(x).replace(/"/g, '&quot;'); }, html = '';
    word.el.classList.toggle('is-off', !word.on);
    word.draft.forEach(function (v, j) {
      var qq = c.t + 1 + j, id = 'path-field-' + qq, last = j === word.draft.length - 1;
      var rm = word.on && j >= c.standing.length && !(c.mode === 'every' && j === 0) ? '<button type="button" class="path-remove" data-path="remove" data-j="' + j + '" aria-label="' + q(wordFill(last ? S.remove_one : S.remove_from, {quarter: qq})) +
               '"><span aria-hidden="true">\u00d7</span></button>' : '';     // a new quarter's x; a standing one binds (Back restores it)
      html += '<div class="path-field' + (word.on ? '' : ' is-off') + '" data-j="' + j + '"><input type="text" inputmode="decimal" autocomplete="off" maxlength="5" class="path-input" id="' + id + '" data-j="' + j + '"' +
              ' aria-label="' + q(wordFill(S.field_label, {quarter: qq})) + '" aria-describedby="' + id + '-note" value="' + (isNaN(v) ? '' : wordField(v)) + '"' + (word.on ? '' : ' disabled') + '>' +
              rm + '<span class="path-field-note" id="' + id + '-note"></span></div>';
    });
    if (word.on && word.draft.length < c.H) {
      var nq = c.t + 1 + word.draft.length;
      html += '<button type="button" class="path-add" data-path="add" aria-label="' + wordFill(S.add_label, {quarter: nq}).replace(/"/g, '&quot;') + '">' + wordFill(S.add, {quarter: nq}) + '</button>';
    }
    box.innerHTML = html;
  }
  // the marks: the fields' notes and classes, the points and the line on the chart, the note of the first breach, the bar's band and summary
  function wordMarks() {
    if (!word) return;
    var c = word.cfg, S = c.strings, n = 0, first = null, entries = word.on ? word.draft.map(function (v, j) { return wordEntry(j); }) : [];
    if (!word.on) $all('.path-field-note', word.el).forEach(function (nt) { nt.textContent = ''; });   // greyed: no notes
    entries.forEach(function (e, j) {
      var f = $q('.path-field[data-j="' + j + '"]', word.el); if (!f) return;
      var note = $q('.path-field-note', f), inp = $q('.path-input', f), bad = !!word.bad[j];
      f.classList.toggle('is-breach', e.kind === 'breach'); f.classList.toggle('is-invalid', bad);
      if (inp) inp.setAttribute('aria-invalid', e.kind === 'breach' || bad ? 'true' : 'false');
      if (note) {                                                     // under the field its band, room or "new"; a breach's full note for screen readers and on hover
        note.textContent = bad ? S.field_invalid : e.kind === 'new' ? S.new : e.room ? wordFill(S.field_room, {room: wordFmt(e.d)}) : wordFill(S.field_band, {band: wordFmt(e.b)});
        if (e.kind === 'breach' && !bad) { var sr = document.createElement('span'); sr.className = 'sr-only'; sr.textContent = ' ' + e.note; note.appendChild(sr); f.setAttribute('title', e.note); }
        else f.removeAttribute('title');
      }
      if (e.kind === 'breach') { n += 1; if (first === null) first = j; }
    });
    var back = $q('[data-path="back"]', word.el);
    if (back) back.hidden = !(word.on && c.standing.length && (word.draft.length !== c.standing.length || word.draft.some(function (v, j) { return isNaN(v) || Math.abs(v - c.standing[j]) > 1e-9; })));
    wordSvg(entries, first);
    var band = $q('.dec-slot[data-slot="band"]'), rb = wordRateBreach();
    if (band && c.due !== null && c.due !== undefined) {
      band.classList.toggle('is-breach', !!rb);
      if (rb) band.setAttribute('title', rb); else band.removeAttribute('title');
      var sr = $q('.sr-only', band); if (!sr) { sr = document.createElement('span'); sr.className = 'sr-only'; band.appendChild(sr); }
      sr.textContent = rb ? ' ' + rb : '';
    }
    var sum = $q('.dec-slot[data-slot="path"]');
    if (sum) {
      var last = Math.min(c.t + word.draft.length, c.T);
      sum.textContent = !word.on ? (c.standing.length ? wordFill(S.path_through, {quarter: Math.min(c.t + c.standing.length, c.T)}) : S.path_none)   // off: the path standing, if any
        : !word.draft.length ? S.path_none : n === 0 ? wordFill(S.path_through, {quarter: last})
        : n === 1 ? wordFill(S.path_breaks_one, {quarter: last}) : wordFill(S.path_breaks_many, {quarter: last, n: n});
      sum.classList.toggle('is-breach', n > 0); sum.removeAttribute('aria-hidden');
    }
  }
  var SVGNS = 'http://www.w3.org/2000/svg';
  function wordX(q) { var g = word.geom; return g.x0 + (q - g.q0) * g.dq; }
  function wordY(v) { var g = word.geom, w = Math.min(Math.max(v, g.lo), g.hi); return g.bot - (w - g.lo) / (g.hi - g.lo) * (g.bot - g.top); }
  function wordSvgEl(name, attrs) { var e = document.createElementNS(SVGNS, name); for (var k in attrs) if (Object.prototype.hasOwnProperty.call(attrs, k)) e.setAttribute(k, attrs[k]); return e; }
  function wordSvg(entries, first) {
    var g = word.g, c = word.cfg; if (!g || !word.geom) return;
    var pts = $all('.path-point', g), rate = rateValue();
    g.classList.toggle('is-off', !word.on);                             // switched off: the path greyed, kept
    if (pts.length !== word.draft.length) { g.innerHTML = ''; pts = []; }
    var line = $q('.path-line', g); if (!line) { line = wordSvgEl('polyline', {'class': 'path-line', fill: 'none', 'stroke-width': '2.5'}); g.appendChild(line); }
    var rp = $q('.path-rate-point', g); if (!rp) { rp = wordSvgEl('circle', {'class': 'path-rate-point', r: '5'}); g.appendChild(rp); }
    var xs = [], ok = !isNaN(rate);
    if (ok) { rp.setAttribute('cx', wordX(c.t).toFixed(1)); rp.setAttribute('cy', wordY(rate).toFixed(1)); rp.removeAttribute('hidden'); xs.push(wordX(c.t).toFixed(1) + ',' + wordY(rate).toFixed(1)); }
    else rp.setAttribute('hidden', '');
    word.draft.forEach(function (v, j) {
      var q = c.t + 1 + j, p = pts[j];
      if (!p) { p = wordSvgEl('circle', {'class': 'path-point', r: '6', tabindex: '0', role: 'slider', 'data-j': String(j), 'aria-valuemin': String(c.floor === null ? word.geom.lo : c.floor), 'aria-valuemax': String(word.geom.hi)}); g.appendChild(p); }
      p.setAttribute('tabindex', word.on ? '0' : '-1'); p.setAttribute('aria-disabled', word.on ? 'false' : 'true');
      if (isNaN(v)) { p.setAttribute('hidden', ''); return; }
      p.removeAttribute('hidden');
      p.setAttribute('cx', wordX(q).toFixed(1)); p.setAttribute('cy', wordY(v).toFixed(1)); p.setAttribute('aria-valuenow', wordField(v));
      p.setAttribute('aria-label', wordFill(c.strings.point_label, {quarter: q, rate: wordFmt(v)}));
      p.classList.toggle('is-breach', !!(entries[j] && entries[j].kind === 'breach'));   // a boolean: switched off there are no entries
      xs.push(wordX(q).toFixed(1) + ',' + wordY(v).toFixed(1));
    });
    line.setAttribute('points', xs.join(' '));
    var old = $q('.path-note', g); if (old) old.parentNode.removeChild(old);
    if (first !== null && entries[first]) {                            // the first breach's note beside its point
      var q1 = c.t + 1 + first, x = wordX(q1), y = wordY(word.draft[first]), txt = entries[first].note, w = Math.min(560, 12 + 6.1 * txt.length);
      var gx = Math.max(word.geom.x0, Math.min(x - w / 2, word.geom.right - w)), gy = y - 34 < word.geom.top ? y + 14 : y - 34;
      var note = wordSvgEl('g', {'class': 'path-note', role: 'note'});
      note.appendChild(wordSvgEl('rect', {x: gx.toFixed(1), y: gy.toFixed(1), width: w.toFixed(1), height: '20', rx: '3'}));
      var tx = wordSvgEl('text', {x: (gx + 6).toFixed(1), y: (gy + 14).toFixed(1), 'font-size': '11'}); tx.textContent = txt; note.appendChild(tx);
      g.appendChild(note);
    }
  }
  function wordSet(j, v, from) {                                       // a point moved (dragged, the arrow keys) or a field typed
    var c = word.cfg;
    if (!isNaN(v) && c.floor !== null && c.floor !== undefined && v < c.floor) v = c.floor;
    word.draft[j] = v; delete word.bad[j];
    if (from !== 'field') { var inp = $q('.path-input[data-j="' + j + '"]', word.el); if (inp) inp.value = isNaN(v) ? '' : wordField(v); forecastSchedule(); }
    wordMarks();
  }
  function wordSnap(v) { var st = word.cfg.step || 0.05; return Math.round(v / st) * st; }
  function wordClick(el) {
    var a = el.getAttribute('data-path'), c = word.cfg; forecastSchedule();
    if (a === 'switch') {                                               // off: the path kept and greyed; on: it is back, or one quarter to start with
      if (c.mode === 'every') return;                                   // from topic 5 locked on
      word.on = !word.on; if (word.on && !word.draft.length) word.draft = c.standing.length ? c.standing.slice() : [isNaN(rateValue()) ? (c.floor || 0) : rateValue()];
      wordFields(); wordMarks(); if (word.on) { var f0 = $q('.path-input', word.el); if (f0) f0.focus(); } return;
    }
    if (a === 'remove') { if (!word.on) return; var jr = parseInt(el.getAttribute('data-j'), 10); if (!(jr >= c.standing.length) || (c.mode === 'every' && jr === 0)) return;   // a new quarter
                          word.draft = word.draft.slice(0, jr); Object.keys(word.bad).forEach(function (k) { if (Number(k) >= jr) delete word.bad[k]; });   // and those after it
                          wordFields(); wordMarks(); var fr = $all('.path-input', word.el), ad = $q('[data-path="add"]', word.el);
                          if (ad) ad.focus(); else if (fr.length) fr[fr.length - 1].focus(); return; }
    if (a === 'add') { if (word.draft.length >= c.H) return; var lv = word.draft.length ? word.draft[word.draft.length - 1] : rateValue(); word.draft.push(isNaN(lv) ? (c.floor || 0) : lv);
                       wordFields(); wordMarks(); var fs = $all('.path-input', word.el); if (fs.length) fs[fs.length - 1].focus(); return; }
    if (a === 'back') { word.draft = c.standing.slice(); word.bad = {}; wordFields(); wordMarks(); var f1 = $q('.path-input', word.el); if (f1) f1.focus(); }
  }
  // dragging a point: its value from the pointer's height on the chart, snapped to the step
  var wordDrag = null;
  document.addEventListener('pointerdown', function (e) {
    var p = e.target && e.target.closest ? e.target.closest('.path-point') : null; if (!p || !word || !word.on) return;   // a greyed path does not move
    e.preventDefault(); wordDrag = {j: parseInt(p.getAttribute('data-j'), 10), p: p}; if (p.setPointerCapture) try { p.setPointerCapture(e.pointerId); } catch (err) { /* ignore */ }
    p.focus();
  });
  document.addEventListener('pointermove', function (e) {
    if (!wordDrag || !word) return;
    var svg = wordDrag.p.ownerSVGElement, m = svg && svg.getScreenCTM ? svg.getScreenCTM() : null; if (!m) return;
    var pt = svg.createSVGPoint(); pt.x = e.clientX; pt.y = e.clientY; var loc = pt.matrixTransform(m.inverse()), g = word.geom;
    var v = g.lo + (g.bot - loc.y) / (g.bot - g.top) * (g.hi - g.lo);
    wordSet(wordDrag.j, wordSnap(Math.min(Math.max(v, g.lo), g.hi)), 'drag');
  });
  document.addEventListener('pointerup', function () { wordDrag = null; });
  document.addEventListener('keydown', function (e) {
    var p = e.target && e.target.closest ? e.target.closest('.path-point') : null; if (!p || !word || !word.on) return;
    var st = word.cfg.step || 0.05, j = parseInt(p.getAttribute('data-j'), 10), v = word.draft[j];
    if (e.key === 'ArrowUp' || e.key === 'ArrowRight') { e.preventDefault(); wordSet(j, wordSnap((isNaN(v) ? 0 : v) + st), 'key'); }
    else if (e.key === 'ArrowDown' || e.key === 'ArrowLeft') { e.preventDefault(); wordSet(j, wordSnap((isNaN(v) ? 0 : v) - st), 'key'); }
  }, true);
  document.addEventListener('input', function (e) {
    var el = e.target; if (el && el.id === 'desk-rate' && !word) { forecastSchedule(); return; }
    if (!el || !word) return;
    if (el.id === 'desk-rate') { wordMarks(); forecastSchedule(); return; }
    if (el.classList && el.classList.contains('path-input')) {
      var j = parseInt(el.getAttribute('data-j'), 10), v = wordNum(el.value);
      if (isNaN(v)) { word.draft[j] = NaN; word.bad[j] = true; wordMarks(); return; }
      wordSet(j, v, 'field'); forecastSchedule();
    }
  });
  // the path Publish sends: the draft's rates (a field holding no number sent as typed, which the server refuses with its line)
  function wordPath() {
    if (!word || !word.on || !word.draft.length) return null;
    return word.draft.map(function (v, j) { if (!word.bad[j]) return v; var inp = $q('.path-input[data-j="' + j + '"]', word.el); return inp ? inp.value : ''; });
  }

  // --- the staff's forecast ---------------------------------------------
  // From topic 5 the block "Staff estimates and projections" carries "Quarter N, if you publish this" (.fig-forecast): a third of a second after
  // the player stops typing (the rate, the path's fields, a point moved), the decision typed goes to the server (game_forecast); its answer
  // replaces the section and redraws each chart's projected point and band from its numbers (.proj-point's data-geom: the quarter's x and the
  // chart's y mapping). Never a recommendation; the server computes, the browser draws.
  var fcTimer = null;
  function forecastSchedule() {
    if (!$q('[data-forecast]')) return;
    clearTimeout(fcTimer); fcTimer = setTimeout(forecastSend, 333);
  }
  function forecastSend() {
    var r = $q('#desk-rate'); if (!r || !window.Shiny) return;
    var v = {rate: r.value, nonce: Date.now() + Math.random()}, path = wordPath(); if (path) v.path = path;
    window.Shiny.setInputValue('game_forecast', v, {priority: 'event'});
  }
  function forecastDraw(name, pt) {
    var g = $q('.proj-point[data-var="' + name + '"]'); if (!g) return;
    var geom; try { geom = JSON.parse(g.getAttribute('data-geom')); } catch (err) { return; }
    var y = function (v) { var w = Math.min(Math.max(v, geom.lo), geom.hi); return (geom.bot - (w - geom.lo) / (geom.hi - geom.lo) * (geom.bot - geom.top)).toFixed(1); };
    var x = Number(geom.x).toFixed(1);
    g.innerHTML = pt ? '<line class="proj-band" x1="' + x + '" x2="' + x + '" y1="' + y(pt.hi) + '" y2="' + y(pt.lo) + '" stroke-width="6" stroke-opacity="0.3" stroke-linecap="round"></line>' +
                       '<circle class="proj-mean" cx="' + x + '" cy="' + y(pt.mean) + '" r="4.5" fill="#FFFFFF" stroke-width="2"></circle>' : '';
  }

  // --- the decision ---------------------------------------------------------------------------------------------------------
  // The bar, one line: the rate as typed, from topic 4 the new path (wordPath),
  // whether the player confirmed a warned decision. The bar's own rule where the topic's economy has no floor (topic 1): a rate below the
  // field's data-min is refused here with the field's data-below line and nothing is sent (the server refuses it too); from topic 2 the
  // engine's floor refuses it at the server (term_check). A warned decision opens the confirm step with every breach the server names.
  function publish(confirmed) {
    var pb = $q('.dec-publish'); if (pb && pb.disabled) return;
    var c = $q('#desk-confirm'); if (c) c.hidden = true;
    var m = $q('#desk-message'); if (m) m.textContent = '';
    var r = $q('#desk-rate'), v = r ? parseFloat(String(r.value).trim().replace(',', '.')) : NaN;
    if (r && r.hasAttribute('data-min') && !isNaN(v) && v < parseFloat(r.getAttribute('data-min'))) {
      if (m) m.textContent = r.getAttribute('data-below') || ''; r.focus(); return;
    }
    var extra = {rate: r ? r.value : '', confirmed: !!confirmed}, path = wordPath();
    var gr = r ? r.getAttribute('data-guided-rate') : null;
    if (gr !== null) {
      var gp = (r.getAttribute('data-guided-plan') || '').split(' ').filter(Boolean), okg = !isNaN(v) && Math.abs(v - Number(gr)) < 0.005;
      if (okg && gp.length) okg = !!path && path.length === gp.length && gp.every(function (x, i) { return Math.abs(wordNum(String(path[i])) - Number(x)) < 0.005; });
      var fl = $q('#desk-chip'); if (fl) fl.classList.toggle('is-wrong', !okg); if (!okg) return;
    }
    if (word && word.cfg.mode === 'every' && !path) { if (m) m.textContent = word.cfg.strings.error_every || ''; return; }   // from topic 5 a path every quarter
    if (path) extra.path = path;
    send('publish', null, extra);
  }

  $(document).on('shiny:connected', function () {
    window.Shiny.addCustomMessageHandler('game_tab', function (on) {
      var was = document.body.classList.contains('is-game');
      document.body.classList.toggle('is-game', !!on); window.scrollTo(0, 0);
      if (on && !was) setTimeout(function () { var h = $q('#game [data-game-focus]'); if (h) h.focus({preventScroll: true}); }, 0);   // back from the Theory
    });
    window.Shiny.addCustomMessageHandler('game_decision', function (msg) {
      var m = $q('#desk-message'), c = $q('#desk-confirm');
      if (msg.status === 'confirm' && c) {
        var l = $q('#desk-confirm-list', c);                           // every breach named
        if (l) { l.innerHTML = ''; (msg.items || []).forEach(function (t) { var li = document.createElement('li'); li.textContent = t; l.appendChild(li); }); }
        c.hidden = false; var b = $q('[data-desk="publish-anyway"]', c); if (b) b.focus(); }
      else if (m) { m.textContent = msg.message || ''; var r = $q('#desk-rate'); if (r) r.focus(); }
    });
    window.Shiny.addCustomMessageHandler('game_paper', function (msg) {   // the morning edition in
      var ph = $q('#game_screen .paper-folded-wrap.is-printing'), t = document.createElement('div');
      if (screenView() !== msg.view || !ph || ph.getAttribute('data-paper-quarter') !== String(msg.quarter)) return;
      t.innerHTML = msg.folded; var f = t.firstElementChild; if (!f) return; ph.parentNode.replaceChild(f, ph);
      var room = $q('#game_screen .desk-room'); t.innerHTML = msg.overlay;
      if (!overlay() && room && t.firstElementChild) room.parentNode.insertBefore(t.firstElementChild, room.nextSibling);
      var b = $q('#game_screen .dec-publish[data-paper-wait]'); if (b) { b.textContent = msg.publish; b.removeAttribute('data-paper-wait'); b.disabled = false; }
      var n = document.createElement('p'); n.className = 'paper-arrived'; n.setAttribute('role', 'status'); f.insertBefore(n, f.firstChild);
      setTimeout(function () { n.textContent = msg.notice; }, 60);
      setTimeout(function () { if (n.parentNode) n.parentNode.removeChild(n); }, 7200);
      if (tour) { tourTargets(tour.steps[tour.i]).forEach(function (el) { el.classList.add('is-tour-target'); }); tourFrame(); }   // a walk-through's frame on it
    });
    window.Shiny.addCustomMessageHandler('game_forecast', function (msg) {   // the staff's projection for the decision typed (topic 5)
      if (!$q('[data-forecast]')) return;
      ['inflation', 'output', 'unemployment'].forEach(function (k) { forecastDraw(k, msg.points ? msg.points[k] : null); });
    });
    window.Shiny.addCustomMessageHandler('game_login', function (msg) {
      var f = $q('#login-password'), m = $q('#login-message'); if (f) f.value = '';
      window.Shiny.setInputValue('game_login', {clear: true, nonce: Date.now() + Math.random()}, {priority: 'event'});   // the entry not left in the inputs
      if (msg.status === 'ok') return;                                  // the server draws the next screen
      pending = false;
      if (m) m.textContent = msg.message || '';
      loginHold(true);
      setTimeout(function () { loginHold(false); var g = $q('#login-password'); if (g) g.focus(); }, Math.max(0, Number(msg.wait || 0) * 1000));
    });
    window.Shiny.addCustomMessageHandler('game_exhibit', function (msg) {
      var body = document.getElementById('exhibit-body-' + msg.id); if (body) body.innerHTML = msg.html;
      if (msg.shown) $all('[data-ex-in]').forEach(function (o) { var k = o.getAttribute('data-ex-in'); if (msg.shown[k] !== undefined) o.textContent = msg.shown[k]; });
      var sl = document.querySelector('input[data-exhibit="' + msg.id + '"]');   // the slider's value read aloud as the figure it shows
      if (sl && msg.shown && msg.shown[sl.dataset.var] !== undefined) sl.setAttribute('aria-valuetext', msg.shown[sl.dataset.var]);
    });
  });
  $(document).on('shiny:value', function (e) {
    if (e.name === 'game_screen') setTimeout(function () { if ($q('#game .game-runs[data-state="connecting"]')) runsSend('load'); }, 0);   // the runs asked for
    if (e.name === 'topbar') { setTimeout(function () { var b = $q('.theory-back'); if (b) b.focus({preventScroll: true}); }, 0); return; }   // the Theory opened
    if (e.name === 'game_window') {
      setTimeout(function () { boardWindowChanged(); if (mapAfterRender()) return; if (tourStart()) return;   // the map's own step at its first opening
        var h = $q('#game_window .window-title'); if (h) { h.setAttribute('tabindex', '-1'); h.focus({preventScroll: true}); } }, 0);
      return;
    }
    if (e.name !== 'game_screen') return;
    var keep = !pending || lastAction === 'publish';                  // not the player's own action, or Publish:
    var held = keep ? {view: kept.view, panel: kept.panel, body: kept.body, page: kept.page, paper: pending ? false : kept.paper, spread: kept.spread} : null;
    setTimeout(function () { if (held) keepRestore(held); else keepNote(); }, 0);   // the same view kept where the player scrolled
    setTimeout(tocAfterRender, 0);                                     // the table of contents' chapters as the player left them
    setTimeout(wordInit, 0);                                           // the path's editor from topic 4, drawn from its data
    boardDisarm(); if (tour) { tour = null; document.body.classList.remove('tour-open'); }
    setTimeout(function () { if (!tourStart()) boardAfterRender(); }, 30);   // a tour first (after the focus has moved), then the board
    setTimeout(mapAfterRender, 0);
    setTimeout(function () { var p = $q('#chat-pane'); if (p && !p.hidden) chatBottom(); }, 0);   // an open chat stays at its newest message
    if (!pending) return;
    pending = false;
    if (lastAction === 'debrief_ask') { setTimeout(function () { var t = $q('#debrief-question'); if (t && !t.disabled) t.focus({preventScroll: true}); }, 0); return; }
    if (lastAction === 'debrief_page') { setTimeout(function () { var b = $q('.debrief-tab.is-current'); if (b) b.focus({preventScroll: true}); }, 0); return; }
    if (lastAction === 'ask') {                                     // the reply arrived: the pane open at its end, the focus on the field
      setTimeout(function () { var l = $q('.chat-list'); if (l) l.scrollTop = l.scrollHeight; var t = $q('#chat-question'); if (t && !t.disabled) t.focus({preventScroll: true}); }, 0);
      return;
    }
    var top = lastAction !== 'publish';                                // after Publish the page stays where it was
    setTimeout(function () { var h = $q('#game [data-card-focus]') || $q('#game [data-game-focus]'); if (h) h.focus({preventScroll: true}); if (top) window.scrollTo(0, 0); }, 0);
  });

  document.addEventListener('click', function (e) {
    var t = e.target.closest ? e.target : null; if (!t) return;
    var tb = t.closest('[data-tour]');
    if (tb && tour) { e.preventDefault(); var ta = tb.getAttribute('data-tour');
      if (ta === 'prev') tourShow(tour.i - 1); else if (ta === 'next') { if (tour.i >= tour.steps.length - 1) tourEnd(); else tourShow(tour.i + 1); }
      else if (ta === 'skip') tourEnd();                                 // the first steps' Skip
      return; }
    if (t.closest('.task-box')) boardBehind(false); else if (t.closest('#chat-pane') || t.closest('.chat-bar')) boardBehind(true);   // the one clicked last on top
    var bd = t.closest('[data-board]');
    if (bd) { e.preventDefault(); if (e.boardClosed) return; if (bd.dataset.board === 'toggle') boardToggle(); else if (bd.dataset.board === 'done') boardDone(bd); return; }
    var tc = t.closest('[data-toc]');                                  // a chapter's row in the Menu's table of contents
    if (tc) { e.preventDefault(); var op = tc.getAttribute('aria-expanded') !== 'true'; tocSet(tc, op); toc[tc.getAttribute('data-toc')] = op; return; }
    var pg = t.closest('[data-paper-goto]');                           // an index line: its page's spread
    if (pg) { e.preventDefault(); showSpread(Math.floor((parseInt(pg.getAttribute('data-paper-goto'), 10) - 1) / 2)); return; }
    var p = t.closest('[data-paper]');
    if (p) { var a = p.dataset.paper;
      if (a === 'stage') { if (t === p) { e.preventDefault(); foldPaper(); } return; }   // a click beside the paper folds it
      e.preventDefault();
      if (a === 'open') openPaper(); else if (a === 'fold') foldPaper(); else if (a === 'prev') showSpread(spread - 1); else if (a === 'next') showSpread(spread + 1);
      else if (a === 'selection') toggleSelection();
      return; }
    if (t.id === 'paper-overlay') { e.preventDefault(); foldPaper(); return; }
    var c = t.closest('[data-chat]');
    if (c && c.dataset.chat === 'ask') { e.preventDefault(); ask(); return; }
    if (t.closest('[data-debrief="ask"]')) { e.preventDefault(); debriefAsk(); return; }
    if (c) { e.preventDefault(); chat(c.dataset.chat === 'toggle' ? !chatOpen() : false); return; }
    var wp = t.closest('[data-path]');
    if (wp && word) { e.preventDefault(); wordClick(wp); return; }
    var d = t.closest('[data-desk]');
    if (d) { var k = d.dataset.desk;
      if (k === 'record') { e.preventDefault(); var lst = document.getElementById('dec-record-list'); if (!lst) return;   // the record line
        var open = lst.hidden; lst.hidden = !open; d.setAttribute('aria-expanded', open ? 'true' : 'false'); return; }
      if (k === 'floor') { e.preventDefault(); var rf = $q('#desk-rate'); if (rf) { rf.value = Number(d.getAttribute('data-value')).toFixed(word ? word.cfg.decimals : 2); rf.dispatchEvent(new window.Event('input', {bubbles: true})); rf.focus(); } return; }   // Set to the floor
      if (k === 'publish-anyway') { e.preventDefault(); publish(true); return; }
      if (k === 'change-rate') { e.preventDefault(); $q('#desk-confirm').hidden = true; var rr = $q('#desk-rate'); if (rr) rr.focus(); return; }
      if (k === 'publish') { e.preventDefault(); publish(false); return; }
    }
    if (mapClick(e, t)) return;                                        // the map's controls, boxes, parts and arrows
    var ru = t.closest('[data-runs]');
    if (ru && ru.tagName !== 'INPUT') { e.preventDefault(); runsClick(ru); return; }
    var b = t.closest('[data-game]');
    if (!b || b.getAttribute('aria-disabled') === 'true') return;
    e.preventDefault();
    if (b.dataset.confirm && !window.confirm(b.dataset.confirm)) return;   // the topic's reset asks first, in the browser's dialog
    send(b.dataset.game, b);
  });
  document.addEventListener('keyup', function (e) {                   // Space's click on keyup suppressed: the keydown above toggled the board
    if (e.key === ' ' && e.target && e.target.closest && e.target.closest('[data-board]')) e.preventDefault();
  });
  document.addEventListener('submit', function (e) {
    if (e.target && e.target.id === 'desk-decision') { e.preventDefault(); publish(false); }
    else if (e.target && e.target.id === 'chat-form') { e.preventDefault(); ask(); }
    else if (e.target && e.target.id === 'debrief-chat-form') { e.preventDefault(); debriefAsk(); }
    else if (e.target && e.target.id === 'login-form') { e.preventDefault(); signIn(); }
    else if (e.target && e.target.classList && e.target.classList.contains('run-form')) {   // a new run's name, or a run's new name
      e.preventDefault(); var i = $q('.run-input', e.target), v = i ? i.value.replace(/^\s+|\s+$/g, '') : '';
      if (!v) { if (i) i.focus(); return; }
      runsSend(e.target.classList.contains('run-create') ? 'create' : 'rename', e.target.dataset.slot, {name: v});
    }
  });
  document.addEventListener('keydown', function (e) {
    if (tour && tourKey(e)) return;                                    // the tour holds the keyboard while it runs
    if (e.key === 'Enter' && !e.shiftKey && e.target && e.target.id === 'chat-question') { e.preventDefault(); ask(); return; }
    var bk = (e.key === 'Enter' || e.key === ' ') && e.target && e.target.closest ? e.target.closest('[data-board]') : null;
    if (bk) { e.preventDefault(); boardDisarm(); if (bk.dataset.board === 'toggle') boardToggle(); else boardDone(bk); return; }   // the key's own click suppressed
    if (e.key === 'Escape' && boardIsOpen()) { e.preventDefault(); boardClose(true); return; }
    if (mapKey(e)) return;                                             // a focused box moved or unfolded, an item pinned
    if (e.key === 'Escape') {
      var rf = e.target && e.target.closest ? e.target.closest('.run-form') : null;
      if (rf) { e.preventDefault(); runsClose(rf.closest('.run-slot') || document, rf.classList.contains('run-create') ? 'create' : 'rename'); return; }
      if (paperOpen()) { e.preventDefault(); foldPaper(); return; }
      if (mapPin) { e.preventDefault(); mapUnpin(true); return; }
      if (windowOpen()) { e.preventDefault(); send('window_close'); return; }
      var rl = document.getElementById('dec-record-list');                 // the record line's list: closed, the focus on its line
      if (rl && !rl.hidden) { e.preventDefault(); rl.hidden = true; var rb = $q('.dec-record-line'); if (rb) { rb.setAttribute('aria-expanded', 'false'); rb.focus(); } return; }
      if (chatOpen()) { e.preventDefault(); chat(false); return; }
    }
    if (paperOpen() && (e.key === 'ArrowRight' || e.key === 'ArrowLeft')) { e.preventDefault(); showSpread(spread + (e.key === 'ArrowRight' ? 1 : -1)); }
  });
  // the map's explanation windows on hover and focus: a short delay lets the pointer move from a part into its window
  document.addEventListener('mouseover', function (e) {
    var t = e.target && e.target.closest ? e.target : null; if (!t) return;
    var it = t.closest('[data-map-item]'); if (it) { mapShow(it.closest('.map'), it.getAttribute('data-map-item')); return; }
    if (t.closest('.map-tip')) clearTimeout(mapTimer);
  });
  document.addEventListener('mouseout', function (e) {
    var t = e.target && e.target.closest ? e.target : null; if (!t) return;
    var from = t.closest('[data-map-item]') || t.closest('.map-tip'); if (!from) return;
    var id = from.getAttribute('data-map-item') || from.getAttribute('data-tip-for');
    var to = e.relatedTarget && e.relatedTarget.closest ? e.relatedTarget : null;
    if (to) {                                                         // still within the part or its window: nothing to hide
      var ti = to.closest('[data-map-item]'), tt = to.closest('.map-tip');
      if ((ti && ti.getAttribute('data-map-item') === id) || (tt && tt.getAttribute('data-tip-for') === id)) return;
    }
    mapLater(from.closest('.map'), id);
  });
  document.addEventListener('focusin', function (e) {
    var it = e.target && e.target.closest ? e.target.closest('[data-map-item]') : null;
    if (it && !mapQuiet) mapShow(it.closest('.map'), it.getAttribute('data-map-item'));
  });
  document.addEventListener('focusout', function (e) {
    var it = e.target && e.target.closest ? e.target.closest('[data-map-item]') : null; if (!it) return;
    var id = it.getAttribute('data-map-item'), to = e.relatedTarget && e.relatedTarget.closest ? e.relatedTarget : null;
    if (to && to.closest('.map-tip[data-tip-for="' + id + '"]')) return;
    mapHide(it.closest('.map'), id);
  });
  // an exhibit's slider: its value to the server, which computes the exhibit again
  function exhibitSend(el) {
    window.Shiny.setInputValue('game_exhibit', {id: el.dataset.exhibit, var: el.dataset.var, value: el.value, nonce: Date.now() + Math.random()}, {priority: 'event'});
  }
  document.addEventListener('input', function (e) {
    var el = e.target; if (!el || !el.dataset) return;
    if (el.dataset.mapSlider) { var ga = el.closest('.map-graph-area'); if (ga) mapGraphDraw(ga); return; }   // a small graph's slider
    if (!el.dataset.exhibit) return;
    clearTimeout(exTimer); exTimer = setTimeout(function () { exhibitSend(el); }, 150);
  });
  document.addEventListener('change', function (e) {
    var el = e.target; if (!el || !el.dataset) return;
    if (el.dataset.exhibit) { clearTimeout(exTimer); exhibitSend(el); return; }
    if (el.dataset.runs === 'setting') { runsSend('setting', el.dataset.slot, {key: el.dataset.key, value: !!el.checked}); return; }   // the run's setting
    if (el.dataset.report === 'rule') { var p1 = el.closest('.report-body') && el.closest('.report-body').querySelector('.plot1'); if (p1) p1.classList.toggle('show-rule', el.checked); }   // the rule as a toggle
  });
  window.gameStaticInit = function () {
    wordInit(); tocAfterRender(); mapAfterRender(); if (!tourStart()) boardAfterRender();
    var p = $q('#chat-pane'); if (p && !p.hidden) chatBottom();
    var o = overlay(); if (o && !o.hidden) { var sp = Number(o.getAttribute('data-open-spread') || 1) - 1; document.body.classList.add('paper-open'); showSpread(sp); paperFit(); }
  };
  if (window.Shiny && window.Shiny.isShim) document.addEventListener('DOMContentLoaded', function () { setTimeout(window.gameStaticInit, 0); });

})();
