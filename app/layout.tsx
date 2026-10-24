import type { Metadata } from 'next';
import './globals.css';
import { AppShell } from '@/components/app-shell';
import { GlobalToast } from '@/components/global-toast';
export const metadata: Metadata = { title:'Inventario | Helados Panda Ballivián', description:'Control de inventario de Agencia Helados Panda Ballivián', icons:{icon:'/panda.jpg'} };
export default function RootLayout({children}:{children:React.ReactNode}) { return <html lang="es"><body><GlobalToast/><AppShell>{children}</AppShell></body></html>; }
