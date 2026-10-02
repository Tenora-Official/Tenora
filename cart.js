/* TENORA cart + checkout (COD / bank transfer). Load AFTER the main inline script. */
(() => {
  const CONFIG = {
    whatsapp: '94000000000',            // <- your real number, digits only
    bank: 'Bank: YOUR BANK\nAccount name: TENORA\nAccount no: 0000000000\nBranch: YOUR BRANCH',
    currency: 'LKR'
  };
  const $ = s => document.querySelector(s);
  const money = n => CONFIG.currency + ' ' + Number(n).toLocaleString();
  const sb = () => window._tsb || (window._tsb = supabase.createClient(TENORA_SUPABASE.url, TENORA_SUPABASE.key));
  let cart = []; try { cart = JSON.parse(localStorage.getItem('tcart') || '[]'); } catch (e) {}
  let prices = {};
  const save = () => { try { localStorage.setItem('tcart', JSON.stringify(cart)); } catch (e) {} render(); };

  // ---------- styles + markup ----------
  document.head.insertAdjacentHTML('beforeend', `<style>
  .cart-fab{position:fixed;left:16px;bottom:calc(18px + env(safe-area-inset-bottom,0px));z-index:60;background:var(--charcoal);color:var(--ivory);border:0;border-radius:999px;padding:14px 20px;font:13px Jost,sans-serif;letter-spacing:.06em;cursor:pointer;box-shadow:0 10px 28px -8px rgba(41,40,39,.55)}
  .cart-drawer{position:fixed;inset:0 0 0 auto;width:min(420px,100%);background:var(--ivory);z-index:130;transform:translateX(100%);transition:transform .3s;display:flex;flex-direction:column;box-shadow:-20px 0 50px -20px rgba(0,0,0,.4)}
  .cart-drawer.open{transform:none}
  .cd-head{display:flex;justify-content:space-between;align-items:center;padding:18px 20px;border-bottom:1px solid var(--line);font:500 24px 'Cormorant Garamond',serif}
  .cd-head button,.cd-x{background:none;border:0;font-size:26px;cursor:pointer;color:var(--text)}
  .cd-body{flex:1;overflow:auto;padding:14px 20px}
  .cd-item{display:grid;grid-template-columns:1fr auto;gap:4px 12px;padding:12px 0;border-bottom:1px solid var(--line);font-size:13.5px}
  .cd-item small{color:var(--text-soft);grid-column:1}
  .cd-qty{display:flex;align-items:center;gap:8px}.cd-qty button{width:28px;height:28px;border-radius:50%;border:1px solid var(--line);background:var(--surface);cursor:pointer}
  .cd-foot{padding:16px 20px;border-top:1px solid var(--line);display:grid;gap:10px}
  .cd-foot input,.cd-foot textarea,.cd-foot select{width:100%;padding:11px;border:1px solid var(--line);border-radius:5px;font:16px Jost,sans-serif;background:var(--surface)}
  .cd-total{display:flex;justify-content:space-between;font-weight:500}
  .cd-note{font-size:12px;color:var(--text-soft);white-space:pre-line}
  .add-cart-btn{width:100%;margin:0 0 10px;padding:13px;border:1px solid var(--charcoal);background:transparent;color:var(--charcoal);border-radius:3px;font:12.5px Jost,sans-serif;letter-spacing:.08em;cursor:pointer}
  .add-cart-btn:hover{background:var(--charcoal);color:var(--ivory)}
  .managed-product .add-cart-btn{margin:6px 0 0}
  </style>`);
  document.body.insertAdjacentHTML('beforeend', `
  <button class="cart-fab" id="cartFab" type="button">Cart (<span id="cartN">0</span>)</button>
  <aside class="cart-drawer" id="cartDrawer" aria-label="Cart">
    <div class="cd-head"><span>Your cart</span><button type="button" class="cd-x" aria-label="Close">&times;</button></div>
    <div class="cd-body" id="cdBody"></div>
    <div class="cd-foot" id="cdFoot">
      <div class="cd-total"><span>Total</span><span id="cdTotal"></span></div>
      <input id="coName" placeholder="Your name" autocomplete="name">
      <input id="coPhone" placeholder="Phone / WhatsApp" inputmode="tel" autocomplete="tel">
      <textarea id="coAddr" rows="2" placeholder="Delivery address"></textarea>
      <select id="coPay"><option value="cod">Cash on delivery (COD)</option><option value="bank">Bank transfer</option></select>
      <div class="cd-note" id="coBank" hidden></div>
      <input id="coNotes" placeholder="Notes (optional)">
      <button class="order-now-btn" id="coSend" type="button">Place order</button>
      <div class="cd-note" id="coMsg"></div>
    </div>
  </aside>`);
  const drawer = $('#cartDrawer');
  const open = v => drawer.classList.toggle('open', v);
  $('#cartFab').onclick = () => open(true);
  drawer.querySelector('.cd-x').onclick = () => open(false);
  $('#coPay').onchange = e => { const b = $('#coBank'); b.hidden = e.target.value !== 'bank'; b.textContent = 'Transfer to:\n' + CONFIG.bank + '\nSend the slip on WhatsApp after ordering.'; };

  // ---------- cart ----------
  const total = () => cart.reduce((s, i) => s + (i.price || 0) * i.qty, 0);
  function add(name, opt, price) {
    const k = name + '|' + opt, f = cart.find(i => i.k === k);
    f ? f.qty++ : cart.push({ k, name, opt, price: price == null ? null : Number(price), qty: 1 });
    save(); open(true);
  }
  function render() {
    $('#cartN').textContent = cart.reduce((s, i) => s + i.qty, 0);
    $('#cdBody').innerHTML = cart.length ? cart.map((i, n) => `<div class="cd-item"><strong>${esc(i.name)}</strong><span>${i.price != null ? money(i.price * i.qty) : 'Price on request'}</span><small>${esc(i.opt)}</small><div class="cd-qty"><button data-d="-1" data-n="${n}">-</button>${i.qty}<button data-d="1" data-n="${n}">+</button></div></div>`).join('') : '<p class="cd-note">Your cart is empty.</p>';
    $('#cdTotal').textContent = money(total()) + (cart.some(i => i.price == null) ? ' + items on request' : '');
    $('#cdFoot').hidden = !cart.length;
  }
  $('#cdBody').onclick = e => {
    const b = e.target.closest('button[data-n]'); if (!b) return;
    const i = cart[b.dataset.n]; i.qty += Number(b.dataset.d);
    if (i.qty < 1) cart.splice(b.dataset.n, 1); save();
  };

  $('#coSend').onclick = async () => {
    const name = $('#coName').value.trim(), phone = $('#coPhone').value.trim(), addr = $('#coAddr').value.trim();
    const msg = $('#coMsg');
    if (!name || !phone || !addr) { msg.textContent = 'Please fill name, phone and address.'; return; }
    const pay = $('#coPay').value, id = crypto.randomUUID(), t = total();
    let saved = true;
    try {
      const { error } = await sb().from('orders').insert({ id, customer_name: name, phone, address: addr, payment_method: pay, items: cart, total: t, notes: $('#coNotes').value.trim() });
      if (error) throw error;
    } catch (e) { saved = false; console.warn(e.message); }
    const lines = [`Hi TENORA, new order #${id.slice(0, 8)}`, ...cart.map(i => `- ${i.name} (${i.opt}) x${i.qty}${i.price != null ? ' = ' + money(i.price * i.qty) : ' (price?)'}`), `Total: ${money(t)}`, `Payment: ${pay === 'cod' ? 'Cash on delivery' : 'Bank transfer (slip to follow)'}`, `Name: ${name}`, `Phone: ${phone}`, `Address: ${addr}`];
    window.open(`https://wa.me/${CONFIG.whatsapp}?text=${encodeURIComponent(lines.join('\n'))}`, '_blank', 'noopener');
    msg.textContent = saved ? 'Order placed. We will confirm on WhatsApp.' : 'Sent via WhatsApp (could not save to our system, we will still process it).';
    cart = []; save();
  };

  // ---------- gift box prices ----------
  sb().from('collections').select('slug,price').then(r => { (r.data || []).forEach(c => prices[c.slug] = c.price); }).catch(() => {});

  // ---------- add-to-cart: collections ----------
  const ob = $('#orderNowBtn'), sel1 = $('#sizeSelect');
  const extra = document.createElement('div');
  extra.innerHTML = '<label class="color-label" for="size2"></label><select id="size2" class="order-size"></select>';
  extra.hidden = true; sel1.after(extra);
  const EXTRA = { 'mother-baby': 'Mother size', 'new-dad': 'Dad size' };
  const ADULT = ['XS', 'S', 'M', 'L', 'XL', 'XXL', 'Not sure - please help'];
  function syncSizes() {
    const lab = EXTRA[currentKey]; extra.hidden = !lab;
    if (lab) { extra.querySelector('label').textContent = lab; $('#size2').innerHTML = ADULT.map(s => `<option>${s}</option>`).join(''); }
    sel1.previousElementSibling.textContent = lab ? 'Baby size' : 'Size';
  }
  new MutationObserver(syncSizes).observe($('#previewTitle'), { childList: true, characterData: true, subtree: true });
  syncSizes();
  const sizeText = () => (EXTRA[currentKey] ? `Baby ${sel1.value} + ${EXTRA[currentKey]} ${$('#size2').value}` : sel1.value);
  ob.addEventListener('click', () => { // keep WhatsApp quick-order message in sync with the 2nd size
    const base = ob.getAttribute('href').split('%0A%5B2%5D')[0];
    if (EXTRA[currentKey]) ob.href = base + encodeURIComponent(`\n[2] ${EXTRA[currentKey]}: ${$('#size2').value}`).replace(/^%0A%5B2%5D/, '%0A%5B2%5D'); else ob.href = base;
  });
  const addBtn = document.createElement('button');
  addBtn.type = 'button'; addBtn.className = 'add-cart-btn'; addBtn.textContent = 'Add collection to cart';
  ob.before(addBtn);
  addBtn.onclick = () => {
    const who = { girl: 'Girl', boy: 'Boy', neutral: 'Neutral' }[selectedGender];
    add($('#previewTitle').textContent + ' (gift box)', `${who} · ${selectedColor.name} · ${sizeText()}`, prices[currentKey]);
  };

  // ---------- add-to-cart: individual products ----------
  const grid = $('#managedProductsGrid');
  function decorate() {
    grid.querySelectorAll('.managed-product').forEach(card => {
      if (card.querySelector('.add-cart-btn')) return;
      const name = card.querySelector('h3').textContent;
      const p = (typeof managedProducts !== 'undefined' ? managedProducts : []).find(x => x.name === name) || {};
      const body = card.querySelector('.managed-product-body');
      const mk = (arr, label) => arr && arr.length ? `<select class="order-size" data-l="${label}" style="margin:6px 0 0">${arr.map(x => `<option>${esc(x)}</option>`).join('')}</select>` : '';
      body.insertAdjacentHTML('beforeend', mk(p.sizes, 'Size') + mk(p.colors, 'Colour') + '<button type="button" class="add-cart-btn">Add to cart</button>');
      card.querySelector('.add-cart-btn').onclick = () => {
        const o = [...card.querySelectorAll('select[data-l]')].map(s => s.value).join(' · ') || 'Standard';
        add(name, o, p.price);
      };
    });
  }
  new MutationObserver(decorate).observe(grid, { childList: true });
  decorate();

  function esc(v = '') { return String(v).replace(/[&<>"']/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c])); }
  // cart button only on Kids & Gift / Collections tabs, not on Home
  const fab = $('#cartFab');
  const upd = () => { const home = ($('.site-tab.active') || {}).dataset?.tab === 'home'; fab.hidden = home; if (home) open(false); };
  new MutationObserver(upd).observe($('.site-tabs'), { subtree: true, attributes: true, attributeFilter: ['class'] });
  upd();
  render();
})();
