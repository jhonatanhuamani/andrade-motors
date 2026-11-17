// Solo emuladores. No necesita credenciales ni paquetes npm adicionales.
const assert = require('node:assert/strict');
const project = 'demo-andrade-motors';
assert.equal(process.env.GCLOUD_PROJECT, project, 'Usar el proyecto demo');
assert.equal(process.env.FIRESTORE_EMULATOR_HOST, '127.0.0.1:8085');
assert.equal(process.env.FIREBASE_STORAGE_EMULATOR_HOST, '127.0.0.1:9195');
const db = `http://${process.env.FIRESTORE_EMULATOR_HOST}/v1/projects/${project}/databases/(default)/documents`;
const storage = `http://${process.env.FIREBASE_STORAGE_EMULATOR_HOST}/v0/b/${project}.appspot.com/o`;
const encode = (value) => Buffer.from(JSON.stringify(value)).toString('base64url');
function token(claims) {
  const now = Math.floor(Date.now() / 1000);
  return `${encode({ alg: 'none', typ: 'JWT' })}.${encode({
    iss: `https://securetoken.google.com/${project}`, aud: project,
    sub: 'test-user', user_id: 'test-user', iat: now, exp: now + 3600,
    auth_time: now, firebase: { sign_in_provider: 'password', identities: {} },
    ...claims,
  })}.`;
}
const admin = token({ admin: true });
const client = token({});
const fakeAdmin = token({ admin: 'true' });
let passed = 0;
async function check(label, request, allowed) {
  const response = await request;
  const body = await response.text();
  assert.equal(response.ok, allowed, `${label}: ${response.status} ${body}`);
  if (!allowed) assert.ok([401, 403].includes(response.status), `${label}: ${body}`);
  console.log(`OK ${++passed}: ${label}`);
}
function product(activo = true) {
  return { nombre: { stringValue: 'Producto real' }, categoria: { stringValue: 'Repuestos' },
    descripcion: { stringValue: 'Prueba de reglas' }, precio: { doubleValue: 25 },
    stock: { integerValue: '5' }, activo: { booleanValue: activo }, imagenUrl: { nullValue: null } };
}
function commit(id, auth, fields, transforms = ['createdAt', 'updatedAt']) {
  return fetch(`${db}:commit`, { method: 'POST', headers: {
    Authorization: `Bearer ${auth}`, 'Content-Type': 'application/json',
  }, body: JSON.stringify({ writes: [{
    update: { name: `projects/${project}/databases/(default)/documents/productos/${id}`, fields },
    updateTransforms: transforms.map((fieldPath) => ({ fieldPath, setToServerValue: 'REQUEST_TIME' })),
  }] }) });
}
function read(path, auth) {
  return fetch(`${db}/${path}`, { headers: auth ? { Authorization: `Bearer ${auth}` } : {} });
}
function remove(path, auth) {
  return fetch(`${db}/${path}`, { method: 'DELETE', headers: { Authorization: `Bearer ${auth}` } });
}
function upload(id, auth, contentType = 'image/png', size = 8) {
  const boundary = 'andrade-test-boundary';
  const name = `productos/${id}/principal`;
  const body = Buffer.concat([
    Buffer.from(`--${boundary}\r\nContent-Type: application/json; charset=utf-8\r\n\r\n${JSON.stringify({ name, contentType })}\r\n--${boundary}\r\nContent-Type: ${contentType}\r\n\r\n`),
    Buffer.alloc(size, 1), Buffer.from(`\r\n--${boundary}--\r\n`),
  ]);
  return fetch(`${storage}?name=${encodeURIComponent(name)}`, {
    method: 'POST', headers: { Authorization: `Firebase ${auth}`,
      'Content-Type': `multipart/related; boundary=${boundary}`, 'X-Goog-Upload-Protocol': 'multipart' },
    body,
  });
}
function image(id, auth, method = 'GET') {
  return fetch(`${storage}/${encodeURIComponent(`productos/${id}/principal`)}`, {
    method, headers: { Authorization: `Firebase ${auth}` },
  });
}
async function main() {
  await check('admin crea activo con timestamps de servidor', commit('activo', admin, product()), true);
  await check('admin crea inactivo', commit('inactivo', admin, product(false)), true);
  await check('cliente no crea', commit('cliente', client, product()), false);
  await check('admin string no concede privilegios', commit('falso', fakeAdmin, product()), false);
  await check('cliente lee activo sin claim', read('productos/activo', client), true);
  await check('visitante lee catalogo activo (compatibilidad)', read('productos/activo'), true);
  await check('cliente no lee inactivo', read('productos/inactivo', client), false);
  await check('admin lee inactivo', read('productos/inactivo', admin), true);
  await check('cliente no lista sin filtrar', read('productos', client), false);
  await check('cliente consulta activos', fetch(`${db}:runQuery`, {
    method: 'POST', headers: { Authorization: `Bearer ${client}`, 'Content-Type': 'application/json' },
    body: JSON.stringify({ structuredQuery: { from: [{ collectionId: 'productos' }],
      where: { fieldFilter: { field: { fieldPath: 'activo' }, op: 'EQUAL', value: { booleanValue: true } } } } }),
  }), true);
  const existing = (await (await read('productos/activo', admin)).json()).fields;
  await check('admin edita preservando createdAt', commit('activo', admin, {
    ...existing, precio: { doubleValue: 30 }, campoExtra: { stringValue: 'Se conserva' },
  }, ['updatedAt']), true);
  await check('cliente no edita', commit('activo', client, existing, ['updatedAt']), false);
  await check('admin no altera createdAt', commit('activo', admin, existing), false);
  await check('admin no guarda stock negativo', commit('activo', admin, {
    ...existing, stock: { integerValue: '-1' },
  }, ['updatedAt']), false);
  await check('updatedAt no puede quedar obsoleto', commit('activo', admin, existing, []), false);
  await check('cliente no elimina', remove('productos/activo', client), false);
  // Documento antiguo, equivalente a los datos locales importados sin timestamps.
  const seed = await fetch(`${db}/productos/antiguo`, { method: 'PATCH', headers: {
    Authorization: 'Bearer owner', 'Content-Type': 'application/json',
  }, body: JSON.stringify({ fields: product() }) });
  assert.ok(seed.ok, await seed.text());
  await check('admin completa timestamps de documento antiguo', commit('antiguo', admin, product()), true);
  for (const collection of ['usuarios', 'servicios', 'reservas', 'inventario', 'pedidos', 'roles', 'configuracion']) {
    await check(`sin acceso inventado a ${collection}`, read(`${collection}/test`, admin), false);
  }
  await check('admin sube PNG', upload('activo', admin), true);
  await check('admin reemplaza por JPEG', upload('activo', admin, 'image/jpeg'), true);
  await check('admin sube WebP de inactivo', upload('inactivo', admin, 'image/webp'), true);
  await check('cliente lee imagen activa desde base default', image('activo', client), true);
  await check('cliente no lee imagen inactiva', image('inactivo', client), false);
  await check('admin lee imagen inactiva', image('inactivo', admin), true);
  await check('cliente no reemplaza', upload('activo', client), false);
  await check('cliente no sube', upload('nuevo', client), false);
  await check('claim string no permite subir', upload('nuevo', fakeAdmin), false);
  await check('admin no sube documento no imagen', upload('nuevo', admin, 'application/pdf'), false);
  await check('admin puede subir exactamente 10 MB', upload('limite', admin, 'image/jpeg', 10 * 1024 * 1024), true);
  await check('admin no supera 10 MB', upload('exceso', admin, 'image/jpeg', 10 * 1024 * 1024 + 1), false);
  await check('cliente no lee foto sin producto', image('limite', client), false);
  await check('cliente no elimina foto', image('activo', client, 'DELETE'), false);
  await check('admin elimina foto', image('activo', admin, 'DELETE'), true);
  await check('admin elimina producto', remove('productos/activo', admin), true);
  console.log(`${passed} comprobaciones de reglas aprobadas. Sin acceso a produccion.`);
}
main().catch((error) => { console.error(error); process.exitCode = 1; });
