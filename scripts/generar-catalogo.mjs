import fs from 'node:fs';
import path from 'node:path';

const root = process.cwd();
const source = path.join(root, 'catalogo');
const output = path.join(root, 'public', 'productos');
fs.mkdirSync(output, { recursive: true });
fs.copyFileSync(path.join(source, '04a95444-7c0e-4509-9a68-0139bf9d212b.jpg'), path.join(root, 'public', 'panda.jpg'));
const manifest = [
['BRAZO GITANO',85,'Postres','unidad',''],['BOLO DE LECHE',22,'Helados','unidad',''],['SUPER LOCO LOCO',15,'Helados','unidad','Tutti frutilla|Chocolate|Mango'],
['YOGURT DE BOTELLA 2 LTS',27,'Yogurt','botella','Plátano|Frutilla|Chirimoya|Uva|Manzana|Durazno|Coco'],['YOGURT DRINKY 100ml',14,'Yogurt','botella','Frutilla|Plátano|Coco|Durazno|Chirimoya'],
['CAPUCCINO',73,'Helados','bolsa',''],['GRANIZADO',73,'Granizados','bolsa',''],['MENTACHOC',115,'Helados','bolsa',''],['CHOCO PANDA',115,'Helados','bolsa',''],['PANDIKROK',115,'Helados','bolsa',''],['KREMOSO',57,'Helados','bolsa',''],['MAXIMO',56,'Helados','bolsa',''],['TROPICAL',56,'Helados','bolsa',''],['GENIAL',56,'Helados','bolsa',''],['PICARON',56,'Helados','bolsa',''],['CHOCOLIMON',60,'Helados','bolsa',''],['CHOCONARANJA',60,'Helados','bolsa',''],['VAMPIRO',115,'Helados','bolsa',''],['CASATTA',25,'Postres','unidad','Chocolate|Vainilla|Frutilla'],['CREMISIMO',73,'Helados','bolsa',''],['CAJA 5 LITROS',90,'Helados','caja','Pie de Limón|Turrón Español|Vainilla|Coco|Frutilla|Chocolate|Granizado|Menta granizado|Canela|Uva|Chicle|Pasas al Ron|Cappuccino|Chirimoya|Moka|Dulce de Leche'],['FAMILIARES DE LITRO',25,'Helados','litro','Frutilla|Chocolate|Granizado|Menta granizado|Cappuccino|Vainilla|Pasas al ron|Chirimoya'],['FROZEN GURT',69,'Helados','bolsa',''],['CASSATIN',7,'Postres','unidad','Cappuccino|Mora|Naranja Chirimoya'],['CREMOLADA TRICOLOR',15,'Granizados','unidad',''],['CREMOLADA CANELA',15,'Granizados','unidad',''],['GUSANITO',57,'Helados','bolsa',''],['PANDI CONO',85,'Helados','bolsa','Chocolate|Frutilla|Pasas al Ron'],['VASITOS',82,'Helados','bolsa','Vainilla|Frutilla|Chirimoya'],['GOLAZO',48,'Helados','paquete',''],['BOLO DE AGUA',18,'Helados','unidad',''],['ESCOLINO',45,'Helados','bolsa',''],['TU Y YO',65,'Helados','bolsa',''],['UNI2',45,'Helados','bolsa',''],['CHICOSITO CANELA',45,'Helados','bolsa',''],['PANDY GELIO',23,'Helados','bolsa',''],['TORTA MEDIANA (25cm)',100,'Postres','unidad','Frutilla|Vainilla|Chirimoya'],['TORTA GRANDE (40cm)',110,'Postres','unidad','Frutilla|Vainilla|Chirimoya'],['DINAMITA',47,'Helados','bolsa',''],['PANDI PANDA',105,'Helados','bolsa',''],['ISLA LOCA',40,'Helados','bolsa','Blue berry|Naranja|Frutilla']
];
const files = fs.readdirSync(source).filter(f => f.toLowerCase().endsWith('.jpg'));
const lookup = new Map(files.map(f => [path.parse(f).name.normalize('NFD').replace(/[\u0300-\u036f]/g,'').toLowerCase().replace(/[^a-z0-9]+/g,''), f]));
lookup.set('yogurtdebotella2lts','YOGURT DE BOTTELLA 2 LTS.jpg');
const slug = s => s.normalize('NFD').replace(/[\u0300-\u036f]/g,'').toLowerCase().replace(/[^a-z0-9]+/g,'-').replace(/^-|-$/g,'');
const products = manifest.map(([name, price, category, unit, flavorText]) => {
  const key = String(name).normalize('NFD').replace(/[\u0300-\u036f]/g,'').toLowerCase().replace(/[^a-z0-9]+/g,'');
  const file = lookup.get(key);
  if (!file) throw new Error(`No se encontró imagen para ${name}`);
  const image = `${slug(name)}.jpg`;
  fs.copyFileSync(path.join(source, file), path.join(output, image));
  const flavors = flavorText ? flavorText.split('|') : ['General'];
  const text = fs.readFileSync(path.join(source, 'CATALOGO DESCRITO PARA CADA IMAGEN.txt'), 'utf8').replace(/\r\n/g,'\n');
  const start = text.toUpperCase().indexOf(String(name).replace('YOGURT DE BOTELLA 2 LTS','YOGURT BOTELLA 2 LITROSCUU').toUpperCase());
  const sectionEnd = text.indexOf('\n\n', start);
  const section = start >= 0 ? text.slice(start, sectionEnd > -1 ? sectionEnd : undefined) : '';
  const units = /(?:Cantidad(?: por| en)? bolsa|Cantidad de)\s*(\d+)\s*unidades?|(?:^|\n)(\d+)\s*unidades?|(?:yogurt\s+)?(\d+)\s*unidades?\s+la bolsa|(\d+)\s*unidades?/i.exec(section);
  const unitsCount = units?.[1] || units?.[2] || units?.[3] || units?.[4];
  const description = unitsCount ? `${unitsCount} unidades${unit === 'bolsa' ? ' por bolsa' : ''}` : '';
  return { name: String(name).replace('YOGURT DE BOTELLA 2 LTS','Yogurt de botella 2 lts'), description, price, currency:'BOB', flavors, unit, category, min_stock:5, stock:0, active:true, image_url:`/productos/${image}`, original_image:file, catalog_description: section.trim() };
});
fs.writeFileSync(path.join(root,'scripts','catalogo.json'), JSON.stringify(products,null,2)+'\n');
const q = value => `'${String(value ?? '').replaceAll("'", "''")}'`;
const sql = ['-- Catálogo inicial. Stock 0 y mínimo 5 en todas las variantes.','begin;'];
for (const [i,p] of products.entries()) {
  const id=`00000000-0000-4000-8000-${String(i+1).padStart(12,'0')}`;
  sql.push(`insert into public.products(id,name,description,category,price,unit,min_stock,image_url,active) values ('${id}',${q(p.name)},${q(p.description)},${q(p.category)},${p.price},${q(p.unit)},5,${q(p.image_url)},true) on conflict(id) do update set name=excluded.name,description=excluded.description,category=excluded.category,price=excluded.price,unit=excluded.unit,min_stock=5,image_url=excluded.image_url,active=true;`);
  for (const [j,name] of p.flavors.entries()) sql.push(`insert into public.product_flavors(product_id,name,stock) values ('${id}',${q(name)},0) on conflict(product_id,name) do nothing;`);
}
sql.push('commit;','');
fs.mkdirSync(path.join(root,'supabase'),{recursive:true});
fs.writeFileSync(path.join(root,'supabase','seed.sql'),sql.join('\n'));
console.log(`Catálogo generado: ${products.length} productos; ${files.length - products.length} imagen de marca excluida.`);
