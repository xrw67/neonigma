/* ============================================================
   可玩 Demo(E-001)
   提示判定与 docs/需求文档.md §3.4 严格一致:
   先算对位(绿),再从左到右配错位(白),其余为灭。
   ============================================================ */
(() => {
'use strict';

const COLORS = ['red', 'orange', 'yellow', 'green', 'blue', 'purple', 'white'];
const SYMS   = ['■', '▲', '●', '◆', '★', '✚', '✿'];
const SECRET = [5, 0, 4, 2];              // 紫 · 红 · 蓝 · 黄
const CLUE   = [5, 0, 4, 1];              // 紫 · 红 · 蓝 · 橙 → 3 绿 1 灭
const MAX    = 6;                         // 玩家可用猜测次数(7 行 - 1 条线索行)

const screenEl = document.getElementById('demoScreen');
const root     = document.getElementById('demoContent');
if (!screenEl || !root) return;

let hintKind = 'direct';                  // direct | indirect
let symOn    = false;
let S        = null;

/* ---------- 规则引擎 ---------- */
function evaluate(code, guess) {
  const n = code.length;
  const used = new Array(n).fill(false);
  const cells = new Array(n).fill('off');
  let greens = 0, whites = 0;
  for (let i = 0; i < n; i++) {
    if (guess[i] === code[i]) { cells[i] = 'on'; used[i] = true; greens++; }
  }
  for (let i = 0; i < n; i++) {
    if (cells[i] === 'on') continue;
    for (let j = 0; j < n; j++) {
      if (!used[j] && guess[i] === code[j]) { cells[i] = 'wt'; used[j] = true; whites++; break; }
    }
  }
  return { greens, whites, cells };
}

function freshState() {
  return {
    rows: [{ guess: CLUE.slice(), hint: evaluate(SECRET, CLUE), isClue: true }],
    cur: { guess: [null, null, null, null], sel: 0 },
    done: false, won: false, sheet: null,
  };
}

/* ---------- 渲染 ---------- */
function paintPeg(el, ci, sel) {
  el.className = 'peg' + (ci != null ? ' pc-' + COLORS[ci] : '') + (sel ? ' sel' : '');
  el.innerHTML = (symOn && ci != null) ? '<span class="sym">' + SYMS[ci] + '</span>' : '';
}

function directHTML(h) {
  return '<div class="dhints">' + h.cells.map(c =>
    '<span class="slot"><span class="hdot ' + c + '"></span></span>').join('') + '</div>';
}
function badgeHTML(h) {
  let s = '';
  for (let i = 0; i < h.greens; i++) s += '<span class="hdot on"></span>';
  for (let i = 0; i < h.whites; i++) s += '<span class="hdot wt"></span>';
  return '<span class="ibadge">' + s + '</span>';
}

function ghostRow() {
  return '<div class="rowwrap"><div class="rowmain"><div class="rowcells">' +
    '<span class="peg ghosted"></span>'.repeat(4) + '</div></div></div>';
}

function legendHTML() {
  if (hintKind === 'direct') {
    return '<div class="legend">' +
      '<span><i class="hdot on"></i>对色对位</span>' +
      '<span><i class="hdot wt"></i>对色错位</span>' +
      '<span><i class="hdot"></i>不存在</span></div>';
  }
  return '<div class="legend">' +
    '<span><i class="hdot on"></i>对位个数</span>' +
    '<span><i class="hdot wt"></i>错位个数</span>' +
    '<span style="color:var(--text-3)">只报数量 · 不报位置</span></div>';
}

function render(animateLast) {
  const used = S.rows.length - 1;
  const rowsHTML = S.rows.map((r) => {
    const hint = hintKind === 'direct' ? directHTML(r.hint) : '';
    const side = hintKind === 'indirect' ? badgeHTML(r.hint) : '';
    const tag = r.isClue ? '<div class="rowtag">第 1 行 · 起始线索</div>' : '';
    return '<div class="rowwrap' + (r.isClue ? ' clue' : '') + '">' +
      '<div class="rowmain">' + tag +
      '<div class="rowcells">' + r.guess.map(c =>
        '<span class="peg pc-' + COLORS[c] + (symOn ? '"><span class="sym">' + SYMS[c] + '</span></span>' : '"></span>')
      ).join('') + '</div>' +
      hint +
      '</div>' + side + '</div>';
  }).join('');

  const curHTML = !S.done
    ? '<div class="rowwrap current"><div class="rowmain">' +
      '<div class="rowtag">第 ' + (S.rows.length + 1) + ' 行 · 编辑中</div>' +
      '<div class="rowcells" id="curRow">' +
      S.cur.guess.map((_, i) => '<span class="peg" data-ci="' + i + '"></span>').join('') +
      '</div></div></div>'
    : '';

  const ghosts = Math.max(0, (MAX + 1) - S.rows.length - (S.done ? 0 : 1));

  root.innerHTML =
    '<div class="navbar">' +
      '<div class="side"><button class="icobtn" id="dBack">‹</button></div>' +
      '<div class="led">E-001</div>' +
      '<div class="side"><button class="icobtn accent" id="dRestart">↻</button></div>' +
    '</div>' +
    '<div class="chipline"><span>' +
      (hintKind === 'direct' ? '简单 · 直接提示' : '进阶 · 间接提示') +
    '</span><span>已用 ' + used + '/' + MAX + ' 次</span></div>' +
    legendHTML() +
    '<div class="rows">' + rowsHTML + curHTML + ghostRow().repeat(ghosts) + '</div>' +
    (!S.done
      ? '<div class="controls">' +
        '<div class="palette">' + COLORS.map((c, i) =>
          '<button class="peg pc-' + c + '" data-pc="' + i + '"></button>').join('') + '</div>' +
        '<div class="btnrow">' +
          '<button class="btn btn-ghost" id="dClear">清空</button>' +
          '<button class="btn btn-primary" id="dGo"' +
            (S.cur.guess.every(c => c != null) ? '' : ' disabled') + '>确 认</button>' +
        '</div></div>'
      : '') +
    sheetHTML();

  bindBoard();
  bindControls();

  if (animateLast && !S.done) {
    const wraps = root.querySelectorAll('.rows > .rowwrap');
    const last = wraps[S.rows.length - 1];
    if (last) last.querySelectorAll('.hdot').forEach((d, i) => {
      d.style.animationDelay = (i * 0.09) + 's';
      d.classList.add('lit');
    });
  }
}

function sheetHTML() {
  if (!S.sheet) return '';
  const answerline =
    '<div class="answerline"><span style="font-size:12px;color:var(--text-3);align-self:center;margin-right:4px">答案</span>' +
    SECRET.map(c => '<span class="peg pc-' + COLORS[c] + (symOn ? '"><span class="sym">' + SYMS[c] + '</span></span>' : '"></span>')).join('') +
    '</div>';

  if (S.sheet === 'win') {
    const n = S.rows.length - 1;
    const starN = n <= 2 ? 3 : n <= 4 ? 2 : 1;
    let stars = '';
    for (let i = 0; i < 3; i++) stars += '<i class="' + (i < starN ? 'on' : '') + '">★</i>';
    return '<div class="overlay" style="background:rgba(5,8,12,.45)"><div class="sheet">' +
      '<div class="stars-big">' + stars + '</div>' +
      '<h2>破译成功!</h2><div class="sub">E-001 · ' + n + ' 次破译</div>' +
      answerline +
      '<div class="btnrow"><button class="btn btn-ghost" id="dSwitch">挑战' + (hintKind === 'direct' ? '间接' : '直接') + '提示</button>' +
      '<button class="btn btn-primary" id="dAgain">再玩一次</button></div>' +
      '</div></div>';
  }
  if (S.sheet === 'lose') {
    return '<div class="overlay"><div class="sheet">' +
      '<span class="tag" style="border-color:rgba(255,93,93,.35);color:var(--danger)">第 7 行 · 未破译</span>' +
      '<h2>差一步!</h2><div class="sub">密码机器咯咯笑了 —— 查看答案,或重整旗鼓</div>' +
      '<div class="btnrow"><button class="btn btn-ghost" id="dReveal">查看答案</button>' +
      '<button class="btn btn-primary" id="dAgain">重试本关</button></div>' +
      '</div></div>';
  }
  return '<div class="overlay"><div class="sheet">' +
    '<span class="tag">答案揭示</span><h2>密码是</h2>' +
    answerline +
    '<div class="sub" style="margin-top:8px">原型机失败不揭示答案 · 本作默认开启,可在设置关闭</div>' +
    '<div class="btnrow"><button class="btn btn-primary" id="dAgain">再试一次</button></div>' +
    '</div></div>';
}

/* ---------- 交互 ---------- */
let curEls = [];

function renderCurRow() {
  S.cur.guess.forEach((c, i) => {
    if (curEls[i]) paintPeg(curEls[i], c, S.cur.sel === i);
  });
}

function bindBoard() {
  curEls = [...root.querySelectorAll('#curRow .peg')];
  curEls.forEach((el, ci) => {
    paintPeg(el, S.cur.guess[ci], S.cur.sel === ci);
    el.style.touchAction = 'none';

    let startY = 0, startC = -1, moved = false, pid = null;

    el.addEventListener('pointerdown', e => {
      if (S.done) return;
      e.preventDefault();
      pid = e.pointerId;
      try { el.setPointerCapture(pid); } catch (_) {}
      startY = e.clientY;
      startC = S.cur.guess[ci] != null ? S.cur.guess[ci] : -1;
      moved = false;
      S.cur.sel = ci;
      renderCurRow();
    });
    el.addEventListener('pointermove', e => {
      if (pid === null) return;
      const dy = e.clientY - startY;
      if (Math.abs(dy) > 4) moved = true;
      const steps = Math.round(dy / 16);
      let nc = ((startC + steps) % 7 + 7) % 7;
      if (nc !== S.cur.guess[ci]) {
        S.cur.guess[ci] = nc;
        paintPeg(el, nc, true);
        updateGoBtn();
      }
    });
    const end = () => { pid = null; if (!moved) { S.cur.sel = ci; render(); } };
    el.addEventListener('pointerup', end);
    el.addEventListener('pointercancel', () => { pid = null; });
  });
}

function updateGoBtn() {
  const btn = root.querySelector('#dGo');
  if (btn) btn.disabled = !S.cur.guess.every(c => c != null);
}

function bindControls() {
  root.querySelectorAll('[data-pc]').forEach(btn => {
    btn.addEventListener('click', () => {
      if (S.done) return;
      if (S.cur.sel == null) {
        S.cur.sel = S.cur.guess.findIndex(c => c == null);
        if (S.cur.sel < 0) S.cur.sel = 0;
      }
      S.cur.guess[S.cur.sel] = +btn.dataset.pc;
      let nxt = -1;
      for (let k = 1; k <= 4; k++) {
        const idx = (S.cur.sel + k) % 4;
        if (S.cur.guess[idx] == null) { nxt = idx; break; }
      }
      S.cur.sel = nxt >= 0 ? nxt : S.cur.sel;
      render();
    });
  });

  const go = root.querySelector('#dGo');
  if (go) go.addEventListener('click', submit);
  const clear = root.querySelector('#dClear');
  if (clear) clear.addEventListener('click', () => {
    S.cur = { guess: [null, null, null, null], sel: 0 };
    render();
  });

  const back = root.querySelector('#dBack');
  if (back) back.addEventListener('click', () => toast('演示:这里会返回上一页'));
  const restart = root.querySelector('#dRestart');
  if (restart) restart.addEventListener('click', restartGame);

  const again = root.querySelector('#dAgain');
  if (again) again.addEventListener('click', restartGame);
  const reveal = root.querySelector('#dReveal');
  if (reveal) reveal.addEventListener('click', () => { S.sheet = 'answer'; render(); });
  const sw = root.querySelector('#dSwitch');
  if (sw) sw.addEventListener('click', () => {
    hintKind = hintKind === 'direct' ? 'indirect' : 'direct';
    syncSeg();
    restartGame();
    toast('已切换为' + (hintKind === 'direct' ? '简单 · 直接' : '进阶 · 间接') + '提示');
  });
}

function submit() {
  if (!S.cur.guess.every(c => c != null)) return;
  const h = evaluate(SECRET, S.cur.guess);
  S.rows.push({ guess: S.cur.guess.slice(), hint: h, isClue: false });
  if (h.greens === 4) { S.done = true; S.won = true; }
  else if (S.rows.length - 1 === MAX) { S.done = true; S.won = false; }
  else S.cur = { guess: [null, null, null, null], sel: 0 };

  render(true);
  if (S.done) {
    setTimeout(() => {
      S.sheet = S.won ? 'win' : 'lose';
      render();
      if (S.won) confetti();
    }, 700);
  }
}

function restartGame() {
  S = freshState();
  render();
}

/* ---------- 外部控制条 ---------- */
function syncSeg() {
  document.querySelectorAll('#demoHintSeg button').forEach(b => {
    b.classList.toggle('on', b.dataset.hint === hintKind);
  });
}
document.querySelectorAll('#demoHintSeg button').forEach(b => {
  b.addEventListener('click', () => {
    hintKind = b.dataset.hint;
    if (S.sheet) restartGame();
    syncSeg();
    render();
  });
});
const symBtn = document.getElementById('demoSym');
if (symBtn) symBtn.addEventListener('click', () => {
  symOn = !symOn;
  symBtn.classList.toggle('on', symOn);
  render();
});
const rstBtn = document.getElementById('demoRestart');
if (rstBtn) rstBtn.addEventListener('click', restartGame);

/* ---------- 彩带 / 轻提示 ---------- */
function confetti() {
  const box = document.createElement('div');
  box.className = 'confetti';
  const vars = ['--c-red', '--c-orange', '--c-yellow', '--c-green', '--c-blue', '--c-purple', '--c-white'];
  for (let i = 0; i < 46; i++) {
    const p = document.createElement('i');
    p.style.left = (Math.random() * 100) + '%';
    p.style.background = 'var(' + vars[i % 7] + ')';
    p.style.animationDuration = (2.2 + Math.random() * 1.6) + 's';
    p.style.animationDelay = (Math.random() * 0.5) + 's';
    box.appendChild(p);
  }
  root.appendChild(box);   /* 常驻飘落,重新开始时随 root 重渲染移除 */
}

let toastEl = null, toastT = null;
function toast(msg) {
  if (!toastEl) {
    toastEl = document.createElement('div');
    toastEl.className = 'demo-toast';
    screenEl.appendChild(toastEl);
  }
  toastEl.textContent = msg;
  toastEl.classList.add('show');
  clearTimeout(toastT);
  toastT = setTimeout(() => toastEl.classList.remove('show'), 2200);
}

/* ---------- 启动 ---------- */
restartGame();
setTimeout(() => toast('点格子选中,再点色盘填色;也可以在格子上拖动换色'), 800);
})();
