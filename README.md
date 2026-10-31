# Inventario de Agencia Helados Panda Ballivián

Aplicación en español para registrar productos, sabores, existencias y movimientos de inventario. Moneda: BOB (Bs). Zona horaria de operación: Bolivia (`America/La_Paz`).

## Requisitos

- Node.js 20 o superior y npm.
- Proyecto Supabase (opcional para desarrollo local; sin credenciales la app guarda los cambios en el navegador).

## Configurar Supabase

1. Crea un proyecto en [Supabase](https://supabase.com/).
2. En **SQL Editor**, ejecuta `supabase/schema.sql` y después `supabase/seed.sql` para cargar el catálogo.
3. Ejecuta `supabase/observaciones_cliente.sql` y luego `supabase/admin_access.sql`.
4. En **Authentication → Users**, crea el primer usuario administrador. Copia su UUID y ejecuta en SQL Editor el `insert` de bootstrap comentado al final de `admin_access.sql`, reemplazando el UUID y el nombre.
5. Copia `.env.example` a `.env.local`. Las variables públicas son `NEXT_PUBLIC_SUPABASE_URL` y `NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY` desde Supabase → **Connect** o **Project Settings → API Keys → Publishable key**. La clave antigua `anon` se acepta como `NEXT_PUBLIC_SUPABASE_ANON_KEY`.

`admin_access.sql` reemplaza las políticas abiertas del esquema inicial: los cajeros pueden consultar productos y registrar ventas, mientras que solo admins pueden editar productos y stock. La clave publishable no es un secreto. Nunca coloques `SUPABASE_SECRET_KEY`/`service_role` en una variable `NEXT_PUBLIC_` ni en el navegador.

## Ejecutar en local

```bash
npm install
npm run dev
```

Abre [http://localhost:3000](http://localhost:3000). El modo de navegador local permite revisar toda la interfaz sin conectar Supabase. En ese modo, cada navegador conserva sus datos por separado.

## Catálogo e imágenes

`scripts/catalogo.json` contiene el catálogo estructurado; `public/productos/` contiene las 40 imágenes renombradas y `public/panda.jpg` es la portada/logo. Los originales permanecen en `catalogo/` y están excluidos de Git. Para regenerar JSON, imágenes y seed SQL desde esa carpeta, usa `npm run catalogo`.

Las dudas de escritura, empaques, descripciones y categorías están en `CATALOGO_REVISION.md`.

## GitHub y Vercel

1. Sube la rama `main` al repositorio GitHub configurado con `git push -u origin main`.
2. En Vercel, importa el repositorio y conserva el preset Next.js.
3. En **Project Settings → Environment Variables**, agrega estas variables para Production, Preview y Development:

   ```env
   NEXT_PUBLIC_SUPABASE_URL=https://TU_PROJECT_REF.supabase.co
   NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY=sb_publishable_TU_CLAVE
   SUPABASE_SECRET_KEY=sb_secret_TU_CLAVE_PRIVADA
   NEXT_PUBLIC_PAYMENT_QR_IMAGE_URL=https://.../qr-de-tu-cuenta.png
   ```

   `SUPABASE_SECRET_KEY` se usa solo en el servidor para crear y administrar cuentas; no le agregues el prefijo `NEXT_PUBLIC_`. La URL de QR es opcional: sube el QR estático de cobro a Supabase Storage y pega aquí su URL pública. Para un proyecto antiguo también puedes usar `NEXT_PUBLIC_SUPABASE_ANON_KEY` con la clave `anon`.
4. Ejecuta los cuatro SQL indicados arriba en orden. Después despliega en Vercel.

## Funcionalidades

- Dashboard con productos, unidades, valoración, alertas de stock/vencimiento y movimientos recientes.
- Inventario con búsqueda, categoría, estado, orden y tarjetas adaptables a móvil.
- Detalle de producto con stock por sabor, entradas, salidas, ajustes, mermas e historial.
- Caja con carrito multiproducto, cobro en efectivo o QR y descuento transaccional de stock.
- Alta y edición de productos con carga de foto desde celular y fecha de vencimiento.
- Gestión de cajeros y admins; historial filtrable y reportes Excel/PDF.
- El cobro QR muestra el QR de la cuenta y requiere que el cajero confirme el abono. La confirmación bancaria automática necesita una integración adicional con el banco/proveedor y su webhook.
- SQL de Supabase con políticas RLS y funciones transaccionales de ventas e inventario.
