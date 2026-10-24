# Revisión del catálogo

Se asociaron **41 imágenes de producto** con las 41 fichas con precio del archivo fuente. La imagen hash `04a95444-7c0e-4509-9a68-0139bf9d212b.jpg` se revisó visualmente: es la portada/logo de Agencia Helados Panda y no se cargó como producto.

## Puntos para confirmar

- Los nombres de dos imágenes no coinciden literalmente con el encabezado del texto: `YOGURT DE BOTTELLA 2 LTS.jpg` se vinculó a “YOGURT BOTELLA 2 LITROSCUU” (se normalizó a “Yogurt de botella 2 lts”), y `CASATTA.jpg` a “CASATTA”. Confirmar escritura comercial preferida.
- Los precios del origen no aclaran de forma uniforme si son por unidad o por presentación. Se conservaron tal cual y se usó “bolsa” cuando el origen especifica cantidad por/en bolsa, “botella” para los yogures, “caja” para Caja 5 litros y “unidad” para los demás. Confirmar especialmente los precios de productos sin cantidad de empaque indicada.
- Para productos sin sabores explícitos se creó el sabor técnico **General**, tal como pide el modelo de inventario. Se pueden reemplazar desde la ficha del producto.
- El origen no trae textos de descripción separados del precio, sabores y cantidad por empaque. Las descripciones quedan vacías cuando no hay una cantidad explícita; no se añadieron características comerciales.
- Se asignaron categorías por el nombre y tipo de producto (Helados, Postres, Yogurt y Granizados); las categorías son una clasificación inicial editable.
- Ninguna imagen de producto excede 300 KB; por ello se copiaron sin recomprimir.

Los productos dudosos conservan el dato de origen disponible y no recibieron precios inventados.
