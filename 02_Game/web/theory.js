// The theory section's modules in the browser: each module's sliders
// recompute its picture and readout with the module's own textbook formulas. Written with 02_Game/content/theory/.
//  - every element with data-theory-go="P5:7" opens chapter P5's topic 7: it is sent to the server as the input theory_nav
//    {chapter, k, nonce}; data-theory-step names the step to scroll to on the page the server then draws;
//  - the reading statuses of the rail (not seen, in progress, finished) are kept for the browser's session (sessionStorage): a topic
//    opened is in progress, a topic left with Next topic or Continue to chapter n is finished, Mark chapter as read finishes the chapter;
//  - term boxes open on hover, on focus and on a click (a tap), stay while hovered and close with Escape (WCAG 2.1 SC 1.4.13);
//  - a module (.theory-module) reads its configuration from data-config (02_Game/ui/theory.R: modules.yaml's entry, the step's controls
//    and view, the data of 02_Game/content/theory/economy.yaml) and draws its picture, its readout (now, and the change against the
//    example economy) and its caption; Back to the example economy resets the sliders. Nothing goes to the server.
(function () {
  'use strict';
  var NS = 'http://www.w3.org/2000/svg', MINUS = '−', STORE = 'mpgame.theory.read';
  var pending = null;                                                  // the step to scroll to after the server's next page

  // --- helpers -------------------------------------------------------------------------------------------------------------------
  function all(sel, root) { return Array.prototype.slice.call((root || document).querySelectorAll(sel)); }
  function svgEl(tag, attrs, parent, text) {
    var e = document.createElementNS(NS, tag);
    for (var k in attrs) if (attrs[k] !== null && attrs[k] !== undefined) e.setAttribute(k, attrs[k]);
    if (text !== undefined && text !== null) e.textContent = text;
    if (parent) parent.appendChild(e);
    return e;
  }
  function htmlEl(tag, attrs, parent, text) {
    var e = document.createElement(tag);
    for (var k in attrs) if (attrs[k] !== null && attrs[k] !== undefined) e.setAttribute(k, attrs[k]);
    if (text !== undefined && text !== null) e.textContent = text;
    if (parent) parent.appendChild(e);
    return e;
  }
  function fill(tpl, v) { return String(tpl || '').replace(/\{(\w+)\}/g, function (m, k) { return v[k] !== undefined ? v[k] : m; }); }
  function rnd(x, d) { var f = Math.pow(10, d), r = Math.round(x * f) / f; return Math.abs(r) < 1e-12 ? 0 : r; }
  // a number to at most d decimals (trailing zeros dropped), thousands marked, the typographic minus
  function num(x, d) {
    if (x === null || x === undefined || isNaN(x) || !isFinite(x)) return '–';
    var r = rnd(x, d), s = Math.abs(r).toFixed(d);
    if (d > 0) s = s.replace(/0+$/, '').replace(/\.$/, '');
    var p = s.split('.'); p[0] = p[0].replace(/\B(?=(\d{3})+(?!\d))/g, ',');
    return (r < 0 ? MINUS : '') + p.join('.');
  }
  function signed(x, d) { var r = rnd(x, d); return r === 0 ? '–' : (r > 0 ? '+' : '') + num(r, d); }
  function merge(a, b) { var o = {}, k; for (k in a) o[k] = a[k]; for (k in b) o[k] = b[k]; return o; }
  function reduced() { return !!(window.matchMedia && window.matchMedia('(prefers-reduced-motion: reduce)').matches); }
  // a figure's frame: the svg in the module's picture slot, with scales x and y over the plot area
  function frame(m, w, h, label, cls, keep) {
    var slot = m.box.querySelector('.tm-figure');
    if (!keep) slot.innerHTML = '';
    return svgEl('svg', {'class': 'tfig tm-svg ' + (cls || ''), viewBox: '0 0 ' + w + ' ' + h, role: 'img', 'aria-label': label}, slot);
  }
  function scale(a0, a1, p0, p1) { return function (v) { return p0 + (v - a0) / (a1 - a0) * (p1 - p0); }; }
  function line(g, x1, y1, x2, y2, cls) { return svgEl('line', {x1: x1.toFixed(1), y1: y1.toFixed(1), x2: x2.toFixed(1), y2: y2.toFixed(1), 'class': cls}, g); }
  function text(g, x, y, s, cls, anchor) { return svgEl('text', {x: x.toFixed(1), y: y.toFixed(1), 'class': cls || '', 'text-anchor': anchor || 'start'}, g, s); }
  function poly(g, xs, ys, cls) { var p = []; for (var i = 0; i < xs.length; i++) p.push(xs[i].toFixed(1) + ',' + ys[i].toFixed(1)); return svgEl('polyline', {points: p.join(' '), 'class': cls}, g); }
  function dot(g, x, y, cls, r) { return svgEl('circle', {cx: x.toFixed(1), cy: y.toFixed(1), r: r || 5, 'class': cls}, g); }
  function rect(g, x, y, w, h, cls, title) { var r = svgEl('rect', {x: x.toFixed(1), y: y.toFixed(1), width: Math.max(w, 0).toFixed(1), height: Math.max(h, 0).toFixed(1), 'class': cls}, g); if (title) svgEl('title', {}, r, title); return r; }
  function vtext(g, x, y, s, cls) { return svgEl('text', {transform: 'translate(' + x + ',' + y + ') rotate(-90)', 'class': cls || 'tf-lab', 'text-anchor': 'middle'}, g, s); }
  // grid lines and tick labels: horizontal lines at ys, vertical ticks at xs
  function grid(g, X, Y, xs, ys, fx, fy, x0, x1, y0, y1) {
    ys.forEach(function (v) { line(g, X(x0), Y(v), X(x1), Y(v), 'tf-grid'); text(g, X(x0) - 8, Y(v) + 4, fy(v), 'tf-tick', 'end'); });
    xs.forEach(function (v) { text(g, X(v), Y(y0) + 18, fx(v), 'tf-tick', 'middle'); });
    line(g, X(x0), Y(y0), X(x1), Y(y0), 'tf-axis'); line(g, X(x0), Y(y0), X(x0), Y(y1), 'tf-axis');
  }
  function steps(a, b, by) { var o = []; for (var v = a; v <= b + 1e-9; v += by) o.push(rnd(v, 6)); return o; }
  // the readout: the rows' values now and their change against the example economy
  function readout(m, rows, now, base) {
    var t = m.box.querySelector('.p3-readout'); if (!t) return; t.innerHTML = '';
    var hd = htmlEl('tr', {}, t); htmlEl('th', {}, hd, ''); htmlEl('th', {}, hd, m.cfg.words.now); htmlEl('th', {}, hd, m.cfg.words.change);
    rows.forEach(function (r) {
      var tr = htmlEl('tr', {'data-row': r.id}, t), d = r.digits || 0, ch = signed(now[r.id] - base[r.id], d);
      htmlEl('td', {}, tr, r.label); htmlEl('td', {'class': 'now'}, tr, num(now[r.id], d)); htmlEl('td', {'class': ch === '–' ? '' : 'chg'}, tr, ch);
    });
  }
  function caption(m, s) { var c = m.box.querySelector('.p3-caption'); if (c) c.textContent = s; }

  // --- navigation and the reading statuses ------------------------------------------------------------------------------------------
  function go(spec, step) {
    var p = String(spec).split(':'), ch = p[0], k = parseInt(p[1], 10);
    pending = step || 'top';
    window.Shiny.setInputValue('theory_nav', {chapter: ch, k: k, nonce: Date.now()}, {priority: 'event'});
  }
  function readState() { try { return JSON.parse(window.sessionStorage.getItem(STORE) || '{}') || {}; } catch (e) { return {}; } }
  function writeState(s) { try { window.sessionStorage.setItem(STORE, JSON.stringify(s)); } catch (e) { /* no storage: statuses for this page only */ } }
  function mark(spec, status) { var s = readState(); if (s[spec] === 'finished') return s; s[spec] = status; writeState(s); return s; }
  function paintRail(shell, s) {
    var at = shell.getAttribute('data-theory-at') || '';
    all('.toc-chap', shell).forEach(function (li) {
      var ch = li.getAttribute('data-chap'), n = parseInt(li.getAttribute('data-topics'), 10) || 0, fin = 0, seen = 0;
      for (var j = 1; j <= n; j++) { var st = s[ch + ':' + j]; if (st === 'finished') fin++; if (st) seen++; }
      var cls = n && fin === n ? 'st-finished' : (seen || at.split(':')[0] === ch) ? 'st-in_progress' : 'st-not_seen';
      li.classList.remove('st-finished', 'st-in_progress', 'st-not_seen'); li.classList.add(cls);
      all('.toc-topic', li).forEach(function (t) {
        var sp = t.getAttribute('data-theory-go'), st = s[sp] || (sp === at ? 'in_progress' : 'not_seen');
        t.classList.remove('st-finished', 'st-in_progress', 'st-not_seen'); t.classList.add('st-' + st);
      });
    });
  }
  function initShell(shell) {
    if (shell.getAttribute('data-theory-ready') === shell.getAttribute('data-theory-at')) return;
    shell.setAttribute('data-theory-ready', shell.getAttribute('data-theory-at'));
    paintRail(shell, mark(shell.getAttribute('data-theory-at'), 'in_progress'));
    if (pending) {                                                     // a page the server drew after theory_nav: its top or its step
      var target = pending === 'top' ? null : document.getElementById(pending); pending = null;
      setTimeout(function () {
        if (target) target.scrollIntoView({block: 'start'}); else window.scrollTo(0, 0);
        var h = document.getElementById('topic-title'); if (h && !target) h.focus({preventScroll: true});
      }, 0);
    }
  }

  // --- term boxes ------------------------------------------------------------------------------------------------------------------
  function closeTerms(except) { all('.term.is-open').forEach(function (t) { if (t !== except) t.classList.remove('is-open'); }); }

  document.addEventListener('click', function (e) {
    var t = e.target && e.target.closest ? e.target : null; if (!t) return;
    var g = t.closest('[data-theory-go]');
    if (g) {
      e.preventDefault(); closeTerms(null);
      var done = g.getAttribute('data-theory-done'); if (done) mark(done, 'finished');
      go(g.getAttribute('data-theory-go'), g.getAttribute('data-theory-step'));
      return;
    }
    var rd = t.closest('[data-theory-read]');
    if (rd) {
      var ch = rd.getAttribute('data-theory-read'), shell = rd.closest('.shell'), li = shell && shell.querySelector('.toc-chap[data-chap="' + ch + '"]');
      var n = li ? parseInt(li.getAttribute('data-topics'), 10) : 0, s = readState();
      for (var j = 1; j <= n; j++) s[ch + ':' + j] = 'finished';
      writeState(s); if (shell) paintRail(shell, s); rd.setAttribute('aria-pressed', 'true');
      return;
    }
    var tm = t.closest('.term');
    if (tm) { closeTerms(tm); tm.classList.toggle('is-open'); tm.classList.remove('is-dismissed'); return; }
    closeTerms(null);
  });
  document.addEventListener('keydown', function (e) {
    if (e.key === 'Escape') { all('.term').forEach(function (t) { t.classList.remove('is-open'); t.classList.add('is-dismissed'); }); return; }
    if (e.key !== 'Enter' && e.key !== ' ') return;
    var t = e.target; if (!t || !t.closest) return;
    var g = t.closest('[data-theory-go]');
    if (g && g === t && g.tagName !== 'BUTTON' && g.tagName !== 'A') { e.preventDefault(); g.click(); return; }   // the rail's entries
    if (t.classList && t.classList.contains('term')) { e.preventDefault(); t.click(); }
  });
  document.addEventListener('mouseout', function (e) { var t = e.target && e.target.closest && e.target.closest('.term');
    if (t && !t.contains(e.relatedTarget)) t.classList.remove('is-dismissed'); });
  document.addEventListener('focusout', function (e) { var t = e.target && e.target.closest && e.target.closest('.term');
    if (t && !t.contains(e.relatedTarget)) { t.classList.remove('is-dismissed'); t.classList.remove('is-open'); } });

  // --- the modules ----------------------------------------------------------------------------------------------------------------
  var KINDS = {};

  // The Keynesian cross (P3): Y = (c0 + I + G - c1 T) / (1 - c1); demand Z = c0 + c1 (Y - T) + I + G against the 45-degree line.
  KINDS.keynesian_cross = function (m) {
    var c = m.cfg, sp = c.spec, d = c.data, zoom = c.controls.length > 0, win = zoom ? sp.window.zoom : sp.window.full;
    function eq(p) { var A = p.c0 + p.I + p.G - p.c1 * p.T, mu = 1 / (1 - p.c1), Y = mu * A, C = p.c0 + p.c1 * (Y - p.T);
      return {Y: Y, C: C, S: Y - p.T - C, A: A, m: mu, a: p.c0 - p.c1 * p.T + p.I + p.G, b: p.c1}; }
    m.draw = function () {
      var p = merge(d, m.vals), e = eq(p), e0 = eq(d), lo = win[0], hi = win[1], L = 64, T = 14, S = 380;
      var X = scale(lo, hi, L, L + S), Y = scale(lo, hi, T + S, T), changed = Math.abs(e.Y - e0.Y) > 1e-9 || Math.abs(e.b - e0.b) > 1e-12 || Math.abs(e.a - e0.a) > 1e-9;
      var svg = frame(m, L + S + 24, T + S + 78, 'Keynesian cross: equilibrium output ' + num(e.Y, 2) + ' million dollars', 'tf-cross');
      var by = zoom ? 100 : 200, t0 = Math.ceil(lo / by) * by;
      grid(svg, X, Y, steps(t0, hi, by), steps(t0, hi, by), function (v) { return num(v, 0); }, function (v) { return num(v, 0); }, lo, hi, lo, hi);
      line(svg, X(lo), Y(lo), X(hi), Y(hi), 'tf-45');
      function zz(q, cls) {                                            // the demand line inside the square window
        var y1 = q.a + q.b * lo >= lo ? lo : (lo - q.a) / q.b, y2 = q.a + q.b * hi <= hi ? hi : (hi - q.a) / q.b;
        if (y2 > y1) line(svg, X(y1), Y(q.a + q.b * y1), X(y2), Y(q.a + q.b * y2), cls); }
      if (changed) zz(e0, 'tf-line-old');
      zz(e, 'tf-line tf-s1');
      line(svg, X(e.Y), Y(e.Y), X(e.Y), Y(lo), 'tf-drop');
      if (changed) { dot(svg, X(e0.Y), Y(e0.Y), 'tf-open', 6);
        var ya = Y(lo) + 30, up = e.Y > e0.Y;
        if (Math.abs(X(e.Y) - X(e0.Y)) > 8) { line(svg, X(e0.Y), ya, X(e.Y) + (up ? -7 : 7), ya, 'tf-arrow-y');
          svgEl('path', {d: 'M' + X(e.Y).toFixed(1) + ' ' + ya + ' l' + (up ? '-9 -5 v10 z' : '9 -5 v10 z'), 'class': 'tf-head-y'}, svg); }
        text(svg, (X(e0.Y) + X(e.Y)) / 2, ya + 16, fill(sp.text.dY, {value: signed(e.Y - e0.Y, 2)}), 'tf-val tf-s2', 'middle'); }
      dot(svg, X(e.Y), Y(e.Y), 'tf-dot tf-s1', 6);
      text(svg, X(e.Y) + 8, Y(e.Y) + 18, fill(sp.text.eq, {value: num(e.Y, 2)}), 'tf-val tf-s1');
      var lg = svgEl('g', {}, svg), ly = T + 18;
      svgEl('rect', {x: L + 6, y: T + 4, width: 196, height: changed ? 58 : 40, 'class': 'tf-legend'}, lg);
      [[sp.text.zz, 'tf-line tf-s1'], changed ? [sp.text.zz_before, 'tf-line-old'] : null, [sp.text.line45, 'tf-45']].forEach(function (it) {
        if (!it) return; line(lg, L + 12, ly - 4, L + 40, ly - 4, it[1]); text(lg, L + 46, ly, it[0], 'tf-note'); ly += 18; });
      text(svg, L + S / 2, T + S + 72, sp.text.x, 'tf-lab', 'middle'); vtext(svg, 16, T + S / 2, sp.text.y);
      readout(m, sp.rows.filter(function (r) { return !r.shown_with || c.show.indexOf(r.shown_with) >= 0; }), e, e0);
      caption(m, sp.caption + (zoom ? ' ' + sp.caption_zoom : ''));
    };
  };

  // The money market (P4): money demand $Y (a - i / b); a money stock gives the rate i = b (a - M / $Y), a policy rate the money stock;
  // central bank money is the money stock divided by the money multiplier (1 + cr) / (cr + rr).
  KINDS.money_market = function (m) {
    var c = m.cfg, sp = c.spec, d = c.data, ctl = c.controls[0], Yn = d.output, a = d.money_demand.share_at_zero, b = d.money_demand.divisor;
    var mult = (1 + d.money.currency_ratio) / (d.money.currency_ratio + d.money.reserve_ratio);
    function demand(i) { return Yn * (a - i / b); }
    function rateFor(M) { return b * (a - M / Yn); }
    m.draw = function () {
      var now = ctl === 'M' ? {M: m.vals.M, i: rateFor(m.vals.M)} : {i: m.vals.i, M: demand(m.vals.i)}, base = {M: d.money.money_stock, i: rateFor(d.money.money_stock)};
      now.B = now.M / mult; base.B = base.M / mult;
      var omo = now.B - d.money.central_bank_money, changed = Math.abs(now.M - base.M) > 1e-9, wx = sp.window.money, wy = sp.window.rate;
      var L = 64, T = 16, W = 380, H = 300, X = scale(wx[0], wx[1], L, L + W), Y = scale(wy[0], wy[1], T + H, T);
      var svg = frame(m, L + W + 30, T + H + 56, 'Money market: interest rate ' + num(now.i, 2) + ' percent, money stock ' + num(now.M, 1) + ' million dollars', 'tf-mm');
      grid(svg, X, Y, steps(wx[0], wx[1], 50), steps(wy[0], wy[1], 1), function (v) { return v % 100 === 0 ? num(v, 0) : ''; }, function (v) { return num(v, 0); }, wx[0], wx[1], wy[0], wy[1]);
      line(svg, X(demand(wy[0])), Y(wy[0]), X(demand(wy[1])), Y(wy[1]), 'tf-line tf-ink');
      text(svg, X(demand(7.5)) + 8, Y(7.5), sp.text.demand, 'tf-key tf-ink');
      if (ctl === 'M') { if (changed) line(svg, X(base.M), Y(wy[0]), X(base.M), Y(wy[1]), 'tf-line-old');
        line(svg, X(now.M), Y(wy[0]), X(now.M), Y(wy[1]), 'tf-supply'); text(svg, X(now.M) + 6, Y(wy[1]) + 14, sp.text.supply, 'tf-key tf-s1'); }
      else { if (changed) line(svg, X(wx[0]), Y(base.i), X(wx[1]), Y(base.i), 'tf-line-old');
        line(svg, X(wx[0]), Y(now.i), X(wx[1]), Y(now.i), 'tf-supply'); text(svg, X(wx[1]) - 4, Y(now.i) - 8, sp.text.rate + ' ' + num(now.i, 2) + '%', 'tf-key tf-s1', 'end'); }
      if (changed) dot(svg, X(base.M), Y(base.i), 'tf-open', 6);
      dot(svg, X(now.M), Y(now.i), 'tf-dot tf-s1', 6);
      text(svg, L + W / 2, T + H + 44, sp.text.x, 'tf-lab', 'middle'); vtext(svg, 16, T + H / 2, sp.text.y);
      readout(m, sp.rows, now, base);
      caption(m, Math.abs(omo) < 1e-9 ? fill(sp.caption, {rate: num(base.i, 2)}) : fill(omo > 0 ? sp.caption_buy : sp.caption_sell, {amount: num(Math.abs(omo), 2)}));
    };
  };

  // The project pool (P4): the cost of finance i - pi_e + premium; a project is carried out if its expected real return exceeds it.
  KINDS.project_pool = function (m) {
    var c = m.cfg, sp = c.spec, d = c.data, inv = d.inventories;
    var pr = d.projects.slice().sort(function (p, q) { return q['return'] - p['return']; });
    function pool(v) { var r = v.i - v.pi_e, cost = r + v.premium, mach = 0; pr.forEach(function (p) { if (p['return'] > cost) mach += p.size; });
      return {r: r, cost: cost, machines: mach, I: mach + inv}; }
    m.draw = function () {
      var v = merge(d.rates, m.vals), now = pool(v), base = pool(d.rates), wx = sp.window.invest, wy = sp.window.rate;
      var L = 56, T = 16, W = 600, H = 280, X = scale(wx[0], wx[1], L, L + W), Y = scale(wy[0], wy[1], T + H, T);
      var svg = frame(m, L + W + 20, T + H + 56, 'Project pool: cost of finance ' + num(now.cost, 2) + ' percent, investment ' + num(now.I, 0) + ' million dollars', 'tf-pool');
      steps(wy[0], wy[1], 1).forEach(function (r) { line(svg, X(wx[0]), Y(r), X(wx[1]), Y(r), r === 0 ? 'tf-zero' : 'tf-grid'); text(svg, L - 8, Y(r) + 4, num(r, 0), 'tf-tick', 'end'); });
      var x0 = 0;
      pr.forEach(function (p) { var on = p['return'] > now.cost;
        rect(svg, X(x0) + 1, Y(p['return']), X(x0 + p.size) - X(x0) - 2, Y(0) - Y(p['return']), on ? 'tf-bar-on' : 'tf-bar-off',
             fill(sp.text.project, {name: p.name, firm: p.firm, size: num(p.size, 0), ret: num(p['return'], 2)}));
        text(svg, (X(x0) + X(x0 + p.size)) / 2, Y(p['return']) - 4, num(p['return'], 2), 'tf-tick', 'middle'); x0 += p.size; });
      steps(wx[0], wx[1], 60).forEach(function (s) { text(svg, X(s), Y(wy[0]) + 18, num(s, 0), 'tf-tick', 'middle'); });
      line(svg, X(wx[0]), Y(wy[0]), X(wx[1]), Y(wy[0]), 'tf-axis'); line(svg, X(wx[0]), Y(wy[0]), X(wx[0]), Y(wy[1]), 'tf-axis');
      if (Math.abs(now.cost - base.cost) > 1e-9) { line(svg, X(wx[0]), Y(base.cost), X(wx[1]), Y(base.cost), 'tf-line-old');
        text(svg, X(wx[1]) - 4, Y(base.cost) + (now.cost > base.cost ? 16 : -6), fill(sp.text.cost_before, {value: num(base.cost, 2)}), 'tf-note', 'end'); }
      line(svg, X(wx[0]), Y(now.cost), X(wx[1]), Y(now.cost), 'tf-cost');
      text(svg, X(wx[1]) - 4, Y(now.cost) + (now.cost > base.cost ? -6 : 16), fill(sp.text.cost, {value: num(now.cost, 2)}), 'tf-val tf-s3', 'end');
      text(svg, L + W / 2, T + H + 44, sp.text.x, 'tf-lab', 'middle'); vtext(svg, 14, T + H / 2, sp.text.y);
      readout(m, sp.rows, now, base); caption(m, sp.caption);
    };
  };

  // The flows of the labour market (P5): U(t+1) = U(t) + s (L - U(t)) - f U(t); the steady state s / (s + f); the spell 1 / f.
  KINDS.labour_flows = function (m) {
    var c = m.cfg, sp = c.spec, d = c.data, L = d.labour_force, U0 = d.unemployed, n = sp.window.months, timer = null, raf = null;
    var OUT = [260, 78, 310, 24, 370, 24, 420, 78], IN = [420, 132, 370, 186, 310, 186, 260, 132];
    function path(s, f) { var U = [U0], sep = [], hire = []; for (var t = 0; t <= n; t++) { var E = L - U[t]; sep[t] = s / 100 * E; hire[t] = f / 100 * U[t]; if (t < n) U[t + 1] = U[t] + sep[t] - hire[t]; }
      return {U: U, sep: sep, hire: hire, u: U.map(function (x) { return 100 * x / L; })}; }
    function vals() { return {s: m.vals.s !== undefined ? m.vals.s : d.flows.separation_rate, f: m.vals.f !== undefined ? m.vals.f : d.flows.finding_rate}; }
    function bez(a, t) { var u = 1 - t; return [u * u * u * a[0] + 3 * u * u * t * a[2] + 3 * u * t * t * a[4] + t * t * t * a[6], u * u * u * a[1] + 3 * u * u * t * a[3] + 3 * u * t * t * a[5] + t * t * t * a[7]]; }
    function arc(g, a, cls, head) { svgEl('path', {d: 'M' + a[0] + ' ' + a[1] + ' C' + a.slice(2).join(' '), 'class': cls, 'marker-end': 'url(#' + head + ')'}, g); }
    m.picture = function (upto) {
      var v = vals(), p = path(v.s, v.f), b = path(d.flows.separation_rate, d.flows.finding_rate), ss = 100 * v.s / (v.s + v.f), mo = Math.min(upto, n);
      var svg = frame(m, 680, 466, 'Labour market flows: steady state ' + num(ss, 1) + ' percent', 'tf-flows'), wy = sp.window.rate, defs = svgEl('defs', {}, svg);
      [['out', 'tf-head-out'], ['in', 'tf-head-in']].forEach(function (h) { var mk = svgEl('marker', {id: c.key + '-' + h[0], viewBox: '0 0 10 10', refX: 8, refY: 5, markerWidth: 7, markerHeight: 7, orient: 'auto-start-reverse'}, defs);
        svgEl('path', {d: 'M1 1L9 5L1 9z', 'class': h[1]}, mk); });
      rect(svg, 60, 60, 200, 90, 'tf-pool-e'); rect(svg, 420, 60, 200, 90, 'tf-pool-u');
      text(svg, 160, 90, sp.text.employed, 'tf-pool-title', 'middle'); text(svg, 520, 90, sp.text.unemployed, 'tf-pool-title', 'middle');
      text(svg, 160, 126, num(L - p.U[mo], 0), 'tf-pool-num', 'middle'); text(svg, 520, 126, num(p.U[mo], 0), 'tf-pool-num', 'middle');
      arc(svg, OUT, 'tf-arc-out', c.key + '-out'); arc(svg, IN, 'tf-arc-in', c.key + '-in');
      text(svg, 340, 14, fill(sp.text.out, {rate: num(v.s, 2), from: num(L - p.U[mo], 0), n: num(p.sep[mo], 0)}), 'tf-val tf-s3', 'middle');
      text(svg, 340, 204, fill(sp.text['in'], {rate: num(v.f, 2), from: num(p.U[mo], 0), n: num(p.hire[mo], 0)}), 'tf-val tf-s2', 'middle');
      if (c.controls.length) text(svg, 340, 110, fill(sp.text.month, {m: mo}), 'tf-key', 'middle');
      svgEl('g', {'class': 'tf-dots'}, svg);
      var X = scale(0, n, 60, 620), Y = scale(wy[0], wy[1], 420, 236);
      grid(svg, X, Y, steps(0, n, 6), steps(wy[0], wy[1], 2), function (t) { return num(t, 0); }, function (u) { return num(u, 0) + '%'; }, 0, n, wy[0], wy[1]);
      var changed = Math.abs(v.s - d.flows.separation_rate) > 1e-9 || Math.abs(v.f - d.flows.finding_rate) > 1e-9, ts = [];
      for (var t = 0; t <= n; t++) ts.push(t);
      if (changed) poly(svg, ts.map(X), b.u.map(Y), 'tf-line-old');
      line(svg, X(0), Y(ss), X(n), Y(ss), 'tf-steady'); text(svg, X(n), Y(ss) - 6, fill(sp.text.steady, {value: num(ss, 1)}), 'tf-note tf-s3', 'end');
      poly(svg, ts.slice(0, mo + 1).map(X), p.u.slice(0, mo + 1).map(Y), 'tf-line tf-s3');
      text(svg, 340, 460, sp.text.x, 'tf-lab', 'middle'); vtext(svg, 16, 328, sp.text.y);
      return {p: p, b: b, ss: ss, v: v};
    };
    m.draw = function () {
      stop(false); var r = m.picture(n), b0 = 100 * d.flows.separation_rate / (d.flows.separation_rate + d.flows.finding_rate);
      readout(m, sp.rows, {ss: r.ss, u6: r.p.u[6], u24: r.p.u[n], spell: 100 / r.v.f}, {ss: b0, u6: r.b.u[6], u24: r.b.u[n], spell: 100 / d.flows.finding_rate});
      caption(m, c.controls.length ? sp.caption : sp.caption_static);
    };
    function dots(month, ms) {
      var g = m.box.querySelector('.tf-dots'); if (!g || !window.requestAnimationFrame) return;
      var r = path(vals().s, vals().f), made = [];
      [[Math.round(r.sep[month] / d.flows.per_dot), OUT, 'tf-dot-out'], [Math.round(r.hire[month] / d.flows.per_dot), IN, 'tf-dot-in']].forEach(function (q) {
        for (var k = 0; k < q[0]; k++) made.push({c: svgEl('circle', {r: 4, 'class': q[2], opacity: 0}, g), a: q[1], delay: k * 0.7 * ms / Math.max(q[0], 1)}); });
      var t0 = performance.now(), dur = 0.8 * ms;
      function tick(now) { var live = false;
        made.forEach(function (o) { var f = (now - t0 - o.delay) / dur;
          if (f < 0) live = true;
          else if (f < 1) { var xy = bez(o.a, f); o.c.setAttribute('cx', xy[0].toFixed(1)); o.c.setAttribute('cy', xy[1].toFixed(1)); o.c.setAttribute('opacity', '0.85'); live = true; }
          else if (o.c.parentNode) o.c.parentNode.removeChild(o.c); });
        if (live && document.contains(g)) raf = window.requestAnimationFrame(tick); }
      raf = window.requestAnimationFrame(tick);
    }
    function stop(again) {
      if (timer) { clearInterval(timer); timer = null; } if (raf && window.cancelAnimationFrame) window.cancelAnimationFrame(raf);
      var b = m.box.querySelector('.tm-play'); if (b) b.textContent = again ? sp.text.again : sp.text.play;
    }
    m.play = function () {
      if (timer) { stop(false); m.draw(); return; }
      if (reduced()) { m.box.classList.add('is-reduced'); m.draw(); return; }
      var ms = sp.month_ms || 900, month = 0, b = m.box.querySelector('.tm-play'); if (b) b.textContent = sp.text.stop;
      m.picture(0);
      timer = setInterval(function () {
        if (!document.contains(m.box)) { stop(false); return; }
        month += 1; m.picture(month); dots(month - 1, ms);
        if (month >= n) stop(true);
      }, ms);
    };
    var pb = m.box.querySelector('.tm-play'); if (pb) pb.addEventListener('click', function () { m.play(); });
    var sb = m.box.querySelector('.tm-slump'); if (sb) sb.addEventListener('click', function () { m.set('f', d.slump.finding_rate); });
  };

  // Wage setting and price setting (P5): WS w = w0 + z - b u, PS w = productivity / (1 + markup); the natural rate where they meet.
  KINDS.ws_ps = function (m) {
    var c = m.cfg, sp = c.spec, d = c.data, ws = d.wage_setting, L = d.labour_force;
    function sol(z, mu) { var ps = d.productivity / (1 + mu / 100), un = (ws.intercept + z - ps) / ws.slope_per_point; return {ps: ps, un: un, Nn: L * (1 - un / 100), w: ps, z: z}; }
    m.draw = function () {
      var now = sol(m.vals.z !== undefined ? m.vals.z : 0, m.vals.markup !== undefined ? m.vals.markup : d.markup), base = sol(0, d.markup);
      var wx = sp.window.u, wy = sp.window.wage, L0 = 72, T = 16, W = 380, H = 300, X = scale(wx[0], wx[1], L0, L0 + W), Y = scale(wy[0], wy[1], T + H, T);
      var svg = frame(m, L0 + W + 30, T + H + 56, 'Wage setting and price setting: natural rate ' + num(now.un, 1) + ' percent', 'tf-wsps');
      grid(svg, X, Y, steps(wx[0], wx[1], 2), steps(wy[0], wy[1], 1000), function (u) { return num(u, 0) + '%'; }, function (w) { return num(w, 0); }, wx[0], wx[1], wy[0], wy[1]);
      var changed = Math.abs(now.un - base.un) > 1e-9 || Math.abs(now.ps - base.ps) > 1e-9;
      function wsLine(z, cls) { line(svg, X(wx[0]), Y(ws.intercept + z - ws.slope_per_point * wx[0]), X(wx[1]), Y(ws.intercept + z - ws.slope_per_point * wx[1]), cls); }
      if (changed) { wsLine(0, 'tf-line-old'); line(svg, X(wx[0]), Y(base.ps), X(wx[1]), Y(base.ps), 'tf-line-old'); dot(svg, X(base.un), Y(base.ps), 'tf-open', 6); }
      wsLine(now.z, 'tf-line tf-ink'); line(svg, X(wx[0]), Y(now.ps), X(wx[1]), Y(now.ps), 'tf-line tf-s1');
      text(svg, X(0.4), Y(ws.intercept + now.z - ws.slope_per_point * 0.4) - 8, sp.text.ws, 'tf-key tf-ink');
      text(svg, X(wx[1]) - 4, Y(now.ps) + 18, sp.text.ps, 'tf-key tf-s1', 'end');
      line(svg, X(now.un), Y(now.ps), X(now.un), Y(wy[0]), 'tf-drop'); dot(svg, X(now.un), Y(now.ps), 'tf-dot tf-s1', 6);
      text(svg, X(now.un) + 6, Y(wy[0]) - 8, fill(sp.text.un, {value: num(now.un, 1)}), 'tf-val tf-s1');
      text(svg, L0 + W / 2, T + H + 44, sp.text.x, 'tf-lab', 'middle'); vtext(svg, 14, T + H / 2, sp.text.y);
      readout(m, sp.rows, now, base); caption(m, sp.caption);
    };
  };

  // The Phillips relation (P5): inflation = expected inflation - a (u - u_n); over the years with expectations anchored at the start
  // or following last year's inflation.
  KINDS.phillips = function (m) {
    var c = m.cfg, sp = c.spec, d = c.data, a = d.phillips.slope, un = d.natural_rate, uh = d.phillips.held_unemployment, ny = d.phillips.years, pe0 = d.phillips.expected_inflation;
    function infl(u, pe) { return pe - a * (u - un); }
    function years(pe) { var an = [pe], ad = [pe]; for (var t = 1; t <= ny; t++) { an.push(infl(uh, pe)); ad.push(infl(uh, ad[t - 1])); } return {an: an, ad: ad}; }
    m.draw = function () {
      var pe = m.vals.pi_e !== undefined ? m.vals.pi_e : pe0, wy = sp.window.inflation, L = 56, T = 16, W = 380, H = 300, svg;
      if (c.view === 'years') {
        var r = years(pe), r0 = years(pe0), X = scale(0, ny, L, L + W), Y = scale(wy[0], wy[1], T + H, T), ts = [];
        for (var t = 0; t <= ny; t++) ts.push(t);
        svg = frame(m, L + W + 150, T + H + 56, 'Inflation with unemployment held at ' + uh + ' percent for ' + ny + ' years', 'tf-years');
        grid(svg, X, Y, ts, steps(wy[0], wy[1], 1), function (t) { return t === 0 ? sp.text.start : String(t); }, function (v) { return num(v, 0) + '%'; }, 0, ny, wy[0], wy[1]);
        [[r.ad, 'tf-s3', sp.text.adaptive, -10], [r.an, 'tf-s1', sp.text.anchored, 20]].forEach(function (s) {
          poly(svg, ts.map(X), s[0].map(Y), 'tf-line ' + s[1]);
          for (var k = 1; k <= ny; k++) { dot(svg, X(k), Y(s[0][k]), 'tf-dot ' + s[1], 4); text(svg, X(k), Y(s[0][k]) + s[3], num(s[0][k], 2) + '%', 'tf-val ' + s[1], 'middle'); }
          text(svg, X(ny) + 14, Y(s[0][ny]) + 4, s[2], 'tf-val ' + s[1]); });
        dot(svg, X(0), Y(pe), 'tf-open', 5);
        text(svg, L + W / 2, T + H + 44, sp.text.years_x, 'tf-lab', 'middle'); vtext(svg, 14, T + H / 2, sp.text.years_y);
        readout(m, sp.rows_years, {pe: pe, an: r.an[ny], ad: r.ad[ny]}, {pe: pe0, an: r0.an[ny], ad: r0.ad[ny]});
        caption(m, fill(sp.caption_years, {u: num(uh, 2), n: ny, pe: num(pe, 2)}));
        return;
      }
      var wx = sp.window.u, Xc = scale(wx[0], wx[1], L, L + W), Yc = scale(wy[0], wy[1], T + H, T);
      svg = frame(m, L + W + 30, T + H + 56, 'Phillips relation at expected inflation of ' + num(pe, 2) + ' percent', 'tf-phillips');
      grid(svg, Xc, Yc, steps(wx[0], wx[1], 2), steps(wy[0], wy[1], 1), function (u) { return num(u, 0) + '%'; }, function (v) { return num(v, 0) + '%'; }, wx[0], wx[1], wy[0], wy[1]);
      line(svg, Xc(wx[0]), Yc(0), Xc(wx[1]), Yc(0), 'tf-zero');
      line(svg, Xc(un), Yc(wy[0]), Xc(un), Yc(wy[1]), 'tf-un'); text(svg, Xc(un) + 4, Yc(wy[1]) + 12, fill(sp.text.natural, {value: num(un, 1)}), 'tf-note');
      if (Math.abs(pe - pe0) > 1e-9) line(svg, Xc(wx[0]), Yc(infl(wx[0], pe0)), Xc(wx[1]), Yc(infl(wx[1], pe0)), 'tf-line-old');
      line(svg, Xc(wx[0]), Yc(infl(wx[0], pe)), Xc(wx[1]), Yc(infl(wx[1], pe)), 'tf-line tf-s1');
      text(svg, Xc(wx[1]) - 4, Yc(infl(wx[1], pe)) - 8, sp.text.curve, 'tf-key tf-s1', 'end');
      dot(svg, Xc(un), Yc(pe), 'tf-open', 6); dot(svg, Xc(uh), Yc(infl(uh, pe)), 'tf-dot tf-s1', 6);
      text(svg, Xc(uh) - 8, Yc(infl(uh, pe)) - 10, fill(sp.text.held, {value: num(uh, 0)}) + ': ' + num(infl(uh, pe), 2) + '%', 'tf-val tf-s1', 'end');
      text(svg, L + W / 2, T + H + 44, sp.text.x, 'tf-lab', 'middle'); vtext(svg, 14, T + H / 2, sp.text.y);
      readout(m, sp.rows_curve, {pe: pe, p3: infl(uh, pe), un: un}, {pe: pe0, p3: infl(uh, pe0), un: un});
      caption(m, sp.caption);
    };
  };

  // The Solow model (P6): Y = K^alpha (A N)^(1 - alpha). Stage A (N and A fixed): K(t+1) = K(t) + s Y(t) - delta K(t), the steady state
  // K* = (s / delta)^(1 / (1 - alpha)) A N. Growth: capital per effective worker k(t+1) = k(t) + s k(t)^alpha - (delta + n + g_A) k(t).
  KINDS.solow = function (m) {
    var c = m.cfg, sp = c.spec, d = c.data, view = c.view, al = d.profits / d.output, N = d.natural_employment, K0 = d.capital, Y0 = d.output;
    var A = Math.pow(Y0 / Math.pow(K0, al), 1 / (1 - al)) / N, AN = A * N, base = {s: d.investment / d.output, delta: d.depreciation_rate / 100, n: d.labour_force_growth / 100, g_A: d.technology_growth / 100};
    function rate(k) { var v = m.vals[k], sl = c.sliders[k]; if (v === undefined || !sl) return base[k]; return Math.abs(v - sl.value) < 1e-9 ? base[k] : v / 100; }
    function F(K) { return Math.pow(K, al) * Math.pow(AN, 1 - al); }
    function stageA(q, years) { var K = [K0]; for (var t = 0; t < years; t++) K.push(K[t] + q.s * F(K[t]) - q.delta * K[t]); return K.map(F); }
    function growth(q, years) { var k = [K0 / AN], x = q.delta + q.n + q.g_A, Y = [], ratio = [];
      for (var t = 0; t < years; t++) k.push(k[t] + q.s * Math.pow(k[t], al) - x * k[t]);
      for (t = 0; t <= years; t++) { Y.push(Math.pow(k[t], al) * A * Math.pow(1 + q.g_A, t) * N * Math.pow(1 + q.n, t)); ratio.push(Math.pow(k[t] / k[0], al)); }
      return {k: k, Y: Y, ratio: ratio}; }
    function figures(q) {
      if (view === 'stage_a') { var Ks = Math.pow(q.s / q.delta, 1 / (1 - al)) * AN, Ys = F(Ks), path = stageA(q, sp.window.half_years), half = null;
        for (var t = 0; t < path.length; t++) if (path[t] - path[0] >= (Ys - path[0]) / 2) { half = t; break; }
        return {Ks: Ks, Ys: Ys, g1: 100 * (path[1] / path[0] - 1), half: half, idx: path.slice(0, sp.window.years + 1).map(function (y) { return 100 * y / Y0; }), kstar: 1000 * Ks / N}; }
      var g = growth(q, sp.window.years), x = q.delta + q.n + q.g_A;
      return {gY: 100 * ((1 + q.n) * (1 + q.g_A) - 1), gy: 100 * q.g_A, lev: 100 * (g.ratio[sp.window.years] - 1), g1: 100 * (g.Y[1] / g.Y[0] - 1),
              idx: g.ratio.map(function (r) { return 100 * r; }), kstar: 1000 * A * Math.pow(q.s / x, 1 / (1 - al))};
    }
    m.draw = function () {
      var q = {s: rate('s'), delta: rate('delta'), n: view === 'stage_a' ? 0 : rate('n'), g_A: view === 'stage_a' ? 0 : rate('g_A')};
      var q0 = {s: base.s, delta: base.delta, n: view === 'stage_a' ? 0 : base.n, g_A: view === 'stage_a' ? 0 : base.g_A};
      var f = figures(q), f0 = figures(q0), wk = sp.window.k, wi = sp.window.inv, changed = ['s', 'delta', 'n', 'g_A'].some(function (k) { return Math.abs(q[k] - q0[k]) > 1e-12; });
      var L = 56, T = 14, W = 380, H = 240, X = scale(wk[0], wk[1], L, L + W), Y = scale(wi[0], wi[1], T + H, T), ks = [];
      for (var k = 0; k <= wk[1]; k += 5) ks.push(k);
      var svg = frame(m, L + W + 30, T + H + 52, 'Solow diagram: steady state at ' + num(f.kstar, 0) + ' thousand dollars of capital per worker', 'tf-solow');
      grid(svg, X, Y, steps(wk[0], wk[1], 100), steps(wi[0], wi[1], 10), function (v) { return num(v, 0); }, function (v) { return num(v, 0); }, wk[0], wk[1], wi[0], wi[1]);
      function inv(qq, kk) { return qq.s * Math.pow(kk / 1000 / A, al) * A * 1000; }      // investment per (effective) worker, $ thousand
      var xLine = function (qq) { return view === 'stage_a' ? qq.delta : qq.delta + qq.n + qq.g_A; };
      function draw(qq, ci, cl) {
        var kk = ks.filter(function (v) { return inv(qq, v) <= wi[1]; });
        poly(svg, kk.map(X), kk.map(function (v) { return Y(inv(qq, v)); }), ci);
        var kmax = Math.min(wk[1], wi[1] / xLine(qq)); line(svg, X(0), Y(0), X(kmax), Y(xLine(qq) * kmax), cl);
      }
      if (changed) { draw(q0, 'tf-line-old', 'tf-line-old'); dot(svg, X(f0.kstar), Y(xLine(q0) * f0.kstar), 'tf-open', 5); }
      draw(q, 'tf-line tf-s1', 'tf-line tf-ink');
      line(svg, X(1000 * K0 / N), Y(wi[0]), X(1000 * K0 / N), Y(wi[1]), 'tf-today'); text(svg, X(1000 * K0 / N) + 4, Y(wi[0]) - 6, sp.text.today, 'tf-note');
      dot(svg, X(f.kstar), Y(xLine(q) * f.kstar), 'tf-dot tf-s1', 6);
      svgEl('rect', {x: L + 8, y: T + 4, width: 214, height: 58, 'class': 'tf-legend'}, svg);
      text(svg, L + 14, T + 20, sp.text.invest, 'tf-key tf-s1');
      text(svg, L + 14, T + 38, view === 'stage_a' ? sp.text.depreciation : sp.text.break_even, 'tf-key tf-ink');
      text(svg, L + 14, T + 56, fill(sp.text.kstar, {value: num(f.kstar, 0)}), 'tf-note');
      text(svg, L + W / 2, T + H + 40, view === 'stage_a' ? sp.text.x_stage_a : sp.text.x_growth, 'tf-lab', 'middle'); vtext(svg, 14, T + H / 2, sp.text.y);
      // the path of output over the years
      var ny = sp.window.years, wix = view === 'stage_a' ? sp.window.index_stage_a : sp.window.index_growth, H2 = 150, T2 = 12;
      var X2 = scale(0, ny, L, L + W), Y2 = scale(wix[0], wix[1], T2 + H2, T2), ts = [];
      for (var t = 0; t <= ny; t++) ts.push(t);
      var p2 = frame(m, L + W + 30, T2 + H2 + 44, 'Output over ' + ny + ' years', 'tf-solow-path', true);
      grid(p2, X2, Y2, steps(0, ny, 20), steps(Math.ceil(wix[0] / 10) * 10, wix[1], 10), function (v) { return num(v, 0); }, function (v) { return num(v, 0); }, 0, ny, wix[0], wix[1]);
      if (changed) poly(p2, ts.map(X2), f0.idx.map(Y2), 'tf-line-old');
      poly(p2, ts.map(X2), f.idx.map(function (v) { return Y2(Math.min(Math.max(v, wix[0]), wix[1])); }), 'tf-line tf-s1');
      text(p2, X2(ny) - 4, Y2(Math.min(Math.max(f.idx[ny], wix[0]), wix[1])) - 8, num(f.idx[ny], 1), 'tf-val tf-s1', 'end');
      text(p2, L + W / 2, T2 + H2 + 38, sp.text.path_x, 'tf-lab', 'middle'); vtext(p2, 14, T2 + H2 / 2, view === 'stage_a' ? sp.text.path_stage_a : sp.text.path_growth);
      readout(m, view === 'stage_a' ? sp.rows_stage_a : sp.rows_growth, f, f0);
      caption(m, view === 'stage_a' ? sp.caption_stage_a : sp.caption_growth);
    };
  };

  // The price toggle (P2): both years' output valued at each year's own prices (nominal) or at year-1 prices (real).
  KINDS.price_toggle = function (m) {
    var c = m.cfg, sp = c.spec, goods = c.data.goods;
    function part(g, t, at) { return g.q[t] * g.p[at]; }
    function value(t, at) { return goods.reduce(function (s, g) { return s + part(g, t, at); }, 0); }
    m.draw = function () {
      var r = m.box.querySelector('input[type=radio]:checked'), real = r && r.value === 'base';
      var at = function (t) { return real ? 0 : t; }, wy = sp.window.value, L = 56, T = 24, W = 360, H = 240;
      var X = scale(0, 2, L, L + W), Y = scale(wy[0], wy[1], T + H, T);
      var svg = frame(m, L + W + 160, T + H + 40, 'Output of years 1 and 2 at ' + (real ? 'year-1 prices' : 'each year’s own prices'), 'tf-toggle');
      steps(wy[0], wy[1], 150).forEach(function (v) { line(svg, X(0), Y(v), X(2), Y(v), 'tf-grid'); text(svg, L - 8, Y(v) + 4, num(v, 0), 'tf-tick', 'end'); });
      [0, 1].forEach(function (t) { var x = X(t + 0.5) - 45, acc = 0;
        goods.forEach(function (g, i) { var v = part(g, t, at(t)); rect(svg, x, Y(acc + v), 90, Y(acc) - Y(acc + v), 'tf-c' + (i + 1), g.name + ': $' + num(v, 1) + ' million');
          if (t === 1) text(svg, x + 98, (Y(acc) + Y(acc + v)) / 2 + 4, g.name + ' ' + num(v, 1), 'tf-seg'); acc += v; });
        text(svg, x + 45, Y(acc) - 7, num(acc, 0), 'tf-tot', 'middle'); text(svg, x + 45, T + H + 22, fill(sp.text.year, {n: t + 1}), 'tf-lab', 'middle'); });
      line(svg, X(0), Y(0), X(2), Y(0), 'tf-axis');
      var now = {y1: value(0, at(0)), y2: value(1, at(1))}, base = {y1: value(0, 0), y2: value(1, 1)};
      now.g = 100 * (now.y2 / now.y1 - 1); base.g = 100 * (base.y2 / base.y1 - 1);
      readout(m, sp.rows, now, base); caption(m, sp.caption);
    };
    all('input[type=radio]', m.box).forEach(function (r) { r.addEventListener('change', function () { m.draw(); }); });
    m.resetExtra = function () { var r0 = m.box.querySelector('input[type=radio]'); if (r0) r0.checked = true; };
  };

  // The circular flow (P1): the worked example, the cards placed on the arrows with an answer at once, the optional drawing challenge.
  KINDS.circular_flow = function (m) {
    var c = m.cfg, tx = c.spec.text, cf = c.data, flows = cf.flows, st = {stage: 'worked', placed: {}, perfect: true, sel: null, fb: null, found: [], dfb: null};
    var shown = function (ids) { return flows.filter(function (f) { return ids.indexOf(f.id) >= 0; }); };
    var name = function (a) { return cf.actors[a] || a; };
    function diagram(parent, show, done, slots) {
      var svg = svgEl('svg', {'class': 'cf-svg', viewBox: '0 0 680 500', role: 'img', 'aria-label': tx.aria}, parent), defs = svgEl('defs', {}, svg);
      ['real', 'money', 'policy'].forEach(function (t) { var mk = svgEl('marker', {id: c.key + '-head-' + t, viewBox: '0 0 10 10', refX: 8, refY: 5, markerWidth: 7, markerHeight: 7, orient: 'auto-start-reverse'}, defs);
        svgEl('path', {d: 'M2 1L8 5L2 9', 'class': 'cf-head cf-' + t}, mk); });
      Object.keys(cf.nodes).forEach(function (a) { var n = cf.nodes[a], g = svgEl('g', {'class': 'cf-node cf-node-' + a}, svg);
        svgEl('rect', {x: n[0], y: n[1], width: n[2], height: n[3], rx: 6}, g); svgEl('text', {x: n[0] + n[2] / 2, y: n[1] + n[3] / 2 + 5, 'text-anchor': 'middle'}, g, name(a)); });
      show.forEach(function (f) { svgEl('path', {d: f.path, 'class': 'cf-arrow cf-' + f.type, 'marker-end': 'url(#' + c.key + '-head-' + f.type + ')'}, svg); });
      show.forEach(function (f) { var ok = done.indexOf(f.id) >= 0, g = svgEl('g', {'class': 'cf-badge' + (ok ? ' is-done' : '') + (slots && !ok ? ' cf-slot' : ''), 'data-arrow': f.id, tabindex: slots && !ok ? 0 : -1, 'aria-label': fill(tx.arrow, {id: f.id})}, svg);
        svgEl('circle', {cx: f.badge[0], cy: f.badge[1], r: 12}, g); svgEl('text', {x: f.badge[0], y: f.badge[1] + 4, 'text-anchor': 'middle'}, g, String(f.id)); });
    }
    function legend(parent) { var lg = htmlEl('div', {'class': 'legend'}, parent);
      ['real', 'money', 'policy'].forEach(function (t) { var s = htmlEl('span', {}, lg); htmlEl('i', {'class': 'cf-key cf-' + t}, s); s.appendChild(document.createTextNode(tx['legend_' + t])); }); }
    function feedback(parent, f) { if (f) htmlEl('div', {'class': 'fb ' + (f.ok ? 'fb-ok' : 'fb-no'), role: 'status'}, parent, f.text); }
    function place(arrow, card) {
      var f = flows.filter(function (x) { return x.id === +arrow; })[0]; if (!f || st.placed[f.id]) return;
      if (card === f.card) { st.placed[f.id] = card; st.fb = {ok: true, text: fill(tx.correct, {from: name(f.from), to: name(f.to), card: card})}; }
      else { st.perfect = false; st.fb = {ok: false, text: fill(tx.wrong, {id: f.id, noun: tx['noun_' + f.type], from: name(f.from), to: name(f.to)})}; }
      st.sel = null; render();
    }
    function render() {
      var box = m.box; box.innerHTML = '';
      var we = cf.stages.worked_example.show, comp = cf.stages.completion.show;
      if (st.stage === 'worked') {
        diagram(box, shown(we), we, false); legend(box); htmlEl('p', {}, box, cf.stages.worked_example.text);
        var ul = htmlEl('ul', {'class': 'flowlist'}, box);
        shown(we).forEach(function (f) { htmlEl('li', {}, ul, f.id + '. ' + name(f.from) + ' → ' + name(f.to) + ': ' + f.card); });
        htmlEl('button', {type: 'button', 'class': 'btn-main', 'data-cf': 'continue'}, box, tx['continue']);
        return;
      }
      if (st.stage === 'completion') {
        var ids = Object.keys(st.placed).map(Number), done = comp.every(function (i) { return st.placed[i]; });
        htmlEl('p', {}, box, cf.stages.completion.task);
        diagram(box, shown(we.concat(comp)), we.concat(ids), true); legend(box);
        if (!done) { var tray = htmlEl('div', {'class': 'tray'}, box), cards = shown(comp).map(function (f) { return f.card; }).sort();
          ids.forEach(function (i) { var k = cards.indexOf(st.placed[i]); if (k >= 0) cards.splice(k, 1); });
          cards.forEach(function (cd) { htmlEl('div', {'class': 'cf-card' + (st.sel === cd ? ' is-selected' : ''), draggable: 'true', tabindex: 0, 'data-card': cd, role: 'button'}, tray, cd); }); }
        var sl = htmlEl('div', {'class': 'slots'}, box);
        comp.forEach(function (i) { var ok = !!st.placed[i], row = htmlEl('div', {'class': 'slotrow ' + (ok ? 'is-done' : 'cf-slot'), 'data-arrow': i, tabindex: ok ? -1 : 0}, sl);
          htmlEl('strong', {}, row, fill(tx.arrow, {id: i})); row.appendChild(document.createTextNode(ok ? st.placed[i] : tx.slot)); });
        htmlEl('p', {'class': 'change'}, box, fill(tx.placed, {n: ids.length, m: comp.length}));
        feedback(box, st.fb);
        if (done) { feedback(box, {ok: true, text: tx.done});
          if (st.perfect) htmlEl('button', {type: 'button', 'class': 'btn-quiet', 'data-cf': 'draw'}, box, tx.challenge);
          else { var p = htmlEl('p', {'class': 'change'}, box, tx.locked + ' '); htmlEl('button', {type: 'button', 'class': 'game-link cf-link', 'data-cf': 'restart'}, p, tx.restart); } }
        return;
      }
      htmlEl('p', {}, box, cf.stages.draw_challenge.task);
      diagram(box, shown(st.found), st.found, false); legend(box);
      var row2 = htmlEl('div', {'class': 'cf-draw'}, box), choose = function (lab, key, opts) {
        var w = htmlEl('label', {'class': 'cf-pick'}, row2, lab + ' '), s = htmlEl('select', {'data-pick': key}, w); htmlEl('option', {value: ''}, s, tx.choose);
        opts.forEach(function (o) { htmlEl('option', {value: o[0]}, s, o[1]); }); };
      var actors = Object.keys(cf.nodes).map(function (a) { return [a, name(a)]; });
      choose(tx.from, 'from', actors); choose(tx.to, 'to', actors);
      choose(tx.activity, 'card', flows.map(function (f) { return f.card; }).filter(function (v, i, a) { return a.indexOf(v) === i; }).sort().map(function (v) { return [v, v]; }));
      htmlEl('button', {type: 'button', 'class': 'btn-main', 'data-cf': 'add'}, box, tx.draw);
      htmlEl('p', {'class': 'change'}, box, fill(tx.drawn, {n: st.found.length, m: flows.length}));
      feedback(box, st.dfb);
    }
    function addDrawn() {
      var v = function (k) { var s = m.box.querySelector('select[data-pick="' + k + '"]'); return s ? s.value : ''; }, from = v('from'), to = v('to'), card = v('card');
      if (!from || !to || !card) { st.dfb = {ok: false, text: tx.draw_missing}; render(); return; }
      var hit = flows.filter(function (f) { return f.from === from && f.to === to && f.card === card && st.found.indexOf(f.id) < 0; })[0];
      if (hit) { st.found.push(hit.id); st.dfb = {ok: true, text: st.found.length === flows.length ? tx.draw_all : fill(tx.draw_correct, {from: name(from), to: name(to), card: card})}; }
      else if (flows.some(function (f) { return f.from === from && f.to === to && f.card === card; })) st.dfb = {ok: false, text: tx.draw_already};
      else if (flows.some(function (f) { return f.from === to && f.to === from && f.card === card; })) st.dfb = {ok: false, text: tx.draw_reverse};
      else if (flows.some(function (f) { return f.card === card; })) st.dfb = {ok: false, text: fill(tx.draw_unconnected, {from: name(from), to: name(to)})};
      else st.dfb = {ok: false, text: tx.draw_unknown};
      render();
    }
    m.box.addEventListener('click', function (e) {
      var t = e.target, b = t.closest('[data-cf]');
      if (b) { var a = b.getAttribute('data-cf');
        if (a === 'continue') st.stage = 'completion';
        else if (a === 'draw') { st.stage = 'draw'; st.found = []; st.dfb = null; }
        else if (a === 'restart') { st.placed = {}; st.perfect = true; st.fb = null; st.stage = 'completion'; }
        else if (a === 'add') { addDrawn(); return; }
        render(); return; }
      var cd = t.closest('.cf-card'); if (cd) { st.sel = cd.getAttribute('data-card'); render(); return; }
      var s = t.closest('.cf-slot'); if (s && st.sel) place(s.getAttribute('data-arrow'), st.sel);
    });
    m.box.addEventListener('keydown', function (e) {
      if ((e.key === 'Enter' || e.key === ' ') && e.target.closest && e.target.closest('.cf-card, .cf-slot')) { e.preventDefault();
        var cd = e.target.closest('.cf-card'); if (cd) { st.sel = cd.getAttribute('data-card'); render(); var again = m.box.querySelector('.cf-card.is-selected'); if (again) again.focus(); return; }
        var s = e.target.closest('.cf-slot'); if (st.sel) place(s.getAttribute('data-arrow'), st.sel); }
    });
    m.box.addEventListener('dragstart', function (e) { var cd = e.target.closest && e.target.closest('.cf-card'); if (cd && e.dataTransfer) e.dataTransfer.setData('text/plain', cd.getAttribute('data-card')); });
    m.box.addEventListener('dragover', function (e) { if (e.target.closest && e.target.closest('.cf-slot')) e.preventDefault(); });
    m.box.addEventListener('drop', function (e) { var s = e.target.closest && e.target.closest('.cf-slot'); if (s && e.dataTransfer) { e.preventDefault(); place(s.getAttribute('data-arrow'), e.dataTransfer.getData('text/plain')); } });
    m.draw = render;
  };

  // The timeline (P1): the stations of macroeconomic thought, shown one at a time.
  KINDS.timeline = function (m) {
    var tx = m.cfg.spec.text, st = all('.station', m.box), shownN = 1, btn = htmlEl('button', {type: 'button', 'class': 'btn-main tl-next'}, m.box);
    m.draw = function () {
      st.forEach(function (s, i) { s.hidden = i >= shownN; });
      btn.hidden = shownN >= st.length; btn.textContent = fill(tx.next, {n: shownN + 1, m: st.length});
    };
    btn.addEventListener('click', function () { shownN = Math.min(st.length, shownN + 1); m.draw(); var s = st[shownN - 1]; if (s && s.scrollIntoView) s.scrollIntoView({block: 'nearest'}); });
  };

  function initModule(box) {
    if (box.getAttribute('data-ready')) return;
    var cfg; try { cfg = JSON.parse(box.getAttribute('data-config')); } catch (e) { return; }
    var make = KINDS[cfg.kind]; if (!make) return;
    box.setAttribute('data-ready', '1');
    cfg.controls = cfg.controls || []; cfg.show = cfg.show || []; if (!cfg.sliders || Array.isArray(cfg.sliders)) cfg.sliders = {};
    var m = {box: box, cfg: cfg, vals: {}, base: {}};
    all('input[type=range]', box).forEach(function (inp) {
      var k = inp.getAttribute('data-key'), out = box.querySelector('output[for="' + inp.id + '"]');
      m.vals[k] = +inp.value; m.base[k] = +inp.value;
      inp.addEventListener('input', function () { m.vals[k] = +inp.value; if (out) out.textContent = inp.value; inp.setAttribute('aria-valuetext', inp.value); m.draw(); });
    });
    m.set = function (k, v) { var inp = box.querySelector('input[data-key="' + k + '"]'); if (inp) { inp.value = v; var out = box.querySelector('output[for="' + inp.id + '"]'); if (out) out.textContent = inp.value; m.vals[k] = +inp.value; } m.draw(); };
    make(m);
    var reset = box.querySelector('[data-theory-reset]');
    if (reset) reset.addEventListener('click', function () {
      all('input[type=range]', box).forEach(function (inp) { var k = inp.getAttribute('data-key'); inp.value = m.base[k]; m.vals[k] = m.base[k];
        var out = box.querySelector('output[for="' + inp.id + '"]'); if (out) out.textContent = inp.value; });
      if (m.resetExtra) m.resetExtra(); m.draw();
    });
    m.draw();
  }
  function initAll(root) {
    all('.shell[data-view="theory"]', root).forEach(initShell);
    all('.theory-module', root).forEach(initModule);
  }
  function start() {
    initAll(document);
    var queued = false;
    if (window.MutationObserver) new MutationObserver(function () {     // the Shiny app's pages arrive after the page has loaded
      if (queued) return; queued = true;
      setTimeout(function () { queued = false; initAll(document); }, 0);
    }).observe(document.body, {childList: true, subtree: true});
  }
  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', start); else start();
})();
