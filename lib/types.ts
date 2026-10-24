export type Product={id:string;name:string;description:string;category:string;price:number;unit:string;min_stock:number;image_url:string;active:boolean;created_at:string;flavors:Flavor[]};
export type Flavor={id:string;product_id:string;name:string;stock:number};
export type Movement={id:string;product_id:string;flavor_id:string;product_name:string;flavor_name:string;type:'entrada'|'salida'|'ajuste'|'merma';quantity:number;stock_before:number;stock_after:number;note:string;created_at:string};
