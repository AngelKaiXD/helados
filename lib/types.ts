export type Product={id:string;name:string;description:string;category:string;price:number;unit:string;min_stock:number;image_url:string;active:boolean;expires_at:string|null;created_at:string;flavors:Flavor[]};
export type Flavor={id:string;product_id:string;name:string;stock:number};
export type Movement={id:string;product_id:string;flavor_id:string;product_name:string;flavor_name:string;type:'entrada'|'salida'|'ajuste'|'merma';quantity:number;stock_before:number;stock_after:number;note:string;created_at:string};
export type Sale={id:string;payment_method:'efectivo'|'qr';total:number;created_at:string;items:{product_id:string;product_name:string;flavor_id:string;flavor_name:string;quantity:number;unit_price:number}[]};
