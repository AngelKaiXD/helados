# Inventario de Agencia Helados Panda Ballivián

Aplicación en español para registrar productos, sabores, existencias y movimientos de inventario. Moneda: BOB (Bs). Zona horaria de operación: Bolivia (`America/La_Paz`).

## Requisitos

- Node.js 20 o superior y npm.
- Proyecto Supabase (opcional para desarrollo local; sin credenciales la app guarda los cambios en el navegador).

## Configurar Supabase

1. Crea un proyecto en [Supabase](https://supabase.com/).
2. En **SQL Editor**, ejecuta `supabase/schema.sql`.
3. Ejecuta después `supabase/seed.sql` para cargar los 40 productos del catálogo.
4. Copia `.env.example` a `.env.local` y completa `NEXT_PUBLIC_SUPABASE_URL` y `NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY` desde Supabase → **Connect** o **Project Settings → API Keys → Publishable key**. Si tu proyecto solo muestra la clave antigua `anon`, puedes colocarla como `NEXT_PUBLIC_SUPABASE_ANON_KEY`; la aplicación todavía la acepta.

La política `anon` del esquema es temporal y deliberadamente pública, sin autenticación. Cualquier visitante con acceso a la app puede modificar datos. La publishable key no es un secreto y no sustituye RLS. Sustituye esas políticas por reglas ligadas a usuarios antes de usar datos reales o sensibles. Nunca coloques la clave `secret`/`service_role` en una variable `NEXT_PUBLIC_` ni en el navegador.

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
3. En **Project Settings → Environment Variables**, agrega estas dos variables para Production, Preview y Development:

   ```env
   NEXT_PUBLIC_SUPABASE_URL=https://TU_PROJECT_REF.supabase.co
   NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY=sb_publishable_TU_CLAVE
   ```

   Copia la URL y publishable key desde Supabase → **Connect** o **Project Settings → API Keys**. Para un proyecto antiguo también puedes usar `NEXT_PUBLIC_SUPABASE_ANON_KEY` con su clave `anon`.
4. Ejecuta `supabase/schema.sql` y luego `supabase/seed.sql` una vez en el SQL Editor del proyecto Supabase. Después despliega en Vercel.

## Funcionalidades

- Dashboard con productos, unidades, valoración, alertas y movimientos recientes.
- Inventario con búsqueda, categoría, estado, orden y tarjetas adaptables a móvil.
- Detalle de producto con stock por sabor, entradas, salidas, ajustes, mermas e historial.
- Alta, edición y baja de productos; gestión de sabores.
- Historial global filtrable y descarga de inventario/movimientos en CSV.
- SQL de Supabase con políticas RLS y RPC transaccional `adjust_stock`.
