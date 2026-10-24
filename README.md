# Inventario de Agencia Helados Panda Ballivián

Aplicación en español para registrar productos, sabores, existencias y movimientos de inventario. Moneda: BOB (Bs). Zona horaria de operación: Bolivia (`America/La_Paz`).

## Requisitos

- Node.js 20 o superior y npm.
- Proyecto Supabase (opcional para desarrollo local; sin credenciales la app guarda los cambios en el navegador).

## Configurar Supabase

1. Crea un proyecto en [Supabase](https://supabase.com/).
2. En **SQL Editor**, ejecuta `supabase/schema.sql`.
3. Ejecuta después `supabase/seed.sql` para cargar los 40 productos del catálogo.
4. Copia `.env.example` a `.env.local` y completa `NEXT_PUBLIC_SUPABASE_URL` y `NEXT_PUBLIC_SUPABASE_ANON_KEY` desde Project Settings → API.

La política `anon` del esquema es temporal y deliberadamente pública, sin autenticación. Cualquier visitante con acceso a la app puede modificar datos. Sustituye esas políticas por reglas ligadas a usuarios antes de usar datos sensibles.

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

1. Inicializa el repositorio local ya preparado con `git init` y el commit inicial.
2. Crea un repositorio vacío en GitHub, agrega su URL como remoto y sube la rama desde tu equipo (`git push -u origin main`). No se hizo push desde este proyecto.
3. En Vercel, importa el repositorio de GitHub y conserva el preset Next.js.
4. Agrega las variables `NEXT_PUBLIC_SUPABASE_URL` y `NEXT_PUBLIC_SUPABASE_ANON_KEY` en Project Settings → Environment Variables y despliega.

## Funcionalidades

- Dashboard con productos, unidades, valoración, alertas y movimientos recientes.
- Inventario con búsqueda, categoría, estado, orden y tarjetas adaptables a móvil.
- Detalle de producto con stock por sabor, entradas, salidas, ajustes, mermas e historial.
- Alta, edición y baja de productos; gestión de sabores.
- Historial global filtrable y descarga de inventario/movimientos en CSV.
- SQL de Supabase con políticas RLS y RPC transaccional `adjust_stock`.
