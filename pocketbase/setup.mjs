const url = process.env.PB_URL ?? 'http://127.0.0.1:8090';
const email = process.env.PB_ADMIN ?? 'admin@flowers.ru';
const password = process.env.PB_PASSWORD ?? 'flowers12345';
const reset = process.argv.includes('--reset');

let token = '';

async function api(method, path, body) {
  const res = await fetch(url + path, {
    method,
    headers: { 'Content-Type': 'application/json', Authorization: token },
    body: body ? JSON.stringify(body) : undefined,
  });
  const text = await res.text();
  const data = text ? JSON.parse(text) : null;
  if (!res.ok) {
    throw new Error(`${method} ${path} -> ${res.status} ${JSON.stringify(data)}`);
  }
  return data;
}

const staff = '@request.auth.role = "florist" || @request.auth.role = "admin"';
const admin = '@request.auth.role = "admin"';

const text = (name, opts = {}) => ({ name, type: 'text', ...opts });
const num = (name, opts = {}) => ({ name, type: 'number', ...opts });
const rel = (name, collection, opts = {}) => ({
  name,
  type: 'relation',
  collection,
  maxSelect: 1,
  ...opts,
});

const schema = [
  {
    name: 'categories',
    rules: { list: '', view: '', create: staff, update: staff, delete: staff },
    fields: [
      text('name', { required: true, min: 2, max: 50 }),
      text('description', { max: 300 }),
    ],
    indexes: ['CREATE UNIQUE INDEX idx_categories_name ON categories (name)'],
  },
  {
    name: 'flowers',
    rules: { list: '', view: '', create: staff, update: staff, delete: staff },
    fields: [
      text('name', { required: true, min: 2, max: 50 }),
      text('color', { max: 30 }),
      num('price', { required: true, min: 1, max: 10000 }),
      num('stock', { min: 0, max: 100000, onlyInt: true }),
    ],
  },
  {
    name: 'bouquets',
    rules: { list: '', view: '', create: staff, update: staff, delete: staff },
    fields: [
      text('name', { required: true, min: 2, max: 100 }),
      rel('category', 'categories', { required: true }),
      num('price', { required: true, min: 1, max: 100000 }),
      text('description', { max: 500 }),
      { name: 'available', type: 'bool' },
    ],
  },
  {
    name: 'bouquet_items',
    rules: { list: '', view: '', create: staff, update: staff, delete: staff },
    fields: [
      rel('bouquet', 'bouquets', { required: true, cascadeDelete: true }),
      rel('flower', 'flowers', { required: true }),
      num('quantity', { required: true, min: 1, max: 101, onlyInt: true }),
    ],
    indexes: [
      'CREATE UNIQUE INDEX idx_bouquet_items ON bouquet_items (bouquet, flower)',
    ],
  },
  {
    name: 'suppliers',
    rules: { list: admin, view: admin, create: admin, update: admin, delete: admin },
    fields: [
      text('name', { required: true, min: 2, max: 100 }),
      text('phone', { pattern: '^\\+7 \\d{3} \\d{3}-\\d{2}-\\d{2}$' }),
      { name: 'email', type: 'email' },
      text('city', { max: 50 }),
    ],
  },
  {
    name: 'supplies',
    rules: { list: admin, view: admin, create: admin, update: admin, delete: admin },
    fields: [
      rel('supplier', 'suppliers', { required: true }),
      rel('flower', 'flowers', { required: true }),
      num('quantity', { required: true, min: 1, max: 10000, onlyInt: true }),
      num('price', { required: true, min: 1, max: 10000 }),
      { name: 'supplied_at', type: 'date', required: true },
    ],
  },
  {
    name: 'cards',
    rules: {
      list: `user = @request.auth.id || ${admin}`,
      view: `user = @request.auth.id || ${admin}`,
      create: admin,
      update: admin,
      delete: admin,
    },
    fields: [
      rel('user', 'users', { required: true, cascadeDelete: true }),
      text('number', { required: true, pattern: '^FC-\\d{6}$' }),
      num('discount', { min: 0, max: 30, onlyInt: true }),
    ],
    indexes: [
      'CREATE UNIQUE INDEX idx_cards_user ON cards (user)',
      'CREATE UNIQUE INDEX idx_cards_number ON cards (number)',
    ],
  },
  {
    name: 'orders',
    rules: {
      list: `user = @request.auth.id || ${staff}`,
      view: `user = @request.auth.id || ${staff}`,
      create: '@request.auth.id != "" && @request.body.user = @request.auth.id && @request.body.status = "new"',
      update: staff,
      delete: admin,
    },
    fields: [
      rel('user', 'users', { required: true }),
      {
        name: 'status',
        type: 'select',
        required: true,
        maxSelect: 1,
        values: ['new', 'assembling', 'delivering', 'done', 'canceled'],
      },
      num('total', { min: 0, max: 10000000 }),
      text('comment', { max: 300 }),
      { name: 'created', type: 'autodate', onCreate: true },
      { name: 'updated', type: 'autodate', onCreate: true, onUpdate: true },
    ],
  },
  {
    name: 'order_items',
    rules: {
      list: `order.user = @request.auth.id || ${staff}`,
      view: `order.user = @request.auth.id || ${staff}`,
      create: '@request.body.order.user = @request.auth.id && @request.body.order.status = "new"',
      update: admin,
      delete: admin,
    },
    fields: [
      rel('order', 'orders', { required: true, cascadeDelete: true }),
      rel('bouquet', 'bouquets', { required: true }),
      num('quantity', { required: true, min: 1, max: 50, onlyInt: true }),
      num('price', { required: true, min: 1, max: 100000 }),
    ],
  },
  {
    name: 'deliveries',
    rules: {
      list: `order.user = @request.auth.id || ${staff}`,
      view: `order.user = @request.auth.id || ${staff}`,
      create: '@request.body.order.user = @request.auth.id && @request.body.order.status = "new"',
      update: staff,
      delete: admin,
    },
    fields: [
      rel('order', 'orders', { required: true, cascadeDelete: true }),
      text('address', { required: true, min: 5, max: 200 }),
      { name: 'date', type: 'date', required: true },
      {
        name: 'time_slot',
        type: 'select',
        required: true,
        maxSelect: 1,
        values: ['10-14', '14-18', '18-22'],
      },
      text('recipient', { required: true, min: 2, max: 100 }),
      text('phone', { required: true, pattern: '^\\+7 \\d{3} \\d{3}-\\d{2}-\\d{2}$' }),
    ],
    indexes: ['CREATE UNIQUE INDEX idx_deliveries_order ON deliveries (order)'],
  },
];

async function setupUsers() {
  const users = await api('GET', '/api/collections/users');
  const fields = users.fields.filter((f) => f.name !== 'role');
  fields.push({
    name: 'role',
    type: 'select',
    required: true,
    maxSelect: 1,
    values: ['customer', 'florist', 'admin'],
  });
  await api('PATCH', '/api/collections/users', {
    fields,
    listRule: `id = @request.auth.id || ${staff}`,
    viewRule: `id = @request.auth.id || ${staff}`,
    createRule: '@request.body.role = "customer"',
    updateRule: `(id = @request.auth.id && @request.body.role:isset = false) || ${admin}`,
    deleteRule: admin,
  });
}

async function createCollections() {
  const ids = { users: (await api('GET', '/api/collections/users')).id };
  for (const c of schema) {
    const fields = c.fields.map((f) => {
      if (f.type !== 'relation') return f;
      const { collection, ...rest } = f;
      return { ...rest, collectionId: ids[collection] };
    });
    const created = await api('POST', '/api/collections', {
      name: c.name,
      type: 'base',
      fields,
      indexes: c.indexes ?? [],
      listRule: c.rules.list,
      viewRule: c.rules.view,
      createRule: c.rules.create,
      updateRule: c.rules.update,
      deleteRule: c.rules.delete,
    });
    ids[c.name] = created.id;
    console.log('коллекция', c.name);
  }
}

async function dropCollections() {
  for (const c of [...schema].reverse()) {
    try {
      await api('DELETE', `/api/collections/${c.name}`);
    } catch (_) {}
  }
  const users = await api('GET', '/api/collections/users/records?perPage=200');
  for (const u of users.items) {
    await api('DELETE', `/api/collections/users/records/${u.id}`);
  }
}

const add = (collection, data) =>
  api('POST', `/api/collections/${collection}/records`, data);

async function seed() {
  const pass = { password: 'flowers12345', passwordConfirm: 'flowers12345' };
  const people = {};
  for (const [key, email, name, role] of [
    ['admin', 'admin@flowers.ru', 'Иванова Анна', 'admin'],
    ['florist', 'florist@flowers.ru', 'Петрова Мария', 'florist'],
    ['customer', 'customer@flowers.ru', 'Смирнов Олег', 'customer'],
    ['customer2', 'kuznetsova@flowers.ru', 'Кузнецова Елена', 'customer'],
  ]) {
    people[key] = await add('users', { email, name, role, emailVisibility: true, verified: true, ...pass });
  }

  await add('cards', { user: people.customer.id, number: 'FC-000001', discount: 5 });
  await add('cards', { user: people.customer2.id, number: 'FC-000002', discount: 10 });

  const cat = {};
  for (const [name, description] of [
    ['Классика', 'Розы и монобукеты'],
    ['Сезонные', 'Букеты из цветов по сезону'],
    ['Свадебные', 'Букеты невесты и композиции'],
    ['В коробке', 'Цветы в шляпных коробках'],
    ['Корпоративные', 'Букеты для офиса и мероприятий'],
  ]) {
    cat[name] = (await add('categories', { name, description })).id;
  }

  const fl = {};
  for (const [name, color, price, stock] of [
    ['Роза', 'красный', 150, 300],
    ['Роза белая', 'белый', 160, 200],
    ['Тюльпан', 'жёлтый', 90, 250],
    ['Пион', 'розовый', 350, 80],
    ['Хризантема', 'белый', 120, 150],
    ['Лилия', 'белый', 280, 60],
    ['Гортензия', 'голубой', 450, 40],
    ['Эвкалипт', 'зелёный', 70, 120],
    ['Гипсофила', 'белый', 60, 200],
    ['Альстромерия', 'сиреневый', 110, 90],
  ]) {
    fl[name] = (await add('flowers', { name, color, price, stock })).id;
  }

  const bq = {};
  for (const [name, category, price, available, items, description] of [
    ['Алые розы', 'Классика', 3900, true, [['Роза', 25]], 'Двадцать пять красных роз'],
    ['Белое облако', 'Классика', 4200, true, [['Роза белая', 15], ['Гипсофила', 10]], 'Белые розы с гипсофилой'],
    ['Весенний', 'Сезонные', 2300, true, [['Тюльпан', 21], ['Эвкалипт', 5]], 'Жёлтые тюльпаны'],
    ['Пионовый рай', 'Сезонные', 5600, true, [['Пион', 15]], 'Пятнадцать пионов'],
    ['Нежность', 'Свадебные', 4800, true, [['Пион', 5], ['Роза белая', 7], ['Эвкалипт', 3]], 'Букет невесты'],
    ['Лилии', 'Свадебные', 3600, false, [['Лилия', 11], ['Гипсофила', 5]], 'Белые лилии'],
    ['Шляпная коробка', 'В коробке', 5200, true, [['Роза', 15], ['Гортензия', 3]], 'Розы и гортензия в коробке'],
    ['Офисный', 'Корпоративные', 1900, true, [['Хризантема', 9], ['Альстромерия', 6]], 'Для ресепшена'],
    ['Синяя гортензия', 'В коробке', 3400, true, [['Гортензия', 5], ['Эвкалипт', 4]], 'Гортензии с эвкалиптом'],
    ['Солнечный', 'Сезонные', 2700, true, [['Тюльпан', 15], ['Альстромерия', 7]], 'Тюльпаны и альстромерии'],
    ['Классика микс', 'Классика', 3100, true, [['Роза', 9], ['Роза белая', 8]], 'Красные и белые розы'],
    ['Юбилейный', 'Корпоративные', 6500, true, [['Роза', 31], ['Эвкалипт', 7]], 'Тридцать одна роза'],
  ]) {
    const b = await add('bouquets', { name, category: cat[category], price, available, description });
    bq[name] = b;
    for (const [flower, quantity] of items) {
      await add('bouquet_items', { bouquet: b.id, flower: fl[flower], quantity });
    }
  }

  const sp = {};
  for (const [name, phone, email, city] of [
    ['Голландские цветы', '+7 495 100-10-01', 'nl@flowers-opt.ru', 'Москва'],
    ['Кенийская роза', '+7 495 100-10-02', 'kenya@rose-opt.ru', 'Москва'],
    ['Подмосковная теплица', '+7 496 200-20-03', 'teplica@mail.ru', 'Дмитров'],
  ]) {
    sp[name] = (await add('suppliers', { name, phone, email, city })).id;
  }
  for (const [supplier, flower, quantity, price, date] of [
    ['Кенийская роза', 'Роза', 500, 70, '2026-10-20'],
    ['Кенийская роза', 'Роза белая', 300, 75, '2026-10-20'],
    ['Голландские цветы', 'Тюльпан', 400, 40, '2026-10-22'],
    ['Голландские цветы', 'Гортензия', 60, 220, '2026-10-22'],
    ['Подмосковная теплица', 'Хризантема', 200, 50, '2026-10-25'],
    ['Подмосковная теплица', 'Эвкалипт', 150, 30, '2026-10-25'],
  ]) {
    await add('supplies', {
      supplier: sp[supplier],
      flower: fl[flower],
      quantity,
      price,
      supplied_at: `${date} 10:00:00.000Z`,
    });
  }

  for (const [who, status, lines, delivery, comment] of [
    ['customer', 'done', [['Алые розы', 1]], ['ул. Ленина, 5, кв. 12', '2026-10-24', '10-14', 'Смирнова Ирина', '+7 900 111-22-33'], ''],
    ['customer', 'assembling', [['Весенний', 2]], ['пр. Мира, 20, офис 3', '2026-11-02', '14-18', 'Смирнов Олег', '+7 900 111-22-34'], 'Позвонить за час'],
    ['customer2', 'new', [['Пионовый рай', 1], ['Офисный', 1]], ['ул. Садовая, 8', '2026-11-03', '18-22', 'Кузнецова Елена', '+7 900 222-33-44'], ''],
    ['customer2', 'delivering', [['Шляпная коробка', 1]], ['ул. Тверская, 1', '2026-11-01', '10-14', 'Орлова Мария', '+7 900 222-33-45'], 'Без открытки'],
  ]) {
    const user = people[who];
    const discount = who === 'customer' ? 5 : 10;
    const sum = lines.reduce((s, [name, q]) => s + bq[name].price * q, 0);
    const total = Math.round((sum * (100 - discount)) / 100);
    const order = await add('orders', { user: user.id, status, total, comment });
    for (const [name, quantity] of lines) {
      await add('order_items', { order: order.id, bouquet: bq[name].id, quantity, price: bq[name].price });
    }
    const [address, date, time_slot, recipient, phone] = delivery;
    await add('deliveries', { order: order.id, address, date: `${date} 12:00:00.000Z`, time_slot, recipient, phone });
  }
  console.log('данные залиты');
}

const auth = await api('POST', '/api/collections/_superusers/auth-with-password', {
  identity: email,
  password,
});
token = auth.token;

const existing = await api('GET', '/api/collections?perPage=200');
const hasSchema = existing.items.some((c) => c.name === 'bouquets');
if (hasSchema && !reset) {
  console.log('Схема уже создана. Для пересоздания: node setup.mjs --reset');
  process.exit(0);
}
if (hasSchema) await dropCollections();

await setupUsers();
await createCollections();
await seed();
console.log('готово');
